//
//  ViewController.swift
//  AR_Ruller
//
//  Created by Maxim Mitin on 20.11.21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    
    var markerNodes = [SCNNode]()
    var textNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.autoenablesDefaultLighting = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchLocation = touches.first?.location(in: sceneView) else { return }
        guard let hitTestResult = sceneView.hitTest(touchLocation, types: .featurePoint).first else {return}
        print("Hit (\(hitTestResult)")
        addMarker(at: hitTestResult)
    }
    
    func addMarker(at hitResult: ARHitTestResult) {
        let cylinder = SCNCylinder(radius: 0.005, height: 0.02)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        cylinder.materials = [material]
        
        //Positioning cylinder
        
        let markerNode = SCNNode(geometry: cylinder)
        let location = hitResult.worldTransform.columns.3
        markerNode.position = SCNVector3(location.x, location.y, location.z)
        sceneView.scene.rootNode.addChildNode(markerNode)
        markerNodes.append(markerNode)
        
        //Node counter
        if markerNodes.count > 2 {
            markerNodes.first?.removeFromParentNode()
            markerNodes.remove(at: 0)
            calculateDistance()
        } else if markerNodes.count == 2{
            calculateDistance()
        }
    }
    
    func calculateDistance() {
        let start = markerNodes[0]
        let end = markerNodes[1]
        
        let startPosition = SCNVector3ToGLKVector3(start.worldPosition)
        let endPosition = SCNVector3ToGLKVector3(end.worldPosition)
        
        let distance = GLKVector3Distance(startPosition, endPosition)
        let sum = GLKVector3Add(startPosition, endPosition)
        let midPoint = SCNVector3(sum.x / 2 , sum.y / 2, sum.z / 2)
        addText(text: meterToCentimeters(meters: distance), location: midPoint)
    }
    
    func addText(text: String, location: SCNVector3) {
        let text = SCNText(string: text, extrusionDepth: 0.1)
        text.font = UIFont(name: "futura", size: 14)
        text.flatness = 0.0
        let scaleFactor = 0.05 / text.font.pointSize
        
        let constraints = SCNBillboardConstraint()
        textNode.constraints = [constraints]
        
        textNode.geometry = text
        textNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
        let (min, max) = textNode.boundingBox
        let offset = (max.x - min.x) / 2 * Float(scaleFactor)
        let textPosition = SCNVector3(location.x - offset, location.y + 0.05, location.z)
        textNode.position = textPosition
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    func meterToCentimeters(meters: Float) -> String {
        let m = Measurement(value: Double(meters), unit: UnitLength.meters)
        var length : Measurement<UnitLength>
        
        if segmentControl.selectedSegmentIndex == 0 {
            length = m.converted(to: .centimeters)
        } else {
            length = m.converted(to: .inches)
        }
        let result = String(format: "%.2f", length.value)
        
        return result
    }
    
    @IBAction func unitsChange(_ sender: Any) {
        calculateDistance()
    }
    
}
