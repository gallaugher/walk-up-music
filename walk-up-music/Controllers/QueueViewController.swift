//
//  QueueViewController.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/22/21.
//

import UIKit
import AVFoundation
import Firebase

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
        
        badAsses = BadAsses()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.roundCorner(withRadius: 25.0)
        
        badAsses.loadData {
            self.badAsses.badAssArray = self.badAsses.badAssArray.filter({$0.queued == true})
            self.badAsses.badAssArray.sort(by: {$0.timePosted < $1.timePosted})
            if self.audioPlayer != nil && self.audioPlayer.isPlaying {
                self.badAsses.badAssArray.removeFirst()
            }
            
            self.tableView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if audioPlayer != nil && audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        
        let currentEmail = Auth.auth().currentUser?.email
        if currentEmail == "john.gallaugher@gmail.com" || currentEmail == "prof.gallaugher@gmail.com" || currentEmail == "gallaugh@bc.edu" {
            self.badAsses.removeAllQueRequests {
                print("All Requests Removed!")
            }
        }
    }
    
    func playNextSong() {
        let badAss = badAsses.badAssArray[0]
        var lastLetter = ""
        if let letter = badAss.lastName.first {
            lastLetter = " \(letter)."
        }
        
        nameLabel.alpha = 0.0
        imageView.alpha = 0.0
        songLabel.alpha = 0.0
        
        nameLabel.text = "\(badAss.firstName)\(lastLetter)"
        if badAss.photoURL == "" {
            imageView.image = UIImage(systemName: "person.crop.circle")
        } else {
            if let url = URL(string: badAss.photoURL) {
                do {
                    let data = try Data(contentsOf: url)
                    let photoImage = UIImage(data: data)
                    imageView.image = photoImage
                } catch {
                    print("😡 ERROR: Could not get image from url \(url)")
                }
            }
        }
        
        UIView.animate(withDuration: 1.0, animations: {
            self.nameLabel.alpha = 1.0
            self.imageView.alpha = 1.0
            self.songLabel.alpha = 1.0
        })
        
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
