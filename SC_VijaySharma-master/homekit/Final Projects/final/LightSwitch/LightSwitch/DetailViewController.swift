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
    @IBOutlet weak var hueSlider: UISlider!
    @IBOutlet weak var satSlider: UISlider!
    @IBOutlet weak var temperSlider: UISlider!
    var PrevVC: AccessoryViewController?
    
    // Init ColorPicker with yellow
    var selectedColor: UIColor = UIColor.white
    
    // IBOutlet for the ColorPicker
    @IBOutlet var colorPicker: SwiftHSVColorPicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        
        lbubButton.setImage(UIImage(named: "off"), for: .normal)
        lbubButton.setImage(UIImage(named: "on"), for: .selected)
//        lbubButton.adjustsImageWhenHighlighted = false
//        lbubButton.contentEdgeInsets = .zero
//        lbubButton.adjustsImageWhenDisabled = false
        
        
        if let num = PrevVC?.passHue{
            hueSlider.value = Float(num)
        }
        if let num = PrevVC?.passSat{
            satSlider.value = Float(num)
        }
        if let num = PrevVC?.passBright{
            brightSlider.value = Float(num)
        }
        
        if let num = PrevVC?.passTemper{
            temperSlider.value = Float(num)
        }
                        
        selectedColor = UIColor(hue: CGFloat(hueSlider.value/360), saturation: CGFloat(satSlider.value/100), brightness: CGFloat(brightSlider.value/100) , alpha: 1.0)
        colorPicker.setViewColor(selectedColor)
        
//        PrevVC?.passCharacteristic?.writeValue(NSNumber(value: hueSlider.value), completionHandler: {_ in
//
//        })
        
//        PrevVC?.passCharacteristic?.writeValue(NSNumber(value: hueSlider.value), completionHandler: nil)
//        PrevVC?.passCharacteristic?.writeValue(NSNumber(value: hueSlider.value), completionHandler: nil)

        lbubButton.layer.shadowOpacity = 0



        if let vc = PrevVC {
            print("vc.passOnoff:",vc.passOnoff)
            lbubButton.isSelected = vc.passOnoff
        }
  
        
        brightSlider.addTarget(self, action: #selector(onBrightChange), for: UIControlEvents.valueChanged)
        hueSlider.addTarget(self, action: #selector(onHueChange), for: UIControlEvents.valueChanged)
        satSlider.addTarget(self, action: #selector(onSaturationChange), for: UIControlEvents.valueChanged)
        temperSlider.addTarget(self, action: #selector(onColorTemperChange), for: UIControlEvents.valueChanged)


//        brightSlider.value = Float(PrevVC?.passBright ??  0)
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
    
    @IBAction func getSelectedColor(_ sender: UIButton) {
        // Get the selected color from the Color Picker.
        
        hueSlider.value = Float(colorPicker.hue*360)
        satSlider.value = Float(colorPicker.saturation*100)
        brightSlider.value = Float(colorPicker.brightness*100)
        PrevVC?.passCharacteristicH?.writeValue(NSNumber(value: hueSlider.value), completionHandler: { _ in
        })
        PrevVC?.passCharacteristicS?.writeValue(NSNumber(value: satSlider.value), completionHandler: { _ in
        })
        PrevVC?.passCharacteristicB?.writeValue(NSNumber(value: brightSlider.value), completionHandler: { _ in
        })
        
        print(selectedColor)
    }
    
   
    @objc func onHueChange(){
        print ("Write hueSlider done:\(Int(self.hueSlider.value))")
        PrevVC?.passCharacteristicH?.writeValue(NSNumber(value: hueSlider.value), completionHandler: { _ in
            self.selectedColor = UIColor(hue: CGFloat(self.hueSlider.value/360), saturation: CGFloat(self.satSlider.value/100), brightness: CGFloat(self.brightSlider.value/100) , alpha: 1.0)
            self.colorPicker.setViewColor(self.selectedColor)
        })
    }
    @objc func onSaturationChange(){
        print ("Write satSlider done:\(Int(self.satSlider.value))")
        PrevVC?.passCharacteristicS?.writeValue(NSNumber(value: satSlider.value), completionHandler: { _ in
            self.selectedColor = UIColor(hue: CGFloat(self.hueSlider.value/360), saturation: CGFloat(self.satSlider.value/100), brightness: CGFloat(self.brightSlider.value/100) , alpha: 1.0)
            self.colorPicker.setViewColor(self.selectedColor)
        })
    }
    @objc func onBrightChange(){
        print ("Write brightSlider done:\(Int(self.brightSlider.value))")
        NotificationCenter.default.post(name: Notification.Name("ReloadCollectionView"), object: nil)

        PrevVC?.passCharacteristicB?.writeValue(NSNumber(value: brightSlider.value), completionHandler: { _ in
            self.selectedColor = UIColor(hue: CGFloat(self.hueSlider.value/360), saturation: CGFloat(self.satSlider.value/100), brightness: CGFloat(self.brightSlider.value/100) , alpha: 1.0)
            self.colorPicker.setViewColor(self.selectedColor)
        })
    }
    
    @objc func onColorTemperChange(){
        print ("Write temperSlider done:\(Int(self.temperSlider.value))")
        PrevVC?.passCharacteristic?.writeValue(NSNumber(value: temperSlider.value), completionHandler: { _ in
          
        })
    }
    
    @IBAction func onClick(_ sender: UIButton) {
     
        if let vc =  PrevVC {
            lbubButton.isSelected = !vc.passOnoff
        }
//        setUIBright()
        
        onHueChange()
        
        
        
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
