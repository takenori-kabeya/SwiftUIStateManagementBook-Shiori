import Foundation

nonisolated enum MemoAttributedString {
    static func make(from memo: String) -> AttributedString {
        var attributed = AttributedString(memo)

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributed
        }

        let nsRange = NSRange(memo.startIndex..<memo.endIndex, in: memo)
        let matches = detector.matches(in: memo, options: [], range: nsRange)

        for match in matches {
            guard let url = match.url,
                  let stringRange = Range(match.range, in: memo),
                  let attributedRange = Range(stringRange, in: attributed) else {
                continue
            }
            attributed[attributedRange].link = url
        }

        return attributed
    }
}
