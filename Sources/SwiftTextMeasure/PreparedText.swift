import CoreText
import Foundation

/// 세그먼트 줄바꿈 종류. Pretext의 SegmentBreakKind에 대응.
public enum SegmentBreakKind: Sendable, Equatable {
    case text
    case space
    case preservedSpace
    case tab
    case glue
    case zeroWidthBreak
    case softHyphen
    case hardBreak
}

/// prepare() 결과. 폭 독립적 불변 핸들.
/// 내부적으로 병렬 배열(SoA)을 사용하여 layout() hot path에서
/// widths 배열만 순회하도록 설계.
public struct PreparedText: Sendable {
    // 병렬 배열 (Struct of Arrays) — 캐시 친화적
    public var widths: [Double]
    public var lineEndFitAdvances: [Double]
    public var kinds: [SegmentBreakKind]
    public var breakableWidths: [[Double]?]
    public var simpleLineWalkFastPath: Bool
    public var discretionaryHyphenWidth: Double
    public var tabStopAdvance: Double

    public var segmentCount: Int { widths.count }
    public var isEmpty: Bool { widths.isEmpty }

    public init(
        widths: [Double],
        lineEndFitAdvances: [Double],
        kinds: [SegmentBreakKind],
        breakableWidths: [[Double]?],
        simpleLineWalkFastPath: Bool,
        discretionaryHyphenWidth: Double,
        tabStopAdvance: Double
    ) {
        self.widths = widths
        self.lineEndFitAdvances = lineEndFitAdvances
        self.kinds = kinds
        self.breakableWidths = breakableWidths
        self.simpleLineWalkFastPath = simpleLineWalkFastPath
        self.discretionaryHyphenWidth = discretionaryHyphenWidth
        self.tabStopAdvance = tabStopAdvance
    }
}

/// prepare() 결과의 리치 변형. 세그먼트 텍스트 포함.
public struct PreparedTextWithSegments: Sendable {
    public let core: PreparedText
    public let segments: [String]

    public init(core: PreparedText, segments: [String]) {
        self.core = core
        self.segments = segments
    }
}

/// layout() 결과.
public struct LayoutResult: Sendable {
    public let lineCount: Int
    public let height: Double
}

/// 줄 커서.
public struct LayoutCursor: Sendable, Equatable {
    public let segmentIndex: Int
    public let graphemeIndex: Int

    public static let start = LayoutCursor(segmentIndex: 0, graphemeIndex: 0)

    public init(segmentIndex: Int, graphemeIndex: Int) {
        self.segmentIndex = segmentIndex
        self.graphemeIndex = graphemeIndex
    }
}

/// 줄 정보 (리치 API용).
public struct LayoutLine: Sendable {
    public let text: String
    public let width: Double
    public let start: LayoutCursor
    public let end: LayoutCursor
}

/// 줄 범위 정보 (텍스트 미생성, 기하 정보만).
public struct LayoutLineRange: Sendable {
    public let width: Double
    public let start: LayoutCursor
    public let end: LayoutCursor
}
