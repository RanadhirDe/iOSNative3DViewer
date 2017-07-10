//
//  ModelViewerViewController.swift
//  iOSNative3DViewer
//
//  Created by Ranadhir Dey on 10/07/17.
//  Copyright © 2017 Ranadhir Dey. All rights reserved.
//

import Foundation
import QuartzCore
import SceneKit
import ModelIO
import SceneKit.ModelIO

struct TaggedItemWithVisibilityFlag{
    var taggedItem:MDLSubmesh
    var isVisible:Bool
}

struct TaggedItemModel{
    var name:String?
    var itemMesh:MDLSubmesh?
    var origialMaterial:SCNMaterial
    var currentMaterial:SCNMaterial
    var node:SCNNode?
    var index:Int
    var isVisible:Bool
    var isSelected:Bool
    var isModified:Bool
    var isTransparent:Bool
}

enum FileType {
    case OBJ
    case DAE
}


class ModelViewerViewController: UIViewController {

    @IBOutlet weak var scnView: SCNView!
    
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var modelNode: SCNNode!
    
    var fileType=FileType.OBJ
    
    static var shouldDisplayMenu=false
    
    let objFolderPath="GeometryFighter.scnassets/ObjFiles/"
    let daeFolderPath="GeometryFighter.scnassets/DaeFiles/"
    
    let modelName="DuplexNew.obj"
    
    var modelPath=""
    
    @IBOutlet weak var transparencySlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //loadModelAsAsset()
        //loadModelInLoop()
        let fileName=NSString(string: modelName)
        if fileName.pathExtension.lowercased() == "dae"{
            fileType = .DAE
            modelPath="\(daeFolderPath)\(modelName)"
        }
        if fileName.pathExtension.lowercased() == "obj"{
            fileType = .OBJ
            modelPath="\(objFolderPath)\(modelName)"
        }
        
        loadAsFileName()
        
        
        if fileName.pathExtension.lowercased() == "dae"{
            DAESceneOperations.scnScene=scnScene
            
            
        }
        else if fileName.pathExtension.lowercased() == "obj"{
            OBJSceneOperations.modelNode=modelNode
            OBJSceneOperations.modelPath=modelPath
            OBJSceneOperations.scnScene=scnScene
            OBJSceneOperations.loadAllNodes()
        }
        
        
        setupView()
        setupCamera()
        
        
        // Do any additional setup after loading the view.
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        //return true
        
        return (action ==  #selector(self.menuRemoveTapped)
            || action ==  #selector(self.menuPropertiesTapped)
            || action ==  #selector(self.menuCancelTapped)
            || action == #selector(self.menuTransparentTapped)
            || action == #selector(self.menuAddSphereTapped))
    }
    
    //MARK: - Setup Scene
    
    func loadAsFileName(){
        scnScene=SCNScene(named: modelPath)
        modelNode=scnScene.rootNode.childNodes.first
        
        
    }
    
    func loadModelAsAsset(){
        let fileName=NSString(string: modelPath)
        let bundle = Bundle.main
        let path = bundle.path(forResource: fileName.deletingPathExtension, ofType: fileName.pathExtension)
        let url = NSURL(fileURLWithPath: path!)
        let asset = MDLAsset(url: url as URL)
        let object = asset.object(at: 0)
        let node = SCNNode(mdlObject: object)
        
        
        scnScene=SCNScene()
        node.position = SCNVector3Make(0, 0, 0)
        scnScene.rootNode.addChildNode(node)
        
        
    }
    
    
    
    func loadModelInLoop(){
        
        let fileName=NSString(string: modelPath)
        
        scnScene=SCNScene()
        
        let bundle = Bundle.main
        let path = bundle.path(forResource: fileName.deletingPathExtension, ofType: fileName.pathExtension)
        let url = NSURL(fileURLWithPath: path!)
        let asset = MDLAsset(url: url as URL)
        
        let mesh = asset.object(at: 0) as! MDLMesh
        let vertexBuffer = mesh.vertexBuffers[0]
        let descripter = mesh.vertexDescriptor
        let submeshes = mesh.submeshes
        
        
        
        
        
        var counter=0
        
        for a in 0 ..< (submeshes?.count)! {
            let submesh = submeshes?[a] as! MDLSubmesh
            
            let singleMesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: mesh.vertexCount, descriptor: descripter, submeshes:  [submesh])
            
            
            
            let geometry = SCNGeometry(mdlMesh: singleMesh)
            
            let node = SCNNode(geometry: geometry)
            node.name=submesh.name
            self.scnScene.rootNode.addChildNode(node)
            
            counter=counter+1
            
            //parentNode.addChildNode(node)
            
        }
        
        print(counter)
    }
    
    
    func setupView() {
        //scnView = self.view as! SCNView
        scnView.scene=scnScene
        scnView.showsStatistics = true
        
        scnView.allowsCameraControl = true
        
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true
        
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action : #selector(self.tapGesture(sender:)));
        doubleTapRecognizer.numberOfTapsRequired = 1;
        doubleTapRecognizer.numberOfTouchesRequired = 1;
        scnView.addGestureRecognizer(doubleTapRecognizer);
        
        
    }
    
    func setupCamera() {
        // 1
        cameraNode = SCNNode()
        // 2
        cameraNode.camera = SCNCamera()
        
        //cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    //MARK: - Manupulaying scene
    
    
    
    
    
    func tapGesture(sender: UITapGestureRecognizer){
        
        
        let p = sender.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: nil)
        
        
        
        
        
        if fileType == .DAE{
            DAESceneOperations.modelTapped(results: hitResults)
        }
        else if fileType == .OBJ{
            OBJSceneOperations.modelTapped(results: hitResults)
            
        }
        
        if  ModelViewerViewController.shouldDisplayMenu == true{
            addMenuToSelection(sender: sender)
        }
        
        
        
    }
    
    func addMenuToSelection(sender: UITapGestureRecognizer){
        if let recognizerView = sender.view
        {
            let menuController = UIMenuController.shared
            menuController.setTargetRect(CGRect(x: sender.location(in: scnView).x, y: sender.location(in: scnView).y, width: 100, height: 100), in: recognizerView)
            
            let menuItemRemove=UIMenuItem(title: "Remove", action: #selector(self.menuRemoveTapped))
            let menuItemTransparent=UIMenuItem(title: "Transparent", action: #selector(self.menuTransparentTapped))
            let menuItemProperties=UIMenuItem(title: "Properties", action: #selector(self.menuPropertiesTapped))
            let menuItemAddPoint=UIMenuItem(title: "Add Point", action: #selector(self.menuAddSphereTapped))
            let menuItemCancel=UIMenuItem(title: "Cancel", action: #selector(self.menuCancelTapped))
            
            menuController.menuItems=[menuItemRemove, menuItemTransparent, menuItemProperties,menuItemAddPoint,menuItemCancel]
            
            menuController.setMenuVisible(true, animated:true)
        }
    }
    
    
    
    @IBAction func showHideSettings(_ sender: Any) {
        //transparencySlider.isHidden=false
        performSegue(withIdentifier: "segToItemList", sender: sender)
        
    }
    
    
    @IBAction func transparencyChanged(_ sender: UISlider) {
        if fileType == .DAE{
            scnScene.rootNode.opacity=CGFloat(sender.value)
            return
        }
        modelNode.opacity=CGFloat(sender.value)
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segToItemList"{
            //let vc:ItemSelectionTableViewController=(segue.destination as! UINavigationController).topViewController as! ItemSelectionTableViewController
            //vc.itemArray=self.allTaggedItemArray
            //vc.delegate=self
            
        }
    }
    
    //MARK: - Menu Tapped
    func menuRemoveTapped(){
        
        if fileType == .DAE{
            DAESceneOperations.removeNode()
            return
        }
        else if fileType == .OBJ{
            OBJSceneOperations.removeNode()
            return
        }
        
        
    }
    func menuTransparentTapped(){
        
        if fileType == .DAE{
            DAESceneOperations.makeTransparentNode()
            return
        }
        else if fileType == .OBJ{
            OBJSceneOperations.makeTransparentNode()
            return
        }
        
        
    }
    
    func menuPropertiesTapped(){
        if fileType == .DAE{
            DAESceneOperations.showProperties()
            return
        }
        else if fileType == .OBJ{
            OBJSceneOperations.showProperties()
            return
        }
    }
    func menuCancelTapped(){
        
        if fileType == .DAE{
            DAESceneOperations.cancelSelection()
            return
        }
        else if fileType == .OBJ{
            OBJSceneOperations.cancelSelection()
            return
        }
        
        
    }
    
    func menuAddSphereTapped(){
        if fileType == .DAE{
            DAESceneOperations.addSphere()
            return
        }
        else if fileType == .OBJ{
            OBJSceneOperations.removeNode()
            return
        }
        
    }


}
