//
//  FaceDetectionViewController.swift
//  DlibTester
//
//  Created by Vicki Larkin on 05/07/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//

import UIKit
import AVFoundation

class FaceDetectionViewController: UIViewController {
    
    let sessionHandler = SessionHandler()
    var isRecording = false
    
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var recordButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sessionHandler.openSession()
        
        let layer = sessionHandler.layer
        layer.frame = preview.bounds
        preview.layer.addSublayer(layer)
        view.layoutIfNeeded()
    }
    
    
    @IBAction func buttonTouched(_ sender: Any) {
        //sessionHandler.closeSession()
        //self.dismiss(animated: true, completion: nil)
        
        if !isRecording {
            sessionHandler.start()
            recordButton.setTitle("Recording", for: .normal)
        } else {
            sessionHandler.stop()
            print("This is the url: \(sessionHandler.outputUrl)")
            recordButton.setTitle("Record", for: .normal)
            performSegue(withIdentifier: "previewVideo", sender: nil)
        }
        
        isRecording = !isRecording
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VideoPreviewViewController {
            let preview = segue.destination as? VideoPreviewViewController
            preview?.fileLocation = sessionHandler.outputUrl
        }
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
