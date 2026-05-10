import SwiftUI

struct AlarmListView: View {
    @EnvironmentObject private var store: AlarmStore

    @State private var isPresentingAdd = false
    @State private var editingItem: AlarmItem?
    @State private var isEditing = false

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
                Text("暂无闹钟")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color(white: 0.5))
                    .padding(.vertical, 10)
            } else {
                ForEach(displayAlarms) { item in
                    alarmRow(item)
                    Divider()
                        .overlay(Color(white: 0.84))
                }
            }
        }
    }

    @ViewBuilder
    private func alarmRow(_ item: AlarmItem) -> some View {
        HStack(spacing: 10) {
            if isEditing {
                Button {
                    store.removeAlarm(id: item.id)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.time.alarmTimeText())
                    .font(.system(size: 68, weight: .light))
                    .foregroundStyle(item.isEnabled ? Color(white: 0.1) : Color(white: 0.6))

                Text(item.label)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color(white: 0.5))
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
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isEditing else { return }
            editingItem = item
        }
    }

    private var displayAlarms: [AlarmItem] {
        store.alarms.sorted {
            let lhs = Calendar.current.dateComponents([.hour, .minute], from: $0.time)
            let rhs = Calendar.current.dateComponents([.hour, .minute], from: $1.time)
            let lhsValue = (lhs.hour ?? 0) * 60 + (lhs.minute ?? 0)
            let rhsValue = (rhs.hour ?? 0) * 60 + (rhs.minute ?? 0)
            return lhsValue < rhsValue
        }
    }

    private var enabledAlarmCount: Int {
        store.alarms.filter(\.isEnabled).count
    }
}

#Preview {
    AlarmListView()
        .environmentObject(AlarmStore())
}
