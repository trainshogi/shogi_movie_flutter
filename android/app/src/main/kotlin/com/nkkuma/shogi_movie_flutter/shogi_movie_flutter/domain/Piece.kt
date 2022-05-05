package com.nkkuma.shogi_movie_flutter.shogi_movie_flutter.domain

enum class Piece(val english: String, val sfen: String) {
    NONE("", ""),
    EMPTY("", "1"),
    EXIST("", "Z"),
    FU("fu", "P"),
    KYO("kyo", "L"),
    KEI("kei", "N"),
    GIN("gin", "S"),
    KIN("kin", "G"),
    KAKU("kaku", "B"),
    HISYA("hisya", "R"),
    OU("ou", "K"),
    GYOKU("gyoku", "K"),
    NFU("nfu", "+P"),
    NKYO("nkyo", "+L"),
    NKEI("nkei", "+N"),
    NGIN("ngin", "+S"),
    NKAKU("nkaku", "+B"),
    NHISYA("nhisya", "+R"),
    VFU("vfu", "p"),
    VKYO("vkyo", "l"),
    VKEI("vkei", "n"),
    VGIN("vgin", "s"),
    VKIN("vkin", "g"),
    VKAKU("vkaku", "b"),
    VHISYA("vhisya", "r"),
    VOU("vou", "k"),
    VGYOKU("vgyoku", "k"),
    VNFU("vnfu", "+p"),
    VNKYO("vnkyo", "+l"),
    VNKEI("vnkei", "+n"),
    VNGIN("vngin", "+s"),
    VNKAKU("vnkaku", "+b"),
    VNHISYA("vnhisya", "+r")
}