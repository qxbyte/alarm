import SwiftUI
import Combine

struct StopwatchView: View {
    @State private var elapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var startDate: Date?
    @State private var laps: [TimeInterval] = []
    private let ticker = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(format(elapsed))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                HStack(spacing: 16) {
                    Button(isRunning ? "计圈" : "重置") {
                        if isRunning {
                            laps.insert(elapsed, at: 0)
                        } else {
                            reset()
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(isRunning ? "停止" : "开始") {
                        isRunning ? stop() : start()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

                List(Array(laps.enumerated()), id: \.offset) { index, value in
                    HStack {
                        Text("第\(laps.count - index)圈")
                        Spacer()
                        Text(format(value))
                            .monospacedDigit()
                    }
                }
            }
            .padding()
            .navigationTitle("秒表")
            .onReceive(ticker) { _ in
                guard isRunning, let startDate else { return }
                elapsed = Date().timeIntervalSince(startDate)
            }
        }
    }

    private func start() {
        isRunning = true
        startDate = Date().addingTimeInterval(-elapsed)
    }

    private func stop() {
        isRunning = false
    }

    private func reset() {
        elapsed = 0
        laps.removeAll()
    }

    private func format(_ value: TimeInterval) -> String {
        let total = Int(value)
        let minutes = total / 60
        let seconds = total % 60
        let fraction = Int((value - floor(value)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, fraction)
    }
}

#Preview {
    StopwatchView()
}
