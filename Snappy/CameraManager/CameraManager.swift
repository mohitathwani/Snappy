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

typealias PhotoCaptureCallback = (Data?, CameraManagerStatus) -> Void

class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
  
  let captureSession = AVCaptureSession()
  var videoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
  
  let photoOutput = AVCapturePhotoOutput()
  var photoCaptureCallback: PhotoCaptureCallback?
  
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
  
  func capturePhoto(_ completion: @escaping PhotoCaptureCallback) {
    guard captureSession.isRunning else {
      completion(nil, .error(errorString: "Session is not running"))
      return
    }
    
    photoCaptureCallback = completion
    
    let photoSettings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: photoSettings, delegate: self)
  }
}

//Delegate Call Backs
extension CameraManager {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    
    guard let callback = photoCaptureCallback,
          let data = photo.fileDataRepresentation() else {
      fatalError("This should never have happened")
    }
    
    callback(data, .success)
  }
}
