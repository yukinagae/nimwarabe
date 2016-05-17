##
## nimwarabe
##

## 思考エンジンのバージョンとしてUSIプロトコルの"usi"コマンドに応答するときの文字列
const ENGINE_VERSION = "0.1"

## pretty表示時に、日本語表記にするかどうかのフラグ(USI形式ではない)
const pretty_jp = false


##
## util
##
proc `<<`(a: int, b: int): int = a shl b # 左シフト
proc `>>`(a: int, b: int): int = a shr b # 右シフト

##
## 手番
##
type Color = enum BLACK, WHITE, COLOR_ALL # BLACK: 先手, WHITE: 後手, COLOR_ALL: 先後共通の何か
proc `~`(c: Color): int = c.ord and 1 # 相手番を返す
proc is_ok(c: Color): bool = (BLACK <= c) and (c <= COLOR_ALL) # 正常な値であるかを検査する。assertで使う用。
proc p(c: Color) = echo c # 出力用(USI形式ではない)　デバッグ用。

##
## 筋
##
type File = enum FILE_1, FILE_2, FILE_3, FILE_4, FILE_5, FILE_6, FILE_7, FILE_8, FILE_9 # 例) FILE_3なら3筋。
proc is_ok(f: FIle): bool = (FILE_1 <= f) and (f <= FILE_9) # 正常な値であるかを検査する。assertで使う用。
proc to_file(c: char): File = File(c.ord - '1'.ord) # USIの指し手文字列などで筋を表す文字列をここで定義されたFileに変換する。(1~9)
proc p(f: File) = echo 1 + f.ord # USI形式でFileを出力する

##
## 段
##
type Rank = enum RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9 # 例) RANK_4なら4段目。
proc is_ok(r: Rank): bool = (RANK_1 <= r) and (r <= RANK_9) # 正常な値であるかを検査する。assertで使う用。

# 移動元、もしくは移動先の升のrankを与えたときに、そこが成れるかどうかを判定する。
# 先手9bit(9段) + 後手9bit(9段) = 18bitのbit列に対して、判定すればいい。
# ただし ×9みたいな掛け算をするのは嫌なのでbit shiftで済むように先手16bit、後手16bitの32bitのbit列に対して判定する。
proc can_promote(c: Color, fromOrToRank: Rank): bool = true # FIXME echo (0x1c00007 and (1 shl ((c.ord shl 4) + fromOrToRank.ord)))

proc relative_rank(c: Color, r: Rank): Rank = return if c == BLACK: r else: Rank(8 - r.ord) # 後手の段なら先手から見た段を返す。 例) relative_rank(WHITE,RANK_1) == RANK_9
proc to_rank(c: char): Rank = Rank(c.ord - 'a'.ord) # USIの指し手文字列などで段を表す文字列をここで定義されたRankに変換する。(a~i)
proc p(r: Rank) = echo char('a'.ord + r.ord) # USI形式でRankを出力する

##
## 升目
##
#  盤上の升目に対応する定数。
# 盤上右上(１一が0)、左下(９九)が80
type Square = enum SQ_11, SQ_12, SQ_13, SQ_14, SQ_15, SQ_16, SQ_17, SQ_18, SQ_19,
                   SQ_21, SQ_22, SQ_23, SQ_24, SQ_25, SQ_26, SQ_27, SQ_28, SQ_29,
                   SQ_31, SQ_32, SQ_33, SQ_34, SQ_35, SQ_36, SQ_37, SQ_38, SQ_39,
                   SQ_41, SQ_42, SQ_43, SQ_44, SQ_45, SQ_46, SQ_47, SQ_48, SQ_49,
                   SQ_51, SQ_52, SQ_53, SQ_54, SQ_55, SQ_56, SQ_57, SQ_58, SQ_59,
                   SQ_61, SQ_62, SQ_63, SQ_64, SQ_65, SQ_66, SQ_67, SQ_68, SQ_69,
                   SQ_71, SQ_72, SQ_73, SQ_74, SQ_75, SQ_76, SQ_77, SQ_78, SQ_79,
                   SQ_81, SQ_82, SQ_83, SQ_84, SQ_85, SQ_86, SQ_87, SQ_88, SQ_89,
                   SQ_91, SQ_92, SQ_93, SQ_94, SQ_95, SQ_96, SQ_97, SQ_98, SQ_99

const SQ_ZERO = 0 # ゼロ
const SQ_NB = 81 # 末尾
const SQ_NB_PLUS1 = SQ_NB + 1 # 玉がいない場合、SQ_NBに移動したものとして扱うため、配列をSQ_NB+1で確保しないといけないときがあるのでこの定数を用いる。

# 方角に関する定数。N=北=盤面の下を意味する。
const SQ_D = +1 # 下(Down)
const SQ_R = -9 # 右(Right)
const SQ_U = -1 # 上(Up)
const SQ_L = +9 # 左(Left)

# 斜めの方角などを意味する定数。
const SQ_RU  = SQ_U  + SQ_R # 右上(Right Up)
const SQ_RD  = SQ_D  + SQ_R # 右下(Right Down)
const SQ_LU  = SQ_U  + SQ_L # 左上(Left Up)
const SQ_LD  = SQ_D  + SQ_L # 左下(Left Down)
const SQ_RUU = SQ_RU + SQ_U # 右上上
const SQ_LUU = SQ_LU + SQ_U # 左上上
const SQ_RDD = SQ_RD + SQ_D # 右下下
const SQ_LDD = SQ_LD + SQ_D # 左下下

# sqが盤面の内側を指しているかを判定する。assert()などで使う用。
# 駒は駒落ちのときにSQ_NBに移動するので、値としてSQ_NBは許容する。
proc is_ok(sq: Square): bool = (SQ_11 <= sq) and (sq <= SQ_99)

##
## table
##
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

# 与えられたSquareに対応する筋を返す。
# →　行数は長くなるが速度面においてテーブルを用いる。
proc file_of(sq: Square): File = SquareToFile[sq]

# 与えられたSquareに対応する段を返す。
# →　行数は長くなるが速度面においてテーブルを用いる。
proc rank_of(sq: Square): Rank = SquareToRank[sq]

proc `|`(f: File, r: Rank): Square = Square(f.ord * 9 + r.ord) # 筋(File)と段(Rank)から、それに対応する升(Square)を返す。

##
## 駒
##
# 金の順番を飛の後ろにしておく。KINGを8にしておく。
# こうすることで、成りを求めるときに pc |= 8;で求まり、かつ、先手の全種類の駒を列挙するときに空きが発生しない。(DRAGONが終端になる)
type RawPiece = enum NO_PIECE, PAWN, LANCE, KNIGHT, SILVER, BISHOP, ROOK, GOLD,
                  KING, PRO_PAWN, PRO_LANCE, PRO_KNIGHT, PRO_SILVER, HORSE, DRAGON, QUEEN
# 以下、先後の区別のある駒(Bがついているのは先手、Wがついているのは後手)
type ColorPiece = enum B_PAWN = 1 , B_LANCE, B_KNIGHT, B_SILVER, B_BISHOP, B_ROOK, B_GOLD , B_KING, B_PRO_PAWN, B_PRO_LANCE, B_PRO_KNIGHT, B_PRO_SILVER, B_HORSE, B_DRAGON, B_QUEEN,
                       W_PAWN = 17, W_LANCE, W_KNIGHT, W_SILVER, W_BISHOP, W_ROOK, W_GOLD , W_KING, W_PRO_PAWN, W_PRO_LANCE, W_PRO_KNIGHT, W_PRO_SILVER, W_HORSE, W_DRAGON, W_QUEEN
type Piece = RawPiece | ColorPiece

const PIECE_PROMOTE = 8 # 成り駒と非成り駒との差(この定数を足すと成り駒になる)
const PIECE_WHITE = 16 # これを先手の駒に加算すると後手の駒になる。

proc usi_piece(pc: Piece): string = ". P L N S B R G K +P+L+N+S+B+R+G+.p l n s b r g k +p+l+n+s+b+r+g+k".substr(pc.ord * 2, pc.ord * 2 + 1) # USIプロトコルで駒を表す文字列を返す。
proc color_of(pc: Piece): Color = return if (pc.ord and PIECE_WHITE) > 0: WHITE else: BLACK # 駒に対して、それが先後、どちらの手番の駒であるかを返す。
proc type_of(pc: Piece): Piece = Piece(pc.ord and 15) # 後手の歩→先手の歩のように、後手という属性を取り払った駒種を返す

# 成ってない駒を返す。後手という属性も消去する。
# 例) 成銀→銀 , 後手の馬→先手の角
# ただし、pc == KINGでの呼び出しはNO_PIECEが返るものとする。
proc raw_type_of(pc: Piece): Piece = Piece(pc.ord and 7)
proc make_piece(c: Color, pt: Piece): Piece = Piece(pt.ord + (c.ord << 4)) # pcとして先手の駒を渡し、cが後手なら後手の駒を返す。cが先手なら先手の駒のまま。pcとしてNO_PIECEは渡してはならない。
proc has_long_effect(pc: Piece): bool = (pc == LANCE) or (((pc.ord + 1) and 6) == 6) # pcが遠方駒であるかを判定する。LANCE,BISHOP(5),ROOK(6),HORSE(13),DRAGON(14)
proc is_ok(pc: Piece): bool = (NO_PIECE <= pc) and (pc <= W_QUEEN) # Pieceの整合性の検査。assert用。

##
## 駒箱
##
# Positionクラスで用いる、駒リスト(どの駒がどこにあるのか)を管理するときの番号。
type PieceNo = enum PIECE_NO_PAWN = 0, PIECE_NO_LANCE = 18, PIECE_NO_KNIGHT = 22, PIECE_NO_SILVER = 26,
                    PIECE_NO_GOLD = 30, PIECE_NO_BISHOP = 34, PIECE_NO_ROOK = 36, PIECE_NO_KING = 38, 
                    # PIECE_NO_BKING = 38, PIECE_NO_WKING = 39, # 先手、後手の玉の番号が必要な場合はこっちを用いる
                    PIECE_NO_NB = 40

proc is_ok(pn: PieceNo): bool = (PIECE_NO_PAWN <= pn) and (pn <= PIECE_NO_NB) # PieceNoの整合性の検査。assert用。

##
## 指し手
##
# 指し手 bit0..6 = 移動先のSquare、bit7..13 = 移動元のSquare(駒打ちのときは駒種)、bit14..駒打ちか、bit15..成りか
type Move = uint16
const MOVE_NONE: Move    = Move(0)            # 無効な移動
const MOVE_NULL: Move    = Move((1 << 7) + 1) # NULL MOVEを意味する指し手。Square(1)からSquare(1)への移動は存在しないのでここを特殊な記号として使う。
const MOVE_RESIGN: Move  = Move((2 << 7) + 2) # << で出力したときに"resign"と表示する投了を意味する指し手。
const MOVE_WIN: Move     = Move((3 << 7) + 3) # 入玉時の宣言勝ちのために使う特殊な指し手
const MOVE_DROP: Move    = Move(1 << 14)      # 駒打ちフラグ
const MOVE_PROMOTE: Move = Move(1 << 15)      # 駒成りフラグ

proc move_from(m: Move): Square = Square((m.ord >> 7) and 127) # 指し手の移動元の升を返す
proc move_to(m: Move): Square = Square(m.ord and 127) # 指し手の移動先の升を返す
proc is_drop(m: Move): bool = (m.ord and MOVE_DROP.ord) != 0 # 指し手が駒打ちか？
proc is_promote(m: Move): bool = (m.ord and MOVE_PROMOTE.ord) != 0 # 指し手が成りか？
proc move_dropped_piece(m: Move) = echo "TODO" # 駒打ち(is_drop()==true)のときの打った駒
proc make_move(from_sq: Square, to_sq: Square): Move = Move(to_sq.ord + (from_sq.ord << 7)) # fromからtoに移動する指し手を生成して返す
proc make_move_promote(from_sq: Square, to_sq: Square): Move = Move(to_sq.ord + (from_sq.ord << 7) + MOVE_PROMOTE.ord) # fromからtoに移動する、成りの指し手を生成して返す
proc make_move_drop(pt: Piece, to: Square): Move = Move(to + (pt.ord << 7) + MOVE_DROP.ord) # Pieceをtoに打つ指し手を生成して返す

# 指し手がおかしくないかをテストする
# ただし、盤面のことは考慮していない。MOVE_NULLとMOVE_NONEであるとfalseが返る。
# これら２つの定数は、移動元と移動先が等しい値になっている。このテストだけをする。
# return move_from(m)!=move_to(m);
# とやりたいところだが、駒打ちでfromのbitを使ってしまっているのでそれだとまずい。
# 駒打ちのbitも考慮に入れるために次のように書く。
proc is_ok(m: Move): bool = (m.ord << 7) != (m.ord and 127)


##
## 手駒
##
# 歩の枚数を8bit、香、桂、銀、角、飛、金を4bitずつで持つ。こうすると16進数表示したときに綺麗に表示される。(なのはのアイデア)
type Hand = uint32
const HAND_ZERO: Hand = 0

##
## 指し手生成器
##
# 将棋のある局面の合法手の最大数。593らしいが、保険をかけて少し大きめにしておく。
const MAX_MOVES = 600

# 生成する指し手の種類
# LEGAL/LEGAL_ALL以外は自殺手が含まれることがある(pseudo-legal)ので、do_moveの前にPosition::legal()でのチェックが必要。
type MOVE_GEN_TYPE = enum
    NON_CAPTURES,           # 駒を取らない指し手
    CAPTURES,               # 駒を取る指し手
    CAPTURES_PRO_PLUS,      # CAPTURES + 価値のかなりあると思われる成り(歩だけ)
    NON_CAPTURES_PRO_MINUS, # NON_CAPTURES - 価値のかなりあると思われる成り(歩だけ)
    # BonanzaではCAPTURESに銀以外の成りを含めていたが、Aperyでは歩の成り以外は含めない。
    # あまり変な成りまで入れるとオーダリングを阻害する。
    # 本ソースコードでは、NON_CAPTURESとCAPTURESは使わず、CAPTURES_PRO_PLUSとNON_CAPTURES_PRO_MINUSを使う。
    # note : NON_CAPTURESとCAPTURESとの生成される指し手の集合は被覆していない。
    # note : CAPTURES_PRO_PLUSとNON_CAPTURES_PRO_MINUSとの生成される指し手の集合も被覆していない。
    # →　被覆させないことで、二段階に指し手生成を分解することが出来る。
    EVASIONS ,              # 王手の回避(指し手生成元で王手されている局面であることがわかっているときはこちらを呼び出す)
    EVASIONS_ALL,           # EVASIONS + 歩の不成なども含む。
    NON_EVASIONS,           # 王手の回避ではない手(指し手生成元で王手されていない局面であることがわかっているときのすべての指し手)
    NON_EVASIONS_ALL,       # NON_EVASIONS + 歩の不成などを含む。
    # 以下の2つは、pos.legalを内部的に呼び出すので生成するのに時間が少しかかる。棋譜の読み込み時などにしか使わない。
    LEGAL,                  # 合法手すべて。ただし、2段目の歩・香の不成や角・飛の不成は生成しない。
    LEGAL_ALL,              # 合法手すべて
    CHECKS,                 # 王手となる指し手(歩の不成などは含まない)
    CHECKS_ALL,             # 王手となる指し手(歩の不成なども含む)
    QUIET_CHECKS,           # 王手となる指し手(歩の不成などは含まない)で、CAPTURESの指し手は含まない指し手
    QUIET_CHECKS_ALL,       # 王手となる指し手(歩の不成なども含む)でCAPTURESの指し手は含まない指し手
    RECAPTURES,             # 指定升への移動の指し手のみを生成する。(歩の不成などは含まない)
    RECAPTURES_ALL          # 指定升への移動の指し手のみを生成する。(歩の不成なども含む)


# TODO ここよくわからないので、あとでちゃんと読む
##
## 壁つきの升表現
##
# This trick is invented by yaneurao in 2016.
# 長い利きを更新するときにある升からある方向に駒にぶつかるまでずっと利きを更新していきたいことがあるが、
# sqの升が盤外であるかどうかを判定する簡単な方法がない。そこで、Squareの表現を拡張して盤外であることを検出
# できるようにする。
# bit 0..7   : Squareと同じ意味
# bit 8      : Squareからのborrow用に1にしておく
# bit 9..13  : いまの升から盤外まで何升右に升があるか(ここがマイナスになるとborrowでbit13が1になる)
# bit 14..18 : いまの升から盤外まで何升上に(略
# bit 19..23 : いまの升から盤外まで何升下に(略
# bit 24..28 : いまの升から盤外まで何升左に(略
# 相対移動するときの差分値
type SquareWithWall = int

const SQWW_U: SquareWithWall           = SQ_U - (1 << 14) + (1 << 19)
const SQWW_R: SquareWithWall           = SQ_R - (1 << 9) + (1 << 24)
const SQWW_L: SquareWithWall           = -int(SQWW_R)
const SQWW_D: SquareWithWall           = -int(SQWW_U)
const SQWW_RU: SquareWithWall          = int(SQWW_R) + int(SQWW_U)
const SQWW_RD: SquareWithWall          = int(SQWW_R) + int(SQWW_D)
const SQWW_LU: SquareWithWall          = int(SQWW_L) + int(SQWW_U)
const SQWW_LD: SquareWithWall          = int(SQWW_L) + int(SQWW_D)
const SQWW_11: SquareWithWall          = int(SQ_11) or (1 << 8) or (0 << 9) or (0 << 14) or (8 << 19) or (8 << 24) # SQ_11の地点に対応する値(他の升はこれ相対で事前に求めテーブルに格納)
const SQWW_BORROW_MASK: SquareWithWall = (1 << 13) or (1 << 18) or (1 << 23) or (1 << 28) # SQWW_RIGHTなどを足して行ったときに盤外に行ったときのborrow bitの集合

const SquareWithWalls = [SQWW_U, SQWW_R, SQWW_L, SQWW_D, SQWW_RU, SQWW_RD, SQWW_LU, SQWW_LD, SQWW_11, SQWW_BORROW_MASK]

##
## 方角
##
# Long Effect Libraryの一部。これは8近傍、24近傍の利きを直列化したり方角を求めたりするライブラリ。
# ここではその一部だけを持って来た。(これらは頻繁に用いるので)

# 方角を表す。遠方駒の利きや、玉から見た方角を表すのに用いる。
# bit0..右上、bit1..右、bit2..右下、bit3..上、bit4..下、bit5..左上、bit6..左、bit7..左下
# 同時に複数のbitが1であることがありうる。
type Directions = enum DIRECTIONS_ZERO = 0,
                       DIRECTIONS_RU   = 1,
                       DIRECTIONS_R    = 2,
                       DIRECTIONS_RD   = 4,
                       DIRECTIONS_U    = 8,
                       DIRECTIONS_D    = 16,
                       DIRECTIONS_LU   = 32,
                       DIRECTIONS_L    = 64,
                       DIRECTIONS_LD   = 128,

# Directionsをpopしたもの。複数の方角を同時に表すことはない。
# おまけで桂馬の移動も追加しておく。
type Direct = enum DIRECT_RU,
                   DIRECT_R,
                   DIRECT_RD,
                   DIRECT_U,
                   DIRECT_D,
                   DIRECT_LU,
                   DIRECT_L,
                   DIRECT_LD,
                   DIRECT_RUU,
                   DIRECT_LUU,
                   DIRECT_RDD,
                   DIRECT_LDD,
                   DIRECT_NB_PLUS4,
const DIRECT_NB = 8
const DIRECT_ZERO = 0

# DirectをSquareWithWall型の差分値で表現したもの。
const DirectToDeltaWW = [SQWW_RU, SQWW_R, SQWW_RD, SQWW_U, SQWW_D, SQWW_LU, SQWW_L, SQWW_LD]
proc directToDeltaWW(d: Direct): SquareWithWall = DirectToDeltaWW[d.ord]

# DirectからDirectionsへの逆変換
proc to_directions(d: Direct): Directions = Directions(1 << d.ord)

##
## pretty
##
import strutils
# Fileを綺麗に出力する(USI形式ではない)
# pretty_jpがtrueならば、日本語文字での表示になる。例 → ８
# pretty_jpがfalseならば、数字のみの表示になる。例 → 8
proc pretty(f: File): string = return if pretty_jp: "１２３４５６７８９".substr(f.ord * 2, 2) else: (f.ord + 1).intToStr

# Rankを綺麗に出力する(USI形式ではない)
# pretty_jpがtrueならば、日本語文字での表示になる。例 → 八
# pretty_jpがfalseならば、数字のみの表示になる。例 → 8
proc pretty(r: Rank): string = return if pretty_jp: "一二三四五六七八九".substr(r.ord * 2, 2) else: (r.ord + 1).intToStr

# Squareを綺麗に出力する(USI形式ではない)
# pretty_jpがtrueならば、日本語文字での表示になる。例 → ８八
# pretty_jpがfalseならば、数字のみの表示になる。例 → 88
proc pretty(sq: Square): string = pretty(file_of(sq)) & pretty(rank_of(sq))

# Pieceを綺麗に出力する(USI形式ではない) 先手の駒は大文字、後手の駒は小文字、成り駒は先頭に+がつく。盤面表示に使う。
proc pretty(pc: Piece): string = usi_piece(pc)

# ↑のpretty()だと先手の駒を表示したときに先頭にスペースが入るので、それが嫌な場合はこちらを用いる。
# FIXME proc pretty2(pc: Piece): string = pretty(pc).substr(1, )

# 見た目に、わかりやすい形式で表示する
proc pretty(m: Move): string =
    if is_drop(m):
        return pretty(move_to(m)) & pretty(RawPiece(move_from(m).ord)) & "*"
    else:
        if is_promote(m):
            return pretty(move_from(m)) & pretty(move_to(m)) & "+"
        else:
            return pretty(move_from(m)) & pretty(move_to(m))

# 移動させた駒がわかっているときに指し手をわかりやすい表示形式で表示する。
proc pretty(m: Move, movedPieceType: RawPiece): string =
    if is_drop(m):
        return pretty(move_to(m)) & pretty(movedPieceType) & "*"
    else:
        if is_promote(m):
            return pretty(move_to(m)) & pretty(movedPieceType) & "+" & "[" & pretty(move_from(m)) & "]"
        else:
            return pretty(move_to(m)) & pretty(movedPieceType) & "[" & pretty(move_from(m)) & "]"


##
## Bitboard
##
type Bitboard = ref object of RootObj
    p: array[2, int64]
    
# p0にはSQ11~SQ79を格納
# p1にはSQ81~99を格納
proc new(p0: int64, p1: int64): Bitboard = Bitboard(p: [p0, p1])

# 値を直接代入する。
proc set(b: Bitboard, p0: int64, p1: int64) = 
    b.p[0] = p0
    b.p[1] = p1

proc bb(b: int64, size: int) =
    var r = b
    for i in countup(0, 8):
        r = r shr (i * size)
        echo r.toBin(size)

proc bb1(b: int64) = bb(b, 7)
proc bb2(b: int64) = bb(b, 2)

proc pretty(b: Bitboard) = echo "[p0] " , b.p[0], "\n", "[p1] ", b.p[1]

proc p(b: Bitboard) = 
    echo "[p0]"
    b.p[0].bb1()
    echo "[p1]"
    b.p[1].bb2()

##
## 動作確認テスト
##

## Bitboard tables
## sqの升が1であるbitboard
var SquareBB: array[SQ_NB_PLUS1, Bitboard];

##
##Bitboard関係のテーブルの初期化
##
# 1) SquareWithWallテーブルの初期化。
var sqww_table: array[SQ_NB_PLUS1, SquareWithWall]
for sq in Square:
    sqww_table[sq.ord] = SquareWithWall(SQWW_11 + file_of(sq).ord * SQWW_L + rank_of(sq).ord * SQWW_D)
    
# 型変換。下位8bit == Square
proc to_sq(sqww: SquareWithWall): Square = Square(sqww.ord and 0xff)
# 型変換。Square型から。
proc to_sqww(sq: Square): SquareWithWall = sqww_table[sq.ord]

# 盤内か。壁(盤外)だとfalseになる。
proc is_ok(sqww: SquareWithWall): bool = (sqww and SQWW_BORROW_MASK) == 0
    
# 2) direct_tableの初期化
var direc_table: array[SQ_NB_PLUS1, array[SQ_NB_PLUS1, Directions]]
for sq1 in Square:
    for dir in Direct(DIRECT_ZERO)..Direct(DIRECT_NB-1):
        # dirの方角に壁にぶつかる(盤外)まで延長していく。このとき、sq1から見てsq2のDirectionsは (1 << dir)である。
        let delta = directToDeltaWW(dir)
        var sq2 = SquareWithWall(to_sqww(sq1).ord + delta.ord)
        while is_ok(sq2):
            direc_table[sq1.ord][to_sq(sq2).ord] = to_directions(dir)
            sq2 = SquareWithWall(sq2.ord + delta.ord)
            
# 3) Square型のsqの指す升が1であるBitboardがSquareBB。これをまず初期化する。
for sq in Square:
    var r = sq.rank_of()
    var f = sq.file_of()
    SquareBB[sq.ord] = Bitboard()
    if f <= FILE_7: SquareBB[sq.ord].p[0] = int64(1 << (f.ord * 9 + r.ord))
    else: SquareBB[sq.ord].p[0] = 0
    if f >= FILE_8: SquareBB[sq.ord].p[1] = (1 << ((f.ord - FILE_8.ord) * 9 + r.ord))
    else: SquareBB[sq.ord].p[1] = 0
