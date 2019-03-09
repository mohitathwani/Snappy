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
  
  static let sessionQ = DispatchQueue(label: "camera_manager_queue")
  static let mainQ = DispatchQueue.main
  
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
    sessionQ.async {
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        CameraManager.mainQ.async {
          handler(.success)
        }
        
      case .denied:
        CameraManager.mainQ.async {
          handler(.error(errorString: "Camera access has been denied. Please update permission by going to the Settings->Privacy"))
        }
        
      case .restricted:
        CameraManager.mainQ.async {
          handler(.error(errorString: "Camera access has been restricted."))
        }
        
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
          if granted {
            mainQ.async {
              handler(.success)
            }
          }
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
  
  func startCaptureSession()  {
    CameraManager.sessionQ.async {[unowned self] in
      self.captureSession.startRunning()
    }
  }
  
  func capturePhoto(_ completion: @escaping PhotoCaptureCallback) {
    CameraManager.sessionQ.async {[unowned self] in
      guard self.captureSession.isRunning else {
        completion(nil, .error(errorString: "Session is not running"))
        return
      }
      
      self.photoCaptureCallback = completion
      
      let photoSettings = AVCapturePhotoSettings()
      if let _ = self.currentVideoDeviceInput?.device.isFlashAvailable {
        photoSettings.flashMode = .auto
      }
      self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
  }
  
  func toggleCamera(completion: @escaping (CameraManagerStatus) -> Void) {
    CameraManager.sessionQ.async {[unowned self] in
      switch self.currentDevicePosition {
      case .back, .unspecified:
        if let videoDeviceInput = self.currentVideoDeviceInput {
          self.removeInputandOutputFromSession(input: videoDeviceInput)
          self.currentDevicePosition = .front
          
          CameraManager.mainQ.async {
            completion(self.configureCaptureSession())
          }
          
        }
      case .front:
        if let videoDeviceInput = self.currentVideoDeviceInput {
          self.removeInputandOutputFromSession(input: videoDeviceInput)
          self.currentDevicePosition = .back
          
          CameraManager.mainQ.async {
            completion(self.configureCaptureSession())
          }
        }
      }
      
      CameraManager.mainQ.async {
        completion(.error(errorString: "Unexpected error."))
      }
    }
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
    
    CameraManager.sessionQ.async {[unowned self] in
      if let currentDevice = self.currentVideoDeviceInput?.device {
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
}

//Delegate Call Backs
extension CameraManager {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    CameraManager.sessionQ.async {[unowned self] in
      guard let callback = self.photoCaptureCallback,
        let data = photo.fileDataRepresentation() else {
          fatalError("This should never have happened")
      }
      
      CameraManager.mainQ.async {
        callback(data, .success)
      }
    }
  }
  
  func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    CameraManager.sessionQ.async {[unowned self] in
      guard let callback = self.photoCaptureCallback else {
        fatalError("This should never have happened")
      }
      
      CameraManager.mainQ.async {
        callback(nil, .success)
      }
    }
  }
}
