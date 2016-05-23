//
//  UIImage+ProgrammaticAssets.swift
//  I Bike CPH
//
//  Created by Troels Michael Trebbien on 23/05/16.
//  Copyright © 2016 I Bike CPH. All rights reserved.
//

import Foundation

func poGreenRouteImage(height height: CGFloat, color: UIColor) -> UIImage? {
    if (height <= 0) {
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
    
    bezierPath.scale(height: height)
    
    UIGraphicsBeginImageContextWithOptions(bezierPath.drawnSize, false, 0.0);
    bezierPath.drawInCurrentContext(color)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
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
}