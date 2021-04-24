//
//  QueueTableViewCell.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/23/21.
//

import UIKit

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

class QueueTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var songLabel: UILabel!
    
    var badAss: BadAss! {
        didSet {
            var lastLetter = ""
            if let letter = badAss.lastName.first {
                lastLetter = " \(letter)."
            }
            nameLabel.text = "\(badAss.firstName)\(lastLetter)"
            let timePosted = badAss.timePosted
            timeLabel.text = "\(dateFormatter.string(from: timePosted))"
            songLabel.text = badAss.song
        }
    }

}
