//
//  UIView+blink.swift
//  GenSenseTool
//
//  Created by alex on 2022/6/29.
//

import Foundation
import UIKit
extension UIView {
    func blink() {
        self.alpha = 1.0;
        UIView.animate(withDuration: 0.2, //Time duration you want,
                       delay: 0.0,
                       options: [.curveEaseInOut],
                       animations: { [weak self] in self?.alpha = 0.2 },
                       completion: { [weak self] _ in self?.alpha = 1.0 })
    }
}
