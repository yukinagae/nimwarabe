
## 手番
type Color = enum BLACK, WHITE, COLOR_ALL ## BLACK: 先手, WHITE: 後手, COLOR_ALL: 先後共通の何か
proc `~`(c: Color): int = c.ord and 1 ## 相手番を返す
proc is_ok(c: Color): bool = (BLACK <= c) and (c <= COLOR_ALL) ## 正常な値であるかを検査する。assertで使う用。
proc p(c: Color) = echo c ## 出力用(USI形式ではない)　デバッグ用。

## 筋
type File = enum FILE_1, FILE_2, FILE_3, FILE_4, FILE_5, FILE_6, FILE_7, FILE_8, FILE_9 ## 例) FILE_3なら3筋。
proc is_ok(f: FIle): bool = (FILE_1 <= f) and (f <= FILE_9) ## 正常な値であるかを検査する。assertで使う用。
proc toFile(c: char): File = File(c.ord - '1'.ord) ## USIの指し手文字列などで筋を表す文字列をここで定義されたFileに変換する。(1~9)
proc p(f: File) = echo 1 + f.ord ## USI形式でFileを出力する

## 段
type Rank = enum RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8, RANK_9 ## 例) RANK_4なら4段目。
proc is_ok(r: Rank): bool = (RANK_1 <= r) and (r <= RANK_9) ## 正常な値であるかを検査する。assertで使う用。
proc toRank(c: char): Rank = Rank(c.ord - 'a'.ord) ## USIの指し手文字列などで段を表す文字列をここで定義されたRankに変換する。(a~i)
proc p(r: Rank) = echo char('a'.ord + r.ord) ## USI形式でRankを出力する
