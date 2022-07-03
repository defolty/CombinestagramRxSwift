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

import UIKit
import RxSwift
import RxRelay

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  /// disposeBag принадлежит viewController.
  /// Как только контроллер представления будет освобожден, все ваши наблюдаемые подписки также будут отписаны
  /// Это делает управление памятью подписок Rx очень простым:
  /// просто бросьте подписки в пакет, и они будут утилизированы вместе с деаллокацией контроллера представления.
  /// Note: Однако для данного конкретного контроллера представления этого не произойдет,
  /// поскольку это корневой viewController, и он не будет освобожден до завершения работы приложения
  private let disposeBag = DisposeBag()
  private let images = BehaviorRelay<[UIImage]>(value: [])
  
  private var imageCache = [Int]()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    bindImages()
    bindUI()
  }
  
  @IBAction func actionClear() {
    // очистить массив
    images.accept([])
    imageCache = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    /// вызываем PhotoWriter.save(image), чтобы сохранить текущий коллаж
    PhotoWriter.save(image)
      /// преобразуем возвращаемую `Observable` в `Single`,
      /// гарантируя, что ваша подписка получит не более одного элемента
      /// и выводим сообщение об успехе `onSuccess` или ошибке `onError`
      .asSingle()
      .subscribe(
        onSuccess: { [weak self] id in
          self?.showMessage("Saved with ID: \(id)")
          self?.actionClear() /// очищаем текущий коллаж, если операция записи прошла успешно.
        },
        onError: { [weak self] error in
          self?.showMessage("Error", description: error.localizedDescription)
        })
    
      .disposed(by: disposeBag)
  }

  @IBAction func actionAdd() {
    /*
    // Сначала вы получаете последнюю коллекцию изображений, испускаемую relay, получая ее через свойство value,
    //                             а затем добавляете к ней еще одно изображение
    let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
    // Далее вы используете функцию relay accept(_), чтобы передать обновленный набор изображений всем наблюдателям, подписанным на relay.
    // Начальное значение relay images - пустой массив, и каждый раз, когда пользователь нажимает кнопку +,
    // последовательность наблюдаемых создаваемая images, испускает новое событие .next с новым массивом в качестве элемента.
    images.accept(newImages)
     -
     */
     
    let photosViewController = storyboard!.instantiateViewController(
      withIdentifier: "PhotosViewController") as! PhotosViewController

    navigationController!.pushViewController(photosViewController, animated: true)
    
    /// `observable-practise`
    /// Перед тем как пушить контроллер, вы подписываетесь на события его наблюдаемой `selectedPhotos`.
    /// Вас интересуют два события: `.next`, которое означает, что пользователь нажал на фотографию, а также когда подписка будет удалена.
    
    let newPhotos = photosViewController.selectedPhotos
      .share()
    
    newPhotos
      /// `takeWhile(...)` будет пропускать фотографии до тех пор, пока общее количество изображений в коллаже меньше 6.
      /// используем `?? nil coalescing operator`, чтобы по умолчанию установить значение 0, если self равно `nil`
      /// Это делается для того, чтобы удовлетворить компилятор и избежать принудительного разворачивания `self`
      .takeWhile { [weak self] image in
        let count = self?.images.value.count ?? 0
        return count < 6
      }
      .filter({ newImage in
        /// каждая фотография, которую выдает newPhotos, должна будет пройти проверку, прежде чем попасть к подписчику.
        /// .filter будет проверять, больше ли ширина изображения, чем его высота, и если да, то он пропустит его.
        /// Фотографии в портретной ориентации будут отброшены.
        return newImage.size.width > newImage.size.height
      })
      .filter { [weak self] newImage in
        /// получаем данные PNG для нового изображения и сохраняем их количество байт в виде константы `lenght`
        let lenght = newImage.pngData()?.count ?? 0
        /// Если `imageCache` содержит число с таким же значением, вы предполагаете,
        /// что изображение не уникально, и отбрасываете его, возвращая `false`
        guard self?.imageCache.contains(lenght) == false else {
          return false
        }
        /// если изображение уникально для коллажа, сохраняем его длину байта в `imageCache` и возвращаете `true`
        self?.imageCache.append(lenght)
        return true
      }
      .subscribe(
        onNext: { [weak self] newImage in
          guard let images = self?.images else { return }
          images.accept(images.value + [newImage])
        },
        onDisposed: {
          print("completed photo selection")
        }
      )
      .disposed(by: disposeBag)
    
    newPhotos
      .ignoreElements()
      .subscribe(onCompleted: { [weak self] in
        self?.updateNavigationIcon()
      })
      .disposed(by: disposeBag)
  }
  
  private func updateNavigationIcon() {
    let icon = imagePreview.image?
      .scaled(CGSize(width: 22,
                     height: 22))
      .withRenderingMode(.alwaysOriginal)
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                       style: .done,
                                                       target: nil,
                                                       action: nil)
  }
  
  private func bindImages() {
    images
      ///# `throttle(_:scheduler:)` фильтрует любые элементы, за которыми следует другой элемент в течение заданного интервала времени
      ///# Таким образом, если пользователь выберет фотографию и через 0,2 секунды коснется другой, то
      ///# `throttle` отфильтрует первый элемент и пропустит только второй.
      ///# Это избавит нас от работы по созданию первого промежуточного коллажа,
      ///# который сразу же будет устаревшим по сравнению со вторым
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak imagePreview] photos in
        guard let preview = imagePreview else { return }
        preview.image = photos.collage(size: preview.frame.size)
      })
    
      .disposed(by: disposeBag)
  }
  
  private func bindUI() {
    images
      .subscribe(onNext: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
    
      .disposed(by: disposeBag)
  }
  
  func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }
  
  func showMessage(_ title: String, description: String? = nil) {
    // with rx ext
    alert(title: title, text: description)
      .subscribe()
    
      .disposed(by: disposeBag)
    
    /* old
     let alert = UIAlertController(title: title,
                                   message: description,
                                   preferredStyle: .alert)
     alert.addAction(UIAlertAction(title: "Close",
                                   style: .default,
                                   handler: { [weak self] _ in self?.dismiss(animated: true,
                                                                            completion: nil)}))
     present(alert, animated: true, completion: nil)
    */
  }
}
 
