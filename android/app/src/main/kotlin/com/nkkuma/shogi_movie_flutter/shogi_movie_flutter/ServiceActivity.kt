package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter

import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.os.Environment
import android.util.Log
import androidx.annotation.RequiresApi
import com.nkkuma.shogi_movie_flutter.shogi_movie_flutter.domain.Board
import com.nkkuma.shogi_movie_flutter.shogi_movie_flutter.domain.Koma
import org.json.JSONObject
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import java.io.File
import kotlin.math.max
import kotlin.streams.toList

class ServiceActivity(private val serviceContext: Context) {

    private val fileController = FileController()
    val util = Util()
    private val initialBoard = Board()

    //    private val SPACE_SIZE = 64
    private val SPACE_WIDTH = 64
    private val SPACE_HEIGHT = 70 // = (64 * 34.8 / 31.7).toInt()

    private val pieceSizeList = listOf(64, 62, 60, 58, 56, 54, 52, 50, 48, 46, 44, 42, 40, 38, 36)
    private val pieceRotateList = listOf(20, 15, 10, 5, 0, -5, -10, -15, -20)

    private fun loadOpenCV() {
        // load opencv
        if (!OpenCVLoader.initDebug())
            Log.e("OpenCV", "Unable to load OpenCV!")
        else
            Log.d("OpenCV", "OpenCV loaded Successfully!")
    }

    fun findContours(srcPath: String): String {
        // load opencv
        loadOpenCV()

        // Bitmapを読み込み
        val img = fileController.readImageFromFileWithRotate(srcPath)
        // BitmapをMatに変換する
        val matSource = Mat()
        Utils.bitmapToMat(img, matSource)
        Log.d("OpenCV", matSource.size().toString())

        // color to grayscale
        Imgproc.cvtColor(matSource, matSource, Imgproc.COLOR_BGR2GRAY)
        // adaptiveThreshold
        Imgproc.adaptiveThreshold(matSource, matSource, 255.0, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY, 11, 2.0)
        // reverse binary
        Core.bitwise_not(matSource, matSource)

        val contours = mutableListOf<MatOfPoint>()
        Imgproc.findContours(matSource, contours, matSource, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)

        // sort by size
        contours.sortBy { Imgproc.contourArea(it) }

        // 近似
        val contour = MatOfPoint2f()
        val approx = MatOfPoint2f()
        contour.fromList(contours.last().toList())
        Imgproc.approxPolyDP(contour, approx, Imgproc.arcLength(contour, true)*0.01, true)

        // 凸包
        val hull = MatOfInt()
        val convApprox = MatOfPoint()
        val approxList = approx.toList()
        convApprox.fromList(approxList)
        Imgproc.convexHull(convApprox, hull)
        val hulledApproxList = mutableListOf<List<Double>>()
        hull.toList().forEach{hulledApproxList.add(listOf(approxList[it].x, approxList[it].y))}

        return JSONObject(hashMapOf("points" to hulledApproxList) as Map<String, *>).toString()
    }

    fun piecePlaceDetect(srcPath: String, points: String): String {
        // load opencv
        if (!OpenCVLoader.initDebug())
            Log.e("OpenCV", "Unable to load OpenCV!")
        else
            Log.d("OpenCV", "OpenCV loaded Successfully!")

        // example: perspective covert
        val pointsFloatList = util.offsetString2FloatList(points)
        Log.d("OpenCV", pointsFloatList.toString())
        return getCurrentPosition(
            srcpath = srcPath,
            relativePoints = pointsFloatList
        )
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun onePieceDetect(srcPath: String,
                               dirName: String,
                               points: String,
                               space: String,
                               pieceNames: String): String {
        // load opencv
        loadOpenCV()

        // example: perspective covert
        val relativePoints = util.offsetString2FloatList(points)
        val spaceList = space.split(',').map { it.toInt() }
        val pieceNameList = if (pieceNames.isEmpty()) listOf() else pieceNames.split(',')
        Log.d("OpenCV", relativePoints.toString())
        val targetPlaceMat = spaceCroppedMat(srcPath, relativePoints, spaceList)
        return detectPiece(
            dirName = dirName,
            pieceNameList = pieceNameList,
            piecesSize = listOf(),
            targetPlaceMat = targetPlaceMat
//                    piecesSize = listOf(37, 42, 43, 47, 47, 48, 50, 50, 50, 37, 42, 43, 47, 47, 48, 50, 50, 50)
        )
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun initialPieceDetect(srcPath: String,
                           dirName: String,
                           points: String): String {
        // load opencv
        loadOpenCV()

        val relativePoints = util.offsetString2FloatList(points)
        val positionJson = JSONObject(getCurrentPosition(
            srcpath = srcPath,
            relativePoints = relativePoints
        ))

        val board = Board()
        board.fromSfen(positionJson.get("sfen") as String)
        val matCropped = file2crop9x9Mat(srcPath, relativePoints)
        for ((i, line) in board.board.withIndex()) {
            for ((j, koma) in line.withIndex()) {
                if (koma == Koma.EXIST) {
                    if (initialBoard.board[i][j] == Koma.NONE) {
                        board.board[i][j] = Koma.NONE
                    } else {
                        val pieceNameList = listOf(initialBoard.board[i][j].english)
                        val targetPlaceMat = spaceCroppedMat(matCropped, listOf(j, i))
                        val detectJsonObject = JSONObject(detectPiece(dirName, pieceNameList, listOf(), targetPlaceMat))
                        val piece = Koma.values().firstOrNull { it.english == detectJsonObject.getString("piece") };
                        board.board[i][j] = piece ?: Koma.NONE
                    }
                }
            }
        }

        // Mat を Bitmap に変換して保存
        val img = fileController.readImageFromFileWithRotate(srcPath)
        val imgResult = Bitmap.createBitmap(matCropped.width(), matCropped.height(), img!!.config)
        Utils.matToBitmap(matCropped, imgResult)
        val imgPath = fileController.saveImageToFile(imgResult, getExternalPictureFilesDir())

        // create json
        val rootObject = JSONObject()
        rootObject.put("imgPath", imgPath)
        rootObject.put("sfen", board.toSfen())
        Log.d("OpenCV", rootObject.toString())
        return rootObject.toString()
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun allPieceDetect(srcPath: String,
                       dirName: String,
                       points: String,
                       piecePlaceListString: String,
                       pieceNames: String): String {
        // load opencv
        loadOpenCV()

        val relativePoints = util.offsetString2FloatList(points)
        val positionJson = JSONObject(getCurrentPosition(
            srcpath = srcPath,
            relativePoints = relativePoints
        ))

        Log.d("OpenCV", "all_piece_detect getCurrentPosition is finished.")
        val board = Board()
        board.fromSfen(positionJson.get("sfen") as String)
        val matCropped = file2crop9x9Mat(srcPath, relativePoints)
        val piecePlaceList = piecePlaceListString.split(",")
        val pieceNamesList = pieceNames.split(",")
        for ((i, line) in board.board.withIndex()) {
            for ((j, koma) in line.withIndex()) {
                if (koma == Koma.EXIST) {
                    if (piecePlaceList[i*10+j] != "" && piecePlaceList[i*10+j].startsWith("v") == pieceNames.startsWith("v")) {
                        board.board[i][j] = Koma.values().first { it.english == piecePlaceList[i*10+j]}
                    }
                    else {
                        val pieceNameList = if (piecePlaceList[i*10+j] == "") listOf() else listOf(piecePlaceList[i*10+j]) + pieceNamesList
                        val targetPlaceMat = spaceCroppedMat(matCropped, listOf(j, i))
                        val detectJsonObject = JSONObject(detectPiece(dirName, pieceNameList, listOf(), targetPlaceMat))
                        val piece = Koma.values().firstOrNull { it.english == detectJsonObject.getString("piece") };
                        board.board[i][j] = piece ?: Koma.NONE
                    }
                }
            }
        }
        Log.d("OpenCV", board.toSfen())

        // create json
        val rootObject = JSONObject()
        rootObject.put("sfen", board.toSfen())
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

    private fun matchTemplateWithRotate(pieceRotate: Int, resizedPieceMat: Mat, resizedMaskMat: Mat, matCropped: Mat): Mat {
        // rotate piece image
        val rotatedPieceMat = util.rotateMat(resizedPieceMat, pieceRotate.toDouble())
        val rotatedMaskMat = util.rotateMat(resizedMaskMat, pieceRotate.toDouble())
        // matchTemplate
        val result = Mat()
        Imgproc.matchTemplate(matCropped, rotatedPieceMat, result, Imgproc.TM_CCOEFF_NORMED, rotatedMaskMat)
        return result
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
    private fun getCurrentPosition(srcpath: String, relativePoints: List<List<Float>>): String {
        // static variable for get piece position
        val pieceExistThreshold = SPACE_HEIGHT * SPACE_WIDTH * 0.03
        val board = Board()
        board.clearBoard()
        // Bitmapを読み込み
        val img = fileController.readImageFromFileWithRotate(srcpath)!!
        // BitmapをMatに変換する
        val matSource = Mat()
        Utils.bitmapToMat(img, matSource)
        Log.d("OpenCV", matSource.size().toString())

        // convert relativePoints to absolutePoints
        val absolutePoints = util.relativePoints2absolutePoints(relativePoints, img.width, img.height)
        Log.d("OpenCV", absolutePoints.toString())

        // crop image
        val matCropped = crop9x9Img(matSource, absolutePoints)

        // color to grayscale
        Imgproc.cvtColor(matCropped, matCropped, Imgproc.COLOR_BGR2GRAY)
        // adaptiveThreshold
        Imgproc.adaptiveThreshold(matCropped, matCropped, 255.0, Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C, Imgproc.THRESH_BINARY, 11, 2.0)
        // reverse binary
        Core.bitwise_not(matCropped, matCropped)

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
                    board.board[i][j] = Koma.EXIST
                } else {
                    board.board[i][j] = Koma.EMPTY
                }
            }
        }

        // Mat を Bitmap に変換して保存
        val imgResult = Bitmap.createBitmap(matCropped.width(), matCropped.height(), img.config)
        Utils.matToBitmap(matCropped, imgResult)
        val imgPath = fileController.saveImageToFile(imgResult, getExternalPictureFilesDir())

        // create json
        val rootObject = JSONObject()
        rootObject.put("imgPath", imgPath)
        rootObject.put("sfen", board.toSfen())
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
    @RequiresApi(Build.VERSION_CODES.N)
    private fun detectPiece(dirName: String, pieceNameList: List<String>, piecesSize: List<Int>, targetPlaceMat: Mat): String {
        // for piece
        val pieceNameListForPiece = if (pieceNameList.isNotEmpty()) pieceNameList else Koma.values().filter { it.english != "" }.map { koma -> koma.english }
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
        croppedPieceMat = util.resizeMatWithSameAspectRatio(croppedPieceMat, max(SPACE_WIDTH, SPACE_HEIGHT) *2.0)
        croppedMaskMat = util.resizeMatWithSameAspectRatio(croppedMaskMat, max(SPACE_WIDTH, SPACE_HEIGHT) *2.0)
        // binalize
        Imgproc.cvtColor(croppedPieceMat, croppedPieceMat, Imgproc.COLOR_BGR2GRAY)
        // if piece name starts v, reverse image
        if (secondHandPiece) {
            croppedPieceMat = util.rotateMat(croppedPieceMat,180.0)
            croppedMaskMat = util.rotateMat(croppedMaskMat,180.0)
        }
        return listOf(croppedPieceMat, croppedMaskMat)
    }

    private fun getExternalPictureFilesDir(): File? {
        return serviceContext.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
    }

}