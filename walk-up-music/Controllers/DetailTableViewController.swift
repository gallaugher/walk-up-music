//
//  DetailTableViewController.swift
//  walk-up-music
//
//  Created by John Gallaugher on 4/22/21.
//

import UIKit
import MapKit
import GooglePlaces
import MobileCoreServices
import AVFoundation
import UniformTypeIdentifiers
import Firebase

class DetailTableViewController: UITableViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var songTextField: UITextField!
    @IBOutlet weak var hometownTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var playStopButton: UIButton!
    @IBOutlet weak var playInSwitch: UISwitch!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var chooseSongButton: UIButton!
    @IBOutlet weak var lookupHometownButton: UIButton!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    var audioPlayer: AVAudioPlayer!
    var badAss: BadAss!
    var songData = Data()
    var photoImage = UIImage()
    var imagePickerController = UIImagePickerController()
    let playImage = UIImage(systemName: "play.fill")
    let stopImage = UIImage(systemName: "stop.fill")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide keyboard if we tap outside of a field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        imagePickerController.delegate = self
        photoImageView.roundCorner(withRadius: 25.0)
        
        if badAss == nil {
            badAss = BadAss()
        }
        navigationController?.setToolbarHidden(false, animated: false)
        setupMapView()
        updateUserInterface()
    }
    
    func updateUserInterface() {
        let currentUserID = (Auth.auth().currentUser?.uid)
        // Allow updates if this is a new user (postingID is "") or user owns this record
        if currentUserID == badAss.postingUserID || badAss.postingUserID == "" {
            firstNameTextField.isEnabled = true
            lastNameTextField.isEnabled = true
            playInSwitch.isEnabled = true
            saveBarButton.isEnabled = true
            chooseSongButton.isEnabled = true
            lookupHometownButton.isEnabled = true
            addPhotoButton.isEnabled = true
        } else {
            firstNameTextField.isEnabled = false
            lastNameTextField.isEnabled = false
            playInSwitch.isEnabled = false
            saveBarButton.isEnabled = false
            chooseSongButton.isEnabled = false
            lookupHometownButton.isEnabled = false
            addPhotoButton.isEnabled = false
        }
        
        playInSwitch.isOn = badAss.queued
        firstNameTextField.text = badAss.firstName
        lastNameTextField.text = badAss.lastName
        songTextField.text = badAss.song
        hometownTextField.text = badAss.homeTown
        
        badAss.loadSong(documentID: badAss.documentID) { (data) in
            self.songData = data
            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.playStopButton.setImage(self.stopImage, for: .normal)
                self.audioPlayer.play()
            } catch {
                print("⚠️ WARNING: No valid song loaded yet for this user. DocumentID: \(self.badAss.documentID) \(error.localizedDescription)")
            }
        }
        
        if badAss.photoURL == "" {
            photoImageView.image = UIImage(systemName: "person.crop.circle")
        } else {
            guard let url = URL(string: badAss.photoURL) else {return}
            do {
                let data = try Data(contentsOf: url)
                photoImage = UIImage(data: data) ?? UIImage(systemName: "person.crop.circle")!
                photoImageView.image = photoImage
            } catch {
                print("😡 ERROR: Could not get image from url \(url)")
            }
        }
    }
    
    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(badAss)
        mapView.setCenter(badAss.coordinate, animated: true)
    }
    
    func setupMapView() {
        let regionDistance: CLLocationDegrees = 150000.0
        let region = MKCoordinateRegion(center: badAss.coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        mapView.setRegion(region, animated: true)
    }

    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func updateFromInterface() {
        badAss.firstName = firstNameTextField.text!
        badAss.lastName = lastNameTextField.text!
        badAss.song = songTextField.text!
        badAss.homeTown = hometownTextField.text!
    }
    
    func cameraOrLibraryAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { (_) in
            self.accessPhotoLibrary()
        }
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (_) in
            self.accessCamera()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func turnOffSound() {
        if audioPlayer != nil && audioPlayer.isPlaying {
            playStopButton.setImage(playImage, for: .normal)
            audioPlayer.stop()
        }
    }
    
    @IBAction func addPhotoPressed(_ sender: UIButton) {
        turnOffSound()
        cameraOrLibraryAlert()
    }
    
    @IBAction func addSongPressed(_ sender: UIButton) {
        turnOffSound()
        let supportedTypes: [UTType] = [UTType.mp3, UTType.mpeg4Audio]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func playInPressed(_ sender: UISwitch) {
        badAss.queued = sender.isOn
        if sender.isOn {
            badAss.timePosted = Date()
        }
    }

    @IBAction func playMySong(_ sender: UIButton) {
        if audioPlayer != nil && audioPlayer.isPlaying {
            playStopButton.setImage(playImage, for: .normal)
            audioPlayer.stop()
        } else {
            badAss.loadSong(documentID: badAss.documentID) { (data) in
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.playStopButton.setImage(self.stopImage, for: .normal)
                    self.audioPlayer.play()
                } catch {
                    print("😡ERROR: Couldn't play audio from data. DocumentID: \(self.badAss.documentID) \(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func lookupHometown(_ sender: UIButton) {
        turnOffSound()
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        // Display the autocomplete view controller.
        present(autocompleteController, animated: true, completion: nil)
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        updateFromInterface()
        badAss.saveData(songData: songData, photoImage: photoImage) { (success) in
            if success {
                self.leaveViewController()
            } else {
                self.oneButtonAlert(title: "Save Failed", message: "For some reason, the data would not save to the cloud.")
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
}

extension DetailTableViewController: UIDocumentPickerDelegate {
    
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        // Start accessing a security-scoped resource.
        guard url.startAccessingSecurityScopedResource() else {
            // Handle the failure here.
            return
        }
        // Make sure you release the security-scoped resource when you are done.
        defer { url.stopAccessingSecurityScopedResource() }
        
        
        
//        let documentURL = urls.first!
        let documentURL = url
        
        do {
            let data = try Data(contentsOf: documentURL)
            songData = data
            audioPlayer = try AVAudioPlayer(data: data)
            playStopButton.setImage(stopImage, for: .normal)
            audioPlayer.play()
        } catch {
            print("😡 ERROR: Error reading or playing data \(error.localizedDescription)")
        }
    }
    
}

extension DetailTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            photoImage = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            photoImage = originalImage
        }
        photoImageView.image = photoImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func accessPhotoLibrary() {
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            present(imagePickerController, animated: true, completion: nil)
        } else {
            self.oneButtonAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
}

extension DetailTableViewController: GMSAutocompleteViewControllerDelegate {
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        badAss.homeTown = place.name ?? "Unknown Place"
        hometownTextField.text = badAss.homeTown
        badAss.coordinate = place.coordinate
        updateMap()
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension DetailTableViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playStopButton.setImage(playImage, for: .normal)
    }
    
}
