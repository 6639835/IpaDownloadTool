import SwiftUI

struct AppBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.orange.opacity(0.18), .yellow.opacity(0.08), .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.orange.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 50)
                .offset(x: -140, y: -280)

            Circle()
                .fill(.cyan.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 160, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct GlassPanelModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .padding(18)
            .glassEffect(interactive ? .regular.interactive() : .regular, in: .rect(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 28, interactive: Bool = false) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}

struct SectionHeading: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
                .textCase(.uppercase)

            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.weight(.semibold))

            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassPanel(cornerRadius: 32)
    }
}

struct IpaArtworkView: View {
    let title: String
    let iconURL: String?

    var body: some View {
        Group {
            if let iconURL, let url = URL(string: iconURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 64, height: 64)
        .background(.white.opacity(0.28), in: .rect(cornerRadius: 18))
        .clipShape(.rect(cornerRadius: 18))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(String(title.prefix(1)).uppercased())
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

struct DetailLine: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AgreementSheetView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeading(
                            eyebrow: "agreement.heading.eyebrow",
                            title: "agreement.heading.title",
                            detail: "agreement.heading.detail"
                        )

                        Text(L10n.agreementBody)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassPanel(cornerRadius: 34)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("agreement.accept") {
                        model.acceptAgreement()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}
