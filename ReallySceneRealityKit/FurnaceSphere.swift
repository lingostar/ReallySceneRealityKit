import Foundation
import RealityKit
import UIKit

enum FurnaceSphere {
    static func make(radius: Float = 0.18) -> Entity {
        let root = Entity()
        root.name = "FurnaceSphere"

        let core = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [makeCoreMaterial()]
        )
        core.name = "Core"
        core.components.set(EmberMaterialComponent())
        root.addChild(core)

        let halo = ModelEntity(
            mesh: .generateSphere(radius: radius * 1.18),
            materials: [makeHaloMaterial()]
        )
        halo.name = "Halo"
        halo.components.set(EmberHaloComponent())
        root.addChild(halo)

        let glow = PointLight()
        glow.light.color = UIColor(red: 1.0, green: 0.55, blue: 0.18, alpha: 1.0)
        glow.light.intensity = 18000
        glow.light.attenuationRadius = 4.0
        glow.position = .zero
        root.addChild(glow)

        return root
    }

    private static func makeCoreMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.55, green: 0.10, blue: 0.02, alpha: 1.0))
        material.emissiveColor = .init(color: UIColor(red: 1.0, green: 0.45, blue: 0.12, alpha: 1.0))
        material.emissiveIntensity = 3.2
        material.roughness = .init(floatLiteral: 0.65)
        material.metallic = .init(floatLiteral: 0.0)
        material.blending = .opaque
        return material
    }

    private static func makeHaloMaterial() -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 1.0, green: 0.35, blue: 0.08, alpha: 0.35))
        material.emissiveColor = .init(color: UIColor(red: 1.0, green: 0.30, blue: 0.05, alpha: 1.0))
        material.emissiveIntensity = 1.4
        material.roughness = .init(floatLiteral: 1.0)
        material.metallic = .init(floatLiteral: 0.0)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.35))
        material.faceCulling = .front
        return material
    }
}
