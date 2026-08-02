import SwiftUI
import TarotUI

@main
struct TarotIPhoneApp: App {
    var body: some Scene {
        WindowGroup { AppRoot() }
    }
}

private struct AppRoot: View {
    @State private var container: AppContainer?
    @State private var errorMessage: String?

    init() {
        do {
            _container = State(initialValue: try AppContainer())
            _errorMessage = State(initialValue: nil)
        } catch {
            _container = State(initialValue: nil)
            _errorMessage = State(initialValue: error.localizedDescription)
        }
    }

    var body: some View {
        Group {
            if let container {
                ContentView(container: container)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("No se pudo iniciar Tarot")
                        .font(.title2.bold())
                    Text(errorMessage ?? "Error de carga de recursos")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    Button {
                        do {
                            container = try AppContainer()
                            errorMessage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reintentar")
                                .bold()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                        .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
    }
}

