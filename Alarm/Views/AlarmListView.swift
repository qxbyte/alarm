import SwiftUI

struct AlarmListView: View {
    @EnvironmentObject private var store: AlarmStore

    @State private var isPresentingAdd = false
    @State private var editingItem: AlarmItem?
    @State private var isEditing = false
    @State private var itemToDelete: AlarmItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.96)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        topBar
                        title
                        alarmSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .task {
                guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
                    return
                }
                await store.requestAlarmAuthorization()
                await store.refreshHolidayEntries()
            }
            .alert("提示", isPresented: Binding(
                get: { store.lastErrorMessage != nil },
                set: { if !$0 { store.lastErrorMessage = nil } }
            )) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(store.lastErrorMessage ?? "")
            }
            .sheet(isPresented: $isPresentingAdd) {
                AlarmEditView { alarm in
                    store.addAlarm(alarm)
                }
            }
            .sheet(item: $editingItem) { item in
                AlarmEditView(
                    existing: item,
                    onSave: { updated in
                        store.updateAlarm(updated)
                    },
                    onDelete: { id in
                        store.removeAlarm(id: id)
                    }
                )
            }
            .alert("确认删除", isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            )) {
                Button("删除", role: .destructive) {
                    if let item = itemToDelete {
                        store.removeAlarm(id: item.id)
                        itemToDelete = nil
                    }
                }
                Button("取消", role: .cancel) {
                    itemToDelete = nil
                }
            } message: {
                Text("确定要删除这个闹钟吗？")
            }
        }
        .preferredColorScheme(.light)
    }

    private var topBar: some View {
        HStack {
            Button(isEditing ? "完成" : "编辑") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditing.toggle()
                }
            }
            .font(.system(size: 18, weight: .regular, design: .rounded))
            .foregroundStyle(Color(white: 0.18))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white))

            Spacer()

            Button {
                isPresentingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color(white: 0.18))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white))
            }
        }
        .padding(.top, 8)
    }

    private var title: some View {
        Text("闹钟")
            .font(.system(size: 36, weight: .semibold))
            .foregroundStyle(Color(white: 0.12))
            .padding(.top, 2)
    }

    private var alarmSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("已启用 \(enabledAlarmCount) 个")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.45))

                Spacer()

                if !store.alarms.isEmpty {
                    Text("共 \(store.alarms.count) 个闹钟")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(white: 0.55))
                }
            }

            Divider()
                .overlay(Color(white: 0.84))

            if store.alarms.isEmpty {
                emptyStateCard
            } else {
                if let upcomingAlarm = upcomingAlarm {
                    upcomingAlarmCard(for: upcomingAlarm)
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                }

                ForEach(displayAlarms) { item in
                    alarmRow(item)
                }
            }
        }
    }

    @ViewBuilder
    private func alarmRow(_ item: AlarmItem) -> some View {
        HStack(spacing: 10) {
            if isEditing {
                Button {
                    itemToDelete = item
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.time.alarmTimeText())
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(item.isEnabled ? Color(white: 0.1) : Color(white: 0.6))

                HStack(spacing: 4) {
                    Text(item.label)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(white: 0.5))
                    
                    Text("·")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(white: 0.6))
                    
                    Text(repeatSummary(for: item))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(white: 0.6))
                }

                Text(store.nextTriggerText(for: item))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.42))
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { store.toggleAlarm(id: item.id, isOn: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .onTapGesture {}
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .opacity(item.isEnabled ? 1.0 : 0.6)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditing else { return }
            editingItem = item
        }
    }

    private var displayAlarms: [AlarmItem] {
        store.alarms.sorted {
            if $0.isEnabled != $1.isEnabled {
                return $0.isEnabled && !$1.isEnabled
            }

            let lhsNext = store.nextTriggerDate(for: $0)
            let rhsNext = store.nextTriggerDate(for: $1)

            switch (lhsNext, rhsNext) {
            case let (lhsDate?, rhsDate?):
                if lhsDate != rhsDate {
                    return lhsDate < rhsDate
                }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }

            return alarmTimeValue(for: $0) < alarmTimeValue(for: $1)
        }
    }

    private var enabledAlarmCount: Int {
        store.alarms.filter(\.isEnabled).count
    }

    private var upcomingAlarm: AlarmItem? {
        store.alarms
            .filter(\.isEnabled)
            .compactMap { item in
                guard let nextDate = store.nextTriggerDate(for: item) else { return nil }
                return (item, nextDate)
            }
            .min { $0.1 < $1.1 }?
            .0
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("暂无闹钟")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(white: 0.18))

            Text("点击右上角 + 创建第一个闹钟，列表会在这里显示重复规则和下一次提醒。")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(white: 0.48))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
        )
        .padding(.top, 6)
    }

    private func upcomingAlarmCard(for item: AlarmItem) -> some View {
        let nextDate = store.nextTriggerDate(for: item)
        let title = item.label == "闹钟" ? "最近提醒" : "最近提醒 · \(item.label)"

        return VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.orange)

            Text(item.time.alarmTimeText())
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color(white: 0.12))

            if let nextDate {
                Text("预计在 \(nextDate.alarmDisplayText()) 响铃")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.42))

                Text(relativeTimeText(to: nextDate))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.58))
            } else {
                Text("当前规则下暂无下次提醒")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.48))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
        )
    }

    private func repeatSummary(for item: AlarmItem) -> String {
        let holidayText = item.skipHolidayEnabled ? "节假日跳过" : "节假日照常"
        if item.repeatRule.preset == .weekdays, item.smartMakeUpEnabled {
            return "\(item.repeatRule.displayText) · 含调休 · \(holidayText)"
        }
        return "\(item.repeatRule.displayText) · \(holidayText)"
    }

    private func alarmTimeValue(for item: AlarmItem) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: item.time)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func relativeTimeText(to date: Date) -> String {
        let interval = max(Int(date.timeIntervalSinceNow), 0)
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60

        if hours == 0 {
            return "\(max(minutes, 1)) 分钟后"
        }
        if minutes == 0 {
            return "\(hours) 小时后"
        }
        return "\(hours) 小时 \(minutes) 分钟后"
    }
}

#Preview {
    AlarmListView()
        .environmentObject(AlarmStore())
}
