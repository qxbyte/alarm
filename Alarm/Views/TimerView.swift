import SwiftUI
import Combine

struct TimerView: View {
    private let presets = [60, 5 * 60, 10 * 60, 25 * 60]

    @State private var durationSeconds: Int = 300
    @State private var remainingSeconds: Int = 300
    @State private var isRunning = false
    @State private var didComplete = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.96)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(format(remainingSeconds))
                        .font(.system(size: 68, weight: .light, design: .rounded))
                        .monospacedDigit()

                    Text(statusText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(white: 0.42))

                    presetRow

                    Stepper("时长：\(durationSeconds / 60) 分钟", value: $durationSeconds, in: 60 ... 24 * 3600, step: 60)
                        .font(.system(size: 16, weight: .regular))
                        .disabled(isRunning)
                        .onChange(of: durationSeconds) { _, newValue in
                            if !isRunning {
                                remainingSeconds = newValue
                            }
                        }

                    HStack(spacing: 16) {
                        Button("重置") {
                            stop()
                            remainingSeconds = durationSeconds
                        }
                        .buttonStyle(.bordered)

                        Button(isRunning ? "暂停" : "开始") {
                            isRunning ? stop() : start()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
                .padding()
            }
            .navigationTitle("计时器")
            .alert("计时结束", isPresented: $didComplete) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("本轮 \(durationSummary(durationSeconds)) 已完成。")
            }
            .onReceive(ticker) { _ in
                guard isRunning else { return }
                if remainingSeconds > 1 {
                    remainingSeconds -= 1
                    return
                }

                complete()
            }
        }
        .preferredColorScheme(.light)
    }

    private func start() {
        guard remainingSeconds > 0 else { return }
        didComplete = false
        isRunning = true
    }

    private func stop() {
        isRunning = false
    }

    private func complete() {
        stop()
        remainingSeconds = 0
        didComplete = true
    }

    private func format(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var presetRow: some View {
        HStack(spacing: 10) {
            ForEach(presets, id: \.self) { preset in
                Button {
                    applyPreset(preset)
                } label: {
                    Text(durationSummary(preset))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(durationSeconds == preset ? .white : Color(white: 0.2))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(durationSeconds == preset ? Color.orange : Color.white)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isRunning)
                .opacity(isRunning ? 0.45 : 1)
            }
        }
    }

    private var statusText: String {
        if didComplete {
            return "本轮倒计时已完成"
        }
        if isRunning {
            return "进行中 · 剩余 \(durationSummary(remainingSeconds))"
        }
        if remainingSeconds == durationSeconds {
            return "选择常用时长后即可开始"
        }
        return "已暂停，可继续或重置"
    }

    private func applyPreset(_ preset: Int) {
        guard !isRunning else { return }
        durationSeconds = preset
        remainingSeconds = preset
        didComplete = false
    }

    private func durationSummary(_ seconds: Int) -> String {
        if seconds < 3600 {
            return "\(seconds / 60) 分钟"
        }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if minutes == 0 {
            return "\(hours) 小时"
        }
        return "\(hours) 小时 \(minutes) 分钟"
    }
}

#Preview {
    TimerView()
}
