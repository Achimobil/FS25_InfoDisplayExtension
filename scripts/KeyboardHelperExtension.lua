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