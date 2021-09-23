package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter

import org.opencv.core.Mat
import org.opencv.core.MatOfPoint
import org.opencv.core.Point
import org.opencv.core.Rect
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
}