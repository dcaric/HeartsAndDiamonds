//
//  ViewController.swift
//  HeartsAndDiamonds
//
//  Created by jonnyb on 8/21/18.
//  Copyright © 2018 jonnyb. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var selectImage: UIButton!
    @IBOutlet weak var imagePresented: UIImageView!
    
    var heartNode: SCNNode?
    var diamondNode: SCNNode?
    var sneekersNode: SCNNode?
    var imageNodes = [SCNNode]()
    var isJumping = false
    
    var selectedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.rendersContinuously = true
        let heartScene = SCNScene(named: "art.scnassets/heart.scn")
        let diamondScene = SCNScene(named: "art.scnassets/diamond.scn")
        let sneekersScene = SCNScene(named: "art.scnassets/PegasusTrail.usdz")
        heartNode = heartScene?.rootNode
        diamondNode = diamondScene?.rootNode
        sneekersNode = sneekersScene?.rootNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    
    func setArScene (image: UIImage) {
        let configuration = ARImageTrackingConfiguration()
        var customReferenceSet = Set<ARReferenceImage>()

        let referenceImage = ARReferenceImage.init(image.cgImage!, orientation: .up, physicalWidth: 0.0635)
        referenceImage.name = "reference"
        configuration.maximumNumberOfTrackedImages = 1
        print("1 referenceImage=\(referenceImage)")
        customReferenceSet.insert(referenceImage)
        configuration.trackingImages = customReferenceSet


        /*
        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Playing Cards", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages
            configuration.maximumNumberOfTrackedImages = 2
            for image in trackingImages {
                print("2 Image=\(image)")
            }

        }
        */
        
        //sceneView.session.run(configuration)
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        print("2 renderer")

    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("1 renderer")

        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            let size = imageAnchor.referenceImage.physicalSize
            let plane = SCNPlane(width: size.width, height: size.height)
            plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.9)
            plane.cornerRadius = 0.005
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
            
            var shapeNode: SCNNode?
            switch imageAnchor.referenceImage.name {
            case CardType.king.rawValue :
                shapeNode = heartNode
            case CardType.queen.rawValue :
                shapeNode = diamondNode
            case CardType.reference.rawValue :
                shapeNode = sneekersNode
            default:
                break
            }
            
            let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
            let repeatSpin = SCNAction.repeatForever(shapeSpin)
            shapeNode?.runAction(repeatSpin)
            
            guard let shape = shapeNode else { return nil }
            node.addChildNode(shape)
            imageNodes.append(node)
            print("1 imageNodes count=\(imageNodes.count)")

            return node
        }
        
        return nil
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //print("1 updateAtTime count=\(imageNodes.count)")

        /*
        if imageNodes.count == 1 {
            let positionOne = SCNVector3ToGLKVector3(imageNodes[0].position)
            let positionTwo = SCNVector3ToGLKVector3(imageNodes[1].position)
            let distance = GLKVector3Distance(positionOne, positionTwo)
            
            if distance < 0.10 {
                spinJump(node: imageNodes[0])
                spinJump(node: imageNodes[1])
                isJumping = true
            } else {
                isJumping = false
            }
        }
         */
    }
    
    func spinJump(node: SCNNode) {
        if isJumping { return }
        let shapeNode = node.childNodes[1]
        let shapeSpin = SCNAction.rotateBy(x: 0, y: 1 * .pi, z: 0, duration: 1)
        shapeSpin.timingMode = .easeInEaseOut
        
        let up = SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 0.5)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        let upDown = SCNAction.sequence([up, down])
        
        shapeNode.runAction(shapeSpin)
        shapeNode.runAction(upDown)
    }
    
    enum CardType : String {
        case king = "king"
        case queen = "queen"
        case reference = "reference"

    }
    
    @IBAction func selectImageButton (_ sender: UIButton) {
        self.imagePresented.image = nil
        self.imagePresented.isHidden  = false
        //sceneView.session.pause()
        /*
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        */
        for nodeAdded in imageNodes {
            nodeAdded.removeFromParentNode()
        }
        imageNodes = [SCNNode]()
        sceneView.sceneTime += 1
        
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }
    

    
    //MARK: ImagePicker Controller Delegate methods
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("imagePickerControllerDidCancel")
        self.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("didFinishPickingMediaWithInfo")
        let chosenImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imagePresented.image = chosenImage
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.imagePresented.isHidden  = true
            self.setArScene(image: chosenImage)
        }
        dismiss(animated:true, completion: nil)
    }
}
