//
//  LocalizedButton.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATLocalizedButton)
open class LocalizedButton: UIButton {

    override open func awakeFromNib() {
        super.awakeFromNib()
        if let title = title(for: .normal) {
            self.setTitle(NSLocalizedString(title, comment: ""), for: .normal)
        }
    }
}
