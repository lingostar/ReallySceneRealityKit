import SwiftUI

@main
struct ReallySceneRealityKitApp: App {
    init() {
        // 커스텀 ECS 등록 — 앱 수명 동안 한 번만.
        SteamEmitterComponent.registerComponent()
        SteamParticleComponent.registerComponent()
        SteamSystem.registerSystem()

        SwayComponent.registerComponent()
        SwaySystem.registerSystem()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
