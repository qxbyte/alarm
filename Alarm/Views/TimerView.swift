import SwiftUI
import Combine

struct TimerView: View {
    @State private var durationSeconds: Int = 300
    @State private var remainingSeconds: Int = 300
    @State private var isRunning = false
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
            .onReceive(ticker) { _ in
                guard isRunning else { return }
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    stop()
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func start() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
    }

    private func stop() {
        isRunning = false
    }

    private func format(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

#Preview {
    TimerView()
}
