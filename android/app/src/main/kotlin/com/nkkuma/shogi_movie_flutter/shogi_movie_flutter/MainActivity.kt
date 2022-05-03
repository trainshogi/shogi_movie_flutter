package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter

import android.os.Build.VERSION_CODES
import android.os.Bundle
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {

    private val CHANNEL_PieceDetect = "com.nkkuma.dev/piece_detect"

    private val serviceActivity = ServiceActivity(context)

    @RequiresApi(VERSION_CODES.N)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        GeneratedPluginRegistrant.registerWith(this)

        MethodChannel(
            flutterEngine!!.dartExecutor,
            CHANNEL_PieceDetect
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "find_contours" -> {
                    // get variable
                    val srcPath = call.argument<String>("srcPath").toString()
                    Log.d("OpenCV", srcPath)

                    thread {
                        val rootObjectString = serviceActivity.findContours(srcPath)
                        runOnUiThread {
                            result.success(rootObjectString)
                        }
                    }
                }
                "piece_place_detect" -> {
                    // get variable
                    val srcPath = call.argument<String>("srcPath").toString()
                    val points = call.argument<String>("points").toString()
                    Log.d("OpenCV", srcPath)
                    Log.d("OpenCV", points)

                    thread {
                        val rootObjectString = serviceActivity.piecePlaceDetect(srcPath, points)
                        runOnUiThread {
                            result.success(rootObjectString)
                        }
                    }
                }
                "one_piece_detect" -> {
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
                        val rootObjectString = serviceActivity.onePieceDetect(
                            srcPath,
                            dirName,
                            points,
                            space,
                            pieceNames
                        )
                        runOnUiThread {
                            result.success(rootObjectString)
                        }
                    }
                }
                "initial_piece_detect" -> {
                    // get variable
                    val srcPath = call.argument<String>("srcPath").toString()
                    val dirName = call.argument<String>("dirName").toString()
                    val points = call.argument<String>("points").toString()
                    Log.d("OpenCV", srcPath)
                    Log.d("OpenCV", dirName)
                    Log.d("OpenCV", points)

                    thread {
                        val rootObjectString =
                            serviceActivity.initialPieceDetect(srcPath, dirName, points)
                        runOnUiThread {
                            result.success(rootObjectString)
                        }
                    }
                }
                "all_piece_detect" -> {
                    // get variable
                    val srcPath = call.argument<String>("srcPath").toString()
                    val dirName = call.argument<String>("dirName").toString()
                    val points = call.argument<String>("points").toString()
                    val piecePlaceListString =
                        call.argument<String>("piecePlaceListString").toString()
                    val pieceNames = call.argument<String>("pieceNames").toString()
                    Log.d("OpenCV", srcPath)
                    Log.d("OpenCV", dirName)
                    Log.d("OpenCV", points)
                    Log.d("OpenCV", piecePlaceListString)
                    Log.d("OpenCV", pieceNames)

                    thread {
                        val rootObjectString = serviceActivity.allPieceDetect(
                            srcPath,
                            dirName,
                            points,
                            piecePlaceListString,
                            pieceNames
                        )
                        runOnUiThread {
                            result.success(rootObjectString)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

}
