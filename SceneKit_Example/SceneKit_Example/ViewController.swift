//
//  ViewController.swift
//  SceneKit_Example
//
//  Created by Христиченко Александр on 2023-05-07.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
//MARK: - PROPERTIES
    private var cubeArray = [SCNNode]()
    private var touchLocations: [AnyObject] = []
    private var isVisible: Bool = false
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    //MARK: - Lifecicle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true //only for development
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints] //only for development
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //check whether it is a suitable device
        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
        } else {
            let alert = UIAlertController(title: "Something went wrong...", message: "Sorry, but your device does not support ARWorldTrackingConfiguration.\nYour phone must have 9 chip at least.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //MARK: - UI
    private func setUpUI() {
        rightButton.isHidden = !isVisible ? true : false
        leftButton.isHidden = !isVisible ? true : false
        downButton.isHidden = !isVisible ? true : false
        upButton.isHidden = !isVisible ? true : false
        deleteButton.isHidden = !isVisible ? true : false
    }

    //MARK: - Add a cube
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            if let hitResults = results.first {
                if !cubeArray.isEmpty {
                    for node in cubeArray {
                        if node.position.x != hitResults.worldTransform.columns.3.x {
                            addCube(atLocation: hitResults)
                        }
                    }
                } else {
                    addCube(atLocation: hitResults)
                }
            }
        }
    }
    
    private func addCube(atLocation hitResults: ARHitTestResult) {
        let cube = SCNBox(width: 0.02, height: 0.02, length: 0.02, chamferRadius: 0.003)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        cube.materials = [material]
        let node = SCNNode()
        node.position = SCNVector3(x: hitResults.worldTransform.columns.3.x,
                                   y: hitResults.worldTransform.columns.3.y + node.boundingSphere.radius,
                                   z: hitResults.worldTransform.columns.3.z)
        node.geometry = cube
        cubeArray.append(node)
        sceneView.scene.rootNode.addChildNode(node)
        DispatchQueue.main.async {
            self.isVisible = true
            self.setUpUI()
        }
    }
    
    //MARK: - Rotate cubes
    @IBAction func rotateLeft(_ sender: UIButton) {
        roll(rotateX: Float.pi/2, button: sender)
    }
    
    @IBAction func rotateUp(_ sender: UIButton) {
        roll(rotateZ: Float.pi/2, button: sender)
    }
    
    @IBAction func rotateDown(_ sender: UIButton) {
        roll(rotateZ: Float.pi/2, button: sender)
    }
    
    @IBAction func rotateRight(_ sender: UIButton) {
        roll(rotateX: Float.pi/2, button: sender)
    }
    
    private func roll(rotateX: Float? = nil, rotateZ: Float? = nil, button: UIButton) {
        if !cubeArray.isEmpty {
            for cube in cubeArray {
                if rotateX != nil {
                    switch button.tag {
                    case 1001:
                        cube.runAction(SCNAction.move(by: SCNVector3(x: -0.02, y: 0, z: 0), duration: 0.5))
                        cube.runAction(SCNAction.rotateBy(
                            x: 0,
                            y: 0,
                            z: CGFloat(rotateX ?? 0.0),
                            duration: 0.5))
                    case 1004:
                        cube.runAction(SCNAction.move(by: SCNVector3(x: 0.02, y: 0, z: 0), duration: 0.5))
                        cube.runAction(SCNAction.rotateBy(
                            x: 0,
                            y: 0,
                            z: -CGFloat(rotateX ?? 0.0),
                            duration: 0.5))
                    default:
                        break
                    }
                }
                
                if rotateZ != nil {
                    switch button.tag {
                    case 1002:
                        cube.runAction(SCNAction.move(by: SCNVector3(x: 0, y: 0, z: -0.02), duration: 0.5))
                        cube.runAction(SCNAction.rotateBy(
                            x: -CGFloat(rotateZ ?? 0.0),
                            y: 0,
                            z: 0,
                            duration: 0.5))
                    case 1003:
                        cube.runAction(SCNAction.move(by: SCNVector3(x: 0, y: 0, z: 0.02), duration: 0.5))
                        cube.runAction(SCNAction.rotateBy(
                            x: CGFloat(rotateZ ?? 0.0),
                            y: 0,
                            z: 0,
                            duration: 0.5))
                    default:
                        break
                    }
                }
            }
        }
    }
    
    //MARK: - Delete all nodes
    @IBAction func deleteAllCubes(_ sender: UIButton) {
        if !cubeArray.isEmpty {
            for cube in cubeArray {
                cube.removeFromParentNode()
            }
            DispatchQueue.main.async {
                self.isVisible = false
                self.setUpUI()
            }
        }
    }
    
    //MARK: - Recognize a surface
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIColor.clear
        plane.materials = [gridMaterial]
        planeNode.geometry = plane
        return planeNode
    }
}
