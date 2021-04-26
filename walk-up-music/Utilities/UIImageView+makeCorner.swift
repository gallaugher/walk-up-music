//
//  UIView+makeCorner.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/23/21.
//

import UIKit

extension UIImageView {
    func roundCorner(withRadius radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
}
