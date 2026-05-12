import ARKit
import RealityKit
import UIKit

final class ARSceneCoordinator: NSObject, ARSessionDelegate {

    weak var arView: ARView?
    private var visualizer: PlaneVisualizer?

    func install(on arView: ARView) {
        self.arView = arView
        self.visualizer = PlaneVisualizer(arView: arView)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.delegate = self
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)
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
