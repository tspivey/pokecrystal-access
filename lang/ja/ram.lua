RAM_IN_BATTLE = 0xd22d
RAM_MENU_HEADER = 0xcf75
RAM_MAP_GROUP = 0xdc7b
RAM_MAP_NUMBER = 0xdc7c
RAM_PLAYER_Y = 0xdc7d
RAM_PLAYER_X = 0xdc7e
RAM_MAP_HEADER = 0xd1ce
RAM_MAP_SCRIPT_HEADER_BANK = RAM_MAP_HEADER+6
RAM_MAP_EVENT_HEADER_POINTER = RAM_MAP_HEADER+9
RAM_MAP_CONNECTIONS = RAM_MAP_HEADER+11
RAM_MAP_NORTH_CONNECTION = RAM_MAP_CONNECTIONS+1
RAM_MAP_SOUTH_CONNECTION = RAM_MAP_CONNECTIONS+1+(1*12)
RAM_MAP_WEST_CONNECTION = RAM_MAP_CONNECTIONS+1+(2*12)
RAM_MAP_EAST_CONNECTION = RAM_MAP_CONNECTIONS+1+(3*12)
RAM_MAP_OBJECTS = 0xd711
RAM_LIVE_OBJECTS = RAM_MAP_OBJECTS+0x100
RAM_MAP_HEIGHT = RAM_MAP_HEADER + 1
RAM_MAP_WIDTH = RAM_MAP_HEADER + 2
RAM_TILE_DOWN = 0xc2fa
RAM_TILE_UP = RAM_TILE_DOWN+1
RAM_TILE_LEFT = RAM_TILE_UP+1
RAM_TILE_RIGHT = RAM_TILE_LEFT+1
RAM_STANDING_TILE = 0xd4d7
RAM_COLLISION_BANK = 0xd210
RAM_COLLISION_ADDR = 0xd211
RAM_OBJECT_STRUCTS = 0xd4c9
RAM_KEYBOARD_X = 0xc330
RAM_KEYBOARD_Y = 0xc331
KEYBOARD_STRING = "ていせい  けってい"
KEYBOARD_UPPER_STRING = "カナ"
KEYBOARD_UPPER = {
{"ア", "イ", "ウ", "エ", "ォ", "ナ", "ニ", "ヌ", "ネ", "ノ", "ヤ", "ユ", "ヨ"},
{"カ", "キ", "ク", "ケ", "コ", "ハ", "ヒ", "フ", "へ", "ホ", "ワ", "ヲ", "ン"},
{"サ", "シ", "ス", "セ", "ソ", "マ", "ミ", "ム", "メ", "モ", "ャ", "ュ", "ョ", "ッ", "ー"},
{"タ", "チ", "ツ", "テ", "ト", "ラ", "り", "ル", "レ", "ロ", "ァ", "ィ", "é", "→", ","},
{"かな", "", "", "", "", "ていせい", "", "", "", "", "けってい", "", "", "", "けってい"}
}
KEYBOARD_LOWER = {
{"あ", "い", "う", "え", "お", "な", "に", "ぬ", "ね", "の", "や", "ゆ", "よ"},
{"か", "き", "く", "け", "こ", "は", "ひ", "ふ", "へ", "ほ", "わ", "を", "ん"},
{"さ", "し", "す", "せ", "そ", "ま", "み", "む", "め", "も", "ゃ", "ゅ", "ょ", "っ", "ー"},
{"た", "ち", "つ", "て", "と", "ら", "り", "る", "れ", "ろ", "?", "!"},
{"カナ", "", "", "", "", "ていせい", "", "", "", "", "けってい", "", "", "", "けってい"}
}
