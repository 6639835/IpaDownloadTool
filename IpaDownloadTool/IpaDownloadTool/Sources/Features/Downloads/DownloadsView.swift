import SwiftUI

struct DownloadsView: View {
    @ObservedObject var model: AppModel
    @State private var mode = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SectionHeading(
                            eyebrow: "downloads.heading.eyebrow",
                            title: "downloads.heading.title",
                            detail: "downloads.heading.detail"
                        )

                        Picker("downloads.mode.label", selection: $mode) {
                            Text("downloads.mode.inProgress").tag(0)
                            Text("downloads.mode.completed").tag(1)
                        }
                        .pickerStyle(.segmented)

                        if mode == 0 {
                            if model.downloads.isEmpty {
                                EmptyStateView(
                                    icon: "arrow.down.circle.dotted",
                                    title: "downloads.empty.inProgress.title",
                                    detail: "downloads.empty.inProgress.detail"
                                )
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(model.downloads) { item in
                                        DownloadCard(item: item, cancelAction: {
                                            model.cancelDownload(item.recordID)
                                        })
                                    }
                                }
                            }
                        } else {
                            if model.downloadedHistory.isEmpty {
                                EmptyStateView(
                                    icon: "internaldrive",
                                    title: "downloads.empty.completed.title",
                                    detail: "downloads.empty.completed.detail"
                                )
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(model.downloadedHistory) { record in
                                        DownloadedCard(record: record, model: model)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("downloads.navigation.title")
        }
    }
}

private struct DownloadCard: View {
    let item: DownloadItem
    let cancelAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 12)
                Text(item.state.titleKey)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: item.expectedBytes > 0 ? item.progress : nil)
                .progressViewStyle(.linear)

            HStack {
                Text(ByteCountFormatter.string(fromByteCount: item.receivedBytes, countStyle: .file))
                Spacer()
                Text(item.expectedBytes > 0 ? ByteCountFormatter.string(fromByteCount: item.expectedBytes, countStyle: .file) : L10n.string("downloads.size.calculating"))
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let errorMessage = item.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if item.state == .downloading || item.state == .queued {
                Button("downloads.action.cancel", role: .cancel, action: cancelAction)
                    .buttonStyle(.glass)
            }
        }
        .glassPanel()
    }
}

private struct DownloadedCard: View {
    let record: IpaRecord
    let model: AppModel

    var body: some View {
        HStack(spacing: 16) {
            IpaArtworkView(title: record.displayTitle, iconURL: record.iconURL)

            VStack(alignment: .leading, spacing: 8) {
                Text(record.displayFileName)
                    .font(.headline)
                    .lineLimit(2)
                Text(model.fileSizeText(for: record))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            if let fileURL = model.localFileURL(for: record) {
                ShareLink(item: fileURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.glass)
            }
        }
        .glassPanel()
        .onTapGesture {
            model.presentedRecordID = record.id
        }
    }
}
