import SwiftUI
import RealityKit
import ARKit

struct ARSceneView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            ARContainerView()
                .ignoresSafeArea()

            HUDView()
                .padding(.bottom, 24)
        }
    }
}

private struct ARContainerView: UIViewRepresentable {
    func makeCoordinator() -> ARSceneCoordinator { ARSceneCoordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )
        arView.renderOptions.insert(.disableMotionBlur)
        context.coordinator.install(on: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    static func dismantleUIView(_ uiView: ARView, coordinator: ARSceneCoordinator) {
        uiView.session.pause()
    }
}

private struct HUDView: View {
    var body: some View {
        VStack(spacing: 8) {
            Label("바닥 → 커피잔  ·  벽면 → 액자", systemImage: "hand.tap")
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
    }
}

#Preview {
    ARSceneView()
}
