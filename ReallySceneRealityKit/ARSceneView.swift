import SwiftUI
import RealityKit
import ARKit

struct ARSceneView: View {
    @State private var peopleOcclusion: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
            ARContainerView(peopleOcclusion: peopleOcclusion)
                .ignoresSafeArea()

            HUDView(peopleOcclusion: $peopleOcclusion)
                .padding(.bottom, 24)
        }
    }
}

private struct ARContainerView: UIViewRepresentable {
    var peopleOcclusion: Bool

    func makeCoordinator() -> ARSceneCoordinator { ARSceneCoordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )
        arView.renderOptions.insert(.disableMotionBlur)
        context.coordinator.install(on: arView, peopleOcclusion: peopleOcclusion)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.setPeopleOcclusion(peopleOcclusion)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ARSceneCoordinator) {
        uiView.session.pause()
    }
}

private struct HUDView: View {
    @Binding var peopleOcclusion: Bool

    private let supportsOcclusion = ARSceneCoordinator.supportsPeopleOcclusion

    var body: some View {
        VStack(spacing: 10) {
            Toggle(isOn: $peopleOcclusion) {
                Label("People Occlusion", systemImage: "person.crop.rectangle.badge.checkmark")
                    .font(.footnote.weight(.semibold))
                    .labelStyle(.titleAndIcon)
            }
            .toggleStyle(.switch)
            .tint(.orange)
            .disabled(!supportsOcclusion)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .frame(maxWidth: 280)

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
