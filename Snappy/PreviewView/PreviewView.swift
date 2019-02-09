//
//  PreviewView.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/9/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {

  override class var layerClass: AnyClass {
    return AVCaptureVideoPreviewLayer.self
  }
  
  /// Convenience wrapper to get layer as its statically known type.
  var videoPreviewLayer: AVCaptureVideoPreviewLayer {
    return layer as! AVCaptureVideoPreviewLayer
  }

}
