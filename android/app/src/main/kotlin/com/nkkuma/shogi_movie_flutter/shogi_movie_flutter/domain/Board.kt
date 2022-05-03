package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter.domain

import android.util.Log

data class Board(
    var blackPiece: Map<Koma, Int> = mapOf(),
    var whitePiece: Map<Koma, Int> = mapOf(),
    var board: MutableList<MutableList<Koma>> = mutableListOf(
        mutableListOf(Koma.VKYO, Koma.VKEI, Koma.VGIN, Koma.VKIN, Koma.VOU, Koma.VKIN, Koma.VGIN, Koma.VKEI, Koma.VKYO),
        mutableListOf(Koma.NONE, Koma.VHISYA, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.VKAKU, Koma.NONE),
        mutableListOf(Koma.VFU, Koma.VFU, Koma.VFU, Koma.VFU, Koma.VFU, Koma.VFU, Koma.VFU, Koma.VFU, Koma.VFU),
        mutableListOf(Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE),
        mutableListOf(Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE),
        mutableListOf(Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE),
        mutableListOf(Koma.FU, Koma.FU, Koma.FU, Koma.FU, Koma.FU, Koma.FU, Koma.FU, Koma.FU, Koma.FU),
        mutableListOf(Koma.NONE, Koma.KAKU, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.NONE, Koma.HISYA, Koma.NONE),
        mutableListOf(Koma.KYO, Koma.KEI, Koma.GIN, Koma.KIN, Koma.GYOKU, Koma.KIN, Koma.GIN, Koma.KEI, Koma.KYO)
    )
) {
    fun clearBoard() = run { board = MutableList(9) { MutableList(9) { Koma.NONE } } }

    fun toSfen(): String {
        val sfenArray = arrayListOf<String>()
        for (line in board) {
            var spaceNumber = 0
            val mergedSfen = StringBuilder()
            for (place in line) {
                if (place != Koma.NONE) {
                    if (spaceNumber > 0) {
                        mergedSfen.append(spaceNumber.toString())
                        spaceNumber = 0
                    }
                    mergedSfen.append(place.sfen)
                }
                else {
                    spaceNumber += 1
                }
            }
            if (spaceNumber > 0) {
                mergedSfen.append(spaceNumber.toString())
            }
            sfenArray.add(mergedSfen.toString())
        }
        return sfenArray.joinToString(separator = "/")
    }

    fun fromSfen(sfen: String) {
        var index = 0
        for (char in sfen) {
            if (char == '/') {
                index += 1
            }
            else if (char == ' ') {
                // it starts mochigoma and kif. currently these are ignored.
                return
            }
            else if (!char.isDigit()) {
                board[index/10][index%10] = Koma.values().first { it.sfen == char.toString() }
                index += 1
            }
            else {
                for (i in 1..Character.getNumericValue(char)) {
                    board[index/10][index%10] = Koma.NONE
                    index += 1
                }
            }
        }
    }
}
