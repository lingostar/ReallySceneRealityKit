import SwiftUI
import RealityKit

struct FurnaceSphereView: View {
    var body: some View {
        RealityView { content in
            let furnace = FurnaceSphere.make()
            furnace.position = SIMD3<Float>(0, 0, 0)
            content.add(furnace)

            let key = DirectionalLight()
            key.light.color = .white
            key.light.intensity = 600
            key.orientation = simd_quatf(angle: -.pi / 5, axis: SIMD3<Float>(1, 0, 0))
            content.add(key)
        }
        .background(
            RadialGradient(
                colors: [Color(red: 0.20, green: 0.06, blue: 0.02),
                         Color.black],
                center: .center,
                startRadius: 40,
                endRadius: 700
            )
        )
    }
}

#Preview {
    FurnaceSphereView()
}
