//
//  CameraManager.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/2/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import AVFoundation

enum PermissionStatus {
  case success
  case error(errorString: String)
}

struct CameraManager {
  static func verifyPermission(handler: @escaping (PermissionStatus) -> Void) {
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
}
