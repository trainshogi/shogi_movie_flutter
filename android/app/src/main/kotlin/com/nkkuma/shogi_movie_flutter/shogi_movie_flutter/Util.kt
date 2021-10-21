package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter

import org.opencv.core.*
import org.opencv.imgproc.Imgproc

class Util {

    fun offsetString2FloatList(offsetStrings: String): List<List<Float>> {
        val trimmed = offsetStrings.replace("Offset", "").replace(" ", "")
        val strlist = trimmed.substring(2, trimmed.length - 2).split("),(")
        val result = mutableListOf<List<Float>>()
        strlist.forEach{ offsetString ->
            val offsetList = offsetString.split(",")
            result.add(listOf(offsetList[0].toFloat(), offsetList[1].toFloat()))
        }
        return result
    }

    fun relativePoints2absolutePoints(relativePoints: List<List<Float>>, imageWidth: Int, imageHeight: Int): List<List<Float>> {
        val result = mutableListOf<List<Float>>()
        relativePoints.forEach{ relativePoint ->
            result.add(listOf(relativePoint[0]*imageWidth/100.toFloat(), relativePoint[1]*imageHeight/100.toFloat()))
        }
        return result
    }

    fun offsetString2MatOfPoint(offsetStrings: String): MatOfPoint {
        val trimmed = offsetStrings.replace("Offset", "").replace(" ", "")
        val strlist = trimmed.substring(1, trimmed.length - 2).split("):(")
        val points = mutableListOf<Point>()
        strlist.forEach{ offsetString ->
            val offsetList = offsetString.split(",")
            points.add(Point(offsetList[0].toDouble(), offsetList[1].toDouble()))
        }
        val result = MatOfPoint()
        result.fromList(points)
        return result
    }

    fun relativeMatOfPoint2AbsoluteMatOfPoint(relativePoints: MatOfPoint, imageWidth: Int, imageHeight: Int): MatOfPoint {
        val points = mutableListOf<Point>()
        relativePoints.toList().forEach{ relativePoint ->
            points.add(Point(relativePoint.x*imageWidth/100, relativePoint.y*imageHeight/100))
        }
        val result = MatOfPoint()
        result.fromList(points)
        return result
    }

    fun cropImageByMatOfPoint(mat: Mat, maskPoints: MatOfPoint): Mat {
        val points = maskPoints.toList()
        val minX = points.minOf { it.x }.toInt()
        val minY = points.minOf { it.y }.toInt()
        val maxX = points.maxOf { it.x }.toInt()
        val maxY = points.maxOf { it.y }.toInt()
        print(Rect(minX, minY, maxX-minX, maxY-minY).toString())
        return Mat(mat, Rect(minX, minY, maxX-minX, maxY-minY))
    }

    fun rotateMat(mat: Mat, angle: Double): Mat {
        val center = Point((mat.width()/2).toDouble(), (mat.height()/2).toDouble())
        val scale = 1.0

        val result = Mat()
        val mapMatrix = Imgproc.getRotationMatrix2D(center, angle, scale)
        Imgproc.warpAffine(mat, result, mapMatrix, mat.size())
        return result
    }

    fun binalizeColorMat(mat: Mat): Mat {
        val hsvMat = Mat()
        val colorMat = mutableListOf<Mat>()
        // split to r,g,b
        Imgproc.cvtColor(mat, hsvMat, Imgproc.COLOR_BGR2HSV_FULL)
        Core.split(hsvMat, colorMat)
//        Imgproc.equalizeHist(colorMat[2], colorMat[2])
        val blur = Mat()
        Imgproc.GaussianBlur(colorMat[2], blur, Size(3.0, 3.0), 0.0)
        Imgproc.threshold(blur, colorMat[2], 0.0, 255.0, Imgproc.THRESH_BINARY + Imgproc.THRESH_OTSU)
//        Imgproc.adaptiveThreshold(colorMat[2], colorMat[2], 255.0, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY, 5, 2.0)
//        Imgproc.threshold(colorMat[2], colorMat[2], 127.0, 255.0, Imgproc.THRESH_BINARY)
//        colorMat.forEach {
//            // binalize one by one
//            Imgproc.threshold(it, it, 127.0, 255.0, Imgproc.THRESH_BINARY)
//        }
        // merge r,g,b to one
        val result = Mat()
        Core.merge(colorMat, result)
        Imgproc.cvtColor(result, result, Imgproc.COLOR_HSV2BGR_FULL)
        return result
    }

    fun replaceChar(baseString: String, index: Int, replaceChar: Char): String {
        val prefix = baseString.substring(0, index)
        val suffix = if (baseString.length - 1 == index) "" else baseString.substring(index + 1)
        return prefix + replaceChar + suffix
    }

    fun replaceStr(baseString: String, index: Int, replaceStr: String): String {
        val prefix = baseString.substring(0, index)
        val suffix = if (baseString.length - 1 == index) "" else baseString.substring(index + 1)
        return prefix + replaceStr + suffix
    }

    fun sfenSpaceMerge(sfen: String): String {
        var spaceNumber = 0
        val mergedSfen = StringBuilder()
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