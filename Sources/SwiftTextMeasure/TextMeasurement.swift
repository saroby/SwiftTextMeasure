import CoreText
import Foundation

/// 세그먼트 메트릭. Pretext의 SegmentMetrics에 대응.
struct SegmentMetrics: Sendable {
    let width: Double
    let containsCJK: Bool
}

/// (font, segment) 쌍 기준 측정 캐시.
/// Pretext의 segmentMetricCaches와 동일한 역할.
public final class SegmentMetricCache: @unchecked Sendable {
    private var cache: [String: SegmentMetrics] = [:]

    public init() {}

    public func width(for segment: String, font: CTFont) -> Double {
        return metrics(for: segment, font: font).width
    }

    func metrics(for segment: String, font: CTFont) -> SegmentMetrics {
        if let cached = cache[segment] {
            return cached
        }
        let m = Self.measure(segment, font: font)
        cache[segment] = m
        return m
    }

    private static func measure(_ segment: String, font: CTFont) -> SegmentMetrics {
        guard !segment.isEmpty else {
            return SegmentMetrics(width: 0, containsCJK: false)
        }
        let attrs = [kCTFontAttributeName: font] as CFDictionary
        let attrStr = CFAttributedStringCreate(nil, segment as CFString, attrs)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        return SegmentMetrics(width: width, containsCJK: isCJK(segment))
    }

    public func clear() {
        cache.removeAll()
    }
}
