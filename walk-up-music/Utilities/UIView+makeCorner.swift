//
//  UIView+makeCorner.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/23/21.
//

import UIKit

extension UIView {
    func makeCorner(withRadius radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.layer.isOpaque = false
    }
}
