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
  var videoDeviceInputs = Set<AVCaptureDeviceInput>()
  var currentDevicePosition = AVCaptureDevice.Position.back
  
  var currentVideoDeviceInput: AVCaptureDeviceInput? {
    get {
      switch currentDevicePosition {
      case .back, .unspecified:
        return videoDeviceInputs.first { $0.device.position == .back}
        
      case .front:
        return videoDeviceInputs.first { $0.device.position == .front}
      }
    }
  }
  
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
  
  override init() {
    if let backVideoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back),
      let videoDeviceInput = try? AVCaptureDeviceInput(device: backVideoDevice)
    {
      videoDeviceInputs.insert(videoDeviceInput)
    }
    
    if let frontVideoDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInTrueDepthCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.front),
      let videoDeviceInput = try? AVCaptureDeviceInput(device: frontVideoDevice)
    {
      videoDeviceInputs.insert(videoDeviceInput)
    }
  }
  
  func configureCaptureSession() -> CameraManagerStatus {
    captureSession.beginConfiguration()
    guard let videoDeviceInput = currentVideoDeviceInput,
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
    if let _ = currentVideoDeviceInput?.device.isFlashAvailable {
      photoSettings.flashMode = .auto
    }
    photoOutput.capturePhoto(with: photoSettings, delegate: self)
  }
  
  func toggleCamera() -> CameraManagerStatus {
    switch currentDevicePosition {
    case .back, .unspecified:
      if let videoDeviceInput = currentVideoDeviceInput {
        removeInputandOutputFromSession(input: videoDeviceInput)
        currentDevicePosition = .front
        return configureCaptureSession()
      }
    case .front:
      if let videoDeviceInput = currentVideoDeviceInput {
        removeInputandOutputFromSession(input: videoDeviceInput)
        currentDevicePosition = .back
        return configureCaptureSession()
      }
    }
    return .error(errorString: "Unexpected error.")
  }
  
  func removeInputandOutputFromSession(input: AVCaptureDeviceInput) {
    captureSession.beginConfiguration()
    captureSession.removeInput(input)
    captureSession.removeOutput(photoOutput)
    captureSession.commitConfiguration()
  }
  
  func focusCamera(with focusMode: AVCaptureDevice.FocusMode,
                   exposureMode: AVCaptureDevice.ExposureMode,
                   at focusPoint: CGPoint,
                   monitorSubjectAreaChanged: Bool) {
    
    if let currentDevice = currentVideoDeviceInput?.device {
      do {
        try currentDevice.lockForConfiguration()
        if currentDevice.isFocusPointOfInterestSupported && currentDevice.isFocusModeSupported(focusMode) {
          currentDevice.focusPointOfInterest = focusPoint
          currentDevice.focusMode = focusMode
        }
        
        if currentDevice.isExposurePointOfInterestSupported && currentDevice.isExposureModeSupported(exposureMode) {
          currentDevice.exposurePointOfInterest = focusPoint
          currentDevice.exposureMode = exposureMode
        }
        
        currentDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChanged //Leave this for crowd to implement
        
        currentDevice.unlockForConfiguration()
      }
      catch {
        print("Unable to lock configuration")
      }
    }
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
  
  func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    guard let callback = photoCaptureCallback else {
      fatalError("This should never have happened")
    }
    
    callback(nil, .success)
  }
}
