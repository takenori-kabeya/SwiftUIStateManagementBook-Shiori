import Foundation
import Testing
@testable import Shiori

struct MemoAttributedStringTests {
    private func linkURLs(in attributed: AttributedString) -> [URL] {
        attributed.runs.compactMap(\.link)
    }

    private func hasAnyLink(in attributed: AttributedString) -> Bool {
        !linkURLs(in: attributed).isEmpty
    }

    @Test func URLがないメモにはリンクを付けないこと() {
        let attributed = MemoAttributedString.make(from: "お土産を買う")

        #expect(String(attributed.characters) == "お土産を買う")
        #expect(!hasAnyLink(in: attributed))
    }

    @Test func HTTPSのURLにリンクを付けること() {
        let memo = "詳細は https://example.com を見てください"
        let attributed = MemoAttributedString.make(from: memo)

        #expect(String(attributed.characters) == memo)
        #expect(linkURLs(in: attributed) == [URL(string: "https://example.com")!])
    }

    @Test func 複数のURLそれぞれにリンクを付けること() {
        let memo = "A: https://example.com B: https://apple.com"
        let attributed = MemoAttributedString.make(from: memo)

        #expect(linkURLs(in: attributed) == [
            URL(string: "https://example.com")!,
            URL(string: "https://apple.com")!,
        ])
    }

    @Test func URL以外の文字列にはリンクを付けないこと() {
        let memo = "メモ本文 https://example.com 続き"
        let attributed = MemoAttributedString.make(from: memo)

        let urls = linkURLs(in: attributed)
        #expect(urls.count == 1)
        #expect(urls[0] == URL(string: "https://example.com")!)

        // URL 以外の先頭文字にはリンクが付かない
        let firstCharacterEnd = attributed.characters.index(after: attributed.startIndex)
        #expect(attributed[attributed.startIndex..<firstCharacterEnd].link == nil)
    }

    @Test func 改行で区切られたURLにもリンクを付けること() {
        let memo = "メモ\nhttps://example.com\n続き"
        let attributed = MemoAttributedString.make(from: memo)

        #expect(String(attributed.characters) == memo)
        #expect(linkURLs(in: attributed) == [URL(string: "https://example.com")!])
    }
}
