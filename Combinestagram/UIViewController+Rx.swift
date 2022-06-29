//
//  UIViewController+Rx.swift
//  Combinestagram
//
//  Created by Nikita Nesporov on 29.06.2022.
//  Copyright © 2022 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
  func alert(title: String, text: String?) -> Completable {
    return Completable.create { [weak self] comletable in
      let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
      alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
        comletable(.completed)
      }))
      
      self?.present(alertVC, animated: true, completion: nil)
      return Disposables.create {
        self?.dismiss(animated: true, completion: nil)
      }
    }
  }
}
