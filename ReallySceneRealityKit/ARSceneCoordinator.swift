import ARKit
import RealityKit
import UIKit

final class ARSceneCoordinator: NSObject, ARSessionDelegate {

    weak var arView: ARView?
    private var visualizer: PlaneVisualizer?
    private let configuration = ARWorldTrackingConfiguration()
    private var peopleOcclusionEnabled = false

    /// People Occlusion 지원 여부 (앱 UI 가 토글을 비활성화할지 결정할 때 사용)
    static var supportsPeopleOcclusion: Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation)
    }

    func install(on arView: ARView, peopleOcclusion: Bool) {
        self.arView = arView
        self.visualizer = PlaneVisualizer(arView: arView)

        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        applyPeopleOcclusion(peopleOcclusion, runSession: false)

        arView.session.delegate = self
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
    }

    /// SwiftUI 의 토글이 변경될 때 호출. 같은 값으로 들어오면 no-op.
    func setPeopleOcclusion(_ enabled: Bool) {
        guard enabled != peopleOcclusionEnabled else { return }
        applyPeopleOcclusion(enabled, runSession: true)
    }

    private func applyPeopleOcclusion(_ enabled: Bool, runSession: Bool) {
        peopleOcclusionEnabled = enabled
        if enabled {
            // depth 가 가능하면 그쪽이 깊이 기반 가림(앞/뒤 둘 다)을 지원
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
                configuration.frameSemantics.insert(.personSegmentationWithDepth)
            } else if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) {
                configuration.frameSemantics.insert(.personSegmentation)
            }
        } else {
            configuration.frameSemantics.remove(.personSegmentationWithDepth)
            configuration.frameSemantics.remove(.personSegmentation)
        }
        if runSession {
            arView?.session.run(configuration)  // reset 없이 의미체계만 갱신
        }
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor else { continue }
            visualizer?.add(plane)
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor else { continue }
            visualizer?.update(plane)
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            visualizer?.remove(anchor.identifier)
        }
    }

    // MARK: - Tap → place USDZ

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let arView, recognizer.state == .ended else { return }
        let point = recognizer.location(in: arView)

        guard let result = arView.raycast(
            from: point,
            allowing: .existingPlaneGeometry,
            alignment: .any
        ).first else { return }

        let alignment: ARPlaneAnchor.Alignment? = (result.anchor as? ARPlaneAnchor)?.alignment
        let isHorizontal = alignment == .horizontal

        let modelName = isHorizontal ? "CoffeeCup" : "PictureFrame"
        guard let model = try? Entity.load(named: modelName) else {
            assertionFailure("USDZ 로드 실패: \(modelName)")
            return
        }

        // 벽면(수직 평면)에 액자를 걸 때 모델 좌표(+Z=정면, +Y=위)를
        // ARKit 평면 좌표(+Y=노말, -Z=중력 반대)로 정렬: -90° around X.
        if !isHorizontal {
            model.transform.rotation = simd_quatf(
                angle: -.pi / 2,
                axis: SIMD3<Float>(1, 0, 0)
            )
        }

        let placement = AnchorEntity(world: result.worldTransform)
        placement.addChild(model)
        arView.scene.addAnchor(placement)
    }
}
