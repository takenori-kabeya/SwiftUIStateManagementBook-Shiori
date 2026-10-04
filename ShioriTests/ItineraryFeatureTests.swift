import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori

/// `ItineraryFeature` を `TestStore` で検証する
@Suite(
    .dependencies {
        $0.uuid = .incrementing
        $0.date = .constant(Date(timeIntervalSince1970: 0))
    }
)
@MainActor
struct ItineraryFeatureTests {
    @Dependency(\.uuid) var uuid
    
    private func makeSpot(
        id: UUID,
        title: String,
        hour: Int? = nil,
        minute: Int = 0,
        durationMinutes: Int? = nil
    ) -> Spot {
        let startTime: SpotTime? = hour.map { SpotTime(hour: $0, minute: minute) }
        return Spot(
            id: id,
            title: title,
            startTime: startTime,
            durationMinutes: durationMinutes,
            memo: ""
        )
    }

    @Test func 指定した日の時間重なりだけを解消し他の日は変えないこと() async {
        let day1ID = uuid()
        let day2ID = uuid()
        let day2Spot = makeSpot(id: uuid(), title: "Day2Only", hour: 9, minute: 0, durationMinutes: 30)
        let initial = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: day1ID,
                    spots: [
                        makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60),
                    ]
                ),
                ItineraryDay(
                    id: day2ID,
                    spots: [day2Spot]
                ),
            ]
        )
        let store = TestStore(initialState: ItineraryFeature.State(itinerary: initial)) {
            ItineraryFeature()
        }
        await store.send(.autoShiftButtonTapped(dayID: day1ID)) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[1].startTime = SpotTime(hour: 11, minute: 30)
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
    }
    @Test func 未知の日IDのときは何もしないこと() async {
        let dayID = uuid()
        let initial = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: dayID,
                    spots: [
                        makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60),
                    ]
                ),
            ]
        )
        let store = TestStore(initialState: ItineraryFeature.State(itinerary: initial)) {
            ItineraryFeature()
        }

        await store.send(.autoShiftButtonTapped(dayID: uuid()))
        await store.receive(\.delegate.itineraryUpdated)
    }

    @Test func 候補追加でタイトルを候補へ追加すること() async {
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]) // ここのuuid()で0番が採られる
            )
        ) {
            ItineraryFeature()
        }
        let implicitSpotID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")! // makeSpotで生成されるSpotのIDを推測。0の次なので1のはず

        let newTitle = "新候補"
        await store.send(.addCandidateButtonTapped(title: newTitle)) {
            $0.$itinerary.withLock {
                $0.candidateSpots.append(makeSpot(id: implicitSpotID, title: newTitle))
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        #expect(store.state.itinerary.candidateSpots.map(\.title) == ["新候補"])
        #expect(store.state.itinerary.candidateSpots.count == 1)
        #expect(store.state.itinerary.candidateSpots[0].memo == "")
        #expect(store.state.itinerary.candidateSpots[0].startTime == nil)
    }
    


    @Test func 確定で日IDに対応する日へ候補を移すこと() async {
        let candidateID = uuid()
        let day0ID = uuid()
        let day1ID = uuid()
        let candidate = makeSpot(id: candidateID, title: "候補")
        let day0Spot = makeSpot(id: uuid(), title: "Day0")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [candidate],
                    itineraryDays: [
                        ItineraryDay(id: day0ID, spots: [day0Spot]),
                        ItineraryDay(id: day1ID, spots: []),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.confirmButtonTapped(candidate)) {
            $0.daySelection = ItineraryFeature.DaySelectionState(spot: candidate)
        }
        await store.send(.daySelected(dayID: day1ID)) {
            $0.$itinerary.withLock {
                $0.candidateSpots = []
                $0.itineraryDays[1].spots = [candidate]
            }
            $0.daySelection = nil
        }
        await store.receive(\.delegate.itineraryUpdated)
    }
    
    @Test func 日選択を閉じると候補は追加せず選択状態だけクリアすること() async {
        let candidateID = uuid()
        let dayID = uuid()
        let candidate = makeSpot(
            id: candidateID,
            title: "候補"
        )

        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [candidate],
                    itineraryDays: [
                        ItineraryDay(id: dayID)
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }
        
        await store.send(.confirmButtonTapped(candidate)) {
            $0.daySelection =
                ItineraryFeature.DaySelectionState(
                    spot: candidate
                )
        }

        await store.send(.daySelectionDismissed) {
            $0.daySelection = nil
        }

        #expect(
            store.state.itinerary.candidateSpots == [candidate]
        )
        #expect(
            store.state.itinerary.itineraryDays[0].spots.isEmpty
        )
    }

    @Test func 候補へ戻すと確定済み行き先を候補へ戻すこと() async {
        let spotID = uuid()


        let spot = makeSpot(id: spotID, title: "A")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: uuid(), spots: [spot])]
                )
            )
        ) {
            ItineraryFeature()
        }
        await store.send(.returnToCandidateButtonTapped(spotID: spotID)) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots = []
                $0.candidateSpots = [spot]
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
    }
    @Test func 上へ移動で前の行き先と入れ替えること() async {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA, spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveUpButtonTapped(spotID: spotBID)) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots = [spotB, spotA]
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
    }

    @Test func 下へ移動で次の行き先と入れ替えること() async {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA, spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveDownButtonTapped(spotID: spotAID)) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots = [spotB, spotA]
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
    }

    @Test func 前日へ移動で前日の末尾へ追加すること() async {
        let spotBID = uuid()
        let spotA = makeSpot(id: uuid(), title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA]),
                        ItineraryDay(id: uuid(), spots: [spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveToPreviousDayButtonTapped(spotID: spotBID)) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots = [spotA, spotB]
                $0.itineraryDays[1].spots = []
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
    }

    @Test func 翌日へ移動で翌日の末尾へ追加すること() async {
        let spotAID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: uuid(), title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA]),
                        ItineraryDay(id: uuid(), spots: [spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveToNextDayButtonTapped(spotID: spotAID)) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots = []
                $0.itineraryDays[1].spots = [spotB, spotA]
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
    }

    @Test func 削除ボタンで削除確認待ちになり行き先はまだ取り除かないこと() async {
        let spotID = uuid()
        let spot = makeSpot(id: spotID, title: "A")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: uuid(), spots: [spot])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.deleteButtonTapped(spotID: spotID)) {
            $0.spotPendingDeletion = spotID
        }
    }

    @Test func 削除確定で行き先を取り除き確認待ちをクリアすること() async {
        let spotID = uuid()
        let spot = makeSpot(id: spotID, title: "A")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: uuid(), spots: [spot])]
                ),
                spotPendingDeletion: spotID
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.deleteConfirmed) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots = []
            }
            $0.spotPendingDeletion = nil
        }
        await store.receive(\.delegate.itineraryUpdated)
    }

    @Test func 削除確認を閉じると旅程は変えず確認待ちだけクリアすること() async {
        let spotID = uuid()
        let spot = makeSpot(id: spotID, title: "A")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: uuid(), spots: [spot])]
                ),
                spotPendingDeletion: spotID
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.deleteConfirmationDismissed) {
            $0.spotPendingDeletion = nil
        }
    }

    @Test func 編集して保存すると旅程を更新し編集状態をクリアすること() async {
        let spotID = uuid()
        let original = makeSpot(id: spotID, title: "旧", hour: 10, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [original],
                    itineraryDays: [ItineraryDay(id: uuid())]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(original)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: original))
        }

        await store.send(.editSpot(.presented(.titleChanged("新")))) {
            $0.editSpot?.draft.title = "新"
        }

        var expectedDraft = SpotDraft(spot: original)
        expectedDraft.title = "新"

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.delegate.presented.saveRequested) {
            $0.$itinerary.withLock {
                $0.candidateSpots = [expectedDraft.spot()]
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }
    }

    @Test func 編集をキャンセルすると旅程は変えず編集状態だけクリアすること() async {
        let spotID = uuid()
        let original = makeSpot(id: spotID, title: "旧", hour: 10, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [original],
                    itineraryDays: [ItineraryDay(id: uuid())]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(original)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: original))
        }

        await store.send(.editSpot(.presented(.titleChanged("変更途中")))) {
            $0.editSpot?.draft.title = "変更途中"
        }

        await store.send(.editSpot(.presented(.cancelButtonTapped)))
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.itinerary.candidateSpots == [original])
    }

    @Test func 滞在を延ばして後続と重なるときずらし確認待ちになること() async {
        let dayID = uuid()
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A", hour: 10, minute: 0, durationMinutes: 60)
        let spotB = makeSpot(id: spotBID, title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(spotA)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: spotA))
        }
        await store.send(.editSpot(.presented(.durationMinutesChanged(90)))) {
            $0.editSpot?.draft.durationMinutes = 90
        }

        var expectedDraft = SpotDraft(spot: spotA)
        expectedDraft.durationMinutes = 90
        let extendedA = expectedDraft.spot()

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.presented.delegate.saveRequested) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[0] = extendedA
            }
            $0.scheduleShiftPending = ItineraryFeature.ScheduleShiftPending(
                dayID: dayID,
                fromSpotID: spotBID
            )
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.itinerary.itineraryDays[0].spots[1].startTime == SpotTime(hour: 11, minute: 0))
    }

    @Test func ずらし確定で後続の開始をずらし確認待ちをクリアすること() async {
        let dayID = uuid()
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A", hour: 10, minute: 0, durationMinutes: 90)
        let spotB = makeSpot(id: spotBID, title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB])]
                ),
                scheduleShiftPending: ItineraryFeature.ScheduleShiftPending(
                    dayID: dayID,
                    fromSpotID: spotBID
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.scheduleShiftConfirmed) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[1].startTime = SpotTime(hour: 11, minute: 30)
            }
            $0.scheduleShiftPending = nil
        }
        await store.receive(\.delegate.itineraryUpdated)
    }

    @Test func ずらし確認を閉じるとずらさず確認待ちだけクリアすること() async {
        let dayID = uuid()
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A", hour: 10, minute: 0, durationMinutes: 90)
        let spotB = makeSpot(id: spotBID, title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB])]
                ),
                scheduleShiftPending: ItineraryFeature.ScheduleShiftPending(
                    dayID: dayID,
                    fromSpotID: spotBID
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.scheduleShiftDismissed) {
            $0.scheduleShiftPending = nil
        }
        
        #expect(store.state.itinerary.itineraryDays[0].spots[0].durationMinutes == 90)
        #expect(store.state.itinerary.itineraryDays[0].spots[1].startTime == SpotTime(hour: 11, minute: 0))
    }

    @Test func 後続と重ならない延長ではずらし確認待ちにしないこと() async {
        let dayID = uuid()
        let spotA = makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 30)
        let spotB = makeSpot(id: uuid(), title: "B", hour: 12, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(spotA)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: spotA))
        }
        await store.send(.editSpot(.presented(.durationMinutesChanged(60)))) {
            $0.editSpot?.draft.durationMinutes = 60
        }

        var expectedDraft = SpotDraft(spot: spotA)
        expectedDraft.durationMinutes = 60

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.presented.delegate.saveRequested) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[0] = expectedDraft.spot()
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.scheduleShiftPending == nil)
    }

    @Test func 滞在を短くしてもずらし確認待ちにしないこと() async {
        let dayID = uuid()
        let spotA = makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90)
        let spotB = makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(spotA)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: spotA))
        }
        await store.send(.editSpot(.presented(.durationMinutesChanged(60)))) {
            $0.editSpot?.draft.durationMinutes = 60
        }

        var expectedDraft = SpotDraft(spot: spotA)
        expectedDraft.durationMinutes = 60

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.presented.delegate.saveRequested) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[0] = expectedDraft.spot()
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.scheduleShiftPending == nil)
    }

    @Test func 最後の行き先の滞在を延ばしてもずらし確認待ちにしないこと() async {
        let dayID = uuid()
        let spotA = makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(spotA)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: spotA))
        }
        await store.send(.editSpot(.presented(.durationMinutesChanged(120)))) {
            $0.editSpot?.draft.durationMinutes = 120
        }

        var expectedDraft = SpotDraft(spot: spotA)
        expectedDraft.durationMinutes = 120

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.presented.delegate.saveRequested) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[0] = expectedDraft.spot()
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.scheduleShiftPending == nil)
    }

    @Test func 終了が前倒しでも後続と重なるときはずらし確認待ちにしないこと() async {
        let dayID = uuid()
        let spotA = makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 120)
        let spotB = makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(spotA)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: spotA))
        }
        await store.send(.editSpot(.presented(.durationMinutesChanged(90)))) {
            $0.editSpot?.draft.durationMinutes = 90
        }

        var expectedDraft = SpotDraft(spot: spotA)
        expectedDraft.durationMinutes = 90

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.presented.delegate.saveRequested) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[0] = expectedDraft.spot()
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.itinerary.itineraryDays[0].spots[0].durationMinutes == 90)
        #expect(store.state.itinerary.itineraryDays[0].spots[1].startTime == SpotTime(hour: 11, minute: 0))
        #expect(store.state.scheduleShiftPending == nil)
    }

    @Test func 後ろ倒し後に先行と重なっても後続と重ならなければずらし確認待ちにしないこと() async {
        let dayID = uuid()
        let spotA = makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90)
        let spotB = makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let spotC = makeSpot(id: uuid(), title: "C", hour: 13, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB, spotC])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.editButtonTapped(spotB)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: spotB))
        }
        await store.send(.editSpot(.presented(.durationMinutesChanged(90)))) {
            $0.editSpot?.draft.durationMinutes = 90
        }

        var expectedDraft = SpotDraft(spot: spotB)
        expectedDraft.durationMinutes = 90

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.presented.delegate.saveRequested) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[1] = expectedDraft.spot()
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.itinerary.itineraryDays[0].spots[0] == spotA)
        #expect(store.state.itinerary.itineraryDays[0].spots[1].durationMinutes == 90)
        #expect(store.state.itinerary.itineraryDays[0].spots[2] == spotC)
        #expect(store.state.scheduleShiftPending == nil)
    }

    @Test func 予定時刻を後ろにずらして後続と重なるとき変更を反映しずらし確認待ちになること() async {
        let dayID = uuid()
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A", hour: 10, minute: 0, durationMinutes: 60)
        let spotB = makeSpot(id: spotBID, title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB])]
                )
            )
        ) {
            ItineraryFeature()
        }

        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1
        components.hour = 10
        components.minute = 30
        let newStart = Calendar.current.date(from: components)!

        await store.send(.editButtonTapped(spotA)) {
            $0.editSpot = SpotFeature.State(draft: SpotDraft(spot: spotA))
        }
        await store.send(.editSpot(.presented(.startTimeChanged(newStart)))) {
            $0.editSpot?.draft.startTime = newStart
        }

        var expectedDraft = SpotDraft(spot: spotA)
        expectedDraft.startTime = newStart
        let shiftedA = expectedDraft.spot()

        await store.send(.editSpot(.presented(.saveButtonTapped)))
        await store.receive(\.editSpot.presented.delegate.saveRequested) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[0] = shiftedA
            }
            $0.scheduleShiftPending = ItineraryFeature.ScheduleShiftPending(
                dayID: dayID,
                fromSpotID: spotBID
            )
        }
        await store.receive(\.delegate.itineraryUpdated)
        await store.receive(\.editSpot.dismiss) {
            $0.editSpot = nil
        }

        #expect(store.state.itinerary.itineraryDays[0].spots[0].startTime == SpotTime(hour: 10, minute: 30))
        #expect(store.state.itinerary.itineraryDays[0].spots[0].durationMinutes == 60)
        #expect(store.state.itinerary.itineraryDays[0].spots[1].startTime == SpotTime(hour: 11, minute: 0))
    }

    @Test func ずらし確定で変更した行き先より前は変えず後続だけずらすこと() async {
        let dayID = uuid()
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A", hour: 10, minute: 0, durationMinutes: 90)
        let spotB = makeSpot(id: spotBID, title: "B", hour: 11, minute: 0, durationMinutes: 60)
        let spotC = makeSpot(id: spotCID, title: "C", hour: 12, minute: 0, durationMinutes: 60)
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: dayID, spots: [spotA, spotB, spotC])]
                ),
                scheduleShiftPending: ItineraryFeature.ScheduleShiftPending(
                    dayID: dayID,
                    fromSpotID: spotBID
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.scheduleShiftConfirmed) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[1].startTime = SpotTime(hour: 11, minute: 30)
                $0.itineraryDays[0].spots[2].startTime = SpotTime(hour: 12, minute: 30)
            }
            $0.scheduleShiftPending = nil
        }
        await store.receive(\.delegate.itineraryUpdated)

        #expect(store.state.itinerary.itineraryDays[0].spots[0].startTime == SpotTime(hour: 10, minute: 0))
        #expect(store.state.itinerary.itineraryDays[0].spots[0].durationMinutes == 90)
    }
}
