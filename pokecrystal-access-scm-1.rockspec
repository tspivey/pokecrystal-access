package = "pokecrystal-access"
version = "scm-1"
source = {
   url = "https://github.com/tspivey/pokecrystal-access"
}
description = {
   homepage = "http://allinaccess.com/pca/",
   license = "GPLv2"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      ["a-star"] = "a-star.lua",
      encoding = "encoding.lua",
      inputbox = "inputbox.lua",
      ["lang.de.chars"] = "lang/de/chars.lua",
      ["lang.de.ram"] = "lang/de/ram.lua",
      ["lang.en.chars"] = "lang/en/chars.lua",
      ["lang.en.default_names"] = "lang/en/default_names.lua",
      ["lang.en.fonts"] = "lang/en/fonts.lua",
      ["lang.en.ram"] = "lang/en/ram.lua",
      ["lang.en.sprites"] = "lang/en/sprites.lua",
      ["lang.es.chars"] = "lang/es/chars.lua",
      ["lang.es.ram"] = "lang/es/ram.lua",
      ["lang.fr.chars"] = "lang/fr/chars.lua",
      ["lang.fr.ram"] = "lang/fr/ram.lua",
      ["lang.it.chars"] = "lang/it/chars.lua",
      ["lang.it.ram"] = "lang/it/ram.lua",
      ["lang.ja.chars"] = "lang/ja/chars.lua",
      ["lang.ja.default_names"] = "lang/ja/default_names.lua",
      ["lang.ja.fonts"] = "lang/ja/fonts.lua",
      ["lang.ja.ram"] = "lang/ja/ram.lua",
      ["lang.ja.sprites"] = "lang/ja/sprites.lua",
      ["rxi-json-lua"] = "log.lua",
      serpent = "serpent.lua",
      tolk = "tolk.lua"
   }
}
