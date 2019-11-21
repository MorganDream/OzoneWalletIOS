//
//  AccountHeaderTableViewCell.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/13/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Kingfisher

class AccountHeaderTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var totalAmountLabel: UILabel?
    @IBOutlet var subTitleLabel: UILabel?
    @IBOutlet var assetCountTitleLabel: UILabel?
    @IBOutlet var moreButton: BadgeUIButton?
    @IBOutlet var toggleStateButton: UIButton?
    @IBOutlet weak var dividerView: UIView!
    
    
    var sectionIndex: Int? = 0
    
    @IBOutlet var horizontalStackView: UIStackView?
    var list: [O3WalletNativeAsset]? {
        didSet {
            self.setupView()
        }
    }
    
    func setupView() {
        if list == nil {
            return
        }
        for v in self.horizontalStackView!.subviews {
            v.removeFromSuperview()
        }
        for i in list! {
            let imageURL = String(format: "https://cdn.testo3.net/img/neo/%@.png",i.symbol.uppercased())
            KingfisherManager.shared.retrieveImage(with: URL(string: imageURL)!, options: [], progressBlock: nil) { image, _, _, _  in
                let imageView = UIImageView(image: image)
                imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                self.horizontalStackView?.addArrangedSubview(imageView)
            }
        }
        let spacerView = UIView(frame: CGRect.zero)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.backgroundColor = UIColor.clear
        self.horizontalStackView?.addArrangedSubview(spacerView)
    }
    
    override func awakeFromNib() {
        titleLabel?.theme_textColor = O3Theme.titleColorPicker
        totalAmountLabel?.theme_textColor = O3Theme.titleColorPicker
        contentView.theme_backgroundColor = O3Theme.cardColorPicker
        theme_backgroundColor = O3Theme.cardColorPicker
        dividerView?.theme_backgroundColor = O3Theme.backgroundLightgrey
        super.awakeFromNib()
    }
}
