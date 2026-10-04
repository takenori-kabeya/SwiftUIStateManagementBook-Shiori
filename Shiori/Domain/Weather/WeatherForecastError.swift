import Foundation

nonisolated enum WeatherForecastError: LocalizedError, Equatable, Sendable {
    case noPlaceSelected
    case invalidResponse
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .noPlaceSelected:
            return "天気予報用の場所が選択されていません。"
        case .invalidResponse:
            return "天気予報の応答形式が不正です。"
        case .requestFailed:
            return "天気予報の取得に失敗しました。"
        }
    }
}
