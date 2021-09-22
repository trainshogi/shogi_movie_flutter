package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter

import org.opencv.core.MatOfPoint
import org.opencv.core.Point

class Util {

    fun offsetString2FloatList(offsetStrings: String): List<List<Float>> {
        val trimmed = offsetStrings.replace("Offset", "").replace(" ", "")
        val strlist = trimmed.substring(2, trimmed.length - 2).split("),(")
        val result = mutableListOf<List<Float>>()
        strlist.forEach{ offsetString ->
            val offsetList = offsetString.split(",")
            result.add(listOf<Float>(offsetList[0].toFloat(), offsetList[1].toFloat()))
        }
        return result
    }

    fun relativePoints2absolutePoints(relativePoints: List<List<Float>>, imageWidth: Int, imageHeight: Int): List<List<Float>> {
        val result = mutableListOf<List<Float>>()
        relativePoints.forEach{ relativePoint ->
            result.add(listOf<Float>(relativePoint[0]*imageWidth/100.toFloat(), relativePoint[1]*imageHeight/100.toFloat()))
        }
        return result
    }

    fun offsetString2MatOfPoint(offsetStrings: String): MatOfPoint {
        val trimmed = offsetStrings.replace("Offset", "").replace(" ", "")
        val strlist = trimmed.substring(2, trimmed.length - 2).split("),(")
        val points = mutableListOf<Point>()
        strlist.forEach{ offsetString ->
            val offsetList = offsetString.split(",")
            points.add(Point(offsetList[0].toDouble(), offsetList[1].toDouble()))
        }
        val result = MatOfPoint()
        result.fromList(points)
        return result
    }
}