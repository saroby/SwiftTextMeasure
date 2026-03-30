import Testing
@testable import SwiftTextMeasure

@Suite("Unicode Helpers")
struct UnicodeHelperTests {
    @Test("CJK 한자 감지")
    func cjkUnified() {
        #expect(isCJK("你好"))
        #expect(isCJK("漢字"))
    }

    @Test("히라가나/카타카나 감지")
    func cjkKana() {
        #expect(isCJK("あいう"))
        #expect(isCJK("アイウ"))
    }

    @Test("한글 감지")
    func cjkHangul() {
        #expect(isCJK("한글"))
    }

    @Test("라틴 문자는 CJK 아님")
    func latinNotCJK() {
        #expect(!isCJK("hello"))
        #expect(!isCJK("abc123"))
    }

    @Test("아랍어는 CJK 아님")
    func arabicNotCJK() {
        #expect(!isCJK("مرحبا"))
    }

    @Test("혼합 텍스트에서 CJK 포함 판정")
    func mixedContainsCJK() {
        #expect(isCJK("hello世界"))
    }

    @Test("빈 문자열")
    func emptyString() {
        #expect(!isCJK(""))
    }
}
