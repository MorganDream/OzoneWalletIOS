//
//  SendRequestTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 11/22/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit


class SendRequestTableViewCell: UITableViewCell {
    @IBOutlet var keyLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!
}

class SendRequestTableViewController: UITableViewController {
    
    var request: dAppProtocol.SendRequest!
    var message: dAppMessage!
    var dappMetadata: dAppMetadata?
    var accountState: AccountState?
    var requestedAsset: TransferableAsset?
    var onConfirm: ((_ message: dAppMessage, _ request: dAppProtocol.SendRequest)->())?
    var onCancel: ((_ message: dAppMessage, _ request: dAppProtocol.SendRequest)->())?
    
    struct info {
        var key: String
        var title: String {
            if key == "fee" {
                return "Network fee"
            }
            return key
        }
        var value: String
    }
    
    var data: [info]! = []
    
    enum dataKey: String{
        case asset = "asset"
        case from = "from"
        case to = "to"
        case remark = "remark"
        case fee = "fee"
    }
    
    func setupView() {
        self.title = "Send request"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.request.network, style: .plain, target: self, action: nil)
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.buildData()
    }
    
    func fetchBalance(address: String) {
        let network = request.network.lowercased().contains("test") ? Network.test : Network.main
        O3APIClient(network: network).getAccountState(address: address) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let accountstate):
                self.accountState = accountstate
                self.checkBalance(accountState: accountstate)
            }
        }
    }
    
    func checkBalance(accountState: AccountState) {
        //check balance with the request
        let isNative = self.request.asset.lowercased() == "neo" || self.request.asset.lowercased() == "gas"
        
        if isNative {
            self.requestedAsset = accountState.assets.first(where: { t -> Bool in
                return t.name.lowercased() == self.request.asset.lowercased()
            })
        } else {
            //nep5
            self.requestedAsset = accountState.nep5Tokens.first(where: { t -> Bool in
                return t.name.lowercased() == self.request.asset.lowercased() || t.id == self.request.asset
            })
        }
        
        //this should never happen
        if self.requestedAsset == nil {
            return
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func buildData() {
        data.append(info(key: dataKey.asset.rawValue, value: String(format: "%@ %@", request.amount, request.asset.uppercased())))
        data.append(info(key: dataKey.from.rawValue, value: String(format: "%@", request.fromAddress!)))
        data.append(info(key: dataKey.to.rawValue, value: String(format: "%@", request.toAddress)))
        if request.remark != nil {
            data.append(info(key: dataKey.remark.rawValue, value: String(format: "%@", request.remark!)))
        }
        if request.fee != nil {
            data.append(info(key: dataKey.fee.rawValue, value: String(format: "%@ GAS", request.fee!)))
        }
        
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.fetchBalance(address: self.request.fromAddress!)
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 159.0
        }
        return 40.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dapp-metadata-cell") as! dAppMetaDataTableViewCell
            cell.dappMetadata = self.dappMetadata
            cell.permissionLabel?.text = String(format: "%@ is requesting you to send", dappMetadata?.title ?? "App")
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "info-cell") as! SendRequestTableViewCell
        
        let info = data[indexPath.row]
        cell.keyLabel.text = String(format:"%@", info.title.uppercased())
        cell.valueLabel.text = String(format:"%@", info.value)
        
//        if info.key.lowercased() == dataKey.asset.rawValue.lowercased()  {
//            
//            if self.requestedAsset != nil {
//                let fm = NumberFormatter()
//                let amountNumber = fm.number(from: self.request.amount)
//                
//                if self.requestedAsset!.value.isLess(than: amountNumber!.doubleValue) {
//                    //insufficient balance
//                    cell.accessoryView = nil
//                    cell.accessoryType = .detailButton
//                    cell.accessoryView?.tintColor = UIColor.red
//                    cell.theme_tintColor = O3Theme.negativeLossColorPicker
//                } else {
//                    cell.accessoryType = .none
//                    cell.accessoryView = nil
//                }
//            } else {
//                let v = UIActivityIndicatorView(style: .gray)
//                v.startAnimating()
//                cell.accessoryView = v
//            }
//        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let info = data[indexPath.row]
        if info.key.lowercased() == dataKey.asset.rawValue.lowercased() && self.requestedAsset != nil {
            self.showInsufficientBalancePopup()
            
        }
    }
    
    //mark: -
    
    func showInsufficientBalancePopup() {
        //show popup saying insufficient balance
        let message = String(format: "Your balance: %@ %@", self.requestedAsset!.value.string(self.requestedAsset!.decimals, removeTrailing: true), self.requestedAsset!.symbol.uppercased())
        OzoneAlert.alertDialog("Insufficient balance", message: message, dismissTitle: "Dismiss") {
            
        }
    }
    
    @IBAction func didTapCancel(_ sender: Any) {
        onCancel?(message, request)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapConfirm(_ sender: Any) {
        //check balance here
        let fm = NumberFormatter()
        let amountNumber = fm.number(from: self.request.amount)
        
//        if self.requestedAsset!.value.isLess(than: amountNumber!.doubleValue) {
//            //insufficient balance
//            self.showInsufficientBalancePopup()
//            return
//        }
        
        onConfirm?(message, request)
        self.dismiss(animated: true, completion: nil)
    }
}

