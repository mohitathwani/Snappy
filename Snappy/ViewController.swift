//
//  ViewController.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/2/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  var cameraManager: ICameraManager?
  override func viewDidLoad() {
    super.viewDidLoad()
    
    cameraManager = CameraManager()
    guard let cameraManager = cameraManager else {
      fatalError("cameraManager is nil.")
    }
    
    type(of: cameraManager).verifyPermission { (permission) in
      switch permission {
      case .success:
        print("Success")
        
      case .error(let errorString):
        print(errorString)
      }
    }
  }


}

