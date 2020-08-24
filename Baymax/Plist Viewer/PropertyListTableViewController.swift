//
//  PropertyListTableViewController.swift
//  Baymax
//
//  Created by Matthew Cheetham on 12/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import UIKit

class PropertyListTableViewController: UITableViewController {
    
    var properties: [PropertyListItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        } else {
            // Fallback on earlier versions
        }
        tableView.register(UINib(nibName: "InformationTableViewCell", bundle: Bundle(for: PropertyListTableViewController.self)), forCellReuseIdentifier: "propertyRow")
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return properties?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "propertyRow", for: indexPath) as! InformationTableViewCell
        
        let property = properties?[indexPath.row]
        
        cell.keyLabel?.text = property?.key
        cell.valueLabel?.text = property?.value?.toString()
        
        if ((property?.children) != nil) {
            
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            
        } else {
            
            cell.selectionStyle = .none
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard (properties?[indexPath.row].children) != nil else {
            return
        }
        
        let nextViewController = PropertyListTableViewController(style: .grouped)
        // Sort by keys!
        nextViewController.properties = properties?[indexPath.row].children?.sorted(by: { (item1, item2) -> Bool in
            switch (item1.key, item2.key) {
            case (.some(let key1), .some(let key2)):
                return key1 < key2
            case (nil, .some(_)):
                return false
            case (.some(_), nil):
                return true
            case (nil, nil):
                return true
            }
        })
        nextViewController.title = properties?[indexPath.row].key
        navigationController?.show(nextViewController, sender: self)
    }
}
