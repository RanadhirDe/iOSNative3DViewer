//
//  OBJSceneOperations.swift
//  Scenekit3DViewer
//
//  Created by Ranadhir Dey on 07/07/17.
//  Copyright © 2017 Ranadhir Dey. All rights reserved.
//

import Foundation
import QuartzCore
import SceneKit
import ModelIO
import SceneKit.ModelIO

class OBJSceneOperations{
    static var scnScene:SCNScene?
    static var modelPath:String?
    static var modelNode:SCNNode?
    
    
    private static var allTaggedItemArray=[TaggedItemModel]()
    
    private static var currentlyTappedItemIndex:Int?
    private static var currentlyTappedCoordinate:SCNVector3?
    
    static func loadAllNodes(){
        
       
        
        let fileName=NSString(string: modelPath!)
        let bundle = Bundle.main
        let path = bundle.path(forResource: fileName.deletingPathExtension, ofType: fileName.pathExtension)
        let url = NSURL(fileURLWithPath: path!)
        
        
        let asset = MDLAsset(url: url as URL)
        
        let mesh = asset.object(at: 0) as! MDLMesh
        
        let submeshes = mesh.submeshes
        
        
        
        var index=0
        for a in 0 ..< (submeshes?.count)! {
            let submesh = submeshes?[a] as! MDLSubmesh
            
           
            
            /*if let opacityProperty=submesh.material?.property(with: .opacity)?.floatValue{
                
                let clearMat = SCNMaterial()
                clearMat.diffuse.contents = UIColor.red //modelNode?.geometry?.materials[index].diffuse.contents
                //clearMat.transparency=0.5//CGFloat(opacityProperty)
                modelNode?.geometry?.materials[index]=clearMat
                
                //print("\(submesh.name) -  \(opacityProperty) - \(String(describing: modelNode?.geometry?.materials[index].name))")
                //modelNode?.geometry?.materials[index].transparency=0.5
                
            }*/
            
            if modelNode?.geometry?.materials[index].name != nil && modelNode?.geometry?.materials[index].name == "6247_Glass"{
                //modelNode?.geometry?.materials.remove(at: index)
               // continue
            }
            
            
            
            let item=TaggedItemModel(name: submesh.name, itemMesh: nil, origialMaterial: (modelNode?.geometry?.materials[index])!, currentMaterial: (modelNode?.geometry?.materials[index])!, node: nil, index: index, isVisible: true, isSelected:false, isModified: false, isTransparent: false)
            
//            if let name:String=item.name!{
//                if name  == "6247_Glass"{
//                 print("stop")
//                }
//            }
            
            if item.name != nil && item.origialMaterial.name == "6247_Glass" {
                print("stop")
            }
            
            
            allTaggedItemArray.append(item)
            
            modelNode?.geometry?.materials[index].lightingModel=SCNMaterial.LightingModel.constant
            
            
           
 
            
            index=index+1
        }
    }
    
    static func modelTapped(results:[SCNHitTestResult]){
        
        clearLastSelection()
        
        if results.count == 0{
            ModelViewerViewController.shouldDisplayMenu = false
            return
        }
        let effectiveResultIndex=findVisibleItemResultIndexForHitTest(results: results)
        if effectiveResultIndex>results.count-1{
             ModelViewerViewController.shouldDisplayMenu = false
            return
        }
        
        ModelViewerViewController.shouldDisplayMenu = true
        let result=results[effectiveResultIndex]
        let node=result.node
        
        currentlyTappedItemIndex=result.geometryIndex
        currentlyTappedCoordinate=result.worldCoordinates
        
        var selectedItem=allTaggedItemArray[currentlyTappedItemIndex!]
        print(selectedItem.origialMaterial.name)
        if !(selectedItem.isSelected){
            let selectionMat = SCNMaterial()
            selectionMat.diffuse.contents = UIColor(red:0.26, green:0.43, blue:0.47, alpha:1.0)
            node.geometry?.materials[currentlyTappedItemIndex!]=selectionMat
            
            selectedItem.currentMaterial=selectionMat
            selectedItem.isSelected=true
            allTaggedItemArray[currentlyTappedItemIndex!]=selectedItem

        }
        
        
    }
    
    private static func clearLastSelection(){
        if currentlyTappedItemIndex != nil{
            var selectedItem=allTaggedItemArray[currentlyTappedItemIndex!]
            selectedItem.isSelected=false
            selectedItem.isModified=false
            if selectedItem.isVisible && selectedItem.isTransparent != true{
                selectedItem.currentMaterial=selectedItem.origialMaterial
                modelNode?.geometry?.materials[currentlyTappedItemIndex!]=selectedItem.origialMaterial
            }
           
            allTaggedItemArray[currentlyTappedItemIndex!]=selectedItem
            currentlyTappedItemIndex = nil
        }
    }
    
    private static func findVisibleItemResultIndexForHitTest(results:[SCNHitTestResult])->Int{
        
        var resultIndex=0
        var result = results[resultIndex]
        var index=result.geometryIndex
        var selectedItem=allTaggedItemArray[index]
        
        
        while !selectedItem.isVisible{
            resultIndex=resultIndex + 1
            //index=in
            if resultIndex>=results.count{
                break
            }
            result = results[resultIndex]
            //node=result.node
            index=result.geometryIndex
            selectedItem=allTaggedItemArray[index]
            
            
        }
        
        return resultIndex
    }
    
    
    private static func redrawModifiedTaggedItems(){
        var index=0
        for var taggedItemWithVisibilityFlag in allTaggedItemArray{
            autoreleasepool{
                if taggedItemWithVisibilityFlag.isModified{
                    taggedItemWithVisibilityFlag.isModified=false
                    if taggedItemWithVisibilityFlag.isVisible==false{
                        let clearMat = SCNMaterial()
                        clearMat.transparency=0.0
                        modelNode?.geometry?.materials[index]=clearMat
                        taggedItemWithVisibilityFlag.currentMaterial=clearMat
                    }
                    else if taggedItemWithVisibilityFlag.isTransparent==true{
                        let clearMat = SCNMaterial()
                        //clearMat.diffuse.contents = UIColor(red:0.26, green:0.43, blue:0.47, alpha:1.0)
                        clearMat.transparency=0.5
                        modelNode?.geometry?.materials[index]=clearMat
                        taggedItemWithVisibilityFlag.currentMaterial=clearMat
                    }
                    else{
                        taggedItemWithVisibilityFlag.currentMaterial=taggedItemWithVisibilityFlag.origialMaterial
                        modelNode?.geometry?.materials[index]=taggedItemWithVisibilityFlag.origialMaterial
                    }
                    
                    allTaggedItemArray[index]=taggedItemWithVisibilityFlag
                    
                    
                }
            }
            
            index = index + 1
        }
        

        
        
    }
    
    //MARK: - Operations on menu tap
    
    static func removeNode(){
        var taggedItem=allTaggedItemArray[currentlyTappedItemIndex!]
        taggedItem.isModified=true
        taggedItem.isVisible=false
        allTaggedItemArray[currentlyTappedItemIndex!]=taggedItem
        
        redrawModifiedTaggedItems()
        
    }
    static func makeTransparentNode(){
        var taggedItem=allTaggedItemArray[currentlyTappedItemIndex!]
        taggedItem.isModified=true
        taggedItem.isTransparent=true
        allTaggedItemArray[currentlyTappedItemIndex!]=taggedItem
        
        redrawModifiedTaggedItems()

    }
    
    static func cancelSelection(){
        
        allTaggedItemArray[currentlyTappedItemIndex!].currentMaterial=allTaggedItemArray[currentlyTappedItemIndex!].origialMaterial
        modelNode?.geometry?.materials[currentlyTappedItemIndex!]=allTaggedItemArray[currentlyTappedItemIndex!].origialMaterial
        allTaggedItemArray[currentlyTappedItemIndex!].isSelected=false
        allTaggedItemArray[currentlyTappedItemIndex!].isModified=false
        /*allTaggedItemArray[currentlyTappedItemIndex!].isTransparent=false
 
        allTaggedItemArray[currentlyTappedItemIndex!].isVisible=true
 */
 
    }
    
    static func showProperties(){
        //Need to implement
    }
    
    static func addSphere(){
        let sphere = SCNSphere(radius: 5000)
        sphere.materials.first?.diffuse.contents=UIColor.red//(red:0.26, green:0.43, blue:0.47, alpha:1.0)
        let node = SCNNode(geometry: sphere)
        scnScene?.rootNode.addChildNode(node)    }
    
}
