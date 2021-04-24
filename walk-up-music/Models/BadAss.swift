//
//  BadAss.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/22/21.
// 

import Foundation
import MapKit
import Firebase

class BadAss: NSObject, MKAnnotation {
    var firstName: String
    var lastName: String
    var homeTown: String
    var coordinate: CLLocationCoordinate2D
    var song: String
    var photoURL: String
    var queued: Bool
    var timePosted: Date
    var postingUserID: String
    var documentID: String
    
    var latitude: CLLocationDegrees {
        return coordinate.latitude
    }
    
    var longitude: CLLocationDegrees {
        return coordinate.longitude
    }
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var title: String? {
        return "\(firstName) \(lastName)"
    }
    
    var subtitle: String? {
        return homeTown
    }
    
    var dictionary: [String: Any] {
        let timeIntervalDate = timePosted.timeIntervalSince1970
        return ["firstName": firstName, "lastName": lastName, "homeTown": homeTown, "latitude": latitude, "longitude": longitude, "song": song, "postedPhotoName" : photoURL, "queued": queued, "date": timeIntervalDate, "postingUserID": postingUserID  ]
    }
    
    init(firstName: String, lastName: String, homeTown: String, coordinate: CLLocationCoordinate2D, song: String, postedPhotoName: String, queued: Bool, timePosted: Date, postingUserID: String, documentID: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.homeTown = homeTown
        self.coordinate = coordinate
        self.song = song
        self.photoURL = postedPhotoName
        self.queued = queued
        self.timePosted = timePosted
        self.postingUserID = postingUserID
        self.documentID = documentID
    }
    
    override convenience init() {
        self.init(firstName: "", lastName: "", homeTown: "", coordinate: CLLocationCoordinate2D(), song: "", postedPhotoName: "", queued: false, timePosted: Date(), postingUserID: "", documentID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let firstName = dictionary["firstName"] as! String? ?? ""
        let lastName = dictionary["lastName"] as! String? ?? ""
        let homeTown = dictionary["homeTown"] as! String? ?? ""
        let latitude = dictionary["latitude"] as! Double? ?? 0.0
        let longitude = dictionary["longitude"] as! Double? ?? 0.0
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let song = dictionary["song"] as! String? ?? ""
        let queued = dictionary["queued"] as! Bool? ?? false
        let timeIntervalDate = dictionary["date"] as! TimeInterval? ?? TimeInterval()
        let timePosted = Date(timeIntervalSince1970: timeIntervalDate)
        let postedPhotoName = dictionary["postedPhotoName"] as! String? ?? ""
        let postingUserID = dictionary["postingUserID"] as! String? ?? ""
        
        self.init(firstName: firstName, lastName: lastName, homeTown: homeTown, coordinate: coordinate, song: song, postedPhotoName: postedPhotoName, queued: queued, timePosted: timePosted, postingUserID: postingUserID, documentID: "")
    }
    
    func saveData(songData: Data, photoImage: UIImage, completion: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // Grab the user ID
        guard let postingUserID = (Auth.auth().currentUser?.uid) else {
            print("😡 ERROR: Could not save data because we don't have a valid postingUserID")
            return completion(false)
        }
        self.postingUserID = postingUserID
        
        // create metadata so that we can see songs in the Firebase Storage Console
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "audio/x-m4a"
        
        // create filename if necessary
        if documentID == "" {
            documentID = postingUserID
        }
        
        // create a storage reference to upload this sound file naming it the same as the postingUserID
        let storageRef = storage.reference().child(documentID)
        
        // create an uplaodTask
        let uploadTask = storageRef.putData(songData, metadata: uploadMetaData) { (metadata, error) in
            if let error = error {
                print("😡 ERROR: upload song for ref \(storageRef) failed. \(error.localizedDescription)")
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            print("Upload Song to Firebase Storage was successful!")
            
//            storageRef.downloadURL { (url, error) in
//                guard error == nil else {
//                    print("😡 ERROR: Couldn't create a download url \(error!.localizedDescription)")
//                    return completion(false)
//                }
//                // Create the dictionary representing data we want to save
//                let dataToSave = self.dictionary
//                let ref = db.collection("badAsses").document(self.documentID)
//                ref.setData(dataToSave) { (error) in
//                    guard error == nil else {
//                        print("😡 ERROR: updating document \(error!.localizedDescription)")
//                        return completion(false)
//                    }
//                    print("💨 Updated document: \(self.documentID)") // It worked!
//                    completion(true)
//                }
//            }
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("ERROR: uplaod task for file \(self.documentID) failed, in spot \(self.documentID), with error \(error.localizedDescription)")
            }
            completion(false)
        }
        
        // AND NOW FOR PHOTO
        // create metadata so that we can see songs in the Firebase Storage Console
        let photoUploadMetaData = StorageMetadata()
        photoUploadMetaData.contentType = "image/jpeg"
        
        // convert photo.image to a Data type so that it can be saved in Firebase Storage
        guard let photoData = photoImage.jpegData(compressionQuality: 0.5) else {
            print("😡 ERROR: Could not convert photo.image to Data.")
            completion(false)
            return
        }
        
        // create a storage reference to upload this image file naming it the same as the postingUserID+photo
        let photoStorageRef = storage.reference().child("\(documentID)-photo")
        
        // create an uplaodTask
        let photoUploadTask = photoStorageRef.putData(photoData, metadata: photoUploadMetaData) { (metadata, error) in
            if let error = error {
                print("😡 ERROR: upload photo for ref \(photoStorageRef) failed. \(error.localizedDescription)")
            }
        }
        
        photoUploadTask.observe(.success) { (snapshot) in
            print("Upload Photo to Firebase Storage was successful!")
            
            photoStorageRef.downloadURL { (url, error) in
                guard error == nil else {
                    print("😡 ERROR: Couldn't create a download url \(error!.localizedDescription)")
                    return completion(false)
                }
                guard let url = url else {
                    print("😡 ERROR: url was nil and this should not have happened because we've already shown there was no error.")
                    return completion(false)
                }
                self.photoURL = "\(url)"
                
                // Create the dictionary representing data we want to save
                let dataToSave = self.dictionary
                let ref = db.collection("badAsses").document(self.documentID)
                ref.setData(dataToSave) { (error) in
                    guard error == nil else {
                        print("😡 ERROR: updating document \(error!.localizedDescription)")
                        return completion(false)
                    }
                    print("💨 Updated document: \(self.documentID)") // It worked!
                    completion(true)
                }
            }
        }
        
        photoUploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("ERROR: uplaod task for file \(self.documentID) failed, in badAss \(self.documentID), with error \(error.localizedDescription)")
            }
            completion(false)
        }
    }
    
    func loadSong(documentID: String, completion: @escaping (Data) -> ()) {
        guard documentID != "" else {
            print("😡 ERROR: did not pass a valid spot into loadImage")
            return
        }
        let storage = Storage.storage()
        let storageRef = storage.reference().child(documentID)
        storageRef.getData(maxSize: 25 * 1024 * 1024) { (data, error) in
            if let error = error {
                print("ERROR: an error occurred while reading data from file ref: \(storageRef) error = \(error.localizedDescription)")
                return completion(Data())
            } else {
                return completion(data!)
            }
        }
    }
}
