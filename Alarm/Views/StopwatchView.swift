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
            ZStack {
                Color(white: 0.96)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(format(elapsed))
                        .font(.system(size: 68, weight: .light, design: .rounded))
                        .monospacedDigit()

                    Text(statusText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(white: 0.42))

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

                    if laps.isEmpty {
                        Text("开始后可记录计圈时间")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(white: 0.55))
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        List(Array(laps.enumerated()), id: \.offset) { index, value in
                            HStack {
                                Text("第\(laps.count - index)圈")
                                    .font(.system(size: 16, weight: .regular))
                                Spacer()
                                Text(format(value))
                                    .font(.system(size: 16, weight: .regular))
                                    .monospacedDigit()
                            }
                            .listRowBackground(Color(white: 0.96))
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("秒表")
            .onReceive(ticker) { _ in
                guard isRunning, let startDate else { return }
                elapsed = Date().timeIntervalSince(startDate)
            }
        }
        .preferredColorScheme(.light)
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

    private var statusText: String {
        if isRunning {
            return "正在计时，可随时记录计圈"
        }
        if elapsed > 0 {
            return "已暂停，可继续或重置"
        }
        return "准备开始"
    }
}

#Preview {
    StopwatchView()
}
