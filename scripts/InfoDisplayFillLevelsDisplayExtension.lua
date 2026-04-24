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

InfoDisplayFillLevelsDisplayExtension = {};

InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH = 420;
InfoDisplayFillLevelsDisplayExtension.BAR_WIDTH = 367;
InfoDisplayFillLevelsDisplayExtension.MAX_BOXES = 10;

FillLevelsDisplay.MAX_BOXES = InfoDisplayFillLevelsDisplayExtension.MAX_BOXES;

function InfoDisplayFillLevelsDisplayExtension:storeScaledValues(superFunc)
    superFunc(self);

    local bgLeftWidth = self.bgLeft.width;
    local bgRightWidth = self.bgRight.width;
    local bgScaleWidth = self:scalePixelToScreenWidth(InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH) - bgLeftWidth - bgRightWidth;

    self.bgTotalWidth = bgScaleWidth + bgLeftWidth + bgRightWidth;

    self.bgScale:setDimension(bgScaleWidth, nil);

    self.bgRight:setPosition(g_hudAnchorRight - self.bgRight.width, nil);
    self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, nil);
    self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, nil);

    local barTotalWidth = self:scalePixelToScreenWidth(InfoDisplayFillLevelsDisplayExtension.BAR_WIDTH);

    self.barTotalWidth = barTotalWidth;
    self.barMaxScaleWidth = barTotalWidth - self.barMinWidth;

    self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil);

    self.helpAnchorPosX = self.bgLeft.x + self:scalePixelToScreenWidth(-15);
end

FillLevelsDisplay.storeScaledValues = Utils.overwrittenFunction(FillLevelsDisplay.storeScaledValues, InfoDisplayFillLevelsDisplayExtension.storeScaledValues);