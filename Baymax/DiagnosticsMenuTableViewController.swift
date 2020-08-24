//
//  DiagnosticsMenuTableViewController.swift
//  Baymax
//
//  Created by Matthew Cheetham on 08/11/2018.
//  Copyright © 2018 3 SIDED CUBE. All rights reserved.
//

import UIKit

/// The presentable view for the baymax framework. Diagnostics tools are accessed from here.
public class DiagnosticsMenuTableViewController: UITableViewController {
        
    var providers: [DiagnosticsServiceProvider] {
        return DiagnosticsManager.shared.diagnosticProviders
    }
    
    public init() {
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Diagnostics [BETA]"
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        } else {
            // Fallback on earlier versions
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "serviceRow")
        self.toolbarItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) ,UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(handleClose))]
        self.navigationController?.isToolbarHidden = false
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard !isBeingDismissed else { return }
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    // MARK: - Table view data source
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return providers.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard section <= providers.count - 1 else {
            return 0
        }
        
        let tools = DiagnosticsManager.shared.availableTools(for: providers[section])
        return tools.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "serviceRow", for: indexPath)
        
        let providerService = DiagnosticsManager.shared.availableTools(for: providers[indexPath.section])[indexPath.row]
        
        cell.textLabel?.text = providerService.displayName
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return providers[section].serviceName
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let navigationController = self.navigationController else {
            return
        }
        DiagnosticsManager.shared.availableTools(for: providers[indexPath.section])[indexPath.row].launchUI(in: navigationController)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DiagnosticsMenuTableViewController {
    
    @objc func handleClose() {
        dismiss(animated: true, completion: nil)
    }
}
