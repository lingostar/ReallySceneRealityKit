# ReallySceneRealityKit

RealityKit과 SceneKit을 직접 비교하며 익히기 위한 iOS 샘플 프로젝트입니다.

## Scene 1 — RealityKit AR Room (Tap-to-Place)

ARKit + RealityKit으로 만든 AR 인테리어 샘플입니다.

- 앱을 실행하면 카메라가 열리고, `ARWorldTrackingConfiguration` 의 `[.horizontal, .vertical]` 평면 감지가 동작합니다.
- 감지된 바닥/벽면 위에 반투명 **회색 격자(10cm 간격)** 가 실시간으로 그려집니다.
- 화면을 탭하면 그 위치에 USDZ가 놓입니다.
  - **바닥(수평 평면) → 커피잔** (`CoffeeCup.usdz`)
  - **벽면(수직 평면) → 액자** (`PictureFrame.usdz`)
- 액자는 모델 좌표(`+Z=정면, +Y=위`)를 ARKit의 평면 좌표계(`+Y=노말, -Z=중력 반대`)에 맞춰 자동 정렬됩니다 (`-90°` around X).
- 배치된 후에는 RealityKit 커스텀 ECS 두 개가 매 프레임 돕니다:
  - `SteamSystem` — 커피컵 위에서 김 입자를 주기적으로 생성하고, 떠오르며 부풀고 페이드아웃 시킵니다.
  - `SwaySystem` — 벽에 걸린 액자에 약한 회전 흔들림(`±1°`)을 줍니다.
- `arView.installGestures(...)` 로 컵에는 **드래그·회전**, 액자에는 **드래그** 가 활성화됩니다 (배치된 객체를 한 손가락 드래그로 이동, 두 손가락 회전으로 돌리기).
- 상단 HUD 의 스위치로 People Occlusion 을 즉시 토글할 수 있습니다.

> ⚠️ AR 카메라/평면 인식은 **시뮬레이터에서 동작하지 않습니다.** 실기기(iPhone/iPad, A12 이상) 에서 실행해 주세요.

### 요구 사항

- Xcode 26 이상
- iOS 18 이상
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### 빌드

```bash
xcodegen generate
open ReallySceneRealityKit.xcodeproj
```

또는:

```bash
xcodegen generate
xcodebuild -project ReallySceneRealityKit.xcodeproj \
  -scheme ReallySceneRealityKit \
  -destination 'generic/platform=iOS' \
  build
```

## USDZ 모델 다시 굽기 (옵션)

`ReallySceneRealityKit/Models/*.usdz` 는 `Tools/GenerateModels.swift` 가 SceneKit으로 굽는 절차적 모델입니다. 디자인을 바꾸고 싶으면 스크립트를 수정하고 다시 실행하세요:

```bash
swift Tools/GenerateModels.swift
```

원하는 외부 USDZ로 교체하려면 같은 파일명(`CoffeeCup.usdz`, `PictureFrame.usdz`)으로 갈아끼우기만 하면 됩니다.

## 디렉터리 구조

```
ReallySceneRealityKit/
├── ReallySceneRealityKitApp.swift   # @main
├── ContentView.swift                # 루트 SwiftUI View
├── ARSceneView.swift                # ARView 의 SwiftUI 래퍼 + HUD
├── ARSceneCoordinator.swift         # 세션 델리게이트 + 탭→배치 + installGestures
├── PlaneVisualizer.swift            # 감지된 평면에 격자 메시 부착
├── GridTexture.swift                # 격자 텍스처 (CGImage)
├── SteamSystem.swift                # ECS: 커피컵 위 김 파티클
├── SwaySystem.swift                 # ECS: 액자 미세 흔들림
├── Models/
│   ├── CoffeeCup.usdz
│   └── PictureFrame.usdz
├── Assets.xcassets/
└── Preview Content/
Tools/
└── GenerateModels.swift             # USDZ 생성 스크립트 (macOS)
```
