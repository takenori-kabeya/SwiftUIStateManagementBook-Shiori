import Foundation

enum PlaceSearchError: LocalizedError, Equatable, Sendable {
    case emptyQuery
    case notFound
    case searchFailed

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "地名を入力してください。"
        case .notFound:
            return "該当する場所が見つかりませんでした。"
        case .searchFailed:
            return "場所の検索に失敗しました。"
        }
    }
}
