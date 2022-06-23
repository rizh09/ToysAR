//
//  ViewController.swift
//  ToysAR
//
//  Created by NHT Global on 5/6/2019.
//  Copyright © 2019 toysAR. All rights reserved.
//

import UIKit
import ARKit
import SceneKit.ModelIO

extension float4x4 {
    
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
    
}

class ViewController: UIViewController, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var nodeList = [SCNNode]()
    var currentNode = SCNNode()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureToSceneView()
        addScaleGestureToSceneView()
        addPanGesutreToSceneView()
        addLongPressGestureToSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let config = ARWorldTrackingConfiguration()
        config.isLightEstimationEnabled = true
        config.environmentTexturing = .automatic
        sceneView.session.run(config)
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        
    }
    
    
    
    func addBox(x: Float = 0, y: Float = 0, z: Float = -0.2) {
        
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(x, y, z)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
        
    }
    
    func addTapGestureToSceneView() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        
        guard let node = hitTestResults.first?.node else
        {
            
            let hitTestResultsWithFeaturePoints = sceneView.hitTest(tapLocation, types: .featurePoint)
            
            if let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
                
                let translation = hitTestResultWithFeaturePoints.worldTransform.translation
                //                addBox(x: translation.x, y: translation.y, z: translation.z)
                addDrummer(x: translation.x, y: translation.y, z: translation.z)
                
            }
            return
        }
        node.removeFromParentNode()
        
    }
    
    
    func addScaleGestureToSceneView(){
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        
        
        
        let location = gesture.location(in: sceneView)
        guard let hitTestResult = sceneView.hitTest(location, options: nil).first else {return }
    
        
        //        sceneView.scene.rootNode.enumerateChildNodes{(node,stop) in
        //            for child in hitTestResult{
        //                print("found node : " + child.node.name!)
        //                print("found childNodes : " + child.node.childNodes)
        //                if node == childNode {
        //                    print("found : " + childNode.name!)
        //                    currentNode =  node
        //                }
        //            }
        //        }
        
        getCurrentNode()
        
        var originalScale = currentNode.scale
        
        switch gesture.state {
        case .began:
            originalScale = currentNode.scale
            gesture.scale = CGFloat((currentNode.scale.x))
        case .changed:
            var newScale = originalScale
            if gesture.scale < 0.01{
                newScale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            }else if gesture.scale > 0.05{
                newScale = SCNVector3(0.05, 0.05, 0.05)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            currentNode.scale = newScale
        case .ended:
            var newScale = originalScale
            if gesture.scale < 0.01{
                newScale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            }else if gesture.scale > 0.05{
                newScale = SCNVector3(0.05, 0.05, 0.05)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            currentNode.scale = newScale
        //            gesture.scale = CGFloat((currentNode.scale.x))
        default:
            gesture.scale = 1.0
            originalScale = currentNode.scale
        }
    }
    
    func addPanGesutreToSceneView(){
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)
    }
    
    var currentAngleY: Float = 0.0
    var currentAngleX: Float = 0.0
    
    
    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        
        
        getCurrentNode()
        
        //spin the object
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        var newAngleX = (Float)(translation.y)*(Float)(Double.pi)/180.0
        
        newAngleY += currentAngleY
        currentNode.eulerAngles.y = newAngleY
        
        newAngleX += currentAngleX
        currentNode.eulerAngles.x = newAngleX
        
        if gesture.state == .ended{
            currentAngleY = newAngleY
            currentAngleX = newAngleX
        }
        
    }
    
    func addLongPressGestureToSceneView(){
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didMove(_:)))
        gesture.delegate = self
        sceneView.addGestureRecognizer(gesture)
    }
    
    @objc func didMove(_ gesture: UILongPressGestureRecognizer) {
        
        getCurrentNode()
        
        //move the object
        let tapLocation = gesture.location(in: sceneView)
        
        guard let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint).first else {return}
        
        let worldTransform = hitTestResults.worldTransform
        
        let newPos = SCNVector3(worldTransform.columns.3.x, worldTransform.columns.3.y,worldTransform.columns.3.z)
        currentNode.simdPosition = float3(newPos.x,newPos.y,newPos.z)
        
    }
    func getDrummerModel() -> SCNScene{
        
        guard let url = Bundle.main.url(forResource: "toy_drummer", withExtension: "usdz")
            else { fatalError() }
        
        let mdlAsset = MDLAsset(url: url)
        mdlAsset.loadTextures()
        let scene = SCNScene(mdlAsset: mdlAsset)
        
        return scene
    }
    
    
    func addDrummer(x: Float = 0, y: Float = 0, z: Float = -0.2) {
        
        let drummerScene = getDrummerModel()
        let drummerSceneChildNode = drummerScene.rootNode.childNodes
        let newNode = SCNNode()
        
        for cn in drummerSceneChildNode{
            newNode.addChildNode(cn)
        }
        newNode.position = SCNVector3(x, y, z)
        newNode.scale = SCNVector3(0.01,0.01,0.01)
        newNode.name = "drummer"+String(nodeList.count)
        nodeList.append(newNode)
        sceneView.scene.lightingEnvironment.contents = drummerScene.lightingEnvironment.contents
        sceneView.scene.rootNode.addChildNode(newNode)
        
        
    }
    
    func getCurrentNode() {
        for i in nodeList{
            sceneView.scene.rootNode.enumerateChildNodes{(node,stop) in
                if node.name == i.name {
                    //                    print("found : " + i.name!)
                    currentNode =  node
                }
            }
        }
    }
    
    //    func getLight() -> SCNLight{
    //        let light = SCNLight()
    //        light.intensity = 1000
    //        light.type = .directional
    //
    //        return light
    //    }
    //
    //    func getMaterial() -> SCNMaterial{
    //        let material = SCNMaterial()
    //        material.lightingModel = .physicallyBased
    //        material.diffuse.contents = UIImage(named: "drummertoy_2x")
    //
    //        return material
    //    }
    
}

