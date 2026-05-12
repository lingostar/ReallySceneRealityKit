import UIKit
import RealityKit

/// 격자 텍스처를 한 번만 그려서 RealityKit `TextureResource` 로 캐싱한다.
enum GridTexture {
    /// 한 변 256px, 8칸으로 나뉜 격자. 알파 0인 배경 + 흐릿한 회색 라인.
    static let resource: TextureResource = {
        let size = 256
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: size, height: size),
            format: {
                let f = UIGraphicsImageRendererFormat.default()
                f.opaque = false
                f.scale = 1
                return f
            }()
        )

        let image = renderer.image { ctx in
            let context = ctx.cgContext
            context.clear(CGRect(x: 0, y: 0, width: size, height: size))

            context.setStrokeColor(UIColor(white: 0.92, alpha: 0.95).cgColor)
            context.setLineWidth(2)

            let cells = 8
            let step = CGFloat(size) / CGFloat(cells)
            for i in 0...cells {
                let p = CGFloat(i) * step
                context.move(to: CGPoint(x: p, y: 0))
                context.addLine(to: CGPoint(x: p, y: CGFloat(size)))
                context.move(to: CGPoint(x: 0, y: p))
                context.addLine(to: CGPoint(x: CGFloat(size), y: p))
            }
            context.strokePath()
        }

        guard let cgImage = image.cgImage else {
            fatalError("GridTexture 이미지를 만들 수 없습니다.")
        }
        return try! TextureResource(
            image: cgImage,
            options: .init(semantic: .color)
        )
    }()
}
