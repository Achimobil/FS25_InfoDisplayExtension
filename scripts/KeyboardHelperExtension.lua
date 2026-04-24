--[[
Copyright (C) Achimobil, 2022-2026

Author: Achimobil

Mod:
FS25_InfoDisplayExtension

Contact:
https://github.com/Achimobil/FS25_InfoDisplayExtension

Important:
This script is part of the FS25_InfoDisplayExtension mod.

Copying this script, using it in other mods or maps, publishing modified versions,
or reusing parts of this script is not permitted without explicit written permission
from the author.

Das Kopieren, Verwenden in eigenen Mods oder Maps, Verändern, Wiederveröffentlichen
oder teilweise Wiederverwenden dieses Skripts ist ohne ausdrückliche schriftliche
Erlaubnis des Autors nicht gestattet.
]]

-- Overwritter to make it possible to load key translations from the mor
KeyboardHelperExtension = {};
function KeyboardHelperExtension.getDisplayKeyName(keyCode)
    local keyGlyph = KeyboardHelper.KEY_GLYPHS[keyCode];
    local text;
    if keyGlyph == nil then
        text = nil;
    else
        text = g_i18n:getText(keyGlyph, g_currentModName);
        if string.find(text, "Missing") then
            text = nil;
        end
    end
    if text == nil then
        text = getKeyName(keyCode);
    end
    return text;
end
KeyboardHelper.getDisplayKeyName = Utils.overwrittenFunction(KeyboardHelper.getDisplayKeyName, KeyboardHelperExtension.getDisplayKeyName)