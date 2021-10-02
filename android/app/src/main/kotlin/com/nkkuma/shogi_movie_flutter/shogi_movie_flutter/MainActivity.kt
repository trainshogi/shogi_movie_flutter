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
import java.lang.StringBuilder
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.coroutineContext
import kotlin.coroutines.suspendCoroutine


class MainActivity: FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/battery"

    private val CHANNEL_PieceDetect = "com.nkkuma.dev/piece_detect"

//    private val SPACE_SIZE = 64
    private val SPACE_WIDTH = 64
    private val SPACE_HEIGHT = 70 // = (64 * 34.8 / 31.7).toInt()
    val pieceNameListJapanese = listOf(
        "歩兵", "香車", "桂馬", "銀将", "金将", "角行", "飛車", "王将", "玉将",
        "と金", "成香", "成桂", "成銀", "竜馬", "龍王"
    )
    val pieceNameListEnglish = listOf(
//        "vfu"
        "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou", "gyoku", "vfu", "vkyo", "vkei", "vgin", "vkin", "vkaku", "vhisya", "vou", "vgyoku"
//        "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou",
//        "nfu", "nkyo", "nkei", "ngin", "nkaku", "nhisya"
    )
    val pieceNameListSfen = listOf(
//        "p"
        "P", "L", "N", "S", "G", "B", "R", "K", "K", "p", "l", "n", "s", "g", "b", "r", "k", "k"
//        "P", "L", "N", "S", "G", "B", "R", "K",
//        "+P", "+L", "+N", "+S", "+B", "+R"
    )
    private val pieceSizeList = listOf(64, 62, 60, 58, 56, 54, 52, 50, 48, 47, 46, 45, 44, 43, 42, 41, 40, 37, 35)
//    private val pieceSizeList = listOf(46, 45, 44, 43, 42, 41, 40, 39, 38, 37, 36, 35)
//    private val pieceRotateList = listOf(20, 15, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -15, -20)
    private val pieceRotateList = listOf(20, 15, 10, 5, 0, -5, -10, -15, -20)

    private val MATCH_THRESHOLD = 0.65

    val fileController = FileController()
    val util = Util()

    @RequiresApi(VERSION_CODES.N)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        GeneratedPluginRegistrant.registerWith(this)

        MethodChannel(flutterEngine!!.getDartExecutor(), CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()
                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }

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
                val resultJson = getCurrentPosition(
                    srcpath = srcPath,
                    dirName = dirName,
                    relativePoints = pointsFloatList,
//                    piecesSize = null
                    piecesSize = listOf(37, 42, 43, 47, 47, 48, 50, 50, 50, 37, 42, 43, 47, 47, 48, 50, 50, 50)
                )
                result.success(resultJson)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }
        return batteryLevel
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

    private fun matchTemplateWithRotate(pieceRotate: Int, resizedPieceMat: Mat, resizedMaskMat: Mat, matCropped: Mat): Set<Point> {
        val foundSpaces = mutableSetOf<Point>()
        // rotate piece image
        val rotatedPieceMat = util.rotateMat(resizedPieceMat, pieceRotate.toDouble())
        val rotatedMaskMat = util.rotateMat(resizedMaskMat, pieceRotate.toDouble())
        // threshold to 127
        // matchTemplate > threshold(0.65)
        val result = Mat()
        Imgproc.matchTemplate(matCropped, rotatedPieceMat, result, Imgproc.TM_CCOEFF_NORMED, rotatedMaskMat)
        Imgproc.threshold(result, result, MATCH_THRESHOLD, 1.0, Imgproc.THRESH_TOZERO);
        // add place to foundlist
        for (i in 0 until result.rows()) {
            for (j in 0 until result.cols()) {
                if (result[i, j][0] > 0) {
                    foundSpaces.add(Point(
                        ((j + rotatedPieceMat.cols()/2)/SPACE_WIDTH).toDouble(),
                        ((i + rotatedPieceMat.rows()/2)/SPACE_HEIGHT).toDouble()
                    ))
                    Imgproc.rectangle(
                        matCropped,
                        Point(j.toDouble(), i.toDouble()),
                        Point((j + rotatedPieceMat.cols()).toDouble(), (i + rotatedPieceMat.rows()).toDouble()),
                        Scalar(0.0, 0.0, 255.0)
                    )
                }
            }
        }
        return foundSpaces
    }

    // crop image and matchTemplate pieces
    @RequiresApi(VERSION_CODES.N)
    private fun getCurrentPosition(
        srcpath: String,
        dirName: String,
        relativePoints: List<List<Float>>,
        piecesSize: List<Int>?
    ): String? {
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
            // binalize
            Imgproc.cvtColor(croppedPieceMat, croppedPieceMat, Imgproc.COLOR_BGR2GRAY)
//            Imgproc.cvtColor(croppedMaskMat, croppedMaskMat, Imgproc.COLOR_BGR2GRAY)
//            croppedPieceMat = util.binalizeColorMat(croppedPieceMat)
//            croppedMaskMat = util.binalizeColorMat(croppedMaskMat)
            // if piece name starts v, reverse image
            if (secondHandPiece) {
                croppedPieceMat = util.rotateMat(croppedPieceMat,180.0)
                croppedMaskMat = util.rotateMat(croppedMaskMat,180.0)
            }

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
                    foundSpaces.addAll(matchTemplateWithRotate(pieceRotate, resizedPieceMat, resizedMaskMat, matCropped))
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

}
