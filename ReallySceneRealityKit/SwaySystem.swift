import Foundation
import RealityKit
import simd

/// 액자가 벽에 걸려 미세하게 흔들리는 듯한 회전을 주는 컴포넌트.
/// - `basis`: 배치 직후의 회전(기본 자세). 시스템은 이 위에 sin 파동만 얹는다.
/// - `localAxis`: 흔들림 회전축(엔티티 로컬). 액자의 경우 +Z (= 벽 법선)
///                 를 쓰면 벽면 평면에서 좌우로 살짝 기우뚱한다.
struct SwayComponent: Component {
    var phase: Float = 0
    var speed: Float = 1.3
    var amplitude: Float = 0.018  // radians, ≈ 1°
    var localAxis: SIMD3<Float> = SIMD3<Float>(0, 0, 1)
    var basis: simd_quatf
}

final class SwaySystem: System {
    private static let query = EntityQuery(where: .has(SwayComponent.self))

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        context.scene.performQuery(Self.query).forEach { entity in
            guard var comp = entity.components[SwayComponent.self] else { return }
            comp.phase += dt
            entity.components.set(comp)

            let angle = sin(comp.phase * comp.speed) * comp.amplitude
            let delta = simd_quatf(angle: angle, axis: simd_normalize(comp.localAxis))
            entity.transform.rotation = comp.basis * delta
        }
    }
}
