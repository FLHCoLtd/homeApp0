//
//  DetailViewController.swift
//  LightSwitch
//
//  Created by alex on 2023/1/16.
//  Copyright © 2023 Ray Wnderlich. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var lbubButton: UIButton!
    @IBOutlet weak var brightSlider: UISlider!
    @IBOutlet weak var brightView: UIView!
    
    var PrevVC: AccessoryViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lbubButton.setImage(UIImage(named: "off"), for: .normal)
        lbubButton.setImage(UIImage(named: "on"), for: .selected)
        lbubButton.adjustsImageWhenHighlighted = false
        lbubButton.contentEdgeInsets = .zero
        lbubButton.adjustsImageWhenDisabled = false
        if let num = PrevVC?.passBright{
            brightSlider.value = Float(num)
        }
      

        lbubButton.layer.shadowOpacity = 0



        if let vc = PrevVC {
            print("vc.passOnoff:",vc.passOnoff)
            lbubButton.isSelected = vc.passOnoff
        }
  
        
  

        brightSlider.addTarget(self, action: #selector(onBrightChange), for: UIControlEvents.valueChanged)

        brightSlider.value = Float(PrevVC?.passBright ??  0)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "返回", style: .plain, target: nil, action: nil)
    }
    func setUIBright(){
        if self.brightSlider.value > 0 && lbubButton.isSelected {
            if let imageView = self.lbubButton.imageView {
                print(" CGFloat(self.brightSlider.value / 100)", CGFloat(self.brightSlider.value / 100))
                imageView.alpha = CGFloat(self.brightSlider.value / 100)
            }
        }else{
            if let imageView = self.lbubButton.imageView {
                imageView.alpha = 1
            }
        }
    }
    @objc func onBrightChange(){
        print ("Write brightSlider done:\(Int(self.brightSlider.value))")
//        setUIBright()
        NotificationCenter.default.post(name: Notification.Name("ReloadCollectionView"), object: nil)

        PrevVC?.passCharacteristic?.writeValue(NSNumber(value: brightSlider.value), completionHandler: { _ in
            self.brightView.alpha = CGFloat(self.brightSlider.value / 100)
        })
    }
    
    @IBAction func onClick(_ sender: UIButton) {
     
        if let vc =  PrevVC {
            lbubButton.isSelected = !vc.passOnoff
        }
//        setUIBright()
        
        NotificationCenter.default.post(name: Notification.Name("ReloadCollectionView"), object: nil)
        if let vc = PrevVC {
            vc.passCharacteristic?.writeValue(vc.passOnoff, completionHandler: { _ in
                
            })
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
