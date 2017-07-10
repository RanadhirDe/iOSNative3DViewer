//
//  ColladaSceneOperations.swift
//  Scenekit3DViewer
//
//  Created by Ranadhir Dey on 06/07/17.
//  Copyright © 2017 Ranadhir Dey. All rights reserved.
//

import Foundation
import QuartzCore
import SceneKit
import ModelIO
import SceneKit.ModelIO

class DAESceneOperations{
    static var scnScene:SCNScene?{
        didSet{
            loadAllNodes()
        }
    }
    private static var allTaggedItemArray=[TaggedItemModel]()
    private static var currentlyTappedItemIndex:Int?
    private static var currentlyTappedCoordinate:SCNVector3?
    
    private static func loadAllNodes(){
        
        var index=0
        
        for node in (scnScene?.rootNode.childNodes.filter({$0.geometry != nil}))!{
            if(node.geometry?.materials != nil){
                if (node.geometry?.materials.count)!>0{
                
                    let item = TaggedItemModel(name: node.name!, itemMesh: nil, origialMaterial: (node.geometry?.materials.first!)!, currentMaterial: (node.geometry?.materials.first!)!, node: node, index: index, isVisible: true, isSelected:false, isModified: false, isTransparent: false)
                    
                    allTaggedItemArray.append(item)
                    
                    index=index+1
                }
            }
           
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
        
        currentlyTappedItemIndex=allTaggedItemArray.index(where: {$0.node == node})
        currentlyTappedCoordinate=result.worldCoordinates
        
        var selectedItem=allTaggedItemArray.filter({ $0.node == node}).first
        if !(selectedItem?.isSelected)!{
            selectedItem?.isSelected=true
            let selectionMat = SCNMaterial()
            selectionMat.diffuse.contents = UIColor(red:0.26, green:0.43, blue:0.47, alpha:1.0)
            node.geometry?.materials[0]=selectionMat
            
            selectedItem?.currentMaterial=selectionMat
            selectedItem?.isSelected=true
            let index=allTaggedItemArray.index(where: {$0.node == node})
            allTaggedItemArray[index!]=selectedItem!
        }
        
        
    }
    
    private static func clearLastSelection(){
        if currentlyTappedItemIndex != nil{
            var selectedItem=allTaggedItemArray[currentlyTappedItemIndex!]
            selectedItem.isSelected=false
            selectedItem.isModified=false
            if selectedItem.isVisible && selectedItem.isTransparent == false{
                selectedItem.currentMaterial=selectedItem.origialMaterial
                selectedItem.node?.geometry?.materials[0]=selectedItem.origialMaterial
            }
            
            allTaggedItemArray[currentlyTappedItemIndex!]=selectedItem
            currentlyTappedItemIndex = nil
        }
    }
    
    private static func findVisibleItemResultIndexForHitTest(results:[SCNHitTestResult])->Int{
        
        var resultIndex=0
        var result = results[resultIndex]
        var node=result.node
        var selectedItem=allTaggedItemArray.filter({ $0.node == node}).first
        if selectedItem == nil{
            return resultIndex
        }
        
        while !(selectedItem?.isVisible)!{
            resultIndex=resultIndex + 1
            if resultIndex>=results.count{
                break
            }
            result = results[resultIndex]
            node=result.node
            selectedItem=allTaggedItemArray.filter({ $0.node == node}).first
            
            if selectedItem == nil{
                break
            }
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
                        taggedItemWithVisibilityFlag.node?.geometry?.materials[0]=clearMat
                        taggedItemWithVisibilityFlag.currentMaterial=clearMat
                    }
                    else if taggedItemWithVisibilityFlag.isTransparent==true{
                        let transparentMat = SCNMaterial()
                        transparentMat.diffuse.contents = UIColor(red:0.26, green:0.43, blue:0.47, alpha:1.0)
                        transparentMat.transparency=0.5
                        taggedItemWithVisibilityFlag.node?.geometry?.materials[0]=transparentMat
                        taggedItemWithVisibilityFlag.currentMaterial=transparentMat
                    }
                    else{
                        taggedItemWithVisibilityFlag.currentMaterial=taggedItemWithVisibilityFlag.origialMaterial
                        taggedItemWithVisibilityFlag.node?.geometry?.materials[0]=taggedItemWithVisibilityFlag.origialMaterial
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
        allTaggedItemArray[currentlyTappedItemIndex!].node?.geometry?.materials[0]=allTaggedItemArray[currentlyTappedItemIndex!].origialMaterial
        allTaggedItemArray[currentlyTappedItemIndex!].isSelected=false
        allTaggedItemArray[currentlyTappedItemIndex!].isModified=false
        
        
    }
    
    static func showProperties(){
        //Need to implement
    }

    static func addSphere(){
        let sphereNode = SCNSphere(radius: 500)
        sphereNode.materials.first?.diffuse.contents=UIColor.red//(red:0.26, green:0.43, blue:0.47, alpha:1.0)
        let node = SCNNode(geometry: sphereNode)
        node.position = SCNVector3(x: (currentlyTappedCoordinate?.x)!, y: (currentlyTappedCoordinate?.y)!, z: (currentlyTappedCoordinate?.z)!)
        scnScene?.rootNode.addChildNode(node)
    }
    
}
