import Foundation
import RealityKit
import UIKit

struct EmberMaterialComponent: Component {
    var phase: Float = 0
    var baseIntensity: Float = 3.2
    var flickerSpeed: Float = 6.0
    var hueDrift: Float = 1.4
}

struct EmberHaloComponent: Component {
    var phase: Float = 0
    var baseScale: Float = 1.0
    var pulseSpeed: Float = 2.6
}

final class EmberMaterialSystem: System {
    private static let coreQuery = EntityQuery(where: .has(EmberMaterialComponent.self))
    private static let haloQuery = EntityQuery(where: .has(EmberHaloComponent.self))

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)

        context.scene.performQuery(Self.coreQuery).forEach { entity in
            guard let modelEntity = entity as? ModelEntity,
                  var comp = entity.components[EmberMaterialComponent.self] else { return }
            comp.phase += dt
            entity.components.set(comp)

            let flicker = sin(comp.phase * comp.flickerSpeed) * 0.45
                + sin(comp.phase * comp.flickerSpeed * 2.3) * 0.22
            let intensity = max(0.6, comp.baseIntensity + flicker)

            let hueShift = sin(comp.phase * comp.hueDrift) * 0.07
            let green = CGFloat(max(0.30, min(0.55, 0.43 + hueShift)))
            let emissive = UIColor(red: 1.0, green: green, blue: 0.10, alpha: 1.0)

            guard var model = modelEntity.model,
                  var material = model.materials.first as? PhysicallyBasedMaterial else { return }
            material.emissiveIntensity = intensity
            material.emissiveColor = .init(color: emissive)
            model.materials = [material]
            modelEntity.model = model
        }

        context.scene.performQuery(Self.haloQuery).forEach { entity in
            guard let modelEntity = entity as? ModelEntity,
                  var comp = entity.components[EmberHaloComponent.self] else { return }
            comp.phase += dt
            entity.components.set(comp)

            let breathe = 1.0 + sin(comp.phase * comp.pulseSpeed) * 0.05
            modelEntity.scale = SIMD3<Float>(repeating: comp.baseScale * breathe)

            guard var model = modelEntity.model,
                  var material = model.materials.first as? PhysicallyBasedMaterial else { return }
            let glow = 1.2 + sin(comp.phase * comp.pulseSpeed * 1.3) * 0.4
            material.emissiveIntensity = glow
            model.materials = [material]
            modelEntity.model = model
        }
    }
}
