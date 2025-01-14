//
//  WalletHeaderCollectionCell.swift
//  O3
//
//  Created by Andrei Terentiev on 9/24/17.
//  Copyright © 2017 drei. All rights reserved.
//

import Foundation
import UIKit
import Neoutils
import PKHUD

protocol WalletHeaderCellDelegate: class {
    func didTapLeft()
    func didTapRight()
}

class WalletHeaderCollectionCell: UICollectionViewCell {
    struct Data {
        var type: HeaderType
        var blockchainAccount: NEP6.Account?
        var externalAccount: ExternalAccounts.Account?
        var latestPrice: PriceData
        var previousPrice: PriceData
        var referenceCurrency: Currency
        var selectedInterval: PriceInterval
    }
    enum HeaderType {
        case blockchainAddress
        case combined
        case linkedAccount
    }
    
    
    @IBOutlet weak var walletHeaderLabel: UILabel!
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var percentChangeLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    
    weak var delegate: WalletHeaderCellDelegate?
    
    func setupBlockchainAddress() {
        walletHeaderLabel.text = data?.blockchainAccount!.label
        leftButton.isHidden = false
        percentChangeLabel.isHidden = false
    }

    func setupCombined() {
        walletHeaderLabel.text = PortfolioStrings.portfolioHeaderCombinedHeader
        rightButton.isHidden = false
        leftButton.isHidden = true
        percentChangeLabel.isHidden = false
    }
    
    func setupLinkedAccount() {
        walletHeaderLabel.text = data?.externalAccount?.platform ?? ""
        leftButton.isHidden = false
        percentChangeLabel.isHidden = false
    }
    
    
    var data: WalletHeaderCollectionCell.Data? {
        didSet {
            portfolioValueLabel.theme_textColor = O3Theme.primaryColorPicker
            guard let type = data?.type,
                let latestPrice = data?.latestPrice,
                let previousPrice = data?.previousPrice,
                let referenceCurrency = data?.referenceCurrency,
                let selectedInterval = data?.selectedInterval else {
                    fatalError("Cell is missing type")
            }
            switch type {
            case .blockchainAddress:
                setupBlockchainAddress()
            case .combined:
                setupCombined()
            case .linkedAccount:
                setupLinkedAccount()
            }
            
            
            switch referenceCurrency {
            case .btc:
                portfolioValueLabel.text = "₿"+latestPrice.averageBTC.string(Precision.btc, removeTrailing: true)
                percentChangeLabel.theme_textColor = latestPrice.averageBTC >= previousPrice.averageBTC ? O3Theme.positiveGainColorPicker : O3Theme.negativeLossColorPicker
            default:
                portfolioValueLabel.text = latestPrice.averageFiatMoney().formattedString()
                percentChangeLabel.theme_textColor = latestPrice.average >= previousPrice.average ? O3Theme.positiveGainColorPicker : O3Theme.negativeLossColorPicker
            }
            percentChangeLabel.text = String.percentChangeString(latestPrice: latestPrice, previousPrice: previousPrice,
                                                                 with: selectedInterval, referenceCurrency: referenceCurrency)
            
            if (latestPrice.average - previousPrice.average == 0.0) {
                portfolioValueLabel.theme_textColor = O3Theme.lightTextColorPicker
                percentChangeLabel.theme_textColor = O3Theme.lightTextColorPicker
                portfolioValueLabel.text = Fiat(amount: Float(0.0)).formattedString()
            }
            
            if UserDefaultsManager.privacyModeEnabled {
                portfolioValueLabel.text = "Tap to Reveal"
                portfolioValueLabel.theme_textColor = O3Theme.lightTextColorPicker
            }
        }
    }
    
    override func prepareForReuse() {
        portfolioValueLabel.theme_textColor = O3Theme.lightTextColorPicker
        percentChangeLabel.theme_textColor = O3Theme.lightTextColorPicker
        portfolioValueLabel.text = Fiat(amount: Float(0.0)).formattedString()
        super.prepareForReuse()
    }
    
    override func awakeFromNib() {
        walletHeaderLabel.theme_textColor = O3Theme.lightTextColorPicker
        super.awakeFromNib()
    }
    
    @IBAction func didTapRight(_ sender: Any) {
        delegate?.didTapRight()
    }

    @IBAction func didTapLeft(_ sender: Any) {
        delegate?.didTapLeft()
    }
}
