import Foundation

/// 텍스트 분석 결과. 병렬 배열 구조.
public struct TextAnalysis: Sendable {
    public let normalized: String
    public var texts: [String]
    public var isWordLike: [Bool]
    public var kinds: [SegmentBreakKind]

    public var count: Int { texts.count }
    public var isEmpty: Bool { texts.isEmpty }
}

/// 공백 모드.
public enum WhiteSpaceMode: Sendable {
    case normal
    case preWrap
}

// MARK: - 공백 정규화

/// CSS white-space: normal 동작 재현.
public func normalizeWhitespace(_ text: String) -> String {
    guard text.contains(where: { $0.isWhitespace && $0 != " " })
       || text.contains("  ")
       || text.first == " "
       || text.last == " "
    else {
        return text
    }

    var result = ""
    var lastWasSpace = true
    for ch in text {
        if ch == " " || ch == "\t" || ch == "\n" || ch == "\r" || ch == "\u{0C}" {
            if !lastWasSpace {
                result.append(" ")
                lastWasSpace = true
            }
        } else {
            result.append(ch)
            lastWasSpace = false
        }
    }
    if result.last == " " {
        result.removeLast()
    }
    return result
}

// MARK: - 줄바꿈 종류 분류

private func classifyBreakKind(_ ch: Character) -> SegmentBreakKind {
    if ch == " " { return .space }
    if ch == "\u{00A0}" || ch == "\u{202F}" || ch == "\u{2060}" || ch == "\u{FEFF}" {
        return .glue
    }
    if ch == "\u{200B}" { return .zeroWidthBreak }
    if ch == "\u{00AD}" { return .softHyphen }
    if ch == "\n" { return .hardBreak }
    if ch == "\t" { return .tab }
    return .text
}

// MARK: - 세그멘테이션

/// 텍스트를 분석하여 세그먼트 배열을 생성.
public func analyzeText(_ text: String, whiteSpace: WhiteSpaceMode = .normal) -> TextAnalysis {
    let normalized: String
    switch whiteSpace {
    case .normal:
        normalized = normalizeWhitespace(text)
    case .preWrap:
        normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
                         .replacingOccurrences(of: "\r", with: "\n")
    }

    guard !normalized.isEmpty else {
        return TextAnalysis(normalized: normalized, texts: [], isWordLike: [], kinds: [])
    }

    // CFStringTokenizer로 단어 경계 분절
    var rawTexts: [String] = []
    var rawWordLike: [Bool] = []
    var rawKinds: [SegmentBreakKind] = []

    let cfStr = normalized as CFString
    let fullRange = CFRange(location: 0, length: CFStringGetLength(cfStr))
    let tokenizer = CFStringTokenizerCreate(
        nil, cfStr, fullRange, kCFStringTokenizerUnitWord, nil
    )

    var prevEndUTF16 = 0
    while CFStringTokenizerAdvanceToNextToken(tokenizer) != [] {
        let cfRange = CFStringTokenizerGetCurrentTokenRange(tokenizer)
        let tokenStartUTF16 = cfRange.location
        let tokenEndUTF16 = cfRange.location + cfRange.length

        // 토큰 전 갭(공백/구두점 등)
        if prevEndUTF16 < tokenStartUTF16 {
            let gap = extractUTF16Substring(cfStr, from: prevEndUTF16, to: tokenStartUTF16)
            for piece in splitByBreakKind(gap) {
                rawTexts.append(piece.text)
                rawWordLike.append(false)
                rawKinds.append(piece.kind)
            }
        }

        let word = extractUTF16Substring(cfStr, from: tokenStartUTF16, to: tokenEndUTF16)
        rawTexts.append(word)
        rawWordLike.append(true)
        rawKinds.append(.text)
        prevEndUTF16 = tokenEndUTF16
    }

    // 마지막 토큰 후 잔여
    let totalLen = CFStringGetLength(cfStr)
    if prevEndUTF16 < totalLen {
        let gap = extractUTF16Substring(cfStr, from: prevEndUTF16, to: totalLen)
        for piece in splitByBreakKind(gap) {
            rawTexts.append(piece.text)
            rawWordLike.append(false)
            rawKinds.append(piece.kind)
        }
    }

    // 구두점 병합 (왼쪽 점착)
    var texts: [String] = []
    var wordLike: [Bool] = []
    var kinds: [SegmentBreakKind] = []

    for i in 0..<rawTexts.count {
        let text = rawTexts[i]
        let kind = rawKinds[i]
        let isWord = rawWordLike[i]

        if kind == .text && !isWord && !texts.isEmpty && kinds.last == .text {
            if isLeftStickySegment(text) {
                texts[texts.count - 1] += text
                continue
            }
        }

        texts.append(text)
        wordLike.append(isWord)
        kinds.append(kind)
    }

    return TextAnalysis(normalized: normalized, texts: texts, isWordLike: wordLike, kinds: kinds)
}

// MARK: - Internal helpers

private func extractUTF16Substring(_ cfStr: CFString, from: Int, to: Int) -> String {
    let range = CFRange(location: from, length: to - from)
    let buf = UnsafeMutablePointer<UniChar>.allocate(capacity: range.length)
    defer { buf.deallocate() }
    CFStringGetCharacters(cfStr, range, buf)
    return String(utf16CodeUnits: buf, count: range.length)
}

private struct BreakPiece {
    let text: String
    let kind: SegmentBreakKind
}

private func splitByBreakKind(_ text: String) -> [BreakPiece] {
    guard !text.isEmpty else { return [] }
    var pieces: [BreakPiece] = []
    var current = ""
    var currentKind: SegmentBreakKind?

    for ch in text {
        let kind = classifyBreakKind(ch)
        if kind == currentKind {
            current.append(ch)
        } else {
            if let k = currentKind, !current.isEmpty {
                pieces.append(BreakPiece(text: current, kind: k))
            }
            current = String(ch)
            currentKind = kind
        }
    }
    if let k = currentKind, !current.isEmpty {
        pieces.append(BreakPiece(text: current, kind: k))
    }
    return pieces
}

private func isLeftStickySegment(_ text: String) -> Bool {
    for ch in text {
        if !leftStickyPunctuation.contains(ch) { return false }
    }
    return !text.isEmpty
}
