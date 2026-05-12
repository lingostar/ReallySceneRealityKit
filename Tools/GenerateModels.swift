#!/usr/bin/env swift

// macOS 전용. SceneKit을 사용해 CoffeeCup.usdz / PictureFrame.usdz 를 생성합니다.
//   $ swift Tools/GenerateModels.swift
// 출력: ReallySceneRealityKit/Models/CoffeeCup.usdz, PictureFrame.usdz

import Foundation
import AppKit
import SceneKit
import ModelIO
import SceneKit.ModelIO

// MARK: - Material helpers

func pbr(_ configure: (SCNMaterial) -> Void) -> SCNMaterial {
    let material = SCNMaterial()
    material.lightingModel = .physicallyBased
    material.isDoubleSided = false
    configure(material)
    return material
}

// MARK: - Coffee cup

func makeCoffeeCupScene() -> SCNScene {
    let scene = SCNScene()
    let root = scene.rootNode

    let porcelain = pbr { m in
        m.diffuse.contents = NSColor(white: 0.96, alpha: 1.0)
        m.roughness.contents = 0.32
        m.metalness.contents = 0.0
    }
    let saucerMat = pbr { m in
        m.diffuse.contents = NSColor(white: 0.93, alpha: 1.0)
        m.roughness.contents = 0.40
        m.metalness.contents = 0.0
    }
    let coffeeMat = pbr { m in
        m.diffuse.contents = NSColor(red: 0.16, green: 0.07, blue: 0.03, alpha: 1.0)
        m.roughness.contents = 0.15
        m.metalness.contents = 0.0
    }

    // 받침
    let saucer = SCNNode(geometry: SCNCylinder(radius: 0.070, height: 0.006))
    saucer.geometry?.firstMaterial = saucerMat
    saucer.position = SCNVector3(0, 0.003, 0)
    root.addChildNode(saucer)

    // 컵 본체
    let cup = SCNNode(geometry: SCNCylinder(radius: 0.038, height: 0.078))
    cup.geometry?.firstMaterial = porcelain
    cup.position = SCNVector3(0, 0.006 + 0.039, 0)
    root.addChildNode(cup)

    // 커피 표면 (컵 윗면 살짝 아래)
    let coffee = SCNNode(geometry: SCNCylinder(radius: 0.035, height: 0.0025))
    coffee.geometry?.firstMaterial = coffeeMat
    coffee.position = SCNVector3(0, 0.006 + 0.073, 0)
    root.addChildNode(coffee)

    // 손잡이 — 토러스를 회전해서 컵 측면에 부착
    let handleTorus = SCNTorus(ringRadius: 0.022, pipeRadius: 0.006)
    let handle = SCNNode(geometry: handleTorus)
    handle.geometry?.firstMaterial = porcelain
    handle.position = SCNVector3(0.042, 0.006 + 0.045, 0)
    handle.eulerAngles = SCNVector3(0, 0, CGFloat.pi / 2)  // 링 평면 → YZ 평면
    root.addChildNode(handle)

    return scene
}

// MARK: - Picture frame
// 모델 좌표 규약:
//   +Z : 정면 (그림 보이는 쪽)
//   +Y : 위쪽
//   +X : 오른쪽

func makePictureFrameScene() -> SCNScene {
    let scene = SCNScene()
    let root = scene.rootNode

    let wood = pbr { m in
        m.diffuse.contents = NSColor(red: 0.42, green: 0.26, blue: 0.14, alpha: 1.0)
        m.roughness.contents = 0.55
        m.metalness.contents = 0.0
    }
    let inner = pbr { m in
        m.diffuse.contents = NSColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1.0)
        m.roughness.contents = 0.65
        m.metalness.contents = 0.0
    }
    let canvas = pbr { m in
        // 따뜻한 베이지 — 그림 자리(원하면 텍스처로 교체 가능)
        m.diffuse.contents = NSColor(red: 0.86, green: 0.78, blue: 0.65, alpha: 1.0)
        m.roughness.contents = 0.70
        m.metalness.contents = 0.0
    }
    let back = pbr { m in
        m.diffuse.contents = NSColor(white: 0.15, alpha: 1.0)
        m.roughness.contents = 0.8
        m.metalness.contents = 0.0
    }

    let width: CGFloat = 0.32
    let height: CGFloat = 0.44
    let depth: CGFloat = 0.022
    let bezel: CGFloat = 0.028
    let innerBezel: CGFloat = 0.008
    let canvasZ: CGFloat = depth / 2 - 0.001

    // 외곽 프레임 4면 (위/아래/좌/우 박스)
    let top = SCNNode(geometry: SCNBox(width: width, height: bezel, length: depth, chamferRadius: 0.003))
    top.geometry?.firstMaterial = wood
    top.position = SCNVector3(0, (height - bezel) / 2, 0)
    root.addChildNode(top)

    let bottom = SCNNode(geometry: SCNBox(width: width, height: bezel, length: depth, chamferRadius: 0.003))
    bottom.geometry?.firstMaterial = wood
    bottom.position = SCNVector3(0, -(height - bezel) / 2, 0)
    root.addChildNode(bottom)

    let leftBar = SCNNode(geometry: SCNBox(width: bezel, height: height - 2 * bezel, length: depth, chamferRadius: 0.003))
    leftBar.geometry?.firstMaterial = wood
    leftBar.position = SCNVector3(-(width - bezel) / 2, 0, 0)
    root.addChildNode(leftBar)

    let rightBar = SCNNode(geometry: SCNBox(width: bezel, height: height - 2 * bezel, length: depth, chamferRadius: 0.003))
    rightBar.geometry?.firstMaterial = wood
    rightBar.position = SCNVector3((width - bezel) / 2, 0, 0)
    root.addChildNode(rightBar)

    // 내부 매트(어두운 띠)
    let matFrame = SCNNode(geometry: SCNBox(
        width: width - 2 * bezel + innerBezel * 2,
        height: height - 2 * bezel + innerBezel * 2,
        length: depth * 0.55,
        chamferRadius: 0.001
    ))
    matFrame.geometry?.firstMaterial = inner
    matFrame.position = SCNVector3(0, 0, depth * 0.20)
    root.addChildNode(matFrame)

    // 캔버스 — 평면
    let canvasNode = SCNNode(geometry: SCNPlane(
        width: width - 2 * bezel - innerBezel,
        height: height - 2 * bezel - innerBezel
    ))
    canvasNode.geometry?.firstMaterial = canvas
    canvasNode.position = SCNVector3(0, 0, canvasZ)
    root.addChildNode(canvasNode)

    // 뒷판 (벽에 닿는 면)
    let backNode = SCNNode(geometry: SCNPlane(width: width, height: height))
    backNode.geometry?.firstMaterial = back
    backNode.position = SCNVector3(0, 0, -depth / 2 + 0.0005)
    backNode.eulerAngles = SCNVector3(0, CGFloat.pi, 0)  // 면 노말이 -Z 방향
    root.addChildNode(backNode)

    return scene
}

// MARK: - Export

func export(_ scene: SCNScene, to url: URL) {
    if FileManager.default.fileExists(atPath: url.path) {
        try? FileManager.default.removeItem(at: url)
    }
    let ok = scene.write(to: url, options: nil, delegate: nil, progressHandler: nil)
    let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
    print("\(ok ? "✅" : "❌") \(url.lastPathComponent)  (\(size) bytes)")
}

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let modelsDir = projectRoot.appendingPathComponent("ReallySceneRealityKit/Models", isDirectory: true)
try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)

export(makeCoffeeCupScene(),  to: modelsDir.appendingPathComponent("CoffeeCup.usdz"))
export(makePictureFrameScene(), to: modelsDir.appendingPathComponent("PictureFrame.usdz"))

print("📁 \(modelsDir.path)")
