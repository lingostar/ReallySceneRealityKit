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
        guard let usdz = try? Entity.load(named: modelName) else {
            assertionFailure("USDZ 로드 실패: \(modelName)")
            return
        }

        // installGestures 는 HasCollision 엔티티를 요구하므로 ModelEntity 래퍼에 담는다.
        let interactive = ModelEntity()
        interactive.name = isHorizontal ? "CoffeeCupRoot" : "PictureFrameRoot"
        interactive.addChild(usdz)

        // 벽면(수직 평면): 모델(+Z=정면, +Y=위)을 ARKit 평면(+Y=노말, -Z=중력 반대)에 맞춤
        if !isHorizontal {
            interactive.transform.rotation = simd_quatf(
                angle: -.pi / 2,
                axis: SIMD3<Float>(1, 0, 0)
            )
        }

        // 콜리전 — visualBounds 기반의 박스 셰이프 (제스처 hit-test 에 사용)
        let bounds = interactive.visualBounds(
            recursive: true,
            relativeTo: interactive,
            excludeInactive: false
        )
        let collisionShape = ShapeResource
            .generateBox(size: bounds.extents)
            .offsetBy(translation: bounds.center)
        interactive.components.set(CollisionComponent(shapes: [collisionShape]))

        // ECS — 컵 위에는 김, 액자에는 가벼운 흔들림
        if isHorizontal {
            interactive.components.set(SteamEmitterComponent(
                spawnOffset: SIMD3<Float>(0, bounds.max.y - 0.005, 0)
            ))
        } else {
            interactive.components.set(SwayComponent(basis: interactive.transform.rotation))
        }

        // 씬에 부착
        let placement = AnchorEntity(world: result.worldTransform)
        placement.addChild(interactive)
        arView.scene.addAnchor(placement)

        // 제스처: 컵은 옮기고 돌리기, 액자는 옮기기만(회전은 sway 와 충돌)
        let gestures: ARView.EntityGestures = isHorizontal ? [.translation, .rotation] : [.translation]
        arView.installGestures(gestures, for: interactive)
    }
}
