import SwiftUI
import CoreText
import SwiftTextMeasure

struct ContentView: View {
    @State private var sliderWidth: Double = 300
    @State private var benchmarkResult: String = ""
    @State private var isRunningBenchmark = false

    private let engine = TextLayoutEngine()

    private let sampleTexts: [(label: String, text: String)] = [
        ("English", "The quick brown fox jumps over the lazy dog and keeps on running through the meadow."),
        ("Korean", "빠른 갈색 여우가 게으른 개를 뛰어넘고 초원을 계속 달립니다. 안녕하세요 세계!"),
        ("Japanese", "吾輩は猫である。名前はまだ無い。どこで生れたかとんと見当がつかぬ。"),
        ("Chinese", "快速的棕色狐狸跳过了懒惰的狗，继续在草地上奔跑。你好世界！"),
        ("Arabic", "الثعلب البني السريع يقفز فوق الكلب الكسول ويواصل الجري عبر المرج"),
        ("Mixed", "AGI 春天到了. بدأت الرحلة 🚀 Hello 世界! 안녕하세요"),
        ("Emoji", "🎉🎊🥳 Happy birthday! 생일 축하해요! 🎂🎈🎁 Let's celebrate! 파티하자!"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Pretext iOS")
                        .font(.largeTitle.bold())
                    Text("DOM-free text measurement for iOS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                widthControlSection
                textMeasurementSection
                benchmarkSection
            }
            .padding()
        }
    }

    // MARK: - Width Control

    private var widthControlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Container Width")
                    .font(.headline)
                Spacer()
                Text("\(Int(sliderWidth))px")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.blue)
            }
            Slider(value: $sliderWidth, in: 60...400, step: 1)
        }
        .padding()
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Text Measurement Cards

    private var textMeasurementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live Measurement")
                .font(.title2.bold())

            Text("Drag the slider above. layout() recalculates instantly (pure arithmetic, no CoreText calls).")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(sampleTexts.enumerated()), id: \.offset) { _, sample in
                textCard(label: sample.label, text: sample.text)
            }
        }
    }

    private func textCard(label: String, text: String) -> some View {
        let font = CTFontCreateWithName("Helvetica" as CFString, 15, nil)
        let prepared = engine.prepare(text, font: font)
        let result = engine.layout(prepared, maxWidth: sliderWidth, lineHeight: 20)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1), in: Capsule())
                Spacer()
                Text("\(result.lineCount) lines")
                    .font(.system(.caption, design: .monospaced))
                Text("|")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("\(Int(result.height))px height")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.green)
            }

            // 실제 텍스트를 Pretext 계산 폭 안에 표시
            Text(text)
                .font(.system(size: 15))
                .lineSpacing(4)
                .frame(width: sliderWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(12)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Benchmark

    private var benchmarkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Benchmark")
                .font(.title2.bold())

            Text("Measures prepare() (CoreText, 1x) vs layout() (arithmetic, every resize)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                runBenchmark()
            } label: {
                HStack {
                    if isRunningBenchmark {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(isRunningBenchmark ? "Running..." : "Run 500-Text Benchmark")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunningBenchmark)

            if !benchmarkResult.isEmpty {
                Text(benchmarkResult)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func runBenchmark() {
        isRunningBenchmark = true
        benchmarkResult = ""

        Task.detached {
            let engine = TextLayoutEngine()
            let font = CTFontCreateWithName("Helvetica" as CFString, 16, nil)

            let texts = (0..<500).map { i in
                "Message \(i): The quick brown fox jumps over the lazy dog. 你好世界。 안녕하세요! 🚀"
            }

            // prepare
            let t0 = ContinuousClock.now
            let prepared = texts.map { engine.prepare($0, font: font) }
            let t1 = ContinuousClock.now

            // layout x100
            let t2 = ContinuousClock.now
            for _ in 0..<100 {
                for p in prepared {
                    let _ = engine.layout(p, maxWidth: 300, lineHeight: 22)
                }
            }
            let t3 = ContinuousClock.now

            // layout x1
            let t4 = ContinuousClock.now
            for p in prepared {
                let _ = engine.layout(p, maxWidth: 300, lineHeight: 22)
            }
            let t5 = ContinuousClock.now

            let prepMs = Double((t1 - t0).components.attoseconds) / 1e15
            let layAvgMs = Double((t3 - t2).components.attoseconds) / 1e15 / 100
            let layOnceMs = Double((t5 - t4).components.attoseconds) / 1e15
            let perTextUs = layOnceMs / 500 * 1000

            let result = """
            === Pretext iOS Benchmark (500 texts) ===

            prepare()    : \(String(format: "%8.2f", prepMs)) ms  (CoreText, 1x)
            layout() avg : \(String(format: "%8.3f", layAvgMs)) ms  (arithmetic, avg 100 runs)
            layout() 1x  : \(String(format: "%8.3f", layOnceMs)) ms
            per text     : \(String(format: "%8.2f", perTextUs)) us

            Speedup      : \(String(format: "%.0f", prepMs / max(layAvgMs, 0.001)))x faster
            """

            await MainActor.run {
                benchmarkResult = result
                isRunningBenchmark = false
            }
        }
    }
}
