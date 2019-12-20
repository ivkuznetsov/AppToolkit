//
//  LocalizedLabel.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATLocalizedLabel)
open class LocalizedLabel: UILabel {

    open override func awakeFromNib() {
        super.awakeFromNib()
        if let text = text {
            self.text = NSLocalizedString(text, comment: "")
        }
    }
}
