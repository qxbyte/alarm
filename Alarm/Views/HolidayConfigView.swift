import SwiftUI

struct HolidayConfigView: View {
    @Environment(\.dismiss) private var dismiss

    let settings: AppSettings
    let onSave: (AppSettings) -> Void

    @State private var legalHolidayEnabled: Bool
    @State private var makeUpWorkdayEnabled: Bool
    @State private var customSkipDates: [Date]
    @State private var customWorkDates: [Date]

    init(settings: AppSettings, onSave: @escaping (AppSettings) -> Void) {
        self.settings = settings
        self.onSave = onSave
        _legalHolidayEnabled = State(initialValue: settings.legalHolidayEnabled)
        _makeUpWorkdayEnabled = State(initialValue: settings.makeUpWorkdayEnabled)
        _customSkipDates = State(initialValue: settings.customSkipDates)
        _customWorkDates = State(initialValue: settings.customWorkDates)
    }

    var body: some View {
        NavigationStack {
            Form {
                Toggle("法定节假日", isOn: $legalHolidayEnabled)
                Toggle("调休工作日", isOn: $makeUpWorkdayEnabled)

                Section("自定义跳过日期") {
                    ForEach(customSkipDates.indices, id: \.self) { index in
                        DatePicker("", selection: bindingForSkip(index), displayedComponents: .date)
                    }
                    .onDelete { offsets in
                        customSkipDates.remove(atOffsets: offsets)
                    }

                    Button("+ 添加跳过日期") {
                        customSkipDates.append(Date())
                    }
                }

                Section("自定义工作日") {
                    ForEach(customWorkDates.indices, id: \.self) { index in
                        DatePicker("", selection: bindingForWork(index), displayedComponents: .date)
                    }
                    .onDelete { offsets in
                        customWorkDates.remove(atOffsets: offsets)
                    }

                    Button("+ 添加工作日") {
                        customWorkDates.append(Date())
                    }
                }
            }
            .navigationTitle("跳过节假日配置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(AppSettings(
                            legalHolidayEnabled: legalHolidayEnabled,
                            makeUpWorkdayEnabled: makeUpWorkdayEnabled,
                            customSkipDates: customSkipDates,
                            customWorkDates: customWorkDates
                        ))
                        dismiss()
                    }
                }
            }
        }
    }

    private func bindingForSkip(_ index: Int) -> Binding<Date> {
        Binding {
            customSkipDates[index]
        } set: { newValue in
            customSkipDates[index] = newValue
        }
    }

    private func bindingForWork(_ index: Int) -> Binding<Date> {
        Binding {
            customWorkDates[index]
        } set: { newValue in
            customWorkDates[index] = newValue
        }
    }
}

#Preview {
    HolidayConfigView(settings: .default) { _ in }
}
