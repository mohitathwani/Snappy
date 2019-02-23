//
//  ImageDisplayVCViewController.swift
//  Snappy
//
//  Created by TeraMo Labs on 2/23/19.
//  Copyright © 2019 TeraMo Labs. All rights reserved.
//

import UIKit

class ImageDisplayVCViewController: UIViewController {
  var image: UIImage?
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
  
  @IBAction func retake(_ sender: UIButton) {
    dismiss(animated: false, completion: nil)
  }
  
  @IBAction func save(_ sender: UIButton) {
    //TODO: Save and then dismiss
    dismiss(animated: false, completion: nil)
  }
}
