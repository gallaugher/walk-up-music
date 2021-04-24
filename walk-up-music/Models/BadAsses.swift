//
//  BadAsses.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/22/21.
//

import Foundation
import Firebase

class BadAsses {
    var badAssArray: [BadAss] = []
    var db: Firestore!
    
    init() {
        db = Firestore.firestore()
    }
    
    func loadData(completed: @escaping () -> ()) {
        db.collection("badAsses").addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("😡 ERROR: adding the snapshot listener \(error!.localizedDescription)")
                return completed()
            }
            self.badAssArray = [] // clean out existing spotArray since new data will load
            // there are querySnapshot!.documents.count documents in the snapshot
            for document in querySnapshot!.documents {
                // You'll have to maek sure you have a dictionary initializer in the singular class
                let badAss = BadAss(dictionary: document.data())
                badAss.documentID = document.documentID
                self.badAssArray.append(badAss)
            }
            completed()
        }
    }
}
