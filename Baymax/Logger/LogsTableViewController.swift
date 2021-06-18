//
//  LogsTableViewController.swift
//  Baymax
//
//  Created by Simon Mitchell on 01/04/2020.
//  Copyright © 2020 3 SIDED CUBE. All rights reserved.
//

import UIKit

extension UserDefaults {
    var baymaxLoggingEnabled: Bool {
        get {
            guard object(forKey: "baymax_logging") != nil else {
                return LogsTool.loggingEnabledByDefault
            }
            return bool(forKey: "baymax_logging")
        }
        set {
            set(newValue, forKey: "baymax_logging")
        }
    }
}

class LogsTableViewController: UITableViewController {
    
    override init(style: UITableView.Style) {
        super.init(style: .grouped)
        title = "Logs"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// `LogFile`s which have been written to disk
    private var logFiles: [LogFile] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        toolbarItems = [
            UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(toggleSharing)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAll(_:)))
        ]
        
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.register(UINib(nibName: "InformationTableViewCell", bundle: Bundle(for: LogsTableViewController.self)), forCellReuseIdentifier: "propertyRow")
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: Bundle(for: LogsTableViewController.self)), forCellReuseIdentifier: "switchRow")

        // Fetch log files
        Logger.shared.logFiles { [weak self] result in
            self?.logFiles = result.success ?? []
        }
    }
    
    var isSharing: Bool = false {
        didSet {
            tableView.reloadData()
        }
    }
    
    var selectedLogIndexes: Set<Int> = [] {
        didSet {
            guard isSharing, let lastItem = toolbarItems?.last else {
                return
            }
            lastItem.isEnabled = !selectedLogIndexes.isEmpty
        }
    }
    
    @objc func toggleSharing() {
        isSharing = !isSharing
        toolbarItems = isSharing ? [
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleSharing)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(image: (#imageLiteral(resourceName: "share") as BaymaxImageLiteral).image, style: .done, target: self, action: #selector(shareSelected(_:)))
        ] : [
            UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(toggleSharing)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteAll(_:)))
        ]
        selectedLogIndexes = []
    }
    
    @objc func deleteAll(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Delete All Logs?", message: "Are you sure you want to do this? You won't be able to retrieve any of the files at a later date.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            let fm = FileManager.default
            self.logFiles.forEach { (file) in
                do {
                    try fm.removeItem(at: file.url)
                } catch _ {
                    
                }
            }
            self.logFiles = []
            self.tableView.reloadData()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func toggleLogging(_ sender: UISwitch) {
        LogsTool.loggingEnabled = sender.isOn
    }
    
    @objc func shareSelected(_ sender: UIBarButtonItem) {
        guard !selectedLogIndexes.isEmpty else { return }
        share(logFiles: selectedLogIndexes.map({ logFiles[$0] }), sender: sender)
    }
    
    let fileSizeFormatter = ByteCountFormatter()

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Settings" : "Logs"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return logFiles.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        if !isSharing {
            toggleSharing()
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard indexPath.section == 1, !isSharing else { return nil }
        
        return UISwipeActionsConfiguration(actions: [
            
            UIContextualAction(style: .destructive, title: "Delete", handler: { [weak self] (_, _, handler) in
                
                guard let self = self else { return }
                
                let alert = UIAlertController(title: "Delete File", message: "Are you sure you want to do this? You won't be able to retrieve the file at a later date.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    handler(false)
                }))
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
                    let fm = FileManager.default
                    let file = self.logFiles[indexPath.row]
                    do {
                        try fm.removeItem(at: file.url)
                        self.logFiles.remove(at: indexPath.row)
                        self.tableView.reloadData()
                        handler(true)
                    } catch _ {
                        handler(false)
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            })
        ])
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchRow", for: indexPath)
            
            cell.selectionStyle = .none
            
            (cell as? SwitchTableViewCell)?.titleLabel.text = "Logging Enabled"
            (cell as? SwitchTableViewCell)?.switch.isOn = LogsTool.loggingEnabled
            (cell as? SwitchTableViewCell)?.switch.removeTarget(nil, action: nil, for: .valueChanged)
            (cell as? SwitchTableViewCell)?.switch.addTarget(self, action: #selector(toggleLogging(_:)), for: .valueChanged)
            
            return cell
            
        case 1:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "propertyRow", for: indexPath)
            
            cell.selectionStyle = .default
            
            if isSharing {
                cell.accessoryType = .none
                cell.accessoryView = UIImageView(image: (selectedLogIndexes.contains(indexPath.row) ? #imageLiteral(resourceName: "checkmark-on") : #imageLiteral(resourceName: "checkmark-off") as BaymaxImageLiteral).image)
                cell.accessoryView?.tintColor = .systemBlue
            } else {
                cell.accessoryType = .disclosureIndicator
                cell.accessoryView = nil
            }
                    
            let logFile = logFiles[indexPath.row]
            
            (cell as? InformationTableViewCell)?.keyLabel?.text = logFile.url.lastPathComponent
            
            if let fileSize = logFile.fileSize {
                (cell as? InformationTableViewCell)?.valueLabel?.text = fileSizeFormatter.string(fromByteCount: Int64(fileSize))
            } else {
                (cell as? InformationTableViewCell)?.valueLabel.text = nil
            }
            
            return cell
            
        default:
            fatalError("cellForRowAt called with unexpected section index!")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section {
        case 1:
            if isSharing {
                if let index = selectedLogIndexes.firstIndex(of: indexPath.row) {
                    selectedLogIndexes.remove(at: index)
                } else {
                    selectedLogIndexes.insert(indexPath.row)
                }
                tableView.reloadRows(at: [indexPath], with: .none)
            } else {
                let file = logFiles[indexPath.row]
                let detailVC = LogDetailViewController(logfile: file)
                navigationController?.show(detailVC, sender: nil)
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func share(logFiles: [LogFile], sender: Any) {
        
        guard let shareHandler = LogsTool.shareHandler else {
            shareLogFilesDefault(logFiles, sender: sender)
            return
        }
        
        // If we were told by share handler that it couldn't handle the files, then fallback to default!
        guard shareHandler(logFiles, sender) == false else {
            return
        }
        
        shareLogFilesDefault(logFiles, sender: sender)
    }
    
    private func shareLogFilesDefault(_ logFiles: [LogFile], sender: Any?) {
        let activityViewController = UIActivityViewController(activityItems: logFiles.map({ $0.url }), applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender as? UIView ?? view
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        present(activityViewController, animated: true, completion: nil)
    }
}
