//
//  ContentView.swift
//  Alarm
//
//  Created by 薛强 on 2026/4/5.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AlarmListView()
                .tabItem {
                    Label("闹钟", systemImage: "alarm.fill")
                }

            StopwatchView()
                .tabItem {
                    Label("秒表", systemImage: "stopwatch.fill")
                }

            TimerView()
                .tabItem {
                    Label("计时器", systemImage: "timer")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AlarmStore())
}
