//
//  MediaManager.swift
//  Snappy
//
//  Created by TeraMo Labs on 3/9/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import Foundation
import Photos

enum PhotoManagerStatus {
  case success
  case error(errorString: String)
}
class MediaManager {
  
  static let sessionQ = DispatchQueue(label: "media_manager_queue")
  static let mainQ = DispatchQueue.main
  
  static func verifyPermission(handler: @escaping (PhotoManagerStatus) ->Void) {
    sessionQ.async {
      PHPhotoLibrary.requestAuthorization { (authorization) in
        mainQ.async {
          switch authorization {
          case .authorized:
            handler(.success)
            
          case .denied:
            handler(.error(errorString: "Photo library access has been denied. Please update permission by going to the Settings->Privacy"))
            
          case .restricted:
            handler(.error(errorString: "Photo library access has been restricted."))
            
          case .notDetermined:
            fatalError("This should not have happened")
          }
        }
      }
    }
  }
  
  static func savePhoto(data: Data, completion: @escaping (PhotoManagerStatus)->Void) {
    sessionQ.async {
      PHPhotoLibrary.shared().performChanges({
        let options = PHAssetResourceCreationOptions()
        let creationRequest = PHAssetCreationRequest.forAsset()
        creationRequest.addResource(with: .photo, data: data, options: options)
        
      }) { (success, error) in
        mainQ.async {
          if let error = error {
            print(error.localizedDescription)
            completion(.error(errorString: "Could not save image"))
          }
          completion(.success)
        }
      }
    }
  }
}
