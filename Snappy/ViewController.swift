//
//  ViewController.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/2/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import UIKit
import AVFoundation

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
    previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
    
    cameraManager.captureSession.startRunning()
  }

  @IBAction func snap(_ sender: UIButton) {
    
    cameraManager.capturePhoto { [unowned self] (data, status) in
      switch status {
      case .success:
        if data == nil {
          self.flashScreen()
        }
        if let imageDisplayVC = self.storyboard?.instantiateViewController(withIdentifier: "imageDisplayVC") as? ImageDisplayVCViewController,
          let data = data {
          imageDisplayVC.image = UIImage(data: data)
          self.present(imageDisplayVC, animated: false, completion: nil)
        }
        
      case .error(let errorString):
        print(errorString)
      }
    }
  }
  
  func flashScreen() {
    previewView.videoPreviewLayer.opacity = 0
    UIView.animate(withDuration: 0.25) {
      self.previewView.videoPreviewLayer.opacity = 1
    }
  }
  
  @IBAction func toggleCamera(_ sender: UITapGestureRecognizer) {
    let cameraToggled = cameraManager.toggleCamera()
    switch cameraToggled {
    case .success:
      print("You might have to make some UI changes here.")
      
    case .error(let errorString):
      print(errorString)
    }
  }
  @IBAction func focus(_ sender: UITapGestureRecognizer) {
    let focusPoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: sender.location(in: sender.view))
    cameraManager.focusCamera(with: .autoFocus, exposureMode: .autoExpose, at: focusPoint, monitorSubjectAreaChanged: true)
  }
}

