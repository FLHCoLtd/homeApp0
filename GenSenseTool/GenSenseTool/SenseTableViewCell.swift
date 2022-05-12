//
//  SenseTableViewCell.swift
//  GenSenseTool
//
//  Created by alex on 2022/5/12.
//

import UIKit

class SenseTableViewCell: UITableViewCell {

    @IBOutlet weak var imgSense: UIImageView!
    @IBOutlet weak var lbSenseName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
