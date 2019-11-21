//
//  AssetSelectorTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 1/23/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit

protocol AssetSelectorDelegate: class {
    func assetSelected(selected: O3WalletNativeAsset, gasBalance: Double)
}

class AssetSelectorTableViewController: UITableViewController {

    var accountState: AccountState!
    weak var delegate: AssetSelectorDelegate?

    enum sections: Int {
        case nativeAssets = 0
        case ontologyAssets
        case nep5Tokens
    }
    var neoAssets = [O3WalletNativeAsset.NEONoBalance(), O3WalletNativeAsset.GASNoBalance()]
    var tokens = [O3WalletNativeAsset]()
    var ontologyAssets = [O3WalletNativeAsset]()

    func addThemedElements() {
        applyNavBarTheme()
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addThemedElements()
        self.title = SendStrings.assetSelectorTitle
        self.loadAccountState()
    }

    func updateCacheAndLocalBalance(accountState: AccountState) {
        for asset in accountState.assets {
            if asset.id.contains(AssetId.neoAssetId.rawValue) {
                neoAssets[0] = asset
            } else {
                neoAssets[1] = asset
            }
        }
        tokens = []
        ontologyAssets = accountState.ontology

        for token in accountState.nep5Tokens {
            tokens.append(token)
        }
    }

    func loadAccountState() {
        O3APIClient(network: AppState.network).getAccountState(address: Authenticated.wallet?.address ?? "") { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    return
                case .success(let accountState):
                    self.updateCacheAndLocalBalance(accountState: accountState)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == sections.nativeAssets.rawValue {
            return neoAssets.count
        }

        if section == sections.ontologyAssets.rawValue {
            return ontologyAssets.count
        }

        return tokens.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == sections.nativeAssets.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nativeasset") as? NativeAssetSelectorTableViewCell else {
                return UITableViewCell(frame: CGRect.zero)
            }

            //NEO
            if indexPath.row == 0 {
                cell.titleLabel.text = "NEO"
                cell.amountLabel.text = neoAssets[0].value.string(0, removeTrailing: true)
                let imageURL = String(format: "https://cdn.testo3.net/img/neo/%@.png", "NEO")
                cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
            }

            //GAS
            if indexPath.row == 1 {
                cell.titleLabel.text = "GAS"
                cell.amountLabel.text = neoAssets[1].value.string(8, removeTrailing: true)
                let imageURL = String(format: "https://cdn.testo3.net/img/neo/%@.png", "GAS")
                cell.iconImageView?.kf.setImage(with: URL(string: imageURL))
            }

            return cell
        }

        if indexPath.section == sections.ontologyAssets.rawValue {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nativeasset") as? NativeAssetSelectorTableViewCell else {
                return UITableViewCell(frame: CGRect.zero)
            }

            cell.titleLabel.text = ontologyAssets[indexPath.row].symbol
            cell.amountLabel.text = ontologyAssets[indexPath.row].value.string(ontologyAssets[indexPath.row].decimals, removeTrailing: true)
            let imageURL = String(format: "https://cdn.testo3.net/img/neo/%@.png", ontologyAssets[indexPath.row].symbol.uppercased())
            cell.iconImageView?.kf.setImage(with: URL(string: imageURL))

            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell-nep5token") as? NEP5TokenSelectorTableViewCell else {
            return UITableViewCell(frame: CGRect.zero)
        }

        let token = tokens[indexPath.row]
        cell.titleLabel.text = token.symbol
        cell.subtitleLabel.text = token.name
        cell.amountLabel.text = token.value.string(token.decimals, removeTrailing: true)

        let imageURL = String(format: "https://cdn.testo3.net/img/neo/%@.png", token.symbol.uppercased())
        cell.iconImageView?.kf.setImage(with: URL(string: imageURL))

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == sections.nativeAssets.rawValue {
            if indexPath.row == 0 {
                //neo
                delegate?.assetSelected(selected: neoAssets[0], gasBalance: neoAssets[1].value)
            } else if indexPath.row == 1 {
                //gas
                delegate?.assetSelected(selected: neoAssets[1], gasBalance: neoAssets[1].value)
            }
        } else if indexPath.section == sections.nep5Tokens.rawValue {
            delegate?.assetSelected(selected: tokens[indexPath.row], gasBalance: neoAssets[1].value)
        } else if indexPath.section == sections.ontologyAssets.rawValue {
            delegate?.assetSelected(selected: ontologyAssets[indexPath.row], gasBalance: neoAssets[1].value)
        }
        self.dismiss(animated: true, completion: nil)
    }
}
