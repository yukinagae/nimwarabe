##
## nimwarabe
##

## 思考エンジンのバージョンとしてUSIプロトコルの"usi"コマンドに応答するときの文字列
const ENGINE_VERSION = "0.1"

## 手番
type Color = enum BLACK, WHITE, COLOR_ALL ## BLACK: 先手, WHITE: 後手, COLOR_ALL: 先後共通の何か
proc `~`(c: Color): int = c.ord and 1 ## 相手番を返す
proc is_ok(c: Color): bool = (BLACK <= c) and (c <= COLOR_ALL) ## 正常な値であるかを検査する。assertで使う用。
proc p(c: Color) = echo c ## 出力用(USI形式ではない)　デバッグ用。

## 筋
type File = enum FILE_1, FILE_2, FILE_3, FILE_4, FILE_5, FILE_6, FILE_7, FILE_8, FILE_9 ## 例) FILE_3なら3筋。
proc is_ok(f: FIle): bool = (FILE_1 <= f) and (f <= FILE_9) ## 正常な値であるかを検査する。assertで使う用。
proc to_file(c: char): File = File(c.ord - '1'.ord) ## USIの指し手文字列などで筋を表す文字列をここで定義されたFileに変換する。(1~9)
proc p(f: File) = echo 1 + f.ord ## USI形式でFileを出力する

## 段
type Rank = enum RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9 ## 例) RANK_4なら4段目。
proc is_ok(r: Rank): bool = (RANK_1 <= r) and (r <= RANK_9) ## 正常な値であるかを検査する。assertで使う用。

## 移動元、もしくは移動先の升のrankを与えたときに、そこが成れるかどうかを判定する。
## 先手9bit(9段) + 後手9bit(9段) = 18bitのbit列に対して、判定すればいい。
## ただし ×9みたいな掛け算をするのは嫌なのでbit shiftで済むように先手16bit、後手16bitの32bitのbit列に対して判定する。
proc can_promote(c: Color, fromOrToRank: Rank): bool = true # FIXME echo (0x1c00007 and (1 shl ((c.ord shl 4) + fromOrToRank.ord)))

proc relative_rank(c: Color, r: Rank): Rank = return if c == BLACK: r else: Rank(8 - r.ord) ## 後手の段なら先手から見た段を返す。 例) relative_rank(WHITE,RANK_1) == RANK_9
proc to_rank(c: char): Rank = Rank(c.ord - 'a'.ord) ## USIの指し手文字列などで段を表す文字列をここで定義されたRankに変換する。(a~i)
proc p(r: Rank) = echo char('a'.ord + r.ord) ## USI形式でRankを出力する

## 升目

##  盤上の升目に対応する定数。
## 盤上右上(１一が0)、左下(９九)が80
type Square = enum SQ_11, SQ_12, SQ_13, SQ_14, SQ_15, SQ_16, SQ_17, SQ_18, SQ_19,
                   SQ_21, SQ_22, SQ_23, SQ_24, SQ_25, SQ_26, SQ_27, SQ_28, SQ_29,
                   SQ_31, SQ_32, SQ_33, SQ_34, SQ_35, SQ_36, SQ_37, SQ_38, SQ_39,
                   SQ_41, SQ_42, SQ_43, SQ_44, SQ_45, SQ_46, SQ_47, SQ_48, SQ_49,
                   SQ_51, SQ_52, SQ_53, SQ_54, SQ_55, SQ_56, SQ_57, SQ_58, SQ_59,
                   SQ_61, SQ_62, SQ_63, SQ_64, SQ_65, SQ_66, SQ_67, SQ_68, SQ_69,
                   SQ_71, SQ_72, SQ_73, SQ_74, SQ_75, SQ_76, SQ_77, SQ_78, SQ_79,
                   SQ_81, SQ_82, SQ_83, SQ_84, SQ_85, SQ_86, SQ_87, SQ_88, SQ_89,
                   SQ_91, SQ_92, SQ_93, SQ_94, SQ_95, SQ_96, SQ_97, SQ_98, SQ_99

## 方角に関する定数。N=北=盤面の下を意味する。
const SQ_D = +1 # 下(Down)
const SQ_R = -9 # 右(Right)
const SQ_U = -1 # 上(Up)
const SQ_L = +9 # 左(Left)

## 斜めの方角などを意味する定数。
const SQ_RU  = SQ_U  + SQ_R # 右上(Right Up)
const SQ_RD  = SQ_D  + SQ_R # 右下(Right Down)
const SQ_LU  = SQ_U  + SQ_L # 左上(Left Up)
const SQ_LD  = SQ_D  + SQ_L # 左下(Left Down)
const SQ_RUU = SQ_RU + SQ_U # 右上上
const SQ_LUU = SQ_LU + SQ_U # 左上上
const SQ_RDD = SQ_RD + SQ_D # 右下下
const SQ_LDD = SQ_LD + SQ_D # 左下下

## sqが盤面の内側を指しているかを判定する。assert()などで使う用。
## 駒は駒落ちのときにSQ_NBに移動するので、値としてSQ_NBは許容する。
proc is_ok(sq: Square): bool = (SQ_11 <= sq) and (sq <= SQ_99)

## table
const SquareToFile: array[SQ_11..SQ_99, File] = [
    FILE_1, FILE_1, FILE_1, FILE_1, FILE_1, FILE_1, FILE_1, FILE_1, FILE_1,
    FILE_2, FILE_2, FILE_2, FILE_2, FILE_2, FILE_2, FILE_2, FILE_2, FILE_2,
    FILE_3, FILE_3, FILE_3, FILE_3, FILE_3, FILE_3, FILE_3, FILE_3, FILE_3,
    FILE_4, FILE_4, FILE_4, FILE_4, FILE_4, FILE_4, FILE_4, FILE_4, FILE_4,
    FILE_5, FILE_5, FILE_5, FILE_5, FILE_5, FILE_5, FILE_5, FILE_5, FILE_5,
    FILE_6, FILE_6, FILE_6, FILE_6, FILE_6, FILE_6, FILE_6, FILE_6, FILE_6,
    FILE_7, FILE_7, FILE_7, FILE_7, FILE_7, FILE_7, FILE_7, FILE_7, FILE_7,
    FILE_8, FILE_8, FILE_8, FILE_8, FILE_8, FILE_8, FILE_8, FILE_8, FILE_8,
    FILE_9, FILE_9, FILE_9, FILE_9, FILE_9, FILE_9, FILE_9, FILE_9, FILE_9
]

const SquareToRank: array[SQ_11..SQ_99, Rank] = [
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9,
    RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9
]

## 与えられたSquareに対応する筋を返す。
## →　行数は長くなるが速度面においてテーブルを用いる。
proc file_of(sq: Square): File = SquareToFile[sq]

## 与えられたSquareに対応する段を返す。
## →　行数は長くなるが速度面においてテーブルを用いる。
proc rank_of(sq: Square): Rank = SquareToRank[sq]

## 筋(File)と段(Rank)から、それに対応する升(Square)を返す。
proc `|`(f: File, r: Rank): Square = Square(f.ord * 9 + r.ord)

## 駒

## 金の順番を飛の後ろにしておく。KINGを8にしておく。
## こうすることで、成りを求めるときに pc |= 8;で求まり、かつ、先手の全種類の駒を列挙するときに空きが発生しない。(DRAGONが終端になる)
type Piece = enum NO_PIECE, PAWN, LANCE, KNIGHT, SILVER, BISHOP, ROOK, GOLD,
                  KING, PRO_PAWN, PRO_LANCE, PRO_KNIGHT, PRO_SILVER, HORSE, DRAGON, QUEEN
type ColorPiece = enum B_PAWN = 1 , B_LANCE, B_KNIGHT, B_SILVER, B_BISHOP, B_ROOK, B_GOLD , B_KING, B_PRO_PAWN, B_PRO_LANCE, B_PRO_KNIGHT, B_PRO_SILVER, B_HORSE, B_DRAGON, B_QUEEN,
                       W_PAWN = 17, W_LANCE, W_KNIGHT, W_SILVER, W_BISHOP, W_ROOK, W_GOLD , W_KING, W_PRO_PAWN, W_PRO_LANCE, W_PRO_KNIGHT, W_PRO_SILVER, W_HORSE, W_DRAGON, W_QUEEN,
const PIECE_PROMOTE = 8 ## 成り駒と非成り駒との差(この定数を足すと成り駒になる)
const PIECE_WHITE = 16 ## これを先手の駒に加算すると後手の駒になる。

## USIプロトコルで駒を表す文字列を返す。
proc usi_piece(pc: Piece): string = ". P L N S B R G K +P+L+N+S+B+R+G+.p l n s b r g k +p+l+n+s+b+r+g+k".substr(pc.ord * 2, pc.ord * 2 + 1)

## 駒に対して、それが先後、どちらの手番の駒であるかを返す。
proc color_of(cpc: ColorPiece): Color = return if (cpc.ord and PIECE_WHITE) > 0: WHITE else: BLACK

# 動作確認テスト
echo ENGINE_VERSION
