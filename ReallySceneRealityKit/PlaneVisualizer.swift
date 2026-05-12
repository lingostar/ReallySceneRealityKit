import ARKit
import RealityKit
import UIKit

/// 감지된 평면 위에 회색 격자를 시각화한다.
/// - 평면당 하나의 `ModelEntity` 를 관리하고, ARKit 가 평면 크기를 갱신할 때마다 메시도 다시 빌드한다.
final class PlaneVisualizer {

    private var anchors: [UUID: AnchorEntity] = [:]
    private var meshes: [UUID: ModelEntity] = [:]
    private weak var arView: ARView?

    init(arView: ARView) {
        self.arView = arView
    }

    func add(_ planeAnchor: ARPlaneAnchor) {
        guard let arView else { return }
        let anchorEntity = AnchorEntity(anchor: planeAnchor)
        let mesh = makeMesh(for: planeAnchor)
        anchorEntity.addChild(mesh)
        arView.scene.addAnchor(anchorEntity)
        anchors[planeAnchor.identifier] = anchorEntity
        meshes[planeAnchor.identifier] = mesh
    }

    func update(_ planeAnchor: ARPlaneAnchor) {
        guard let old = meshes[planeAnchor.identifier],
              let anchorEntity = anchors[planeAnchor.identifier]
        else { return }
        old.removeFromParent()
        let mesh = makeMesh(for: planeAnchor)
        anchorEntity.addChild(mesh)
        meshes[planeAnchor.identifier] = mesh
    }

    func remove(_ identifier: UUID) {
        meshes[identifier]?.removeFromParent()
        anchors[identifier]?.removeFromParent()
        meshes.removeValue(forKey: identifier)
        anchors.removeValue(forKey: identifier)
    }

    func removeAll() {
        for (_, entity) in anchors {
            entity.removeFromParent()
        }
        anchors.removeAll()
        meshes.removeAll()
    }

    // MARK: - Mesh

    private func makeMesh(for planeAnchor: ARPlaneAnchor) -> ModelEntity {
        let extent = planeAnchor.planeExtent
        let mesh = Self.makeGridPlaneMesh(width: extent.width, depth: extent.height)
        let material = Self.makeGridMaterial()
        let entity = ModelEntity(mesh: mesh, materials: [material])

        // ARKit 가 추정한 평면 중심으로 이동 + 회전 보정
        entity.transform.translation = planeAnchor.center
        entity.transform.rotation = simd_quatf(
            angle: extent.rotationOnYAxis,
            axis: SIMD3<Float>(0, 1, 0)
        )
        return entity
    }

    /// 격자 1 칸 = 10cm 가 되도록 UV 를 스케일한 평면 메시.
    private static func makeGridPlaneMesh(width: Float, depth: Float) -> MeshResource {
        let halfW = width / 2
        let halfD = depth / 2
        let uvScale: Float = 1.25  // 1m 당 격자 10칸 (=10cm 간격) — 텍스처가 8칸이므로 1.25배

        let positions: [SIMD3<Float>] = [
            [-halfW, 0, -halfD],
            [ halfW, 0, -halfD],
            [ halfW, 0,  halfD],
            [-halfW, 0,  halfD],
        ]
        let normals: [SIMD3<Float>] = Array(repeating: SIMD3<Float>(0, 1, 0), count: 4)
        let uvs: [SIMD2<Float>] = [
            [0, 0],
            [width * uvScale, 0],
            [width * uvScale, depth * uvScale],
            [0, depth * uvScale],
        ]
        let triangleIndices: [UInt32] = [0, 2, 1, 0, 3, 2]

        var descriptor = MeshDescriptor(name: "PlaneGrid")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(triangleIndices)

        return try! MeshResource.generate(from: [descriptor])
    }

    private static func makeGridMaterial() -> Material {
        var material = UnlitMaterial()
        material.color = .init(
            tint: UIColor.white.withAlphaComponent(0.85),
            texture: .init(GridTexture.resource)
        )
        material.blending = .transparent(opacity: .init(floatLiteral: 0.85))
        return material
    }
}
