//
//  FileController.swift
//  Runner
//
//  Created by 佐藤旭 on 2022/01/10.
//

import Foundation
class FileController {
  func getAnswer(orig: Int, add: Int) -> Int {
      var answer: Int = 0
      answer = orig + add
      return answer
  }
  
  func rotateImage(image: UIImage, degree: CGFloat) -> UIImage {
      let radian = -degree * CGFloat.pi / 180
      UIGraphicsBeginImageContext(image.size)
      let context = UIGraphicsGetCurrentContext()!
      context.translateBy(x: image.size.width / 2, y: image.size.height / 2)
      context.scaleBy(x: 1.0, y: -1.0)

      context.rotate(by: radian)
      context.draw(image.cgImage!,
                   in: CGRect(x: -(image.size.width / 2),
                              y: -(image.size.height / 2),
                              width: image.size.width,
                              height: image.size.height))

      let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      return rotatedImage
  }
  
  func saveImage(image: UIImage, path: String) -> Bool {
    let jpgImageData = image.jpegData(compressionQuality:0.5)
    do {
        try jpgImageData!.write(to: URL(fileURLWithPath: path), options: .atomic)
    } catch {
        print(error)
        return false
    }
    return true
  }
}
