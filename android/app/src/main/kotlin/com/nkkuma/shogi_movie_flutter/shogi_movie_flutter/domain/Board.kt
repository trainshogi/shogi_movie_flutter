package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter.domain

data class Board(
    var blackPiece: Map<Piece, Int> = mapOf(),
    var whitePiece: Map<Piece, Int> = mapOf(),
    var board: MutableList<MutableList<Piece>> = mutableListOf(
        mutableListOf(Piece.VKYO, Piece.VKEI, Piece.VGIN, Piece.VKIN, Piece.VOU, Piece.VKIN, Piece.VGIN, Piece.VKEI, Piece.VKYO),
        mutableListOf(Piece.NONE, Piece.VHISYA, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.VKAKU, Piece.NONE),
        mutableListOf(Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU),
        mutableListOf(Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE),
        mutableListOf(Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE),
        mutableListOf(Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE),
        mutableListOf(Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU),
        mutableListOf(Piece.NONE, Piece.KAKU, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.HISYA, Piece.NONE),
        mutableListOf(Piece.KYO, Piece.KEI, Piece.GIN, Piece.KIN, Piece.GYOKU, Piece.KIN, Piece.GIN, Piece.KEI, Piece.KYO)
    )
) {
    fun clearBoard() = run { board = MutableList(9) { MutableList(9) { Piece.NONE } } }

    fun toSfen(): String {
        val sfenArray = arrayListOf<String>()
        for (line in board) {
            var spaceNumber = 0
            val mergedSfen = StringBuilder()
            for (place in line) {
                if (place != Piece.NONE) {
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

    fun fromSfen(sfen: String): Board {
        val board = MutableList(9) { MutableList(9) { Piece.NONE } }
        var index = 0
        var promote = false
        for (char in sfen) {
            if (char == '/') {
                index += 1
                promote = false
            }
            else if (char == '+') {
                promote = true
            }
            else if (char == ' ') {
                // it starts mochigoma and kif. currently these are ignored.
                break
            }
            else if (!char.isDigit()) {
                val pieceStr = if (promote) "+$char" else char.toString()
                board[index/10][index%10] = Piece.values().first { it.sfen == pieceStr }
                promote = false
                index += 1
            }
            else {
                for (i in 1..Character.getNumericValue(char)) {
                    board[index/10][index%10] = Piece.NONE
                    promote = false
                    index += 1
                }
            }
        }
        return Board(mapOf(), mapOf(), board)
    }
}
