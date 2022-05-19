//
//  PopView.swift
//  GenSenseTool
//
//  Created by alex on 2022/5/18.
//

import UIKit
import HomeKit

class PopView: UIView {
    
    @IBOutlet var lbTitle:UILabel!
    @IBOutlet var tvInfo:UITextView!
 
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    //圓角
    override func layoutSubviews() {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
}
