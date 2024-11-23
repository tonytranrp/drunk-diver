//
//  SetupUtils.swift
//  driver simu
//
//  Created by Tony on 21/11/2024.
//
import SceneKit
import AppKit

class SetupUtils {
    static func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 15)
        scene.rootNode.addChildNode(cameraNode)
        
        // Lighting
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // Ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        return scene
    }
    
    static func createGround() -> SCNNode {
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0.2
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = NSColor.gray
        groundGeometry.materials = [groundMaterial]
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.position = SCNVector3(x: 0, y: -2, z: 0)
        return groundNode
    }
    
    static func createShip() -> SCNNode {
        if let shipScene = SCNScene(named: "art.scnassets/ship.scn"),
           let shipNode = shipScene.rootNode.childNode(withName: "ship", recursively: true) {
            shipNode.position = SCNVector3Zero
            return shipNode
        } else {
            // Fallback cube
            let shipGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
            let shipMaterial = SCNMaterial()
            shipMaterial.diffuse.contents = NSColor.blue
            shipGeometry.materials = [shipMaterial]
            let shipNode = SCNNode(geometry: shipGeometry)
            shipNode.position = SCNVector3Zero
            return shipNode
        }
    }
    
    static func configureSceneView(_ scnView: SCNView, scene: SCNScene) {
        scnView.scene = scene
        scnView.allowsCameraControl = false
        scnView.showsStatistics = true
        scnView.backgroundColor = NSColor.black
    }
}
