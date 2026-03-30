import Foundation

/// 코드포인트가 CJK 범위인지 판정.
/// Pretext의 isCJK()를 Swift로 포팅.
public func isCJK(_ text: String) -> Bool {
    for scalar in text.unicodeScalars {
        let c = scalar.value
        if (c >= 0x4E00 && c <= 0x9FFF) ||
           (c >= 0x3400 && c <= 0x4DBF) ||
           (c >= 0x20000 && c <= 0x2A6DF) ||
           (c >= 0x2A700 && c <= 0x2B73F) ||
           (c >= 0x2B740 && c <= 0x2B81F) ||
           (c >= 0x2B820 && c <= 0x2CEAF) ||
           (c >= 0x2CEB0 && c <= 0x2EBEF) ||
           (c >= 0x30000 && c <= 0x3134F) ||
           (c >= 0xF900 && c <= 0xFAFF) ||
           (c >= 0x2F800 && c <= 0x2FA1F) ||
           (c >= 0x3000 && c <= 0x303F) ||
           (c >= 0x3040 && c <= 0x309F) ||
           (c >= 0x30A0 && c <= 0x30FF) ||
           (c >= 0xAC00 && c <= 0xD7AF) ||
           (c >= 0xFF00 && c <= 0xFFEF) {
            return true
        }
    }
    return false
}

/// 줄 시작 금지 문자 (kinsoku start). 닫는 구두점, 반복 부호 등.
public let kinsokuStart: Set<Character> = [
    "\u{FF0C}", "\u{FF0E}", "\u{FF01}", "\u{FF1A}", "\u{FF1B}", "\u{FF1F}",
    "\u{3001}", "\u{3002}", "\u{30FB}",
    "\u{FF09}", "\u{3015}", "\u{3009}", "\u{300B}", "\u{300D}", "\u{300F}",
    "\u{3011}", "\u{3017}", "\u{3019}", "\u{301B}",
    "\u{30FC}", "\u{3005}", "\u{303B}", "\u{309D}", "\u{309E}", "\u{30FD}", "\u{30FE}",
]

/// 줄 끝 금지 문자 (kinsoku end). 여는 괄호/따옴표 등.
public let kinsokuEnd: Set<Character> = [
    "\"", "(", "[", "{",
    "\u{201C}", "\u{2018}", "\u{00AB}", "\u{2039}",
    "\u{FF08}", "\u{3014}", "\u{3008}", "\u{300A}", "\u{300C}", "\u{300E}",
    "\u{3010}", "\u{3016}", "\u{3018}", "\u{301A}",
]

/// 왼쪽 점착 구두점. 앞 단어에 병합.
public let leftStickyPunctuation: Set<Character> = [
    ".", ",", "!", "?", ":", ";",
    "\u{060C}", "\u{061B}", "\u{061F}",
    "\u{0964}", "\u{0965}",
    "\u{104A}", "\u{104B}", "\u{104C}", "\u{104D}", "\u{104F}",
    ")", "]", "}",
    "%",
    "\"",
    "\u{201D}", "\u{2019}", "\u{00BB}", "\u{203A}",
    "\u{2026}",
]
