package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.graphics.Bitmap
import android.os.Environment
import android.util.Log
import androidx.annotation.RequiresApi
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import java.io.File
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.opencv.core.Mat

import org.opencv.core.Scalar
import kotlin.concurrent.thread
import kotlin.math.max
import kotlin.streams.toList


class MainActivity: FlutterActivity() {

    private val CHANNEL_PieceDetect = "com.nkkuma.dev/piece_detect"

//    private val SPACE_SIZE = 64
    private val SPACE_WIDTH = 64
    private val SPACE_HEIGHT = 70 // = (64 * 34.8 / 31.7).toInt()
    val pieceNameListEnglish = listOf(
        "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou", "gyoku",
        "nfu", "nkyo", "nkei", "ngin", "nkaku", "nhisya",
        "vfu", "vkyo", "vkei", "vgin", "vkin", "vkaku", "vhisya", "vou", "vgyoku",
        "vnfu", "vnkyo", "vnkei", "vngin", "vnkaku", "vnhisya"
    )
    val pieceNameListSfen = listOf(
        "P", "L", "N", "S", "G", "B", "R", "K", "K",
        "+P", "+L", "+N", "+S", "+B", "+R",
        "p", "l", "n", "s", "g", "b", "r", "k", "k",
        "+p", "+l", "+n", "+s", "+b", "+r"
    )

    private val initialPiecePlacement = listOf(
        "vkyo", "vkei", "vgin", "vkin", "vou", "vkin", "vgin", "vkei", "vkyo", "",
        "", "vhisya", "", "", "", "", "", "vkaku", "", "",
        "vfu", "vfu", "vfu", "vfu", "vfu", "vfu", "vfu", "vfu", "vfu", "",
        "", "", "", "", "", "", "", "", "", "",
        "", "", "", "", "", "", "", "", "", "",
        "", "", "", "", "", "", "", "", "", "",
        "fu", "fu", "fu", "fu", "fu", "fu", "fu", "fu", "fu", "",
        "", "kaku", "", "", "", "", "", "hisya", "", "",
        "kyo", "kei", "gin", "kin", "gyoku", "kin", "gin", "kei", "kyo"
    )

    private val pieceSizeList = listOf(64, 62, 60, 58, 56, 54, 52, 50, 48, 46, 44, 42, 40, 38, 36)
    private val pieceRotateList = listOf(20, 15, 10, 5, 0, -5, -10, -15, -20)

    private val MATCH_THRESHOLD = 0.65

    val fileController = FileController()
    val util = Util()

    @RequiresApi(VERSION_CODES.N)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        GeneratedPluginRegistrant.registerWith(this)

        MethodChannel(flutterEngine!!.getDartExecutor(), CHANNEL_PieceDetect).setMethodCallHandler{ call, result ->
            if (call.method == "piece_detect") {

                // load opencv
                if (!OpenCVLoader.initDebug())
                    Log.e("OpenCV", "Unable to load OpenCV!")
                else
                    Log.d("OpenCV", "OpenCV loaded Successfully!")

                // get variable
                val srcPath = call.argument<String>("srcPath").toString()
                val dirName = call.argument<String>("dirName").toString()
                val points = call.argument<String>("points").toString()
                Log.d("OpenCV", srcPath)
                Log.d("OpenCV", dirName)
                Log.d("OpenCV", points)

                // example: perspective covert
                val pointsFloatList = util.offsetString2FloatList(points)
                Log.d("OpenCV", pointsFloatList.toString())
                val resultJson = getCurrentSfen(
                    srcpath = srcPath,
                    dirName = dirName,
                    relativePoints = pointsFloatList,
//                    piecesSize = null
                    piecesSize = listOf(37, 42, 43, 47, 47, 48, 50, 50, 50, 37, 42, 43, 47, 47, 48, 50, 50, 50)
                )
                result.success(resultJson)
            }
            else if (call.method == "piece_place_detect") {
                // get variable
                val srcPath = call.argument<String>("srcPath").toString()
                val dirName = call.argument<String>("dirName").toString()
                val points = call.argument<String>("points").toString()
                Log.d("OpenCV", srcPath)
                Log.d("OpenCV", dirName)
                Log.d("OpenCV", points)

                thread {
                    val rootObjectString = piece_place_detect(srcPath, dirName, points)
                    runOnUiThread {
                        result.success(rootObjectString)
                    }
                }
            }
            else if (call.method == "one_piece_detect") {
                // get variable
                val srcPath = call.argument<String>("srcPath").toString()
                val dirName = call.argument<String>("dirName").toString()
                val points = call.argument<String>("points").toString()
                val space = call.argument<String>("space").toString()
                val pieceNames = call.argument<String>("pieceNames").toString()
                Log.d("OpenCV", srcPath)
                Log.d("OpenCV", dirName)
                Log.d("OpenCV", points)
                Log.d("OpenCV", space)
                Log.d("OpenCV", pieceNames)

                thread {
                    val rootObjectString = one_piece_detect(srcPath, dirName, points, space, pieceNames)
                    runOnUiThread {
                        result.success(rootObjectString)
                    }
                }
            }
            else if (call.method == "initial_piece_detect") {
                // get variable
                val srcPath = call.argument<String>("srcPath").toString()
                val dirName = call.argument<String>("dirName").toString()
                val points = call.argument<String>("points").toString()
                Log.d("OpenCV", srcPath)
                Log.d("OpenCV", dirName)
                Log.d("OpenCV", points)

                thread {
                    val rootObjectString = initial_piece_detect(srcPath, dirName, points)
                    runOnUiThread {
                        result.success(rootObjectString)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun piece_place_detect(srcPath: String, dirName: String, points: String): String {
        // load opencv
        if (!OpenCVLoader.initDebug())
            Log.e("OpenCV", "Unable to load OpenCV!")
        else
            Log.d("OpenCV", "OpenCV loaded Successfully!")

        // example: perspective covert
        val pointsFloatList = util.offsetString2FloatList(points)
        Log.d("OpenCV", pointsFloatList.toString())
        val resultJson = getCurrentPosition(
            srcpath = srcPath,
            relativePoints = pointsFloatList
        )
        return resultJson.toString()
    }

    @RequiresApi(VERSION_CODES.N)
    private fun one_piece_detect(srcPath: String, dirName: String, points: String, space: String, pieceNames: String): String {
        // load opencv
        if (!OpenCVLoader.initDebug())
            Log.e("OpenCV", "Unable to load OpenCV!")
        else
            Log.d("OpenCV", "OpenCV loaded Successfully!")

        // example: perspective covert
        val relativePoints = util.offsetString2FloatList(points)
        val spaceList = space.split(',').map { it.toInt() }
        val pieceNameList = if (pieceNames.isEmpty()) listOf() else pieceNames.split(',')
        Log.d("OpenCV", relativePoints.toString())
        val targetPlaceMat = spaceCroppedMat(srcPath, relativePoints, spaceList)
        val resultJson = detectPiece(
            dirName = dirName,
            pieceNameList = pieceNameList,
            piecesSize = listOf(),
            targetPlaceMat = targetPlaceMat
//                    piecesSize = listOf(37, 42, 43, 47, 47, 48, 50, 50, 50, 37, 42, 43, 47, 47, 48, 50, 50, 50)
        )
        return resultJson.toString()
    }

    @RequiresApi(VERSION_CODES.N)
    private fun initial_piece_detect(srcPath: String, dirName: String, points: String): String {
        // load opencv
        if (!OpenCVLoader.initDebug())
            Log.e("OpenCV", "Unable to load OpenCV!")
        else
            Log.d("OpenCV", "OpenCV loaded Successfully!")

        val relativePoints = util.offsetString2FloatList(points)
        val positionJson = JSONObject(getCurrentPosition(
            srcpath = srcPath,
            relativePoints = relativePoints
        ))

        var sfen = "111111111/111111111/111111111/111111111/111111111/111111111/111111111/111111111/111111111"
        val placeSfen: String = positionJson.get("sfen") as String
        val matCropped = file2crop9x9Mat(srcPath, relativePoints)
        placeSfen.toCharArray().forEachIndexed{ index, char ->
            if (char == 'Z') {
                val pieceNameList = if (initialPiecePlacement[index] == "") listOf() else listOf(initialPiecePlacement[index])
                val targetPlaceMat = spaceCroppedMat(matCropped, listOf(index%10, index/10))
                val detectJsonObject = JSONObject(detectPiece(dirName, pieceNameList, listOf(), targetPlaceMat))
                val pieceNameIndex = pieceNameListEnglish.indexOf(detectJsonObject.getString("piece"))
                if (pieceNameIndex != -1) {
                    sfen = util.replaceStr(sfen, index, pieceNameListSfen[pieceNameIndex])
                }
            }
        }

        // Mat を Bitmap に変換して保存
        val img = fileController.readImageFromFileWithRotate(srcPath)
        val imgResult = Bitmap.createBitmap(matCropped.width(), matCropped.height(), img!!.config)
        Utils.matToBitmap(matCropped, imgResult)
        val imgPath = fileController.saveImageToFile(imgResult, getExternalFilesDir(Environment.DIRECTORY_PICTURES))

        // create json
        val rootObject = JSONObject()
        rootObject.put("imgPath", imgPath)
        rootObject.put("sfen", util.sfenSpaceMerge(sfen))
        Log.d("OpenCV", rootObject.toString())
        return rootObject.toString()
    }

    // perspective transform
    private fun crop9x9Img(matSource: Mat, absolutePoints: List<List<Float>>): Mat {

        Log.d("OpenCV", absolutePoints.toString())

        // sort points if need

        // set points as ptSrc
        val ptSrc = Mat(4, 2, CvType.CV_32F)
        ptSrc.put(0, 0, floatArrayOf(absolutePoints[0][0], absolutePoints[0][1]))
        ptSrc.put(1, 0, floatArrayOf(absolutePoints[1][0], absolutePoints[1][1]))
        ptSrc.put(2, 0, floatArrayOf(absolutePoints[2][0], absolutePoints[2][1]))
        ptSrc.put(3, 0, floatArrayOf(absolutePoints[3][0], absolutePoints[3][1]))
        Log.d("OpenCV", ptSrc.toString())

        // set target as ptDst
        val width = SPACE_WIDTH*9
        val height = SPACE_HEIGHT*9
        val ptDst = Mat(4, 2, CvType.CV_32F)
        ptDst.put(0, 0, floatArrayOf(0.0f, 0.0f))
        ptDst.put(1, 0, floatArrayOf(0.0f, (height - 1).toFloat()))
        ptDst.put(2, 0, floatArrayOf((width - 1).toFloat(), (height - 1).toFloat()))
        ptDst.put(3, 0, floatArrayOf((width - 1).toFloat(), 0.0f))
        Log.d("OpenCV", ptDst.toString())
        // Transformation matrix
        val matTrans = Imgproc.getPerspectiveTransform(ptSrc, ptDst)
        // transform and resize image
        val matCropped = Mat(width, height, matSource.type())
        Imgproc.warpPerspective(matSource, matCropped, matTrans, Size(width.toDouble(), height.toDouble()))

        return matCropped
    }

    private fun file2crop9x9Mat(srcpath: String, relativePoints: List<List<Float>>): Mat {
        // Bitmapを読み込み
        val img = fileController.readImageFromFileWithRotate(srcpath)
        // BitmapをMatに変換する
        val matSource = Mat()
        Utils.bitmapToMat(img, matSource)
        Log.d("OpenCV", matSource.size().toString())

        // convert relativePoints to absolutePoints
        val absolutePoints = util.relativePoints2absolutePoints(relativePoints, img!!.getWidth(), img!!.getHeight())
        Log.d("OpenCV", absolutePoints.toString())

        val matCropped = crop9x9Img(matSource, absolutePoints)
        Imgproc.cvtColor(matCropped, matCropped, Imgproc.COLOR_BGR2GRAY)
        matCropped.convertTo(matCropped, CvType.CV_8UC1)
        return matCropped
    }

    private fun matchTemplateWithRotateAndDetectPlace(pieceRotate: Int, resizedPieceMat: Mat, resizedMaskMat: Mat, matCropped: Mat): Set<Point> {
        val foundSpaces = mutableSetOf<Point>()
        // matchTemplate > threshold(0.65)
        val result = matchTemplateWithRotate(pieceRotate, resizedPieceMat, resizedMaskMat, matCropped)
        Imgproc.threshold(result, result, MATCH_THRESHOLD, 1.0, Imgproc.THRESH_TOZERO);
        // add place to foundlist
        for (i in 0 until result.rows()) {
            for (j in 0 until result.cols()) {
                if (result[i, j][0] > 0) {
                    foundSpaces.add(Point(
                        ((j + resizedPieceMat.cols()/2)/SPACE_WIDTH).toDouble(),
                        ((i + resizedPieceMat.rows()/2)/SPACE_HEIGHT).toDouble()
                    ))
                    Imgproc.rectangle(
                        matCropped,
                        Point(j.toDouble(), i.toDouble()),
                        Point((j + resizedPieceMat.cols()).toDouble(), (i + resizedPieceMat.rows()).toDouble()),
                        Scalar(0.0, 0.0, 255.0)
                    )
                }
            }
        }
        return foundSpaces
    }

    private fun matchTemplateWithRotate(pieceRotate: Int, resizedPieceMat: Mat, resizedMaskMat: Mat, matCropped: Mat): Mat {
        // rotate piece image
        val rotatedPieceMat = util.rotateMat(resizedPieceMat, pieceRotate.toDouble())
        val rotatedMaskMat = util.rotateMat(resizedMaskMat, pieceRotate.toDouble())
        // matchTemplate
        val result = Mat()
        Imgproc.matchTemplate(matCropped, rotatedPieceMat, result, Imgproc.TM_CCOEFF_NORMED, rotatedMaskMat)
        return result
    }

    // crop image and matchTemplate pieces
    @RequiresApi(VERSION_CODES.N)
    private fun getCurrentSfen(srcpath: String, dirName: String, relativePoints: List<List<Float>>, piecesSize: List<Int>?): String? {
        var sfen = "111111111/111111111/111111111/111111111/111111111/111111111/111111111/111111111/111111111"
        // Bitmapを読み込み
        val img = fileController.readImageFromFileWithRotate(srcpath)
        // BitmapをMatに変換する
        var matSource = Mat()
        Utils.bitmapToMat(img, matSource)
        Log.d("OpenCV", matSource.size().toString())

//        Imgproc.cvtColor(matSource, matSource, Imgproc.COLOR_BGR2GRAY)
//        matSource = util.binalizeColorMat(matSource)

        // convert relativePoints to absolutePoints
        val absolutePoints = util.relativePoints2absolutePoints(relativePoints, img!!.getWidth(), img!!.getHeight())
        Log.d("OpenCV", absolutePoints.toString())

        val matCropped = crop9x9Img(matSource, absolutePoints)

        // equalizeHist
//        Imgproc.equalizeHist(matCropped, matCropped)
//        Imgproc.adaptiveThreshold(matCropped, matCropped,
//            255.0, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY,11,
//            10.0
//        )

        // canny
        Imgproc.cvtColor(matCropped, matCropped, Imgproc.COLOR_BGR2GRAY)
//        Imgproc.Canny(matCropped, matCropped, 150.0, 200.0)
//        matCropped.convertTo(matCropped, CvType.CV_8UC1)

        // for piece
        for ((index, pieceName) in pieceNameListEnglish.withIndex()) {
//        pieceNameListEnglish.withIndex().toList().parallelStream().forEach { (index, pieceName) ->
            val croppedMatList = createCroppedMat(dirName, pieceName)
            val croppedPieceMat = croppedMatList[0]
            val croppedMaskMat = croppedMatList[1]

            // for piece size
            val pieceSizeListForPiece = if (piecesSize != null) listOf(piecesSize[index]) else pieceSizeList

            pieceSizeListForPiece.forEach { pieceSize ->
                // resize piece image
                val resizedPieceMat = Mat()
                val resizedMaskMat = Mat()
                val ratio = croppedPieceMat.height().toDouble() / croppedPieceMat.width().toDouble()
                Imgproc.resize(croppedPieceMat, resizedPieceMat, Size(pieceSize.toDouble(), pieceSize*ratio))
                Imgproc.resize(croppedMaskMat, resizedMaskMat, Size(pieceSize.toDouble(), pieceSize*ratio))

                // canny
//                Imgproc.cvtColor(resizedPieceMat, resizedPieceMat, Imgproc.COLOR_BGR2GRAY)
//                Imgproc.Canny(resizedPieceMat, resizedPieceMat, 150.0, 200.0)
//                resizedPieceMat.convertTo(resizedPieceMat, CvType.CV_8UC1)

                // foundSpaces
                val foundSpaces = mutableSetOf<Point>()
                // for piece rotate
                pieceRotateList.parallelStream().forEach { pieceRotate ->
                    foundSpaces.addAll(matchTemplateWithRotateAndDetectPlace(pieceRotate, resizedPieceMat, resizedMaskMat, matCropped))
                }

                // apply to sfen
                foundSpaces.forEach { point ->
                    sfen = util.replaceChar(sfen, (point.y*10+point.x).toInt(), pieceNameListSfen[index].toCharArray()[0])
                }

                Log.d("OpenCV", pieceSize.toString() + ", " + foundSpaces.size.toString() + ", " + foundSpaces.toString())
                // end loop of size
            }
            // end loop of piece
        }


        // Mat を Bitmap に変換して保存
        val imgResult = Bitmap.createBitmap(matCropped.width(), matCropped.height(), img!!.config)
        Utils.matToBitmap(matCropped, imgResult)
        val imgPath = fileController.saveImageToFile(imgResult, getExternalFilesDir(Environment.DIRECTORY_PICTURES))

        // create json
        val rootObject = JSONObject()
        rootObject.put("imgPath", imgPath)
        rootObject.put("sfen", util.sfenSpaceMerge(sfen))
        Log.d("OpenCV", rootObject.toString())

        return rootObject.toString()
    }

    private fun pieceDetectCircleMat(): Mat {
        val circleMat = Mat.zeros(Size(SPACE_WIDTH*9.0, SPACE_HEIGHT*9.0), CvType.CV_8UC1)
        for (i in 0..8) {
            for (j in 0..8) {
                Imgproc.circle(
                    circleMat,
                    Point((SPACE_WIDTH*i+SPACE_WIDTH/2).toDouble(), (SPACE_HEIGHT*j+SPACE_HEIGHT/2).toDouble()),
                    kotlin.math.min(SPACE_WIDTH, SPACE_HEIGHT)/3,
                    Scalar(255.0),
                    -1
                )
            }
        }
        return circleMat
    }

    // crop image and matchTemplate pieces
//    @RequiresApi(VERSION_CODES.N)
    private fun getCurrentPosition(srcpath: String, relativePoints: List<List<Float>>): String {
        // static variable for get piece position
        val pieceExistThreshold = SPACE_HEIGHT * SPACE_WIDTH * 0.01
        var sfen = "111111111/111111111/111111111/111111111/111111111/111111111/111111111/111111111/111111111"
        // Bitmapを読み込み
        val img = fileController.readImageFromFileWithRotate(srcpath)
        // BitmapをMatに変換する
        var matSource = Mat()
        Utils.bitmapToMat(img, matSource)
        Log.d("OpenCV", matSource.size().toString())

        // convert relativePoints to absolutePoints
        val absolutePoints = util.relativePoints2absolutePoints(relativePoints, img!!.getWidth(), img!!.getHeight())
        Log.d("OpenCV", absolutePoints.toString())

        // crop image
        val matCropped = crop9x9Img(matSource, absolutePoints)

        // color to grayscale
        Imgproc.cvtColor(matCropped, matCropped, Imgproc.COLOR_BGR2GRAY)
        // grayscale to edge
        Imgproc.Canny(matCropped, matCropped, 150.0, 200.0)
        matCropped.convertTo(matCropped, CvType.CV_8UC1)
        // edge to threshold
        Imgproc.threshold(matCropped, matCropped, 127.0, 255.0, Imgproc.THRESH_BINARY)

        // target circle image
        val targetCircleMat = pieceDetectCircleMat()
        // for space if
        val whiteCountArray = Array(9) { IntArray(9) }
        for (i in 0 until SPACE_HEIGHT*9) {
            for (j in 0 until SPACE_WIDTH*9) {
                if ((targetCircleMat.get(i, j)[0] > 0) && (matCropped.get(i, j)[0] > 0)) {
                    whiteCountArray[i/SPACE_HEIGHT][j/SPACE_WIDTH] += 1
                }
            }
        }
        // if white place number > threshold, exists
        for (i in 0..8) {
            for (j in 0..8) {
                if (whiteCountArray[i][j] > pieceExistThreshold) {
                    sfen = util.replaceChar(sfen, i*10+j, 'Z')
                }
            }
        }

        // Mat を Bitmap に変換して保存
        val imgResult = Bitmap.createBitmap(matCropped.width(), matCropped.height(), img!!.config)
        Utils.matToBitmap(matCropped, imgResult)
        val imgPath = fileController.saveImageToFile(imgResult, getExternalFilesDir(Environment.DIRECTORY_PICTURES))

        // create json
        val rootObject = JSONObject()
        rootObject.put("imgPath", imgPath)
        rootObject.put("sfen", sfen)
        Log.d("OpenCV", rootObject.toString())

        return rootObject.toString()
    }

    private fun spaceCroppedMat(srcpath: String, relativePoints: List<List<Float>>, spaceList: List<Int>): Mat {
        return spaceCroppedMat(file2crop9x9Mat(srcpath, relativePoints), spaceList)
    }

    private fun spaceCroppedMat(matCropped: Mat, spaceList: List<Int>): Mat {
        // crop target place
        val minX = if (SPACE_WIDTH*spaceList[0] - SPACE_WIDTH/4 > 0) SPACE_WIDTH*spaceList[0] - SPACE_WIDTH/4 else 0
        val minY = if (SPACE_HEIGHT*spaceList[1] - SPACE_HEIGHT/4 > 0) SPACE_HEIGHT*spaceList[1] - SPACE_HEIGHT/4 else 0
        val maxX = if (SPACE_WIDTH*(spaceList[0]+1) + SPACE_WIDTH/4 < matCropped.size().width) SPACE_WIDTH*(spaceList[0]+1) + SPACE_WIDTH/4 else matCropped.size().width
        val maxY = if (SPACE_HEIGHT*(spaceList[1]+1) + SPACE_HEIGHT/4 < matCropped.size().height) SPACE_HEIGHT*(spaceList[1]+1) + SPACE_HEIGHT/4 else matCropped.size().height

        val roi = Rect(Point(minX.toDouble(), minY.toDouble()), Point(maxX.toDouble(), maxY.toDouble()))
        return Mat(matCropped, roi)
    }

    // crop image and matchTemplate pieces
    @RequiresApi(VERSION_CODES.N)
    private fun detectPiece(dirName: String, pieceNameList: List<String>, piecesSize: List<Int>, targetPlaceMat: Mat): String {
        // for piece
        val pieceNameListForPiece = if (pieceNameList.isNotEmpty()) pieceNameList else pieceNameListEnglish
//        for ((index, pieceName) in pieceNameListEnglish.withIndex()) {
        val result = pieceNameListForPiece.asSequence().withIndex().toList().map { (index, pieceName) ->
            val croppedMatList = createCroppedMat(dirName, pieceName)
            val croppedPieceMat = croppedMatList[0]
            val croppedMaskMat = croppedMatList[1]
            val ratio = croppedPieceMat.height().toDouble() / croppedPieceMat.width().toDouble()

            // for piece size
            val pieceSizeListForPiece = if (piecesSize.isNotEmpty()) listOf(piecesSize[index]) else pieceSizeList

            pieceSizeListForPiece.stream().map { pieceSize ->
                // if targetSize < resizedSize, return 0.0
                if (targetPlaceMat.size().width <= pieceSize || targetPlaceMat.size().height <= pieceSize*ratio) {
                    0.0
                }
                else {
                    // resize piece image
                    val resizedPieceMat = Mat()
                    val resizedMaskMat = Mat()
                    Imgproc.resize(croppedPieceMat, resizedPieceMat, Size(pieceSize.toDouble(), pieceSize*ratio))
                    Imgproc.resize(croppedMaskMat, resizedMaskMat, Size(pieceSize.toDouble(), pieceSize*ratio))

                    // for piece rotate
                    pieceRotateList.parallelStream().map { pieceRotate ->
                        Core.minMaxLoc(matchTemplateWithRotate(pieceRotate, resizedPieceMat, resizedMaskMat, targetPlaceMat)).maxVal
                    }.toList().maxOrNull() ?: 0.0
                }
            }.toList().maxOrNull() ?: 0.0
            // end loop of piece
        }.withIndex().toList().maxByOrNull { it.value }

        val pieceName = if (result != null) pieceNameListForPiece[result.index] else ""
        val pieceValue = result?.value ?: 0

        // create json
        val rootObject = JSONObject()
        rootObject.put("piece", pieceName)
        rootObject.put("value", pieceValue)
        Log.d("OpenCV", rootObject.toString())

        return rootObject.toString()
    }

    private fun createCroppedMat(dirName: String, pieceName: String): List<Mat> {
        // if piece name starts v, remove v and set second hand piece flag to true
        val secondHandPiece = pieceName[0] == 'v'
        // Bitmapを読み込み
        val filePath = "${dirName}/${pieceName.removePrefix("v")}"
        val pieceImg = fileController.readImageFromFileWithRotate("${filePath}.jpg")
        // BitmapをMatに変換する
        val pieceMat = Mat()
        Utils.bitmapToMat(pieceImg, pieceMat)
        Log.d("OpenCV", pieceMat.size().toString())
        // create mask image by fillConvexPoly
        val rowPointsString = File("${filePath}.txt").readText()
        val pieceRelativePoints = util.offsetString2MatOfPoint(rowPointsString.split("/")[1])
        val pieceAbstractPoints = util.relativeMatOfPoint2AbsoluteMatOfPoint(pieceRelativePoints, pieceImg!!.width, pieceImg.height)
        val maskMat = Mat.zeros(pieceMat.size(), CvType.CV_8U)
        Imgproc.fillConvexPoly(maskMat, pieceAbstractPoints, Scalar(255.0, 255.0, 255.0))
        // crop image
        var croppedPieceMat = util.cropImageByMatOfPoint(pieceMat, pieceAbstractPoints)
        var croppedMaskMat = util.cropImageByMatOfPoint(maskMat, pieceAbstractPoints)
        // resize image to deal easy
        croppedPieceMat = util.resizeMatWithSameAspectRatio(croppedPieceMat, max(SPACE_WIDTH, SPACE_HEIGHT)*2.0)
        croppedMaskMat = util.resizeMatWithSameAspectRatio(croppedMaskMat, max(SPACE_WIDTH, SPACE_HEIGHT)*2.0)
        // binalize
        Imgproc.cvtColor(croppedPieceMat, croppedPieceMat, Imgproc.COLOR_BGR2GRAY)
        // if piece name starts v, reverse image
        if (secondHandPiece) {
            croppedPieceMat = util.rotateMat(croppedPieceMat,180.0)
            croppedMaskMat = util.rotateMat(croppedMaskMat,180.0)
        }
        return listOf(croppedPieceMat, croppedMaskMat)
    }
}
