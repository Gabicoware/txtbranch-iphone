//
//  BranchViewModel.swift
//  txtbranch
//
//  Created by Daniel Mueller on 9/22/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

import Foundation

@objc
public class BranchViewModel : NSObject{
    public var branchKeys:[String] = []
    public var childBranchKeys:[String] = []
    public var parentBranchKey:String?
    public var branches:[String:NSObject] = [:]
    
    public var currentBranchKey: String? {
        get {
            return self.branchKeys.last
        }
    }
    
    public var isCurrentBranchValid: Bool {
        get {
            if let key = self.currentBranchKey{
                if let object:NSObject = self.branches[key]{
                    if let branch:[String:NSObject] = object as? [String:NSObject]{
                        if let content = branch["content"] {
                            if let link = branch["link"] {
                                return content != "" && link != ""
                            }
                        }
                    }
                }
            }
            return false
        }
    }
    
    public var allKeys: [String] {
        get{
            var result:[String] = []
            result += branchKeys
            result += childBranchKeys
            if let key = parentBranchKey{
                result += [key]
            }
            return result
        }
    }
    
    public var hasParentBranchKey: Bool {
        get {
            return self.parentBranchKey != nil
        }
    }
    
    
    override public func isEqual(object: AnyObject?) -> Bool{
        
        if let model = object as? BranchViewModel{
            return self == model
        }
        return false
        
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        let result:BranchViewModel = BranchViewModel();
        
        result.parentBranchKey = self.parentBranchKey
        result.branchKeys = self.branchKeys
        result.childBranchKeys = self.childBranchKeys
        
        return result;
    }
    
}

public func == (this:BranchViewModel, that:BranchViewModel) -> Bool {
    
    var hasMatchingParentKeys:Bool = this.parentBranchKey == that.parentBranchKey
    
    let hasMatchingBranches:Bool = this.branches == that.branches
    
    let hasMatchingBranchKeys:Bool = this.branchKeys == that.branchKeys
    
    let hasMatchingChildBranches:Bool = this.childBranchKeys == that.childBranchKeys
    
    return hasMatchingParentKeys && hasMatchingBranches && hasMatchingBranchKeys && hasMatchingChildBranches
    
}
