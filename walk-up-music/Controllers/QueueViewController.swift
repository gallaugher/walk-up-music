//
//  QueueViewController.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/22/21.
//

import UIKit
import AVFoundation

class QueueViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    
    var badAsses: BadAsses!
    var audioPlayer: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
//        imageView.makeCornerRadio(withRadius: 15.0)
        
        badAsses = BadAsses()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        badAsses.loadData {
            self.badAsses.badAssArray = self.badAsses.badAssArray.filter({$0.queued == true})
            self.badAsses.badAssArray.sort(by: {$0.timePosted < $1.timePosted})

            self.tableView.reloadData()
        }
    }
    
    func playNextSong() {
        let badAss = badAsses.badAssArray[0]
        var lastLetter = ""
        if let letter = badAss.lastName.first {
            lastLetter = " \(letter)."
        }
        
        nameLabel.text = "\(badAss.firstName)\(lastLetter)"
        if badAss.photoURL == "" {
            imageView.image = UIImage(systemName: "person.crop.circle")
        } else {
            guard let url = URL(string: badAss.photoURL) else {return}
            do {
                let data = try Data(contentsOf: url)
                let photoImage = UIImage(data: data)
                imageView.image = photoImage
            } catch {
                print("😡 ERROR: Could not get image from url \(url)")
            }
        }
        songLabel.text = badAss.song
        badAsses.badAssArray[0].loadSong(documentID: badAss.documentID) { (data) in
            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer.delegate = self
                self.audioPlayer.play()
                _ = self.badAsses.badAssArray.removeFirst()
                self.tableView.reloadData()
            } catch {
                print("😡ERROR: Couldn't play audio from data. DocumentID: \(self.badAsses.badAssArray[0].documentID) \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func playButtonPressed(_ sender: UIBarButtonItem) {
        if badAsses.badAssArray.count > 0 {
            playNextSong()
        }
    }
    
}

extension QueueViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return badAsses.badAssArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueueTableViewCell
        cell.badAss = badAsses.badAssArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
}

extension QueueViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if badAsses.badAssArray.count > 0 {
            playNextSong()
        } else {
            nameLabel.text = "No One in Queue"
            imageView.image = UIImage(systemName: "person.circle")
            songLabel.text = ""
        }
    }
    
}
