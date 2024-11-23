//
//  MathUtils.swift
//  driver simu
//
//  Created by Tony on 21/11/2024.
//
import SceneKit

struct MathUtils {
    // Vector operations
    static func createVector3(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> SCNVector3 {
        return SCNVector3(x, y, z)
    }
    
    // Constants
    static let acceleration: CGFloat = 0.5
    static let drag: CGFloat = 0.98
    
    // Movement calculations
    static func calculateNewPosition(current: SCNVector3, delta: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            current.x + delta.x,
            current.y + delta.y,
            current.z + delta.z
        )
    }
    
    static func applyDrag(to position: SCNVector3, factor: CGFloat) -> SCNVector3 {
        return SCNVector3(
            position.x * factor,
            position.y,
            position.z * factor
        )
    }
}
