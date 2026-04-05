import SwiftUI

struct AlarmListView: View {
    @EnvironmentObject private var store: AlarmStore

    @State private var isPresentingAdd = false
    @State private var editingItem: AlarmItem?
    @State private var isPresentingHolidayConfig = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.alarms) { item in
                    alarmRow(item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingItem = item
                        }
                }
                .onDelete { offsets in
                    for offset in offsets {
                        store.removeAlarm(id: store.alarms[offset].id)
                    }
                }

                Button {
                    isPresentingAdd = true
                } label: {
                    Label("添加闹钟", systemImage: "plus.circle.fill")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("闹钟")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingHolidayConfig = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
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
            .sheet(isPresented: $isPresentingHolidayConfig) {
                HolidayConfigView(settings: store.settings) { updated in
                    store.saveSettings(updated)
                }
            }
        }
    }

    @ViewBuilder
    private func alarmRow(_ item: AlarmItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.time.alarmTimeText())
                    .font(.system(size: 42, weight: .medium, design: .rounded))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { item.isEnabled },
                    set: { store.toggleAlarm(id: item.id, isOn: $0) }
                ))
                .labelsHidden()
            }

            Text("\(item.repeatRule.displayText) · \(item.label)")
                .foregroundStyle(.secondary)

            Text(store.nextTriggerText(for: item))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    AlarmListView()
        .environmentObject(AlarmStore())
}
