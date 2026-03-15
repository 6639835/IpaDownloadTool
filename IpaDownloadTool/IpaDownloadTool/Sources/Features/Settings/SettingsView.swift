import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    @State private var blockedHostsText = ""
    @State private var mobileRulesText = ""
    @State private var virtualUDID = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeading(
                            eyebrow: "settings.heading.eyebrow",
                            title: "settings.heading.title",
                            detail: "settings.heading.detail"
                        )

                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("settings.developerMode", isOn: $model.settings.developerMode)
                                .onChange(of: model.settings.developerMode) { _, _ in
                                    model.persist()
                                }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("settings.virtualUDID")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                TextField("settings.virtualUDID.placeholder", text: $virtualUDID)
                                    .textInputAutocapitalization(.never)
                                    .onSubmit {
                                        model.settings.virtualUDID = virtualUDID
                                        model.persist()
                                    }
                            }
                        }
                        .glassPanel()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.blockedHosts")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextEditor(text: $blockedHostsText)
                                .frame(minHeight: 88)
                                .scrollContentBackground(.hidden)
                                .background(.white.opacity(0.12), in: .rect(cornerRadius: 18))
                                .onChange(of: blockedHostsText) { _, value in
                                    model.settings.blockedHosts = parseLines(value)
                                    model.persist()
                                }
                        }
                        .glassPanel()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.mobileProvisionRules")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextEditor(text: $mobileRulesText)
                                .frame(minHeight: 88)
                                .scrollContentBackground(.hidden)
                                .background(.white.opacity(0.12), in: .rect(cornerRadius: 18))
                                .onChange(of: mobileRulesText) { _, value in
                                    model.settings.mobileProvisionRules = parseLines(value)
                                    model.persist()
                                }
                        }
                        .glassPanel()

                        GlassEffectContainer(spacing: 12) {
                            VStack(spacing: 12) {
                                Button("settings.action.export") {
                                    model.prepareExport()
                                }
                                .buttonStyle(.glassProminent)

                                Button("settings.action.import") {
                                    model.importFromPasteboard()
                                }
                                .buttonStyle(.glass)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Link(destination: URL(string: "https://github.com/SmileZXLee/IpaDownloadTool")!) {
                                Label("settings.opensource", systemImage: "link")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Text(L10n.formatted("settings.summary", model.ipaHistory.count, model.webHistory.count))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .glassPanel()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("settings.navigation.title")
            .onAppear {
                blockedHostsText = model.settings.blockedHosts.joined(separator: "\n")
                mobileRulesText = model.settings.mobileProvisionRules.joined(separator: "\n")
                virtualUDID = model.settings.virtualUDID
            }
        }
    }

    private func parseLines(_ text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
