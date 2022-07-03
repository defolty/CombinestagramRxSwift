//
//  PHPhotoLibrary+Rx.swift
//  Combinestagram
//
//  Created by Nikita Nesporov on 03.07.2022.
//  Copyright © 2022 Underplot ltd. All rights reserved.
//

import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
  static var authorized: Observable<Bool> {
    return Observable.create { observer in
      
      DispatchQueue.main.async {
        if authorizationStatus() == .authorized {
          observer.onNext(true)
          observer.onCompleted()
        } else {
          observer.onNext(false)
          requestAuthorization { newStatus in
            observer.onNext(newStatus == .authorized)
            observer.onCompleted()
          }
        }
      }
       
      ///# Замечание по поводу использования `DispatchQueue.main.async {...}`:
      ///# как правило, ваши наблюдаемые не должны блокировать текущий поток,
      ///# поскольку это может заблокировать ваш пользовательский интерфейс,
      ///# помешать другим подпискам или привести к другим неприятным последствиям.
        
      return Disposables.create()
    }
  }
}
