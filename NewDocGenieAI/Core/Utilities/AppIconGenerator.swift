import UIKit

enum AppIconGenerator {
    /// Renders a polished 1024x1024 app icon.
    /// Design: dark gradient background -> glowing document -> AI sparkles with depth.
    static func generateIcon(size: CGFloat = 1024) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let ctx = context.cgContext

            // -- 1. Rich dark gradient background --
            let bgColors = [
                UIColor(red: 0.051, green: 0.075, blue: 0.129, alpha: 1.0).cgColor, // #0D1321
                UIColor(red: 0.106, green: 0.157, blue: 0.271, alpha: 1.0).cgColor  // #1B2845
            ]
            let bgGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: bgColors as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.drawLinearGradient(
                bgGradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size, y: size),
                options: []
            )

            // -- 2. Warm ambient glow (indigo + hint of purple) --
            let ambientColors = [
                UIColor(red: 0.388, green: 0.400, blue: 0.945, alpha: 0.30).cgColor,
                UIColor(red: 0.388, green: 0.400, blue: 0.945, alpha: 0.0).cgColor
            ]
            let ambientGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: ambientColors as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.drawRadialGradient(
                ambientGradient,
                startCenter: CGPoint(x: size * 0.45, y: size * 0.50),
                startRadius: 0,
                endCenter: CGPoint(x: size * 0.45, y: size * 0.50),
                endRadius: size * 0.55,
                options: []
            )

            // Secondary warm glow (purple accent, upper right)
            let warmColors = [
                UIColor(red: 0.655, green: 0.545, blue: 0.980, alpha: 0.12).cgColor,
                UIColor(red: 0.655, green: 0.545, blue: 0.980, alpha: 0.0).cgColor
            ]
            let warmGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: warmColors as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.drawRadialGradient(
                warmGradient,
                startCenter: CGPoint(x: size * 0.70, y: size * 0.30),
                startRadius: 0,
                endCenter: CGPoint(x: size * 0.70, y: size * 0.30),
                endRadius: size * 0.35,
                options: []
            )

            // -- 3. Document shadow (depth) --
            let docWidth = size * 0.44
            let docHeight = size * 0.54
            let docX = size * 0.22
            let docY = size * 0.26
            let docRect = CGRect(x: docX, y: docY, width: docWidth, height: docHeight)

            ctx.saveGState()
            ctx.setShadow(
                offset: CGSize(width: size * 0.01, height: size * 0.02),
                blur: size * 0.05,
                color: UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor
            )
            let shadowPath = UIBezierPath(roundedRect: docRect, cornerRadius: size * 0.025)
            ctx.setFillColor(UIColor(white: 0, alpha: 0.01).cgColor)
            ctx.addPath(shadowPath.cgPath)
            ctx.fillPath()
            ctx.restoreGState()

            // -- 4. Document body with gradient fill --
            let docPath = UIBezierPath(roundedRect: docRect, cornerRadius: size * 0.025)

            // Gradient fill: subtle white-to-indigo tint
            ctx.saveGState()
            ctx.addPath(docPath.cgPath)
            ctx.clip()
            let docFillColors = [
                UIColor(white: 1.0, alpha: 0.25).cgColor,
                UIColor(red: 0.388, green: 0.400, blue: 0.945, alpha: 0.08).cgColor
            ]
            let docFillGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: docFillColors as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.drawLinearGradient(
                docFillGradient,
                start: CGPoint(x: docX, y: docY),
                end: CGPoint(x: docX + docWidth, y: docY + docHeight),
                options: []
            )
            ctx.restoreGState()

            // Document border (stronger indigo)
            ctx.setStrokeColor(UIColor(red: 0.388, green: 0.400, blue: 0.945, alpha: 0.75).cgColor)
            ctx.setLineWidth(size * 0.006)
            ctx.addPath(docPath.cgPath)
            ctx.strokePath()

            // -- 5. Document fold corner (top-right) --
            let foldSize = size * 0.06
            let foldX = docX + docWidth - foldSize
            let foldY = docY
            let foldPath = UIBezierPath()
            foldPath.move(to: CGPoint(x: foldX, y: foldY))
            foldPath.addLine(to: CGPoint(x: foldX + foldSize, y: foldY + foldSize))
            foldPath.addLine(to: CGPoint(x: foldX, y: foldY + foldSize))
            foldPath.close()
            ctx.setFillColor(UIColor(red: 0.051, green: 0.075, blue: 0.129, alpha: 0.6).cgColor)
            ctx.addPath(foldPath.cgPath)
            ctx.fillPath()

            // Fold border
            ctx.setStrokeColor(UIColor(red: 0.388, green: 0.400, blue: 0.945, alpha: 0.4).cgColor)
            ctx.setLineWidth(size * 0.003)
            let foldLine = UIBezierPath()
            foldLine.move(to: CGPoint(x: foldX, y: foldY))
            foldLine.addLine(to: CGPoint(x: foldX, y: foldY + foldSize))
            foldLine.addLine(to: CGPoint(x: foldX + foldSize, y: foldY + foldSize))
            ctx.addPath(foldLine.cgPath)
            ctx.strokePath()

            // -- 6. Document text lines (higher contrast) --
            let lineStartX = docX + size * 0.04
            let lineWidths: [CGFloat] = [0.70, 0.58, 0.65, 0.40]
            let lineHeight = size * 0.018

            for i in 0..<4 {
                let lineY = docY + size * 0.10 + CGFloat(i) * size * 0.052
                let w = docWidth * lineWidths[i]
                let lineRect = CGRect(x: lineStartX, y: lineY, width: w, height: lineHeight)
                let linePath = UIBezierPath(roundedRect: lineRect, cornerRadius: lineHeight / 2)
                ctx.setFillColor(UIColor(white: 1.0, alpha: 0.35).cgColor)
                ctx.addPath(linePath.cgPath)
                ctx.fillPath()
            }

            // -- 7. AI sparkles with glow halos --
            // Primary sparkle (large, bright cyan) -- top-right of document
            drawSparkleWithGlow(
                ctx: ctx, size: size,
                center: CGPoint(x: size * 0.72, y: size * 0.24),
                armLength: size * 0.085,
                color: UIColor(red: 0.024, green: 0.839, blue: 0.831, alpha: 1.0),
                glowRadius: size * 0.06,
                glowAlpha: 0.25
            )

            // Secondary sparkle (medium, lighter indigo)
            drawSparkleWithGlow(
                ctx: ctx, size: size,
                center: CGPoint(x: size * 0.80, y: size * 0.46),
                armLength: size * 0.055,
                color: UIColor(red: 0.506, green: 0.549, blue: 0.973, alpha: 0.95),
                glowRadius: size * 0.04,
                glowAlpha: 0.20
            )

            // Tertiary sparkle (small, warm purple accent)
            drawSparkleWithGlow(
                ctx: ctx, size: size,
                center: CGPoint(x: size * 0.60, y: size * 0.16),
                armLength: size * 0.038,
                color: UIColor(red: 0.655, green: 0.545, blue: 0.980, alpha: 0.90),
                glowRadius: size * 0.03,
                glowAlpha: 0.18
            )

            // Tiny accent sparkle (cyan dot)
            drawSparkleWithGlow(
                ctx: ctx, size: size,
                center: CGPoint(x: size * 0.86, y: size * 0.32),
                armLength: size * 0.022,
                color: UIColor(red: 0.024, green: 0.714, blue: 0.831, alpha: 0.7),
                glowRadius: size * 0.015,
                glowAlpha: 0.12
            )
        }
    }

    // MARK: - Sparkle with Glow Halo

    private static func drawSparkleWithGlow(
        ctx: CGContext, size: CGFloat,
        center: CGPoint, armLength: CGFloat,
        color: UIColor,
        glowRadius: CGFloat, glowAlpha: CGFloat
    ) {
        // Glow halo behind the sparkle
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        let glowColors = [
            UIColor(red: r, green: g, blue: b, alpha: glowAlpha).cgColor,
            UIColor(red: r, green: g, blue: b, alpha: 0.0).cgColor
        ]
        let glowGradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: glowColors as CFArray,
            locations: [0.0, 1.0]
        )!
        ctx.drawRadialGradient(
            glowGradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: glowRadius + armLength,
            options: []
        )

        // Sparkle shape (4-pointed star with smooth curves)
        drawSparkle(ctx: ctx, center: center, armLength: armLength, color: color)
    }

    private static func drawSparkle(ctx: CGContext, center: CGPoint, armLength: CGFloat, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        let crossWidth = armLength * 0.22
        let path = UIBezierPath()

        // Vertical arm
        path.move(to: CGPoint(x: center.x, y: center.y - armLength))
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + armLength),
            controlPoint: CGPoint(x: center.x + crossWidth, y: center.y)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - armLength),
            controlPoint: CGPoint(x: center.x - crossWidth, y: center.y)
        )
        path.close()

        // Horizontal arm
        path.move(to: CGPoint(x: center.x - armLength, y: center.y))
        path.addQuadCurve(
            to: CGPoint(x: center.x + armLength, y: center.y),
            controlPoint: CGPoint(x: center.x, y: center.y + crossWidth)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - armLength, y: center.y),
            controlPoint: CGPoint(x: center.x, y: center.y - crossWidth)
        )
        path.close()

        ctx.addPath(path.cgPath)
        ctx.fillPath()
    }
}
