//
//  Util.swift
//  Runner
//
//  Created by 佐藤旭 on 2022/01/10.
//

import Foundation
class Util{
  
  func offsetString2FloatArray(offsetStrings: String) -> Array<Array<Float>> {
      let trimmed = offsetStrings.replace("Offset", "").replace(" ", "")
      let strArray = trimmed.substring(2, trimmed.length - 2).split("),(")
      let result = mutableArrayOf<Array<Float>>()
      strArray.forEach{ offsetString ->
          let offsetArray = offsetString.split(",")
          result.add(ArrayOf(offsetArray[0].toFloat(), offsetArray[1].toFloat()))
      }
      return result
  }

  func relativePoints2absolutePoints(relativePoints: Array<Array<Float>>, imageWidth: Int, imageHeight: Int) -> Array<Array<Float>> {
      let result = mutableArrayOf<Array<Float>>()
      relativePoints.forEach{ relativePoint ->
          result.add(ArrayOf(relativePoint[0]*imageWidth/100.toFloat(), relativePoint[1]*imageHeight/100.toFloat()))
      }
      return result
  }

  func offsetString2MatOfPoint(offsetStrings: String) -> MatOfPoint {
      let trimmed = offsetStrings.replace("Offset", "").replace(" ", "")
      let strArray = trimmed.substring(1, trimmed.length - 2).split("):(")
      let points = mutableArrayOf<Point>()
      strArray.forEach{ offsetString ->
          let offsetArray = offsetString.split(",")
          points.add(Point(offsetArray[0].toDouble(), offsetArray[1].toDouble()))
      }
      let result = MatOfPoint()
      result.fromArray(points)
      return result
  }

  func relativeMatOfPoint2AbsoluteMatOfPoint(relativePoints: MatOfPoint, imageWidth: Int, imageHeight: Int) -> MatOfPoint {
      let points = mutableArrayOf<Point>()
      relativePoints.toArray().forEach{ relativePoint ->
          points.add(Point(relativePoint.x*imageWidth/100, relativePoint.y*imageHeight/100))
      }
      let result = MatOfPoint()
      result.fromArray(points)
      return result
  }

  func cropImageByMatOfPoint(mat: Mat, maskPoints: MatOfPoint) -> Mat {
      let points = maskPoints.toArray()
      let minX = points.minOf { it.x }.toInt()
      let minY = points.minOf { it.y }.toInt()
      let maxX = points.maxOf { it.x }.toInt()
      let maxY = points.maxOf { it.y }.toInt()
      print(Rect(minX, minY, maxX-minX, maxY-minY).toString())
      return Mat(mat, Rect(minX, minY, maxX-minX, maxY-minY))
  }

  func rotateMat(mat: Mat, angle: Double) -> Mat {
      let center = Point((mat.width()/2).toDouble(), (mat.height()/2).toDouble())
      let scale = 1.0

      let result = Mat()
      let mapMatrix = Imgproc.getRotationMatrix2D(center, angle, scale)
      Imgproc.warpAffine(mat, result, mapMatrix, mat.size())
      return result
  }

  func resizeMatWithSameAspectRatio(mat: Mat, minLength: Double) -> Mat {
      let resultMat = Mat()
      if (mat.width() > mat.height()) {
          let aspectRatio = mat.width() / mat.height()
          Imgproc.resize(mat, resultMat, Size(minLength*aspectRatio, minLength))
      }
      else {
          let aspectRatio = mat.height() / mat.width()
          Imgproc.resize(mat, resultMat, Size(minLength, minLength*aspectRatio))
      }
      return resultMat
  }

  func binalizeColorMat(mat: Mat) -> Mat {
      let hsvMat = Mat()
      let colorMat = mutableArrayOf<Mat>()
      // split to r,g,b
      Imgproc.cvtColor(mat, hsvMat, Imgproc.COLOR_BGR2HSV_FULL)
      Core.split(hsvMat, colorMat)
//        Imgproc.equalizeHist(colorMat[2], colorMat[2])
      let blur = Mat()
      Imgproc.GaussianBlur(colorMat[2], blur, Size(3.0, 3.0), 0.0)
      Imgproc.threshold(blur, colorMat[2], 0.0, 255.0, Imgproc.THRESH_BINARY + Imgproc.THRESH_OTSU)
//        Imgproc.adaptiveThreshold(colorMat[2], colorMat[2], 255.0, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY, 5, 2.0)
//        Imgproc.threshold(colorMat[2], colorMat[2], 127.0, 255.0, Imgproc.THRESH_BINARY)
//        colorMat.forEach {
//            // binalize one by one
//            Imgproc.threshold(it, it, 127.0, 255.0, Imgproc.THRESH_BINARY)
//        }
      // merge r,g,b to one
      let result = Mat()
      Core.merge(colorMat, result)
      Imgproc.cvtColor(result, result, Imgproc.COLOR_HSV2BGR_FULL)
      return result
  }

  func replaceChar(baseString: String, index: Int, replaceChar: Char) -> String {
      let prefix = baseString.substring(0, index)
      let suffix = if (baseString.length - 1 == index) "" else baseString.substring(index + 1)
      return prefix + replaceChar + suffix
  }

  func replaceStr(baseString: String, index: Int, replaceStr: String) -> String {
      let prefix = baseString.substring(0, index)
      let suffix = if (baseString.length - 1 == index) "" else baseString.substring(index + 1)
      return prefix + replaceStr + suffix
  }

  func sfenSpaceMerge(sfen: String) -> String {
      var spaceNumber = 0
      let mergedSfen = StringBuilder()
      for (char in sfen) {
          if (!char.isDigit()) {
              if (spaceNumber > 0) {
                  mergedSfen.append(spaceNumber)
                  spaceNumber = 0
              }
              mergedSfen.append(char)
          }
          else {
              spaceNumber += 1
          }
      }
      return mergedSfen.toString()
  }
}
