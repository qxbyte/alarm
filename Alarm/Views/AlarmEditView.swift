import SwiftUI

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss

    let existing: AlarmItem?
    let onSave: (AlarmItem) -> Void
    let onDelete: ((UUID) -> Void)?

    @State private var time: Date
    @State private var label: String
    @State private var selectedWeekdays: Set<Int>
    @State private var soundName: String
    @State private var snoozeEnabled: Bool
    @State private var snoozeMinutes: Int
    @State private var skipHolidayEnabled: Bool
    @State private var isEnabled: Bool

    @State private var showSnoozePicker = false
    @State private var showRepeatSheet = false

    init(existing: AlarmItem? = nil, onSave: @escaping (AlarmItem) -> Void, onDelete: ((UUID) -> Void)? = nil) {
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete

        _time = State(initialValue: existing?.time ?? Date())
        _label = State(initialValue: existing?.label ?? "闹钟")
        _selectedWeekdays = State(initialValue: existing?.repeatRule.weekdays ?? Set([2, 3, 4, 5, 6]))
        _soundName = State(initialValue: existing?.soundName ?? "雷达")
        _snoozeEnabled = State(initialValue: existing?.snoozeEnabled ?? true)
        _snoozeMinutes = State(initialValue: existing?.snoozeMinutes ?? 9)
        _skipHolidayEnabled = State(initialValue: existing?.skipHolidayEnabled ?? true)
        _isEnabled = State(initialValue: existing?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("时间", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)

                Button {
                    showRepeatSheet = true
                } label: {
                    HStack {
                        Text("重复")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(AlarmRepeatRule.custom(selectedWeekdays).displayText)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }

                TextField("标签", text: $label)
                TextField("铃声", text: $soundName)

                Toggle("稍后提醒", isOn: $snoozeEnabled)

                Button {
                    guard snoozeEnabled else { return }
                    showSnoozePicker.toggle()
                } label: {
                    HStack {
                        Text("稍后提醒时长")
                            .foregroundStyle(snoozeEnabled ? .primary : .secondary)
                        Spacer()
                        Text("\(snoozeMinutes)分钟")
                            .foregroundStyle(snoozeEnabled ? .orange : .secondary)
                    }
                }
                .disabled(!snoozeEnabled)

                if snoozeEnabled, showSnoozePicker {
                    Picker("稍后提醒时长", selection: $snoozeMinutes) {
                        ForEach(1 ... 30, id: \.self) { minute in
                            Text("\(minute)分钟").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 160)
                }

                Toggle("跳过节假日", isOn: $skipHolidayEnabled)
                Toggle("启用", isOn: $isEnabled)

                if let id = existing?.id {
                    Section {
                        Button(role: .destructive) {
                            onDelete?(id)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("删除闹钟")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "新建闹钟" : "编辑闹钟")
            .sheet(isPresented: $showRepeatSheet) {
                RepeatSelectionView(selectedWeekdays: $selectedWeekdays)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.gray.opacity(0.35)))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(buildAlarm())
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.orange))
                    }
                }
            }
        }
    }

    private func buildAlarm() -> AlarmItem {
        let repeatRule = normalizedRepeatRule()

        return AlarmItem(
            id: existing?.id ?? UUID(),
            time: time,
            repeatRule: repeatRule,
            label: label.isEmpty ? "闹钟" : label,
            soundName: soundName.isEmpty ? "雷达" : soundName,
            snoozeEnabled: snoozeEnabled,
            snoozeMinutes: snoozeMinutes,
            skipHolidayEnabled: skipHolidayEnabled,
            smartMakeUpEnabled: false,
            isEnabled: isEnabled,
            createdAt: existing?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }

    private func normalizedRepeatRule() -> AlarmRepeatRule {
        if selectedWeekdays == Set(1 ... 7) {
            return .everyDay
        }
        if selectedWeekdays == Set([2, 3, 4, 5, 6]) {
            return .weekdays
        }
        return .custom(selectedWeekdays)
    }
}

#Preview {
    AlarmEditView { _ in }
}

private struct RepeatSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedWeekdays: Set<Int>

    var body: some View {
        NavigationStack {
            List {
                ForEach(1 ... 7, id: \.self) { day in
                    Button {
                        toggle(day)
                    } label: {
                        HStack {
                            Text(AlarmRepeatRule.weekdayRowTitle(day))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedWeekdays.contains(day) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("重复")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
    }

    private func toggle(_ day: Int) {
        if selectedWeekdays.contains(day) {
            selectedWeekdays.remove(day)
        } else {
            selectedWeekdays.insert(day)
        }
    }
}
