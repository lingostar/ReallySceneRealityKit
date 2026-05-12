# ReallySceneRealityKit

RealityKit과 SceneKit을 직접 비교하며 익히기 위한 iOS 샘플 프로젝트입니다.

## Scene 1 — RealityKit Furnace Sphere

첫 장면은 RealityKit으로 구성된 "용광로처럼 이글거리는 공" 입니다.

- `RealityView` 위에 `PhysicallyBasedMaterial`을 입힌 구체를 눈높이에 배치합니다.
- 커스텀 `Component`/`System`(`EmberMaterialSystem`)이 매 프레임마다 emissive 강도와 색조를 흔들어 불씨가 일렁이는 느낌을 줍니다.
- 외곽의 반투명 halo와 `PointLight`로 화면에 따뜻한 글로우를 더합니다.

### 요구 사항

- Xcode 26 이상
- iOS 18 이상 (시뮬레이터/실기기)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### 빌드 방법

```bash
xcodegen generate
open ReallySceneRealityKit.xcodeproj
```

또는 커맨드라인에서 바로 빌드:

```bash
xcodegen generate
xcodebuild -project ReallySceneRealityKit.xcodeproj \
  -scheme ReallySceneRealityKit \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## 디렉터리 구조

```
ReallySceneRealityKit/
├── ReallySceneRealityKitApp.swift   # @main, 컴포넌트·시스템 등록
├── ContentView.swift                # 루트 SwiftUI View
├── FurnaceSphereView.swift          # RealityView 호스팅
├── FurnaceSphere.swift              # 구체 엔티티 팩토리
├── EmberMaterialSystem.swift        # ECS 컴포넌트와 업데이트 시스템
├── Assets.xcassets/
└── Preview Content/
```
