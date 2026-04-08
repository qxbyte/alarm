//
//  AlarmApp.swift
//  Alarm
//
//  Created by 薛强 on 2026/4/5.
//

import SwiftUI

@main
struct AlarmApp: App {
    @StateObject private var store = AlarmStore(scheduler: buildScheduler())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }

    private static func buildScheduler() -> AlarmScheduler {
        #if canImport(AlarmKit)
        return AdaptiveAlarmScheduler(primary: AlarmKitScheduler())
        #else
        return NotificationAlarmScheduler()
        #endif
    }
}
