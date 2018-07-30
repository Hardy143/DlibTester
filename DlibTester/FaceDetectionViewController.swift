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
        
        SessionHandler.shared.openSession()
        
        let layer = SessionHandler.shared.layer
        layer.frame = preview.bounds
        preview.layer.addSublayer(layer)
        view.layoutIfNeeded()
    }
    
    
    @IBAction func buttonTouched(_ sender: Any) {
        
        if !SessionHandler.shared.isRecording {
            SessionHandler.shared.start()
            recordButton.setTitle("Recording", for: .normal)
            SessionHandler.shared.isRecording = true
        } else {
            SessionHandler.shared.stop()
            recordButton.setTitle("Record", for: .normal)
            performSegue(withIdentifier: "previewVideo", sender: nil)
            SessionHandler.shared.isRecording = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is VideoPreviewViewController {
            let preview = segue.destination as? VideoPreviewViewController
            preview?.fileLocation = SessionHandler.shared.outputUrl
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
