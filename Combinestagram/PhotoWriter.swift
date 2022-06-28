/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

//import Foundation
import UIKit
import Photos
import RxSwift

class PhotoWriter {
   
  enum Errors: Error {
    case couldNotSavePhoto
  }
  
  ///# создаём `Observable`, который передаём коду, желающему сохранить фотографии:
  ///# `save(_:)` вернет `Observable<String>`,
  ///# потому что после сохранения фотографии будет выдан единственный элемент:
  ///# уникальный локальный идентификатор созданного ассета.
  static func save(_ image : UIImage) -> Observable<String> {
    
    ///# `Observable.create(_)` создает новую `Observable`,
    ///# и нужно добавить всю нужную логику внутри этого последнего кложура.
    return Observable.create { observer in
      
      var savedAssetId: String?
      
      PHPhotoLibrary.shared().performChanges({
        
        ///# В первом кложуре `performChanges(_:completionHandler:)` вы создадите photo asset из предоставленного изображения
        ///# Вы создаете новый photo asset с помощью `PHAssetChangeRequest.creationRequestForAsset(from:)`
        let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
        
        ///# и сохраняете его `ID(String)` в `savedAssetId`
        savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
        
      }, completionHandler: { success, error in
        
        ///# во втором кложуре - либо идентификатор ассета, либо событие `.error`.
        DispatchQueue.main.async {
          if success, let id = savedAssetId {
            observer.onNext(id)
            observer.onCompleted()
          } else {
            observer.onError(error ?? Errors.couldNotSavePhoto)
          }
        }
      })
      return Disposables.create()
    }
  }
}
