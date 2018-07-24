//
//  VideoPreviewViewController.swift
//  DlibTester
//
//  Created by Vicki Larkin on 12/07/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class VideoPreviewViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!

    var fileLocation: URL?
    
    //AVPlayer properties
    var player = AVPlayer()
    var playerLayer: AVPlayerLayer!
    var playerItem: AVPlayerItem?
    
    // Key-value observing context
    var playerItemContext = 0
    
    let assetKeys = [
    "playable",
    "hasProtectedContent"
    ]
    
    @IBOutlet weak var videoPreview: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareToPlay()
        self.player.play()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "return", sender: nil)
    }
    
    @IBAction func saveButtonTouched(_ sender: Any) {
        
        addVideoToLibrary()
    }
    
    // MARK: prepare the AVPLayer
    func prepareToPlay() {

        let asset = AVAsset(url: fileLocation!) 
        playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        
        // register as an abserver of the player item's status property
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.videoPreview.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        videoPreview.layer.addSublayer(playerLayer)
        
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            // Switch over status value
            switch status {
                // player item is ready to play
            case .readyToPlay:
                print("Ready to play")
                // player item failed. See error
            case .failed:
                print(handleErrorWithMessage(player.currentItem!.error?.localizedDescription, error: player.currentItem!.error))
                // player item is not yet ready
            case .unknown:
                print("Player not ready")
            }
        }
    }
    
    // add video to photo library
    func addVideoToLibrary() {
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.fileLocation!)
        }, completionHandler: { success, error in
            if success {
                let alert = UIAlertController(title: "Success", message: "Video saved to your library", preferredStyle: .alert)
                let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                print("Successful")
            } else if let error = error {
                print("\(error.localizedDescription)")
            }
        })
    }
    
    // Error message function
    func handleErrorWithMessage(_ message: String?, error: Error? = nil) {
        print("Error occurred with message: \(String(describing: message)), error: \(String(describing: error)).")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
