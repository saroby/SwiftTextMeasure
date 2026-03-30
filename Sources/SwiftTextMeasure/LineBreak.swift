import Foundation

/// 축소 가능한 공백인지 판정.
private func isCollapsibleSpace(_ kind: SegmentBreakKind) -> Bool {
    kind == .space
}

// MARK: - Hot Path: 줄 수 카운트

/// 캐시된 폭 배열만으로 줄 수를 산술 계산.
/// 이 함수가 전체 라이브러리의 핵심 hot path.
/// - Canvas/CoreText 호출 없음
/// - 문자열 연산 없음
/// - 메모리 할당 없음
/// - [Double] 순회 + 비교 연산만
public func countLines(_ prepared: PreparedText, maxWidth: Double) -> Int {
    let widths = prepared.widths
    let kinds = prepared.kinds
    let breakableWidths = prepared.breakableWidths

    guard !widths.isEmpty else { return 0 }

    let lineFitEpsilon = 0.005
    var lineCount = 0
    var lineW = 0.0
    var hasContent = false

    for i in 0..<widths.count {
        let w = widths[i]
        let kind = kinds[i]

        if !hasContent {
            if w > maxWidth, let gWidths = breakableWidths[i] {
                lineW = 0
                for gw in gWidths {
                    if lineW > 0 && lineW + gw > maxWidth + lineFitEpsilon {
                        lineCount += 1
                        lineW = gw
                    } else {
                        if lineW == 0 { lineCount += 1 }
                        lineW += gw
                    }
                }
            } else {
                lineW = w
                lineCount += 1
            }
            hasContent = true
            continue
        }

        let newW = lineW + w
        if newW > maxWidth + lineFitEpsilon {
            if isCollapsibleSpace(kind) { continue }
            if w > maxWidth, let gWidths = breakableWidths[i] {
                lineW = 0
                hasContent = false
                for gw in gWidths {
                    if lineW > 0 && lineW + gw > maxWidth + lineFitEpsilon {
                        lineCount += 1
                        lineW = gw
                    } else {
                        if lineW == 0 { lineCount += 1 }
                        lineW += gw
                    }
                }
                hasContent = true
            } else {
                lineW = w
                lineCount += 1
            }
            continue
        }

        lineW = newW
    }

    if !hasContent { return lineCount + 1 }
    return lineCount
}
