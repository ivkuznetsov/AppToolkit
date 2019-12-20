//
//  OptionCell.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

class OptionCell: BaseTableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tintColor = textLabel?.tintColor
    }
}
