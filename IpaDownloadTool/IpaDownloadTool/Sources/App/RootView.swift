import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            BrowserView(model: model)
                .tag(RootTab.browser)
                .tabItem {
                    Label("tab.browser", systemImage: "safari")
                }

            HistoryView(model: model)
                .tag(RootTab.history)
                .tabItem {
                    Label("tab.history", systemImage: "clock.fill")
                }

            DownloadsView(model: model)
                .tag(RootTab.downloads)
                .tabItem {
                    Label("tab.downloads", systemImage: "arrow.down.circle.fill")
                }

            SettingsView(model: model)
                .tag(RootTab.settings)
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape.fill")
                }
        }
        .sheet(
            isPresented: Binding(
                get: { model.presentedRecordID != nil },
                set: { if !$0 { model.presentedRecordID = nil } }
            )
        ) {
            if let recordID = model.presentedRecordID {
                IpaDetailView(model: model, recordID: recordID)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $model.sharePayload) { payload in
            ShareSheet(items: [payload.text])
        }
        .sheet(isPresented: $model.showAgreementSheet) {
            AgreementSheetView(model: model)
        }
        .confirmationDialog(
            "root.pasteboard.title",
            isPresented: Binding(
                get: { model.pasteboardPromptURL != nil },
                set: { if !$0 { model.pasteboardPromptURL = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("root.pasteboard.open") {
                model.loadFromPasteboardPrompt()
            }
            Button("root.pasteboard.ignore", role: .cancel) {
                model.dismissPasteboardPrompt()
            }
        } message: {
            Text(model.pasteboardPromptURL ?? "")
        }
        .alert(
            model.notice?.title ?? "",
            isPresented: Binding(
                get: { model.notice != nil },
                set: { if !$0 { model.notice = nil } }
            ),
            presenting: model.notice
        ) { _ in
            Button("common.ok") { model.notice = nil }
        } message: { notice in
            Text(notice.message)
        }
    }
}
