//
//  UIImage+ProgrammaticAssets.swift
//  I Bike CPH
//
//  Created by Troels Michael Trebbien on 23/05/16.
//  Copyright © 2016 I Bike CPH. All rights reserved.
//

import Foundation

func poGreenRouteImage(width width: CGFloat, color: UIColor) -> UIImage? {
    if (width <= 0) {
        return nil
    }

    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPoint(x: 0.64, y: 0.34))
    bezierPath.addCurveToPoint(CGPoint(x: 0.11, y: 0.88), controlPoint1: CGPoint(x: 0.19, y: 0.29), controlPoint2: CGPoint(x: 0.11, y: 0.88))
    bezierPath.addLineToPoint(CGPoint(x: 0.17, y: 0.89))
    bezierPath.addCurveToPoint(CGPoint(x: 0.53, y: 0.48), controlPoint1: CGPoint(x: 0.17, y: 0.67), controlPoint2: CGPoint(x: 0.23, y: 0.55))
    bezierPath.addCurveToPoint(CGPoint(x: 0.25, y: 0.72), controlPoint1: CGPoint(x: 0.53, y: 0.48), controlPoint2: CGPoint(x: 0.26, y: 0.58))
    bezierPath.addCurveToPoint(CGPoint(x: 1, y: 0.31), controlPoint1: CGPoint(x: 0.78, y: 0.86), controlPoint2: CGPoint(x: 1, y: 0.31))
    bezierPath.addCurveToPoint(CGPoint(x: 0.64, y: 0.34), controlPoint1: CGPoint(x: 0.93, y: 0.35), controlPoint2: CGPoint(x: 0.86, y: 0.36))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.04, y: 0))
    bezierPath.addCurveToPoint(CGPoint(x: 0.02, y: 0.22), controlPoint1: CGPoint(x: 0.06, y: 0.05), controlPoint2: CGPoint(x: 0.06, y: 0.09))
    bezierPath.addCurveToPoint(CGPoint(x: 0.17, y: 0.55), controlPoint1: CGPoint(x: -0.06, y: 0.48), controlPoint2: CGPoint(x: 0.17, y: 0.55))
    bezierPath.addCurveToPoint(CGPoint(x: 0.04, y: 0), controlPoint1: CGPoint(x: 0.35, y: 0.24), controlPoint2: CGPoint(x: 0.04, y: 0))
    bezierPath.closePath()
    bezierPath.miterLimit = 4
    bezierPath.lineWidth = 0.0
    
    bezierPath.scale(width: width)
    
    return bezierPath.renderFilledImage(color)
}

func poCargoRouteImage(width width: CGFloat, color: UIColor) -> UIImage? {
    if (width <= 0) {
        return nil
    }

    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPoint(x: 0.17, y: 0.55))
    bezierPath.addCurveToPoint(CGPoint(x: 0.06, y: 0.43), controlPoint1: CGPoint(x: 0.11, y: 0.55), controlPoint2: CGPoint(x: 0.06, y: 0.5))
    bezierPath.addCurveToPoint(CGPoint(x: 0.17, y: 0.32), controlPoint1: CGPoint(x: 0.06, y: 0.37), controlPoint2: CGPoint(x: 0.11, y: 0.32))
    bezierPath.addCurveToPoint(CGPoint(x: 0.21, y: 0.33), controlPoint1: CGPoint(x: 0.18, y: 0.32), controlPoint2: CGPoint(x: 0.2, y: 0.32))
    bezierPath.addLineToPoint(CGPoint(x: 0.15, y: 0.42))
    bezierPath.addCurveToPoint(CGPoint(x: 0.15, y: 0.46), controlPoint1: CGPoint(x: 0.14, y: 0.43), controlPoint2: CGPoint(x: 0.14, y: 0.45))
    bezierPath.addCurveToPoint(CGPoint(x: 0.17, y: 0.46), controlPoint1: CGPoint(x: 0.16, y: 0.46), controlPoint2: CGPoint(x: 0.16, y: 0.46))
    bezierPath.addCurveToPoint(CGPoint(x: 0.17, y: 0.46), controlPoint1: CGPoint(x: 0.17, y: 0.46), controlPoint2: CGPoint(x: 0.17, y: 0.46))
    bezierPath.addLineToPoint(CGPoint(x: 0.28, y: 0.46))
    bezierPath.addCurveToPoint(CGPoint(x: 0.17, y: 0.55), controlPoint1: CGPoint(x: 0.27, y: 0.51), controlPoint2: CGPoint(x: 0.22, y: 0.55))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.22, y: 0.4))
    bezierPath.addLineToPoint(CGPoint(x: 0.25, y: 0.36))
    bezierPath.addCurveToPoint(CGPoint(x: 0.28, y: 0.4), controlPoint1: CGPoint(x: 0.27, y: 0.37), controlPoint2: CGPoint(x: 0.27, y: 0.39))
    bezierPath.addLineToPoint(CGPoint(x: 0.22, y: 0.4))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.32, y: 0.26))
    bezierPath.addLineToPoint(CGPoint(x: 0.39, y: 0.41))
    bezierPath.addLineToPoint(CGPoint(x: 0.34, y: 0.4))
    bezierPath.addCurveToPoint(CGPoint(x: 0.29, y: 0.31), controlPoint1: CGPoint(x: 0.33, y: 0.37), controlPoint2: CGPoint(x: 0.31, y: 0.34))
    bezierPath.addLineToPoint(CGPoint(x: 0.32, y: 0.26))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.76, y: 0.55))
    bezierPath.addCurveToPoint(CGPoint(x: 0.64, y: 0.43), controlPoint1: CGPoint(x: 0.7, y: 0.55), controlPoint2: CGPoint(x: 0.64, y: 0.5))
    bezierPath.addCurveToPoint(CGPoint(x: 0.76, y: 0.32), controlPoint1: CGPoint(x: 0.64, y: 0.37), controlPoint2: CGPoint(x: 0.7, y: 0.32))
    bezierPath.addCurveToPoint(CGPoint(x: 0.87, y: 0.43), controlPoint1: CGPoint(x: 0.82, y: 0.32), controlPoint2: CGPoint(x: 0.87, y: 0.37))
    bezierPath.addCurveToPoint(CGPoint(x: 0.76, y: 0.55), controlPoint1: CGPoint(x: 0.87, y: 0.5), controlPoint2: CGPoint(x: 0.82, y: 0.55))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 1, y: 0.21))
    bezierPath.addLineToPoint(CGPoint(x: 0.57, y: 0.14))
    bezierPath.addLineToPoint(CGPoint(x: 0.57, y: 0.06))
    bezierPath.addLineToPoint(CGPoint(x: 0.52, y: 0.01))
    bezierPath.addCurveToPoint(CGPoint(x: 0.48, y: 0.01), controlPoint1: CGPoint(x: 0.51, y: -0), controlPoint2: CGPoint(x: 0.49, y: -0))
    bezierPath.addCurveToPoint(CGPoint(x: 0.48, y: 0.05), controlPoint1: CGPoint(x: 0.47, y: 0.02), controlPoint2: CGPoint(x: 0.47, y: 0.04))
    bezierPath.addLineToPoint(CGPoint(x: 0.51, y: 0.08))
    bezierPath.addLineToPoint(CGPoint(x: 0.51, y: 0.41))
    bezierPath.addLineToPoint(CGPoint(x: 0.45, y: 0.41))
    bezierPath.addLineToPoint(CGPoint(x: 0.31, y: 0.11))
    bezierPath.addLineToPoint(CGPoint(x: 0.35, y: 0.11))
    bezierPath.addCurveToPoint(CGPoint(x: 0.38, y: 0.08), controlPoint1: CGPoint(x: 0.36, y: 0.11), controlPoint2: CGPoint(x: 0.38, y: 0.1))
    bezierPath.addCurveToPoint(CGPoint(x: 0.35, y: 0.06), controlPoint1: CGPoint(x: 0.38, y: 0.07), controlPoint2: CGPoint(x: 0.36, y: 0.06))
    bezierPath.addLineToPoint(CGPoint(x: 0.2, y: 0.06))
    bezierPath.addCurveToPoint(CGPoint(x: 0.18, y: 0.08), controlPoint1: CGPoint(x: 0.19, y: 0.06), controlPoint2: CGPoint(x: 0.18, y: 0.07))
    bezierPath.addCurveToPoint(CGPoint(x: 0.2, y: 0.11), controlPoint1: CGPoint(x: 0.18, y: 0.1), controlPoint2: CGPoint(x: 0.19, y: 0.11))
    bezierPath.addLineToPoint(CGPoint(x: 0.25, y: 0.11))
    bezierPath.addLineToPoint(CGPoint(x: 0.29, y: 0.2))
    bezierPath.addLineToPoint(CGPoint(x: 0.24, y: 0.28))
    bezierPath.addCurveToPoint(CGPoint(x: 0.17, y: 0.26), controlPoint1: CGPoint(x: 0.22, y: 0.27), controlPoint2: CGPoint(x: 0.19, y: 0.26))
    bezierPath.addCurveToPoint(CGPoint(x: 0, y: 0.43), controlPoint1: CGPoint(x: 0.08, y: 0.26), controlPoint2: CGPoint(x: 0, y: 0.34))
    bezierPath.addCurveToPoint(CGPoint(x: 0.17, y: 0.6), controlPoint1: CGPoint(x: 0, y: 0.53), controlPoint2: CGPoint(x: 0.08, y: 0.6))
    bezierPath.addCurveToPoint(CGPoint(x: 0.34, y: 0.46), controlPoint1: CGPoint(x: 0.25, y: 0.6), controlPoint2: CGPoint(x: 0.32, y: 0.54))
    bezierPath.addLineToPoint(CGPoint(x: 0.59, y: 0.46))
    bezierPath.addCurveToPoint(CGPoint(x: 0.76, y: 0.6), controlPoint1: CGPoint(x: 0.6, y: 0.54), controlPoint2: CGPoint(x: 0.67, y: 0.6))
    bezierPath.addCurveToPoint(CGPoint(x: 0.92, y: 0.46), controlPoint1: CGPoint(x: 0.84, y: 0.6), controlPoint2: CGPoint(x: 0.91, y: 0.54))
    bezierPath.addLineToPoint(CGPoint(x: 1, y: 0.46))
    bezierPath.addLineToPoint(CGPoint(x: 1, y: 0.21))
    bezierPath.closePath()
    bezierPath.miterLimit = 4
    bezierPath.lineWidth = 0.0
    
    bezierPath.scale(width: width)
    
    return bezierPath.renderFilledImage(color)
}

func poFastRouteImage(width width: CGFloat, color: UIColor) -> UIImage? {
    if (width <= 0) {
        return nil
    }

    let bezierPath = UIBezierPath()
    bezierPath.moveToPoint(CGPoint(x: 0.22, y: 0.62))
    bezierPath.addCurveToPoint(CGPoint(x: 0.18, y: 0.65), controlPoint1: CGPoint(x: 0.2, y: 0.62), controlPoint2: CGPoint(x: 0.18, y: 0.63))
    bezierPath.addCurveToPoint(CGPoint(x: 0.22, y: 0.69), controlPoint1: CGPoint(x: 0.18, y: 0.67), controlPoint2: CGPoint(x: 0.2, y: 0.69))
    bezierPath.addLineToPoint(CGPoint(x: 0.42, y: 0.69))
    bezierPath.addCurveToPoint(CGPoint(x: 0.37, y: 0.62), controlPoint1: CGPoint(x: 0.4, y: 0.67), controlPoint2: CGPoint(x: 0.38, y: 0.64))
    bezierPath.addLineToPoint(CGPoint(x: 0.22, y: 0.62))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.04, y: 0.18))
    bezierPath.addCurveToPoint(CGPoint(x: 0, y: 0.22), controlPoint1: CGPoint(x: 0.02, y: 0.18), controlPoint2: CGPoint(x: 0, y: 0.2))
    bezierPath.addCurveToPoint(CGPoint(x: 0.04, y: 0.25), controlPoint1: CGPoint(x: 0, y: 0.24), controlPoint2: CGPoint(x: 0.02, y: 0.25))
    bezierPath.addLineToPoint(CGPoint(x: 0.36, y: 0.25))
    bezierPath.addCurveToPoint(CGPoint(x: 0.41, y: 0.18), controlPoint1: CGPoint(x: 0.38, y: 0.23), controlPoint2: CGPoint(x: 0.39, y: 0.2))
    bezierPath.addLineToPoint(CGPoint(x: 0.04, y: 0.18))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.33, y: 0.33))
    bezierPath.addLineToPoint(CGPoint(x: 0.1, y: 0.33))
    bezierPath.addCurveToPoint(CGPoint(x: 0.06, y: 0.36), controlPoint1: CGPoint(x: 0.08, y: 0.33), controlPoint2: CGPoint(x: 0.06, y: 0.34))
    bezierPath.addCurveToPoint(CGPoint(x: 0.1, y: 0.4), controlPoint1: CGPoint(x: 0.06, y: 0.38), controlPoint2: CGPoint(x: 0.08, y: 0.4))
    bezierPath.addLineToPoint(CGPoint(x: 0.32, y: 0.4))
    bezierPath.addCurveToPoint(CGPoint(x: 0.33, y: 0.33), controlPoint1: CGPoint(x: 0.32, y: 0.37), controlPoint2: CGPoint(x: 0.33, y: 0.35))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.16, y: 0.47))
    bezierPath.addCurveToPoint(CGPoint(x: 0.12, y: 0.51), controlPoint1: CGPoint(x: 0.14, y: 0.47), controlPoint2: CGPoint(x: 0.12, y: 0.49))
    bezierPath.addCurveToPoint(CGPoint(x: 0.16, y: 0.54), controlPoint1: CGPoint(x: 0.12, y: 0.53), controlPoint2: CGPoint(x: 0.14, y: 0.54))
    bezierPath.addLineToPoint(CGPoint(x: 0.34, y: 0.54))
    bezierPath.addCurveToPoint(CGPoint(x: 0.32, y: 0.47), controlPoint1: CGPoint(x: 0.33, y: 0.52), controlPoint2: CGPoint(x: 0.32, y: 0.5))
    bezierPath.addLineToPoint(CGPoint(x: 0.16, y: 0.47))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.74, y: 0.46))
    bezierPath.addLineToPoint(CGPoint(x: 0.74, y: 0.46))
    bezierPath.addCurveToPoint(CGPoint(x: 0.69, y: 0.49), controlPoint1: CGPoint(x: 0.73, y: 0.48), controlPoint2: CGPoint(x: 0.71, y: 0.49))
    bezierPath.addCurveToPoint(CGPoint(x: 0.64, y: 0.47), controlPoint1: CGPoint(x: 0.67, y: 0.49), controlPoint2: CGPoint(x: 0.66, y: 0.48))
    bezierPath.addLineToPoint(CGPoint(x: 0.64, y: 0.47))
    bezierPath.addCurveToPoint(CGPoint(x: 0.63, y: 0.43), controlPoint1: CGPoint(x: 0.63, y: 0.46), controlPoint2: CGPoint(x: 0.63, y: 0.45))
    bezierPath.addCurveToPoint(CGPoint(x: 0.66, y: 0.38), controlPoint1: CGPoint(x: 0.63, y: 0.41), controlPoint2: CGPoint(x: 0.64, y: 0.39))
    bezierPath.addLineToPoint(CGPoint(x: 0.66, y: 0.38))
    bezierPath.addLineToPoint(CGPoint(x: 0.86, y: 0.26))
    bezierPath.addLineToPoint(CGPoint(x: 0.74, y: 0.46))
    bezierPath.closePath()
    bezierPath.moveToPoint(CGPoint(x: 0.95, y: 0.26))
    bezierPath.addLineToPoint(CGPoint(x: 0.98, y: 0.23))
    bezierPath.addCurveToPoint(CGPoint(x: 0.98, y: 0.2), controlPoint1: CGPoint(x: 0.99, y: 0.22), controlPoint2: CGPoint(x: 0.99, y: 0.21))
    bezierPath.addLineToPoint(CGPoint(x: 0.92, y: 0.14))
    bezierPath.addCurveToPoint(CGPoint(x: 0.88, y: 0.14), controlPoint1: CGPoint(x: 0.91, y: 0.13), controlPoint2: CGPoint(x: 0.89, y: 0.13))
    bezierPath.addLineToPoint(CGPoint(x: 0.86, y: 0.16))
    bezierPath.addCurveToPoint(CGPoint(x: 0.73, y: 0.12), controlPoint1: CGPoint(x: 0.82, y: 0.14), controlPoint2: CGPoint(x: 0.78, y: 0.12))
    bezierPath.addLineToPoint(CGPoint(x: 0.73, y: 0.09))
    bezierPath.addLineToPoint(CGPoint(x: 0.78, y: 0.09))
    bezierPath.addLineToPoint(CGPoint(x: 0.78, y: 0))
    bezierPath.addLineToPoint(CGPoint(x: 0.6, y: 0))
    bezierPath.addLineToPoint(CGPoint(x: 0.6, y: 0.09))
    bezierPath.addLineToPoint(CGPoint(x: 0.64, y: 0.09))
    bezierPath.addLineToPoint(CGPoint(x: 0.64, y: 0.12))
    bezierPath.addCurveToPoint(CGPoint(x: 0.37, y: 0.43), controlPoint1: CGPoint(x: 0.49, y: 0.14), controlPoint2: CGPoint(x: 0.37, y: 0.27))
    bezierPath.addCurveToPoint(CGPoint(x: 0.69, y: 0.74), controlPoint1: CGPoint(x: 0.37, y: 0.6), controlPoint2: CGPoint(x: 0.51, y: 0.74))
    bezierPath.addCurveToPoint(CGPoint(x: 1, y: 0.43), controlPoint1: CGPoint(x: 0.86, y: 0.74), controlPoint2: CGPoint(x: 1, y: 0.6))
    bezierPath.addCurveToPoint(CGPoint(x: 0.95, y: 0.26), controlPoint1: CGPoint(x: 1, y: 0.37), controlPoint2: CGPoint(x: 0.98, y: 0.31))
    bezierPath.closePath()
    bezierPath.miterLimit = 4
    bezierPath.lineWidth = 0.0
    
    bezierPath.scale(width: width)
    
    return bezierPath.renderFilledImage(color)
}

private extension UIBezierPath {
    var drawnSize: CGSize {
        return CGSizeMake(self.bounds.size.width + self.lineWidth, self.bounds.size.height + self.lineWidth);
    }
    
    func drawInCurrentContext(fillColor: UIColor) {

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        CGContextSaveGState(context)

        fillColor.setFill()
        CGContextSetBlendMode(context, .Normal)
        self.fill()
        
        CGContextRestoreGState(context)
    }
    
    func scale(height height: CGFloat) {
        let scaleFactor: CGFloat = height / self.bounds.size.height
        self.applyTransform(CGAffineTransformMakeScale(scaleFactor, scaleFactor))
    }
    
    func scale(width width: CGFloat) {
        let scaleFactor: CGFloat = width / self.bounds.size.width
        self.applyTransform(CGAffineTransformMakeScale(scaleFactor, scaleFactor))
    }
    
    func renderFilledImage(fillColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.drawnSize, false, 0.0);
        self.drawInCurrentContext(fillColor)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}