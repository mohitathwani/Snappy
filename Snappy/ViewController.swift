//
//  ViewController.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/2/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  let cameraManager = CameraManager()
  var permissionGranted = false {
    willSet {
      if newValue == true {
        configureSession()
      }
    }
  }
  
  @IBOutlet weak var previewView: PreviewView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    verifyPermission()
  }

  func verifyPermission() {
    CameraManager.verifyPermission {[unowned self] (permission) in
      switch permission {
      case .success:
        print("Success")
        self.permissionGranted = true
        
      case .error(let errorString):
        print(errorString)
      }
      
    }
  }
  
  func configureSession() {
    let sessionConfigured = cameraManager.configureCaptureSession()
    
    switch sessionConfigured {
    case .success:
      print("Session Configured")
      setupPreviewView()
      
    case .error(let errorString):
      print(errorString)
    }
  }
  
  func setupPreviewView () {
    previewView.videoPreviewLayer.session = cameraManager.captureSession
//    previewView.frame = view.frame
//    view.addSubview(previewView)
    
    cameraManager.captureSession.startRunning()
  }

}

