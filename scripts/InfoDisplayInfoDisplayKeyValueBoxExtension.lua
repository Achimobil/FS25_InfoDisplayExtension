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

InfoDisplayInfoDisplayKeyValueBoxExtension = {};

--- Override just to make the fixed programmed width of giant more width
-- @param function superFunc
function InfoDisplayInfoDisplayKeyValueBoxExtension:storeScaledValues(superFunc)
    superFunc(self);

    local infoDisplay = self.infoDisplay;
    local bgWidth = infoDisplay:scalePixelToScreenWidth(460);

    self.bgBottom:setDimension(bgWidth, nil);
    self.bgTop:setDimension(bgWidth, nil);
    self.bgScale:setDimension(bgWidth, nil);

    self.boxWidth = bgWidth;
    self.titleMaxWidth = infoDisplay:scalePixelToScreenWidth(432);
end

InfoDisplayKeyValueBox.storeScaledValues = Utils.overwrittenFunction(InfoDisplayKeyValueBox.storeScaledValues, InfoDisplayInfoDisplayKeyValueBoxExtension.storeScaledValues);

