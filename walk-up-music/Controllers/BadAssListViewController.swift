//
//  BadAssListViewController.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/22/21.
//

import UIKit
import Firebase

class BadAssListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var badAsses: BadAsses!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        badAsses = BadAsses()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        badAsses.loadData {
            // disables + (add) button if the user's record exists
            let currentUserID = (Auth.auth().currentUser?.uid)
            var newUser = true
            for badAss in self.badAsses.badAssArray {
                if badAss.postingUserID == currentUserID {
                    newUser = false
                }
            }
            self.addButton.isEnabled = newUser
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let destination = segue.destination as! DetailTableViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.badAss = badAsses.badAssArray[selectedIndexPath.row]
        }
    }
    
}

extension BadAssListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return badAsses.badAssArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(badAsses.badAssArray[indexPath.row].firstName) \(badAsses.badAssArray[indexPath.row].lastName)"
        cell.detailTextLabel?.text = badAsses.badAssArray[indexPath.row].song
        return cell
    }
    
    
}
