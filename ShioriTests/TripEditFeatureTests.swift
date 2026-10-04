import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori

/// `TripEditFeature` を `TestStore` で検証する
@MainActor
struct TripEditFeatureTests {
    private func makeSpot(id: UUID = UUID(), title: String) -> Spot {
        Spot(id: id, title: title, startTime: nil, durationMinutes: nil, memo: "")
    }

    private func makeDraft(
        title: String = "東京",
        startDate: Date = Date(timeIntervalSince1970: 0),
        days: [[String]]
    ) -> TripDraft {
        let itineraryDays = days.map { titles in
            ItineraryDay(
                id: UUID(),
                spots: titles.map { makeSpot(title: $0) }
            )
        }
        return TripDraft(
            info: TripInfo(id: UUID(), title: title, startDate: startDate),
            itinerary: Itinerary(candidateSpots: [], itineraryDays: itineraryDays)
        )
    }

    private func makeState(
        title: String = "東京",
        startDate: Date = Date(timeIntervalSince1970: 0),
        days: [[String]] = [[]]
    ) -> TripEditFeature.State {
        TripEditFeature.State(draft: makeDraft(title: title, startDate: startDate, days: days))
    }

    @Test func タイトル変更で下書きのタイトルが更新されること() async {
        let store = TestStore(initialState: makeState(title: "旧")) {
            TripEditFeature()
        }

        await store.send(.titleChanged("新")) {
            $0.draft.info.title = "新"
        }
    }

    @Test func 開始日変更で下書きの開始日が更新されること() async {
        let newDate = Date(timeIntervalSince1970: 86_400)
        let store = TestStore(initialState: makeState()) {
            TripEditFeature()
        }

        await store.send(.startDateChanged(newDate)) {
            $0.draft.info.startDate = newDate
        }
    }

    @Test func 日数変更で下書きの新日数が更新されること() async {
        let store = TestStore(initialState: makeState(days: [[], []])) {
            TripEditFeature()
        }

        await store.send(.numDaysChanged(3)) {
            $0.draft.newNumDays = 3
        }
    }

    @Test func 日数を減らさずに保存すると保存要求を送り閉じること() async {
        let draft = makeDraft(days: [["A"], ["B"]])
        let store = TestStore(initialState: TripEditFeature.State(draft: draft)) {
            TripEditFeature()
        }

        await store.send(.saveButtonTapped)
        await store.receive(\.delegate.saveRequested)

        #expect(store.state.dayCountReductionPending == nil)
        #expect(store.state.draft == draft)
    }

    @Test func 日数を減らして保存すると移動予定のタイトル付きで確認待ちになること() async {
        var draft = makeDraft(days: [
            ["一日目"],
            ["二日目甲", "二日目乙"],
            ["三日目"],
        ])
        draft.newNumDays = 1
        let expectedTitles = draft.spotTitlesToMoveWhenReducingDayCount(to: 1)
        let store = TestStore(initialState: TripEditFeature.State(draft: draft)) {
            TripEditFeature()
        }

        await store.send(.saveButtonTapped) {
            $0.dayCountReductionPending = TripEditFeature.DayCountReductionPending(
                spotTitlesToMove: expectedTitles
            )
        }

        #expect(expectedTitles == ["二日目甲", "二日目乙", "三日目"])
        #expect(store.state.draft == draft)
    }

    @Test func 日数削減を確定すると確認待ちをクリアし保存要求を送ること() async {
        var draft = makeDraft(days: [["A"], ["B"], ["C"]])
        draft.newNumDays = 1
        let store = TestStore(
            initialState: TripEditFeature.State(
                draft: draft,
                dayCountReductionPending: .init(spotTitlesToMove: ["B", "C"])
            )
        ) {
            TripEditFeature()
        }

        await store.send(.dayCountReductionConfirmed) {
            $0.dayCountReductionPending = nil
        }
        await store.receive(\.delegate.saveRequested)

        #expect(store.state.draft == draft)
        #expect(store.state.dayCountReductionPending == nil)
    }

    @Test func 日数削減確認を閉じると旅程は変えず確認待ちだけクリアすること() async {
        var draft = makeDraft(days: [["A"], ["B"]])
        draft.newNumDays = 1
        let store = TestStore(
            initialState: TripEditFeature.State(
                draft: draft,
                dayCountReductionPending: .init(spotTitlesToMove: ["B"])
            )
        ) {
            TripEditFeature()
        }

        await store.send(.dayCountReductionDismissed) {
            $0.dayCountReductionPending = nil
        }

        #expect(store.state.draft == draft)
    }

    @Test func キャンセルすると閉じること() async {
        let draft = makeDraft(days: [["A"]])
        let store = TestStore(initialState: TripEditFeature.State(draft: draft)) {
            TripEditFeature()
        }

        await store.send(.cancelButtonTapped)

        #expect(store.state.draft == draft)
        #expect(store.state.dayCountReductionPending == nil)
    }
}
