//
//  Picker.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// A media picker
public class Picker: Browser {
    
    /// Create a media picker
    public override init(library: Library) {
        super.init(library: library)
        
        // setup albums
        factory(with: .albums).flatMap {
            $0.cell = PickerAlbumCell.self
            $0.controller = PickerAlbumController.self
        }
    }
    
    var allowsUpdatingLibraryChagned: Bool = true
    
    // MARK: Library Change
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    open override func library(_ library: Library, didChange change: Change) {
        super.library(library, didChange: change)
    }
    
    // MARK: Selection Item
    
    /// Select a item 
    @discardableResult
    func selectItem(with asset: Asset, sender: Any) -> SelectionStatus? {
        
        // the asset has been selected?
        if let status = _selectedItems[asset.identifier] {
            return status
        }
        let status = SelectionStatus(asset: asset)
        _selectedItems[asset.identifier] = status
        return status
    }
    
    /// Deselect a item
    @discardableResult
    func deselectItem(with asset: Asset, sender: Any) -> SelectionStatus? {
        
        // the asset has been selected?
        if let status = _selectedItems.removeValue(forKey: asset.identifier) {
            
            // update
            status.no = -1
        }
        
        return nil
    }
    
    /// Returns a item select status
    func statusOfItem(with asset: Asset) -> SelectionStatus? {
        return _selectedItems[asset.identifier]
    }
    
    // MARK: Ivar
    
    private lazy var _selectedItems: [String: SelectionStatus] = [:]
}
