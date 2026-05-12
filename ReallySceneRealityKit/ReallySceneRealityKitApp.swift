import SwiftUI

@main
struct ReallySceneRealityKitApp: App {
    init() {
        EmberMaterialComponent.registerComponent()
        EmberHaloComponent.registerComponent()
        EmberMaterialSystem.registerSystem()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
