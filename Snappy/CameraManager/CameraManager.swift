//
//  CameraManager.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/2/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import AVFoundation

enum CameraManagerStatus {
  case success
  case error(errorString: String)
}

struct CameraManager {
  let captureSession = AVCaptureSession()
  var videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
  
  let photoOutput = AVCapturePhotoOutput()
  
  static func verifyPermission(handler: @escaping (CameraManagerStatus) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      handler(.success)
      
    case .denied:
      handler(.error(errorString: "Camera access has been denied. Please update permission by going to the Settings->Privacy"))
      
    case .restricted:
      handler(.error(errorString: "Camera access has been restricted."))
      
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { (granted) in
        if granted {
          handler(.success)
        }
      }
    }
  }
  
  func configureCaptureSession() -> CameraManagerStatus {
    captureSession.beginConfiguration()
    guard let videoDevice = videoDevice,
          let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
          captureSession.canAddInput(videoDeviceInput),
          captureSession.canAddOutput(photoOutput)
    else {
        return .error(errorString: "Error in connecting to the camera.")
    }
    
    
    captureSession.addInput(videoDeviceInput)
    captureSession.sessionPreset = .photo
    captureSession.addOutput(photoOutput)
    captureSession.commitConfiguration()
    return .success
  }
}
