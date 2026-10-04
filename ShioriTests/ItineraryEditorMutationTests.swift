import Foundation
import Testing
@testable import Shiori

struct ItineraryEditorMutationTests {
    private func makeSpot(
        id: UUID = UUID(),
        title: String,
        memo: String = ""
    ) -> Spot {
        Spot(id: id, title: title, startTime: nil, durationMinutes: nil, memo: memo)
    }
    
    private func makeSpot(
        id: UUID = UUID(),
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

    private func makeItinerary(
        candidates: [Spot] = [],
        days: [[Spot]]
    ) -> Itinerary {
        Itinerary(
            candidateSpots: candidates,
            itineraryDays: days.map { spots in
                ItineraryDay(id: UUID(), spots: spots)
            }
        )
    }

    // MARK: - addCandidate

    @Test func 候補追加で前後空白を除いたタイトルを候補末尾へ追加すること() {
        var itinerary = makeItinerary(days: [[]])

        itinerary.addCandidate(title: "  カフェ  ")

        #expect(itinerary.candidateSpots.count == 1)
        #expect(itinerary.candidateSpots[0].title == "カフェ")
        #expect(itinerary.candidateSpots[0].memo == "")
        #expect(itinerary.candidateSpots[0].startTime == nil)
        #expect(itinerary.candidateSpots[0].durationMinutes == nil)
    }

    @Test func タイトルが空または空白のみのとき候補追加は何もしないこと() {
        var itinerary = makeItinerary(days: [[]])
        let before = itinerary

        itinerary.addCandidate(title: "")
        itinerary.addCandidate(title: "   ")

        #expect(itinerary == before)
    }

    // MARK: - confirmCandidate
    
    @Test func 確定で日IDに対応する日へ候補を移すこと() {
        let candidateID = UUID()
        let day0ID = UUID()
        let day1ID = UUID()
        var itinerary = Itinerary(
            candidateSpots: [makeSpot(id: candidateID, title: "候補")],
            itineraryDays: [
                ItineraryDay(id: day0ID, spots: [makeSpot(title: "Day0")]),
                ItineraryDay(id: day1ID, spots: []),
            ]
        )

        guard itinerary.itineraryDays.firstIndex(where: { $0.id == day1ID }) != nil else {
            Issue.record("day1ID must exist")
            return
        }
        itinerary.confirmCandidate(spotID: candidateID, toDayID: day1ID)

        #expect(itinerary.candidateSpots.isEmpty)
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [candidateID])
    }

    // MARK: - returnSpotToCandidates

    @Test func 候補へ戻すと確定済み行き先を候補末尾へ移すこと() {
        let spotAID = UUID()
        let spotBID = UUID()
        let existingCandidateID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: existingCandidateID, title: "候補")],
            days: [
                [makeSpot(id: spotAID, title: "A"), makeSpot(id: spotBID, title: "B")],
                [],
            ]
        )

        itinerary.returnSpotToCandidates(spotID: spotAID)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotBID])
        #expect(itinerary.candidateSpots.map(\.id) == [existingCandidateID, spotAID])
    }

    @Test func 未知の行き先IDのとき候補へ戻しても何もしないこと() {
        var itinerary = makeItinerary(
            candidates: [makeSpot(title: "候補")],
            days: [[makeSpot(title: "A")]]
        )
        let before = itinerary

        itinerary.returnSpotToCandidates(spotID: UUID())

        #expect(itinerary == before)
    }

    // MARK: - deleteSpot

    @Test func 削除で候補から行き先を取り除くこと() {
        let candidateID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補"), makeSpot(title: "他")],
            days:[[]]
        )

        itinerary.deleteSpot(spotID: candidateID)

        #expect(itinerary.candidateSpots.map(\.title) == ["他"])
    }

    @Test func 削除で確定日の行き先を取り除くこと() {
        let spotAID = UUID()
        let spotBID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])

        itinerary.deleteSpot(spotID: spotAID)

        #expect(itinerary.itineraryDays[0].spots.isEmpty)
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotBID])
    }

    @Test func 未知の行き先IDのとき削除は何もしないこと() {
        var itinerary = makeItinerary(
            candidates: [makeSpot(title: "候補")],
            days: [[makeSpot(title: "A")]]
        )
        let before = itinerary

        itinerary.deleteSpot(spotID: UUID())

        #expect(itinerary == before)
    }

    // MARK: - updateSpot

    @Test func 更新で候補の行き先を置き換えること() {
        let spotID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: spotID, title: "旧", memo: "m1")],
            days: [[]]
        )
        let updated = makeSpot(id: spotID, title: "新", memo: "m2")

        itinerary.updateSpot(updated)

        #expect(itinerary.candidateSpots == [updated])
    }

    @Test func 更新で確定済み行き先を置き換えること() {
        let spotID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotID, title: "旧"), makeSpot(title: "他")],
        ])
        let updated = makeSpot(id: spotID, title: "新", memo: "メモ")

        itinerary.updateSpot(updated)

        #expect(itinerary.itineraryDays[0].spots[0] == updated)
        #expect(itinerary.itineraryDays[0].spots[1].title == "他")
    }

    @Test func タイトルが空または空白のみのとき更新は何もしないこと() {
        let spotID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: spotID, title: "旧")],
            days: [[]]
        )
        let before = itinerary

        itinerary.updateSpot(makeSpot(id: spotID, title: "   "))

        #expect(itinerary == before)
    }

    @Test func 未知の行き先IDのとき更新は何もしないこと() {
        var itinerary = makeItinerary(
            candidates: [makeSpot(title: "候補")],
            days: [[makeSpot(title: "A")]]
        )
        let before = itinerary

        itinerary.updateSpot(makeSpot(id: UUID(), title: "新"))

        #expect(itinerary == before)
    }

    // MARK: - moveConfirmedSpotUp / Down

    @Test func 上へ移動で同じ日内の前の行き先と入れ替えること() {
        let spotAID = UUID()
        let spotBID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A"), makeSpot(id: spotBID, title: "B")],
        ])

        itinerary.moveConfirmedSpotUp(spotID: spotBID)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotBID, spotAID])
    }

    @Test func 下へ移動で日境界を越えて入れ替えること() {
        let spotAID = UUID()
        let spotBID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])

        itinerary.moveConfirmedSpotDown(spotID: spotAID)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotBID])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotAID])
    }

    @Test func 先頭の行き先を上へ移動しても何もしないこと() {
        let spotAID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A"), makeSpot(title: "B")],
        ])
        let before = itinerary

        itinerary.moveConfirmedSpotUp(spotID: spotAID)

        #expect(itinerary == before)
    }

    @Test func 末尾の行き先を下へ移動しても何もしないこと() {
        let spotBID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(title: "A"), makeSpot(id: spotBID, title: "B")],
        ])
        let before = itinerary

        itinerary.moveConfirmedSpotDown(spotID: spotBID)

        #expect(itinerary == before)
    }

    @Test func 未知の行き先IDのとき上へ移動しても何もしないこと() {
        var itinerary = makeItinerary(days: [[makeSpot(title: "A")]])
        let before = itinerary

        itinerary.moveConfirmedSpotUp(spotID: UUID())

        #expect(itinerary == before)
    }

    // MARK: - moveSpotToPreviousDay / NextDay

    @Test func 翌日へ移動で移動先の末尾へ追加すること() {
        let spotAID = UUID()
        let spotCID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A"), makeSpot(title: "B")],
            [makeSpot(id: spotCID, title: "C")],
        ])

        itinerary.moveSpotToNextDay(spotID: spotAID)

        #expect(itinerary.itineraryDays[0].spots.map(\.title) == ["B"])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotCID, spotAID])
    }

    @Test func 前日へ移動で移動先の末尾へ追加すること() {
        let spotBID = UUID()
        let spotAID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])

        itinerary.moveSpotToPreviousDay(spotID: spotBID)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotAID, spotBID])
        #expect(itinerary.itineraryDays[1].spots.isEmpty)
    }

    @Test func 一日目の行き先を前日へ移動しても何もしないこと() {
        let spotAID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(title: "B")],
        ])
        let before = itinerary

        itinerary.moveSpotToPreviousDay(spotID: spotAID)

        #expect(itinerary == before)
    }

    @Test func 最終日の行き先を翌日へ移動しても何もしないこと() {
        let spotBID = UUID()
        var itinerary = makeItinerary(days: [
            [makeSpot(title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])
        let before = itinerary

        itinerary.moveSpotToNextDay(spotID: spotBID)

        #expect(itinerary == before)
    }
    
    // MARK: - resolveScheduleConflicts
    
    @Test func 指定した日の時間重なりだけを解消し他の日は変えないこと() {
        let day1ID = UUID()
        let day2ID = UUID()
        var itinerary = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: day1ID,
                    spots: [
                        makeSpot(title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(title: "B", hour: 11, minute: 0, durationMinutes: 60),
                    ]
                ),
                ItineraryDay(
                    id: day2ID,
                    spots: [
                        makeSpot(title: "Day2Only", hour: 9, minute: 0, durationMinutes: 30),
                    ]
                ),
            ]
        )
        let day2Before = itinerary.itineraryDays[1]

        itinerary.resolveScheduleConflicts(dayID: day1ID)

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: itinerary.itineraryDays[0].spots).isEmpty)
        #expect(itinerary.itineraryDays[0].spots[1].startTime == SpotTime(hour: 11, minute: 30))
        #expect(itinerary.itineraryDays[1] == day2Before)
    }

    @Test func 未知の日IDのときは何もしないこと() {
        let dayID = UUID()
        var itinerary = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: dayID,
                    spots: [
                        makeSpot(title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(title: "B", hour: 11, minute: 0, durationMinutes: 60),
                    ]
                ),
            ]
        )
        let before = itinerary

        itinerary.resolveScheduleConflicts(dayID: UUID())

        #expect(itinerary == before)
    }
}
