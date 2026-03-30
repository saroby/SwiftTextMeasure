import CoreText
import Foundation

/// Pretext 패턴의 iOS 구현.
///
/// ```swift
/// let engine = TextLayoutEngine()
/// let prepared = engine.prepare("텍스트", font: myFont)
/// let result = engine.layout(prepared, maxWidth: 320, lineHeight: 22)
/// ```
public final class TextLayoutEngine: @unchecked Sendable {
    private let metricCache = SegmentMetricCache()

    public init() {}

    /// 텍스트를 분석하고 세그먼트 폭을 측정. 1회 호출.
    public func prepare(_ text: String, font: CTFont) -> PreparedText {
        let analysis = analyzeText(text)
        return measureAnalysis(analysis, font: font)
    }

    /// 캐시된 폭 배열만으로 줄 수/높이를 산술 계산. 리사이즈마다 호출.
    public func layout(_ prepared: PreparedText, maxWidth: Double, lineHeight: Double) -> LayoutResult {
        let lineCount = countLines(prepared, maxWidth: maxWidth)
        return LayoutResult(lineCount: lineCount, height: Double(lineCount) * lineHeight)
    }

    public func clearCache() {
        metricCache.clear()
    }

    // MARK: - Internal

    private func measureAnalysis(_ analysis: TextAnalysis, font: CTFont) -> PreparedText {
        guard !analysis.isEmpty else {
            return PreparedText(
                widths: [], lineEndFitAdvances: [], kinds: [],
                breakableWidths: [], simpleLineWalkFastPath: true,
                discretionaryHyphenWidth: 0, tabStopAdvance: 0
            )
        }

        let spaceWidth = metricCache.width(for: " ", font: font)
        let hyphenWidth = metricCache.width(for: "-", font: font)
        let tabStopAdvance = spaceWidth * 8

        var widths: [Double] = []
        var fitAdvances: [Double] = []
        var kinds: [SegmentBreakKind] = []
        var breakableWidths: [[Double]?] = []
        var simpleLineWalkFastPath = true

        for i in 0..<analysis.count {
            let segText = analysis.texts[i]
            let segKind = analysis.kinds[i]
            let segWordLike = analysis.isWordLike[i]

            if segKind == .softHyphen {
                widths.append(0)
                fitAdvances.append(hyphenWidth)
                kinds.append(segKind)
                breakableWidths.append(nil)
                simpleLineWalkFastPath = false
                continue
            }

            if segKind == .hardBreak || segKind == .tab {
                widths.append(0)
                fitAdvances.append(0)
                kinds.append(segKind)
                breakableWidths.append(nil)
                simpleLineWalkFastPath = false
                continue
            }

            let metrics = metricCache.metrics(for: segText, font: font)
            let w = metrics.width
            let fitAdvance: Double
            switch segKind {
            case .space, .preservedSpace, .zeroWidthBreak:
                fitAdvance = 0
            default:
                fitAdvance = w
            }

            // CJK 세그먼트: 문자별 분리
            if segKind == .text && metrics.containsCJK {
                for ch in segText {
                    let charStr = String(ch)
                    let charW = metricCache.width(for: charStr, font: font)
                    widths.append(charW)
                    fitAdvances.append(charW)
                    kinds.append(.text)
                    breakableWidths.append(nil)
                }
                continue
            }

            widths.append(w)
            fitAdvances.append(fitAdvance)
            kinds.append(segKind)

            // 긴 단어: 그래핌 단위 폭 사전 측정
            if segWordLike && segText.count > 1 {
                var gWidths: [Double] = []
                for ch in segText {
                    let charW = metricCache.width(for: String(ch), font: font)
                    gWidths.append(charW)
                }
                breakableWidths.append(gWidths.count > 1 ? gWidths : nil)
            } else {
                breakableWidths.append(nil)
            }
        }

        return PreparedText(
            widths: widths, lineEndFitAdvances: fitAdvances, kinds: kinds,
            breakableWidths: breakableWidths, simpleLineWalkFastPath: simpleLineWalkFastPath,
            discretionaryHyphenWidth: hyphenWidth, tabStopAdvance: tabStopAdvance
        )
    }
}
