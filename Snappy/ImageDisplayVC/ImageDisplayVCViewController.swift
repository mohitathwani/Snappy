//
//  ImageDisplayVCViewController.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/23/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import UIKit

class ImageDisplayVCViewController: UIViewController {
  var imageData: Data?
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let data = imageData {
      imageView.image = UIImage(data: data)
    }
  }
  
  @IBAction func retake(_ sender: UIButton) {
    dismiss(animated: false, completion: nil)
  }
  
  @IBAction func save(_ sender: UIButton) {
    MediaManager.verifyPermission {[unowned self] (status)  in
      switch status {
      case .success :
        if let data = self.imageData {
          MediaManager.savePhoto(data: data, completion: {[unowned self] (status) in
            switch status {
            case .success:
              self.dismiss(animated: false, completion: nil)
              
            case .error(let errorString):
              print(errorString)
            }
          })
        }
        
      case .error(let errorString):
        print(errorString)
      }
    }
  }
}
