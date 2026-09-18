import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    infrastructureCard
                    nextStageCard
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(FacelyTheme.accent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FACELY")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("iOS · ETAPA 1")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FacelyTheme.accent)
            Text("Infraestructura nativa preparada para portar la aplicación Android sin mezclar los índices faciales.")
                .foregroundStyle(.secondary)
        }
    }

    private var infrastructureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Infraestructura", systemImage: "externaldrive.badge.checkmark")
                .font(.headline)

            statusRow(title: "SwiftUI", value: "Activo")
            statusRow(title: "iOS mínimo", value: "16.0")
            statusRow(title: "Base FaceNet", value: databaseStatus(for: .faceNet))
            statusRow(title: "Base UniFace · ArcFace", value: databaseStatus(for: .arcFace))
            statusRow(title: "Migraciones", value: "No destructivas")
        }
        .facelyCard()
    }

    private var nextStageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Próxima etapa", systemImage: "photo.on.rectangle.angled")
                .font(.headline)
            Text("PhotoKit: permisos completo/limitado, lectura de PHAsset y escaneo incremental. Estas funciones todavía no se presentan como terminadas.")
                .foregroundStyle(.secondary)
        }
        .facelyCard()
    }

    private func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func databaseStatus(for profile: FaceEngineProfile) -> String {
        switch model.bootstrapState {
        case .idle:
            return "Pendiente"
        case .loading:
            return "Inicializando…"
        case let .ready(faceNetSchema, arcFaceSchema):
            let version = profile == .faceNet ? faceNetSchema : arcFaceSchema
            return "SQLite v\(version)"
        case let .failed(message):
            return "Error: \(message)"
        }
    }
}

private extension View {
    func facelyCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FacelyTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(FacelyTheme.border, lineWidth: 1)
            }
    }
}
