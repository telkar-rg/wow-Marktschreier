local addonName, addonTable = ...;



addonTable.Colors = {}
local colors = addonTable.Colors

addonTable.Functions = {}
local func = addonTable.Functions


colors.sys = "FF7cc1c1"
colors.yellow = "FFffff70"
colors.orange = "FFff9933"
colors.lightblue = "FF44aaff"
colors.gray = "FFaaaaaa"


local function colText(col, txt) return "|c" .. col .. tostring(txt) .. "|r" end
func.colText = colText

