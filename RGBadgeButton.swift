//
//  RGBadgeButton.swift
//  Rgbee
//
//  Created by an chieh huang on 2019/12/11.
//  Copyright © 2019 An Chieh Huang. All rights reserved.
//

import Foundation

class RGBadgeButton: UIButton {
    
    var badgeLabel = UILabel()
    
    var badge: String? {
        didSet {
            addBadgeToButon(badge: badge)
        }
    }

    public var badgeBackgroundColor = UIColor(rgba: UIColor.rgbeeMainPurple) {
        didSet {
            badgeLabel.backgroundColor = badgeBackgroundColor
        }
    }
    
    public var badgeTextColor = UIColor.white {
        didSet {
            badgeLabel.textColor = badgeTextColor
        }
    }
    
    public var badgeFont = UIFont.systemFont(ofSize: 12.0) {
        didSet {
            badgeLabel.font = badgeFont
        }
    }
    
    public var badgeEdgeInsets: UIEdgeInsets? {
        didSet {
            addBadgeToButon(badge: badge)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addBadgeToButon(badge: nil)
    }
    
    func addBadgeToButon(badge: String?) {
        badgeLabel.text = badge
        badgeLabel.textColor = badgeTextColor
        badgeLabel.backgroundColor = badgeBackgroundColor
        badgeLabel.font = badgeFont
        badgeLabel.sizeToFit()
        badgeLabel.textAlignment = .center
        let badgeSize = badgeLabel.frame.size
        
        let height = max(18, Double(badgeSize.height) + 5.0)
        let width = max(height, Double(badgeSize.width) + 10.0)
        
        var vertical: Double?
        var horizontal: Double?
        
        if let badgeInset = self.badgeEdgeInsets {
            vertical = Double(badgeInset.top) - Double(badgeInset.bottom)
            horizontal = Double(badgeInset.left) - Double(badgeInset.right)
            
            let pointX = (Double(bounds.size.width) - 10 + horizontal!)
            let pointY = -(Double(badgeSize.height) / 2) - 10 + vertical!
            badgeLabel.frame = CGRect(x: pointX, y: pointY, width: width, height: height)
        } else {
            let pointX = self.frame.width - CGFloat((width))
            let pointY = CGFloat(0)
            badgeLabel.frame = CGRect(x: pointX, y: pointY, width: CGFloat(width), height: CGFloat(height))
        }
        
        badgeLabel.layer.cornerRadius = badgeLabel.frame.height/2
        badgeLabel.layer.masksToBounds = true
        addSubview(badgeLabel)
        badgeLabel.isHidden = (badge != nil && badge != "0") ? false : true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addBadgeToButon(badge: nil)
        
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: shopCartNotification), object: nil, queue: nil, using: {[weak self](_) in
            guard let self = self else {return}
            self.badge = "\(RGShopCartManager.share.productCount)"
        })
    }
}
