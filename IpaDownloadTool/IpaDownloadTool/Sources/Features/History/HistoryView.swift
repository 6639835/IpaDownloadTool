import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: AppModel
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                if model.sortedHistory.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "tray",
                            title: "history.empty.title",
                            detail: "history.empty.detail"
                        )
                        .padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeading(
                                eyebrow: "history.heading.eyebrow",
                                title: "history.heading.title",
                                detail: "history.heading.detail"
                            )

                            Picker("history.sort.label", selection: $model.settings.historySort) {
                                ForEach(HistorySort.allCases) { sort in
                                    Text(sort.titleKey).tag(sort)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: model.settings.historySort) { _, _ in
                                model.persist()
                            }

                            LazyVStack(spacing: 14) {
                                ForEach(model.sortedHistory) { record in
                                    Button {
                                        model.presentedRecordID = record.id
                                    } label: {
                                        HistoryCard(record: record, model: model)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            model.presentedRecordID = record.id
                                        } label: {
                                            Label("history.action.viewDetails", systemImage: "info.circle")
                                        }
                                        Button {
                                            model.startDownload(for: record.id)
                                        } label: {
                                            Label("history.action.startDownload", systemImage: "arrow.down.circle")
                                        }
                                        Button(role: .destructive) {
                                            model.deleteHistoryRecord(record.id)
                                        } label: {
                                            Label("history.action.delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("history.navigation.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !model.sortedHistory.isEmpty {
                        Button("history.action.clear", role: .destructive) {
                            showClearConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog(
                "history.clear.confirm.title",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("history.action.clear", role: .destructive) {
                    model.clearHistory()
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("history.clear.confirm.message")
            }
        }
    }
}

private struct HistoryCard: View {
    let record: IpaRecord
    let model: AppModel

    var body: some View {
        HStack(spacing: 16) {
            IpaArtworkView(title: record.displayTitle, iconURL: record.iconURL)

            VStack(alignment: .leading, spacing: 8) {
                Text(record.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if let version = record.version, !version.isEmpty {
                        Label(version, systemImage: "number")
                    }
                    if record.hasLocalFile {
                        Label("history.badge.downloaded", systemImage: "checkmark.circle.fill")
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

                Text(record.createdAt.localizedTimestamp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .glassPanel()
    }
}

struct IpaDetailView: View {
    @ObservedObject var model: AppModel
    let recordID: String

    @State private var draftTitle = ""

    private var record: IpaRecord? {
        model.record(for: recordID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                if let record {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 16) {
                                IpaArtworkView(title: record.displayTitle, iconURL: record.iconURL)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(record.displayTitle)
                                        .font(.title2.weight(.bold))
                                    Text(record.version ?? L10n.string("history.detail.versionMissing"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    if record.hasLocalFile {
                                        Label(model.fileSizeText(for: record), systemImage: "internaldrive")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .glassPanel(cornerRadius: 34)

                            VStack(alignment: .leading, spacing: 14) {
                                Text("history.detail.appName")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                TextField("history.detail.appNamePlaceholder", text: $draftTitle)
                                    .textInputAutocapitalization(.never)
                                    .onSubmit {
                                        model.renameRecord(id: record.id, title: draftTitle)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(.white.opacity(0.18), in: .rect(cornerRadius: 18))
                            }
                            .glassPanel()

                            VStack(alignment: .leading, spacing: 16) {
                                DetailLine(title: "history.detail.bundleIdentifier", value: record.bundleIdentifier ?? L10n.string("common.unknown"))
                                DetailLine(title: "history.detail.downloadURL", value: record.downloadURL)
                                DetailLine(title: "history.detail.sourceURL", value: record.fromPageURL ?? L10n.string("common.unknown"))
                                DetailLine(title: "history.detail.createdAt", value: record.createdAt.localizedTimestamp)
                            }
                            .glassPanel()

                            GlassEffectContainer(spacing: 12) {
                                VStack(spacing: 12) {
                                    Button("history.detail.downloadAgain") {
                                        model.startDownload(for: record.id)
                                    }
                                    .buttonStyle(.glassProminent)

                                    if let fileURL = model.localFileURL(for: record), fileURL.isFileURL {
                                        ShareLink(item: fileURL) {
                                            Label("history.detail.shareLocalIPA", systemImage: "square.and.arrow.up")
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.glass)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                    .onAppear {
                        draftTitle = record.displayTitle
                    }
                } else {
                    ScrollView {
                        EmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "history.detail.missing.title",
                            detail: "history.detail.missing.detail"
                        )
                        .padding(20)
                    }
                }
            }
            .navigationTitle("history.detail.navigation.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") {
                        model.presentedRecordID = nil
                    }
                }
            }
        }
    }
}
