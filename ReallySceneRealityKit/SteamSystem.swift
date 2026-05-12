import Foundation
import RealityKit
import UIKit

// MARK: - Components

/// 커피컵 위에 부착되어 일정 주기로 김 입자를 뿜는다.
struct SteamEmitterComponent: Component {
    var spawnInterval: Float = 0.15
    var timeSinceLastSpawn: Float = 0
    var spawnOffset: SIMD3<Float> = .zero
    var maxParticles: Int = 35
    var particleLifetime: Float = 1.8
}

/// 각각의 김 입자(子 엔티티)에 부착되어 수명/속도를 추적.
struct SteamParticleComponent: Component {
    var velocity: SIMD3<Float>
    var age: Float = 0
    var lifetime: Float
}

// MARK: - System

/// RealityKit ECS 시스템 — 매 프레임 emitter 에서 새 입자를 만들고,
/// 살아있는 입자는 위로 띄우면서 커지고 사라지게 한다.
final class SteamSystem: System {
    private static let emitterQuery = EntityQuery(where: .has(SteamEmitterComponent.self))
    private static let particleQuery = EntityQuery(where: .has(SteamParticleComponent.self))

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        spawn(context: context, dt: dt)
        advance(context: context, dt: dt)
    }

    // MARK: spawn

    private func spawn(context: SceneUpdateContext, dt: Float) {
        context.scene.performQuery(Self.emitterQuery).forEach { emitter in
            guard var comp = emitter.components[SteamEmitterComponent.self] else { return }
            comp.timeSinceLastSpawn += dt

            let active = emitter.children.lazy.filter {
                $0.components.has(SteamParticleComponent.self)
            }.count

            if comp.timeSinceLastSpawn >= comp.spawnInterval, active < comp.maxParticles {
                comp.timeSinceLastSpawn = 0
                emitter.addChild(makeParticle(
                    offset: comp.spawnOffset,
                    lifetime: comp.particleLifetime
                ))
            }
            emitter.components.set(comp)
        }
    }

    // MARK: advance

    private func advance(context: SceneUpdateContext, dt: Float) {
        var doomed: [Entity] = []
        context.scene.performQuery(Self.particleQuery).forEach { entity in
            guard let particle = entity as? ModelEntity,
                  var comp = entity.components[SteamParticleComponent.self] else { return }
            comp.age += dt
            if comp.age >= comp.lifetime {
                doomed.append(particle)
                return
            }
            let t = comp.age / comp.lifetime  // 0..1

            // 떠오르기 + 약간의 흔들림
            particle.position += comp.velocity * dt

            // 부풀기
            particle.scale = SIMD3<Float>(repeating: 1.0 + t * 2.6)

            // 페이드 아웃
            let alpha = (1 - t) * 0.55
            if var model = particle.model,
               var material = model.materials.first as? UnlitMaterial {
                material.color = .init(tint: UIColor.white.withAlphaComponent(CGFloat(alpha)))
                material.blending = .transparent(opacity: .init(floatLiteral: alpha))
                model.materials = [material]
                particle.model = model
            }

            particle.components.set(comp)
        }
        doomed.forEach { $0.removeFromParent() }
    }

    // MARK: factory

    private func makeParticle(offset: SIMD3<Float>, lifetime: Float) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.010)
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor.white.withAlphaComponent(0.55))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.55))
        let entity = ModelEntity(mesh: mesh, materials: [material])

        let jitter = SIMD3<Float>(
            Float.random(in: -0.006...0.006),
            0,
            Float.random(in: -0.006...0.006)
        )
        entity.position = offset + jitter

        let velocity = SIMD3<Float>(
            Float.random(in: -0.015...0.015),
            Float.random(in: 0.055...0.090),
            Float.random(in: -0.015...0.015)
        )
        entity.components.set(SteamParticleComponent(velocity: velocity, lifetime: lifetime))
        return entity
    }
}
