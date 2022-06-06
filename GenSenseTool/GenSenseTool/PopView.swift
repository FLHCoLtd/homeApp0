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
        
        //首先導航到您的 App Clip 目標的構建設置並為 Active Compilation Condition 構建設置創建一個新值（例如，APPCLIP）。然後，在需要的地方添加對共享代碼的檢查，以排除您不想在 App Clip 中使用的代碼。

        //以下代碼檢查APPCLIP您添加到 Active Compilation Conditions 構建設置的值：

        #if !APPCLIP
        // Code you don't want to use in your App Clip.
            print ("* main app")
        #else
        // Code your App Clip may access.
            print ("* clip app")
        #endif
    }
}
