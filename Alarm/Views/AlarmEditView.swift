import SwiftUI

private let secondaryPageBackground = Color(white: 0.92)
private let panelCornerRadius: CGFloat = 24

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

    @State private var showSnoozePicker = false

    init(existing: AlarmItem? = nil, onSave: @escaping (AlarmItem) -> Void, onDelete: ((UUID) -> Void)? = nil) {
        self.existing = existing
        self.onSave = onSave
        self.onDelete = onDelete

        _time = State(initialValue: existing?.time ?? Date())
        _label = State(initialValue: existing?.label ?? "闹钟")
        _selectedWeekdays = State(initialValue: existing?.repeatRule.weekdays ?? Set([2, 3, 4, 5, 6]))
        _soundName = State(initialValue: existing?.soundName ?? "射线")
        _snoozeEnabled = State(initialValue: existing?.snoozeEnabled ?? true)
        _snoozeMinutes = State(initialValue: existing?.snoozeMinutes ?? 9)
        _skipHolidayEnabled = State(initialValue: existing?.skipHolidayEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                secondaryPageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        topBar

                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 188)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: panelCornerRadius).fill(Color.white))

                        settingsCard

                        if let id = existing?.id {
                            Button {
                                onDelete?(id)
                                dismiss()
                            } label: {
                                Text("删除闹钟")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: panelCornerRadius).fill(Color.white))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color(white: 0.25))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
            }

            Spacer()

            Text("编辑闹钟")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(white: 0.14))

            Spacer()

            Button {
                onSave(buildAlarm())
                dismiss()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.orange))
            }
        }
        .padding(.top, 14)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            NavigationLink {
                RepeatSelectionView(selectedWeekdays: $selectedWeekdays)
            } label: {
                row("重复", value: normalizedRepeatRule().displayText)
            }

            divider

            NavigationLink {
                AlarmLabelEditView(label: $label)
            } label: {
                row("标签", value: label)
            }

            divider

            NavigationLink {
                AlarmSoundSelectionView(selectedSound: $soundName)
            } label: {
                row("铃声", value: soundName)
            }

            divider

            HStack {
                Text("稍后提醒")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.14))
                Spacer()
                Toggle("", isOn: $snoozeEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal, 18)
            .frame(height: 56)

            divider

            Button {
                guard snoozeEnabled else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSnoozePicker.toggle()
                }
            } label: {
                HStack {
                    Text("稍后提醒时长")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(snoozeEnabled ? Color(white: 0.14) : Color(white: 0.6))
                    Spacer()
                    Text("\(snoozeMinutes)分钟")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(snoozeEnabled ? .orange : Color(white: 0.6))
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
            }
            .disabled(!snoozeEnabled)

            if snoozeEnabled, showSnoozePicker {
                divider

                Picker("稍后提醒时长", selection: $snoozeMinutes) {
                    ForEach(1 ... 30, id: \.self) { minute in
                        Text("\(minute)分钟").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showSnoozePicker)
            }

            divider

            HStack {
                Text("跳过节假日")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.14))
                Spacer()
                Toggle("", isOn: $skipHolidayEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
        }
        .background(RoundedRectangle(cornerRadius: panelCornerRadius).fill(Color.white))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(white: 0.88))
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(white: 0.14))

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(white: 0.5))
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(white: 0.6))
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
    }

    private func buildAlarm() -> AlarmItem {
        let repeatRule = normalizedRepeatRule()

        return AlarmItem(
            id: existing?.id ?? UUID(),
            time: time,
            repeatRule: repeatRule,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "闹钟" : label,
            soundName: soundName,
            snoozeEnabled: snoozeEnabled,
            snoozeMinutes: snoozeMinutes,
            skipHolidayEnabled: skipHolidayEnabled,
            smartMakeUpEnabled: false,
            isEnabled: existing?.isEnabled ?? true,
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
        ZStack {
            secondaryPageBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                pageHeader(title: "重复")

                VStack(spacing: 0) {
                    ForEach(1 ... 7, id: \.self) { day in
                        Button {
                            toggle(day)
                        } label: {
                            HStack {
                                Text(AlarmRepeatRule.weekdayRowTitle(day))
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Color(white: 0.14))

                                Spacer()

                                if selectedWeekdays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.horizontal, 18)
                            .frame(height: 64)
                        }

                        if day != 7 {
                            Rectangle()
                                .fill(Color(white: 0.88))
                                .frame(height: 1)
                                .padding(.horizontal, 18)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: panelCornerRadius).fill(Color.white))
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 12)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }

    private func toggle(_ day: Int) {
        if selectedWeekdays.contains(day) {
            selectedWeekdays.remove(day)
        } else {
            selectedWeekdays.insert(day)
        }
    }

    private func pageHeader(title: String) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color(white: 0.25))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
            }

            Spacer()

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(white: 0.14))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
    }
}

private struct AlarmLabelEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var label: String

    var body: some View {
        ZStack {
            secondaryPageBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                pageHeader(title: "标签")

                TextField("输入闹钟描述", text: $label)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.14))
                    .padding(.horizontal, 16)
                    .frame(height: 62)
                    .background(RoundedRectangle(cornerRadius: panelCornerRadius).fill(Color.white))
                    .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 12)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }

    private func pageHeader(title: String) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color(white: 0.25))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
            }

            Spacer()

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(white: 0.14))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
    }
}

private struct AlarmSoundSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSound: String
    @State private var tones: [ToneOption] = []

    var body: some View {
        ZStack {
            secondaryPageBackground.ignoresSafeArea()

            VStack(spacing: 12) {
                pageHeader(title: "铃声")

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        card {
                            optionRow(title: "触感反馈", value: "默认", showsChevron: true)
                        }

                        Text("商店")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(white: 0.45))
                            .padding(.horizontal, 18)

                        card {
                            VStack(spacing: 0) {
                                Text("Tone Store")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Color.orange)
                                    .padding(.horizontal, 18)
                                    .frame(height: 50)
                                divider
                                Text("下载所有已购买的铃声")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Color.orange)
                                    .padding(.horizontal, 18)
                                    .frame(height: 50)
                            }
                        }

                        Text("歌曲")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(white: 0.45))
                            .padding(.horizontal, 18)

                        card {
                            optionRow(title: "选取歌曲", value: "", showsChevron: true)
                        }

                        Text("电话铃声")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(white: 0.45))
                            .padding(.horizontal, 18)

                        card {
                            VStack(spacing: 0) {
                                ForEach(Array(tones.enumerated()), id: \.offset) { index, tone in
                                    Button {
                                        selectedSound = tone.displayName
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedSound == tone.displayName ? "checkmark" : "circle")
                                                .font(.system(size: 16, weight: .regular))
                                                .foregroundStyle(selectedSound == tone.displayName ? .orange : .clear)
                                                .frame(width: 18)

                                            Text(tone.displayName + (index == 0 ? "（默认）" : ""))
                                                .font(.system(size: 15, weight: .regular))
                                                .foregroundStyle(Color(white: 0.14))

                                            Spacer()

                                            if index == 4 {
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundStyle(Color(white: 0.6))
                                            }
                                        }
                                        .padding(.horizontal, 18)
                                        .frame(height: 52)
                                    }

                                    if index != tones.count - 1 {
                                        divider
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
            .padding(.top, 12)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if tones.isEmpty {
                tones = SystemToneProvider.loadTones()
                if !tones.contains(where: { $0.displayName == selectedSound }), let first = tones.first {
                    selectedSound = first.displayName
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func pageHeader(title: String) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color(white: 0.25))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white))
            }

            Spacer()

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(white: 0.14))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .background(RoundedRectangle(cornerRadius: panelCornerRadius).fill(Color.white))
    }

    private func optionRow(title: String, value: String, showsChevron: Bool) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(white: 0.14))
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(white: 0.5))
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(white: 0.6))
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(white: 0.88))
            .frame(height: 1)
            .padding(.horizontal, 18)
    }
}

private struct ToneOption: Identifiable, Hashable {
    let id: String
    let displayName: String
}

private enum SystemToneProvider {
    static func loadTones() -> [ToneOption] {
        let systemRoots = [
            "/System/Library/Audio/UISounds",
            "/System/Library/Audio/UISounds/Modern"
        ]
        let allowedExtensions = Set(["caf", "m4r", "aiff", "wav", "mp3"])

        var options: [ToneOption] = []
        var seen = Set<String>()

        for root in systemRoots {
            guard let enumerator = FileManager.default.enumerator(atPath: root) else { continue }
            for case let path as String in enumerator {
                let url = URL(fileURLWithPath: path)
                let ext = url.pathExtension.lowercased()
                guard allowedExtensions.contains(ext) else { continue }

                let identifier = (path as NSString).lastPathComponent
                guard !seen.contains(identifier) else { continue }
                seen.insert(identifier)

                let rawName = URL(fileURLWithPath: identifier).deletingPathExtension().lastPathComponent
                let displayName = prettifyToneName(rawName)
                options.append(ToneOption(id: identifier, displayName: displayName))
            }
        }

        let sorted = options.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
        if !sorted.isEmpty {
            return sorted
        }

        // Fallback only if system tone files cannot be enumerated.
        return ["射线", "雷达", "底炉", "出发", "倒影", "顶篷", "故事时间", "脚步"].map {
            ToneOption(id: $0, displayName: $0)
        }
    }

    private static func prettifyToneName(_ raw: String) -> String {
        var value = raw.replacingOccurrences(of: "_", with: " ")
        value = value.replacingOccurrences(of: "-", with: " ")
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "未知铃声" : value
    }
}
