import SwiftUI

struct AlarmEditView: View {
    @Environment(\.dismiss) private var dismiss

    let existing: AlarmItem?
    let onSave: (AlarmItem) -> Void
    let onDelete: ((UUID) -> Void)?

    @State private var time: Date
    @State private var label: String
    @State private var repeatPreset: AlarmRepeatPreset
    @State private var customWeekdays: Set<Int>
    @State private var soundName: String
    @State private var snoozeEnabled: Bool
    @State private var snoozeMinutes: Int
    @State private var skipHolidayEnabled: Bool
    @State private var isEnabled: Bool

    @State private var showSnoozePicker = false

    init(existing: AlarmItem? = nil, onSave: @escaping (AlarmItem) -> Void, onDelete: ((UUID) -> Void)? = nil) {
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete

        _time = State(initialValue: existing?.time ?? Date())
        _label = State(initialValue: existing?.label ?? "闹钟")
        _repeatPreset = State(initialValue: existing?.repeatRule.preset ?? .weekdays)
        _customWeekdays = State(initialValue: existing?.repeatRule.weekdays ?? [2, 3, 4, 5, 6])
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

                Picker("重复", selection: $repeatPreset) {
                    ForEach(AlarmRepeatPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }

                if repeatPreset == .custom {
                    weekdayChips
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

    private var weekdayChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("自定义重复")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(1 ... 7, id: \.self) { day in
                    let selected = customWeekdays.contains(day)
                    Button(AlarmRepeatRule.weekdayTitle(day)) {
                        if selected {
                            customWeekdays.remove(day)
                        } else {
                            customWeekdays.insert(day)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(selected ? .orange : .gray)
                }
            }
        }
    }

    private func buildAlarm() -> AlarmItem {
        let repeatRule: AlarmRepeatRule

        switch repeatPreset {
        case .everyDay:
            repeatRule = .everyDay
        case .weekdays:
            repeatRule = .weekdays
        case .custom:
            repeatRule = .custom(customWeekdays)
        }

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
}

#Preview {
    AlarmEditView { _ in }
}
