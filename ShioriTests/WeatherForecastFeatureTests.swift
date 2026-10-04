import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori

/// `fetch` の呼び出しを suspend / resume し、キャンセルを観測するテスト用ゲート
class FetchGate<ResultT>: @unchecked Sendable {
    private struct Call {
        var continuation: CheckedContinuation<[ResultT], Error>?
        var isCancelled = false
    }
    
    init(keepContinuationWhenCancel: Bool = false) {
        self.keepContinuationWhenCancel = keepContinuationWhenCancel
    }

    private let lock = NSLock()
    private var calls: [Call] = []
    private(set) var fetchCallCount = 0
    private(set) var cancelledCallIndices: Set<Int> = []
    private var fetchCallCountWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private var cancelledWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    var keepContinuationWhenCancel: Bool

    /// fetch を開始し、resume かキャンセルまでサスペンドする
    func fetch(
    ) async throws -> [ResultT] {
        let callIndex = lock.withLock {
            let index = fetchCallCount
            fetchCallCount += 1
            calls.append(Call())
            let count = fetchCallCount
            fetchCallCountWaiters[count]?.forEach { $0.resume() }
            fetchCallCountWaiters[count] = nil
            return index
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.withLock {
                    guard callIndex < calls.count else { return }
                    if calls[callIndex].isCancelled && !keepContinuationWhenCancel {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    calls[callIndex].continuation = continuation
                }
            }
        } onCancel: {
            self.handleCancellation(callIndex: callIndex)
        }
    }

    /// 指定インデックスの呼び出しをキャンセル済みにし、待ち中なら CancellationError で起こす
    private func handleCancellation(callIndex: Int) {
        lock.withLock {
            guard callIndex < calls.count else { return }
            calls[callIndex].isCancelled = true
            cancelledCallIndices.insert(callIndex)
            cancelledWaiters[callIndex]?.forEach { $0.resume() }
            cancelledWaiters[callIndex] = nil
            guard !keepContinuationWhenCancel else { return }
            if let continuation = calls[callIndex].continuation {
                calls[callIndex].continuation = nil
                continuation.resume(throwing: CancellationError())
            }
        }
    }

    /// fetch の呼び出し回数が expected 以上になるまで待つ
    func waitUntilFetchCallCount(_ expected: Int) async {
        if callCount() >= expected { return }
        await withCheckedContinuation { continuation in
            lock.withLock {
                if fetchCallCount >= expected {
                    continuation.resume()
                } else {
                    fetchCallCountWaiters[expected, default: []].append(continuation)
                }
            }
        }
    }
    
    /// 指定インデックスの fetch がキャンセルされるまで待つ
    func waitUntilCancelled(at index: Int) async {
        if cancelledIndices().contains(index) { return }
        await withCheckedContinuation { continuation in
            lock.withLock {
                if cancelledCallIndices.contains(index) {
                    continuation.resume()
                } else {
                    cancelledWaiters[index, default: []].append(continuation)
                }
            }
        }
    }

    /// 指定インデックスの待ち中 fetch を success / failure で再開する
    func resume(at index: Int, with result: Result<[ResultT], Error>) {
        lock.withLock {
            guard index < calls.count else { return }
            guard keepContinuationWhenCancel || !calls[index].isCancelled else { return }
            guard let continuation = calls[index].continuation else { return }
            calls[index].continuation = nil
            switch result {
            case let .success(forecasts):
                continuation.resume(returning: forecasts)
            case let .failure(error):
                continuation.resume(throwing: error)
            }
        }
    }

    /// これまでに開始された fetch の回数を返す
    func callCount() -> Int {
        lock.withLock { fetchCallCount }
    }

    /// キャンセルされた fetch のインデックス集合を返す
    func cancelledIndices() -> Set<Int> {
        lock.withLock { cancelledCallIndices }
    }
}

private extension NSLock {
    /// ロックを取得してブロックを実行し、実行後にロックを解放する
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

private func makePlace(
    name: String = "東京駅",
    latitude: Double = 35.6812,
    longitude: Double = 139.7671
) -> Place {
    Place(
        name: name,
        address: "東京都千代田区",
        latitude: latitude,
        longitude: longitude
    )
}

private func makeForecast(date: String = "2026-08-01") -> DailyWeatherForecast {
    DailyWeatherForecast.available(
        date: try! Date(date, strategy: .iso8601.year().month().day()),
        condition: .clearSky,
        maxTemperature: 30.0,
        minTemperature: 22.0,
        precipitationProbability: 10
    )
}

private func makeCondition(
    place: Place?,
    fromDate: Date = Date.makeDate(year: 2026, month: 8, day: 1),
    numDays: Int = 3
) -> ForecastCondition {
    ForecastCondition(
        latitude: place?.latitude,
        longitude: place?.longitude,
        fromDate: fromDate,
        numDays: numDays
    )
}

@MainActor
private func makeStoreWithGate(
    gate: FetchGate<DailyWeatherForecast>,
    initialForecasts: [DailyWeatherForecast] = []
) -> TestStore<WeatherForecastFeature.State, WeatherForecastFeature.Action> {
    let place = makePlace()
    let condition = makeCondition(place: place)
    return TestStore(
        initialState: WeatherForecastFeature.State(forecastCondition: condition, dailyForecasts: initialForecasts)
    ) {
        WeatherForecastFeature()
    } withDependencies: {
        $0.weatherForecast.fetchForecast = { latitude, longitude, fromDate, numDays in
            try await gate.fetch()
        }
    }
}

/// 2回の refreshRequested を送信し、2回目の fetch が開始されるのを待つ
/// 戻り値は1回目の refreshRequested の Task。
@MainActor
private func sendTwoRefreshRequestsAndWaitForSecondFetch(
    gate: FetchGate<DailyWeatherForecast>,
    store: TestStore<WeatherForecastFeature.State, WeatherForecastFeature.Action>
) async -> TestStoreTask {
    let firstTask = await store.send(.refreshRequested) {
        $0.isFetching = true
        $0.errorMessage = nil
    }
    await gate.waitUntilFetchCallCount(1)

    await store.send(.refreshRequested)
    await gate.waitUntilFetchCallCount(2)
    return firstTask
}

/// `WeatherForecastFeature` を `TestStore` で検証する
@Suite(.dependencies)
@MainActor
struct WeatherForecastFeatureTests {
    @Test func 場所なしのときクライアントを呼ばずnoPlaceSelectedにすること() async {
        actor Counter {
            var count: Int = 0
            func increment() { count += 1 }
        }
        let fetchCallCount = Counter()
        let store = TestStore(initialState: WeatherForecastFeature.State(forecastCondition: ForecastCondition(fromDate: Date.makeDate(year: 2026, month: 9, day: 1), numDays: 4))) {
            WeatherForecastFeature()
        } withDependencies: {
            $0.weatherForecast.fetchForecast = { _, _, _, _ in
                await fetchCallCount.increment()
                return []
            }
        }
        
        let expectedForecasts = [
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 9, day: 1), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 9, day: 2), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 9, day: 3), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 9, day: 4), availability: .notYet),
        ]

        await store.send(.refreshRequested) {
            $0.dailyForecasts = expectedForecasts
            $0.errorMessage = WeatherForecastError.noPlaceSelected.localizedDescription
            $0.isFetching = false
        }

        #expect(await fetchCallCount.count == 0)
        await store.finish()
    }

    @Test func 取得成功でdailyForecastsを更新すること() async {
        let place = makePlace()
        let condition = makeCondition(place: place)
        let forecasts = [
            makeForecast(date: "2026-08-01"),
            makeForecast(date: "2026-08-02"),
            makeForecast(date: "2026-08-03"),
        ]
        let store = TestStore(
            initialState: WeatherForecastFeature.State(forecastCondition: condition)
        ) {
            WeatherForecastFeature()
        } withDependencies: {
            $0.weatherForecast.fetchForecast = { latitude, longitude, fromDate, numDays in
                #expect(latitude == place.latitude)
                #expect(longitude == place.longitude)
                return forecasts
            }
        }

        await store.send(.refreshRequested) {
            $0.isFetching = true
            $0.errorMessage = nil
        }
        await store.receive(\.fetchResponse.success) {
            $0.isFetching = false
            $0.dailyForecasts = forecasts
            $0.errorMessage = nil
        }
        await store.finish()
    }

    @Test func 取得失敗でエラーメッセージを設定するが予報は維持すること() async {
        let place = makePlace()
        let store = TestStore(
            initialState: WeatherForecastFeature.State(
                forecastCondition: makeCondition(place: place),
                dailyForecasts: [makeForecast()]
            )
        ) {
            WeatherForecastFeature()
        } withDependencies: {
            $0.weatherForecast.fetchForecast = { _, _, _, _ in
                throw WeatherForecastError.requestFailed
            }
        }

        await store.send(.refreshRequested) {
            $0.isFetching = true
            $0.errorMessage = nil
        }
        await store.receive(\.fetchResponse.failure) {
            $0.isFetching = false
            $0.errorMessage = WeatherForecastError.requestFailed.localizedDescription
        }
        await store.finish()
    }

    @Test func forecastConditionUpdatedで予報状態をリセットすること() async {
        let place = makePlace(name: "旧")
        let store = TestStore(
            initialState: WeatherForecastFeature.State(
                forecastCondition: makeCondition(place: place),
                dailyForecasts: [makeForecast()],
                isFetching: true,
                errorMessage: "前回のエラー"
            )
        ) {
            WeatherForecastFeature()
        }

        let newPlace = makePlace(name: "新")
        let newCondition = makeCondition(
            place: newPlace,
            fromDate: Date.makeDate(year: 2026, month: 8, day: 4),
            numDays: 5
        )
        let expectedForecasts = [
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 4), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 5), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 6), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 7), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 8), availability: .notYet),
        ]
        await store.send(.forecastConditionUpdated(newCondition)) {
            $0.forecastCondition = newCondition
            $0.dailyForecasts = expectedForecasts
            $0.errorMessage = nil
            $0.isFetching = false
        }
        await store.finish()
    }

    @Test func forecastConditionUpdatedで緯度経度がnilのとき予報とエラーメッセージをクリアすること() async {
        let place = makePlace()
        let store = TestStore(
            initialState: WeatherForecastFeature.State(
                forecastCondition: makeCondition(place: place),
                dailyForecasts: [makeForecast()],
                errorMessage: "前回のエラー"
            )
        ) {
            WeatherForecastFeature()
        }

        let newCondition = makeCondition(place: nil)
        let expectedForecasts = [
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 1), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 2), availability: .notYet),
            DailyWeatherForecast(date: Date.makeDate(year: 2026, month: 8, day: 3), availability: .notYet),
        ]
        await store.send(.forecastConditionUpdated(newCondition)) {
            $0.forecastCondition = newCondition
            $0.dailyForecasts = expectedForecasts
            $0.errorMessage = nil
        }
        await store.finish()
    }
}

/// キャンセル検証は in-flight Effect の競合を避けるため直列実行する
@Suite(.serialized, .dependencies)
@MainActor
struct WeatherForecastFeatureCancellationTests {
    @Test func 二回目の更新で一回目の取得をキャンセルし最新の成功だけ反映すること() async {
        let gate = FetchGate<DailyWeatherForecast>()
        let firstForecasts = [makeForecast(date: "2026-08-01")]
        let secondForecasts = [makeForecast(date: "2026-08-02")]
        let store = makeStoreWithGate(gate: gate)

        _ = await sendTwoRefreshRequestsAndWaitForSecondFetch(gate: gate, store: store)
        await gate.waitUntilCancelled(at: 0)

        #expect(gate.callCount() == 2)
        #expect(gate.cancelledIndices().contains(0))
        #expect(!gate.cancelledIndices().contains(1))
        
        gate.resume(at: 0, with: .success(firstForecasts))
        #expect(store.state.isFetching == true)
        #expect(store.state.dailyForecasts == [])
        #expect(store.state.errorMessage == nil)

        gate.resume(at: 1, with: .success(secondForecasts))
        await store.receive(\.fetchResponse.success) {
            $0.isFetching = false
            $0.dailyForecasts = secondForecasts
            $0.errorMessage = nil
        }
        await store.finish()
    }
    
    @Test func 二回目の更新で一回目の取得から成功が返ってきても最新の成功だけ反映すること() async {
        let gate = FetchGate<DailyWeatherForecast>(keepContinuationWhenCancel: true)
        let firstForecasts = [makeForecast(date: "2026-08-01")]
        let secondForecasts = [makeForecast(date: "2026-08-02")]
        let store = makeStoreWithGate(gate: gate)

        _ = await sendTwoRefreshRequestsAndWaitForSecondFetch(gate: gate, store: store)
        await gate.waitUntilCancelled(at: 0)

        #expect(gate.callCount() == 2)
        #expect(gate.cancelledIndices().contains(0))
        #expect(!gate.cancelledIndices().contains(1))
        
        gate.resume(at: 0, with: .success(firstForecasts))
        #expect(store.state.isFetching == true)
        #expect(store.state.dailyForecasts == [])
        #expect(store.state.errorMessage == nil)

        gate.resume(at: 1, with: .success(secondForecasts))
        await store.receive(\.fetchResponse.success) {
            $0.isFetching = false
            $0.dailyForecasts = secondForecasts
            $0.errorMessage = nil
        }
        await store.finish()
    }
    
    @Test func キャンセルされた一回目の取得失敗ではエラーメッセージを設定しないこと() async {
        let gate = FetchGate<DailyWeatherForecast>()
        let secondForecasts = [makeForecast(date: "2026-08-02")]
        let store = makeStoreWithGate(gate: gate)

        _ = await sendTwoRefreshRequestsAndWaitForSecondFetch(gate: gate, store: store)

        gate.resume(at: 0, with: .failure(WeatherForecastError.requestFailed))
        #expect(store.state.errorMessage == nil)
        #expect(store.state.isFetching == true)
        #expect(store.state.dailyForecasts == [])

        gate.resume(at: 1, with: .success(secondForecasts))
        await store.receive(\.fetchResponse.success) {
            $0.isFetching = false
            $0.dailyForecasts = secondForecasts
            $0.errorMessage = nil
        }
        await store.finish()
    }
    
    @Test func viewDisappearedで取得をキャンセルすること() async {
        let gate = FetchGate<DailyWeatherForecast>()
        let existingForecasts = [makeForecast(date: "2026-07-31")]
        let forecastsToFetch = [makeForecast(date: "2026-08-01")]
        let store = makeStoreWithGate(gate: gate, initialForecasts: existingForecasts)

        await store.send(.refreshRequested) {
            $0.isFetching = true
            $0.errorMessage = nil
        }
        await gate.waitUntilFetchCallCount(1)
        
        #expect(!gate.cancelledCallIndices.contains(0))
        #expect(store.state.errorMessage == nil)
        #expect(store.state.isFetching == true)
        #expect(store.state.dailyForecasts == existingForecasts)

        await store.send(.viewDisappeared) {
            $0.isFetching = false
        }
        await gate.waitUntilCancelled(at: 0)
        #expect(gate.cancelledCallIndices.contains(0))
        
        gate.resume(at: 0, with: .success(forecastsToFetch))
        
        await store.finish()
    }
}
