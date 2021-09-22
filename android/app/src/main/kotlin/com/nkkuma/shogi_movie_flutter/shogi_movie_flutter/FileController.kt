package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class FileController {

    // Bitmap を回転
    private fun rotateImage(source: Bitmap, angle: Float): Bitmap? {
        val matrix = Matrix()
        matrix.postRotate(angle)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    // 画像を読み込み、exif に応じて回転
    fun readImageFromFileWithRotate(path:String): Bitmap? {
        try {
            val ei = ExifInterface(path)
            val orientation = ei.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED)
            val options = BitmapFactory.Options()
            options.inPreferredConfig = Bitmap.Config.ARGB_8888
            val bitmap = BitmapFactory.decodeFile(path, options)
            var rotatedBitmap: Bitmap? = null
            rotatedBitmap = when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> rotateImage(bitmap, 90.0f)
                ExifInterface.ORIENTATION_ROTATE_180 -> rotateImage(bitmap, 180.0f)
                ExifInterface.ORIENTATION_ROTATE_270 -> rotateImage(bitmap, 270.0f)
                ExifInterface.ORIENTATION_NORMAL -> bitmap
                else -> bitmap
            }
            return rotatedBitmap
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return null
    }

    // 画像を保存する
    fun saveImageToFile(img: Bitmap, storageDir: File?): String? {
        try {
            // 一時ファイルを生成
            val timeStamp: String = SimpleDateFormat("yyyyMMdd_HHmmss").format(Date())
            if (storageDir == null) {
                return null
            }

            val file = File.createTempFile(
                "JPEG_${timeStamp}_",
                ".jpeg",
                storageDir)
            if (file == null) {
                return null
            }

            // PNGファイルで保存
            val out = FileOutputStream(file)
            img.compress(Bitmap.CompressFormat.JPEG, 100, out)
            out.flush()
            out.close()

            return file.absolutePath
        }
        catch (e: IOException) {
            e.printStackTrace()
            return null
        }
    }
}