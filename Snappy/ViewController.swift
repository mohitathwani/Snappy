//
//  ViewController.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/2/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    CameraManager.verifyPermission { (permission) in
      switch permission {
      case .success:
        print("Success")
        
      case .error(let errorString):
        print(errorString)
      }
      
    }
  }


}

