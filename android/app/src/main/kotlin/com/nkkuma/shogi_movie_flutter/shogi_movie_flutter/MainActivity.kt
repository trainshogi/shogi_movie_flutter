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
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import java.io.File
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/battery"

    private val CHANNEL_PieceDetect = "com.nkkuma.dev/piece_detect"

    private val SPACE_SIZE = 64
    val pieceNameListJapanese = listOf(
        "歩兵", "香車", "桂馬", "銀将", "金将", "角行", "飛車", "王将",
        "と金", "成香", "成桂", "成銀", "竜馬", "龍王"
    )
    val pieceNameListEnglish = listOf(
        "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou",
        "nfu", "nkyo", "nkei", "ngin", "nkaku", "nhisya"
    )
    val pieceSizeList = listOf(64, 62, 60, 58, 56, 54, 52, 50, 48, 47, 46, 45, 43, 44, 42, 40, 37, 35)
    val pieceRotateList = listOf(20, 15, 10, 8, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -8,  -10, -15, -20)

    val fileController = FileController()
    val util = Util()

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
                val convertedpath = toPerspectiveTransformationImg(srcpath = srcPath, dirName = dirName, relativePoints = pointsFloatList)
                result.success(convertedpath)
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

    // パースペクティブ変換
    private fun toPerspectiveTransformationImg(srcpath: String, dirName: String, relativePoints: List<List<Float>>): String? {
        // Bitmapを読み込み
        val img = fileController.readImageFromFileWithRotate(srcpath)
        // BitmapをMatに変換する
        val matSource = Mat()
        Utils.bitmapToMat(img, matSource)
        Log.d("OpenCV", matSource.size().toString())

        // 前処理
        val matDest = Mat()
        // グレースケール変換
        Imgproc.cvtColor(matSource, matDest, Imgproc.COLOR_BGR2GRAY)
        // 2値化
        Imgproc.threshold(matDest, matDest, 0.0, 255.0, Imgproc.THRESH_OTSU)

        // convert relativePoints to absolutePoints
        val absolutePoints = util.relativePoints2absolutePoints(relativePoints, img!!.getWidth(), img!!.getHeight())
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
        val width = SPACE_SIZE*9
        val height = SPACE_SIZE*9
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

        // equalizeHist
//        val matHist = Mat(width, height, matCropped.type())
//        Imgproc.equalizeHist(matCropped, matHist)

        // for koma
        pieceNameListEnglish.forEach { pieceName ->
            // Bitmapを読み込み
            val komaImg = fileController.readImageFromFileWithRotate("${dirName}/${pieceName}.jpg")
            // BitmapをMatに変換する
            val matKoma = Mat()
            Utils.bitmapToMat(komaImg, matKoma)
            // create mask image by fillConvexPoly
            val rowPointsString = File("${dirName}/${pieceName}.txt").readText()
            val relativeMatOfPoints = util.offsetString2MatOfPoint(rowPointsString.split("/")[1])
            val matMask = Mat(100, 100, 0)
            Imgproc.fillConvexPoly(matMask, relativeMatOfPoints, Scalar(255.0, 255.0, 255.0))
            // for koma-size
            pieceSizeList.forEach { pieceSize ->
                // resize koma image
                // for koma-rotate
                pieceRotateList.forEach { pieceRotate ->
                    // rotate koma image
                    // threshold to 127
                    // matchTemplate > threshold(0.65)
                    // add place to foundlist
                }
            }
        }

        // create json


        // Mat を Bitmap に変換して保存
        val imgResult = Bitmap.createBitmap(width, height, img!!.config)
        Utils.matToBitmap(matCropped, imgResult)

        return fileController.saveImageToFile(imgResult, getExternalFilesDir(Environment.DIRECTORY_PICTURES))
    }

}
