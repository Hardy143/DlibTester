//
//  ViewController.swift
//  DlibTester
//
//  Created by Vicki Larkin on 05/07/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var inSession = false
    
    @IBOutlet weak var startImage: UIImageView!
    @IBOutlet weak var button: UIButton!
    //@IBOutlet weak var preview: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonTouched(_ sender: Any) {
        
       self.performSegue(withIdentifier: "faceDetector", sender: nil)
        
    }
    

    
    
    
}

