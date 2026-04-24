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

InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH = 300;
InfoDisplayFillLevelsDisplayExtension.BAR_WIDTH = 247;
InfoDisplayFillLevelsDisplayExtension.MAX_BOXES = 10;
InfoDisplayFillLevelsDisplayExtension.MIN_BOX_WIDTH = 300;
InfoDisplayFillLevelsDisplayExtension.MAX_BOX_WIDTH = 520;
InfoDisplayFillLevelsDisplayExtension.WIDTH_GROW_THRESHOLD = 10;
InfoDisplayFillLevelsDisplayExtension.SHRINK_DELAY = 15000;

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


function InfoDisplayFillLevelsDisplayExtension:draw(superFunc)
    local currentNeededBoxWidth = InfoDisplayFillLevelsDisplayExtension.MIN_BOX_WIDTH;
    local wantedBoxWidth = InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH;

    for _, data in ipairs(self.fillLevelData) do
        if data.isValid then
            local fillTypeText = data.customFillTypeText;

            if fillTypeText == nil and data.fillType ~= FillType.UNKNOWN then
                fillTypeText = g_fillTypeManager:getFillTypeTitleByIndex(data.fillType);
            end

            if fillTypeText ~= nil and data.fillLevelText ~= nil then
                local fillTypeTextWidth = getTextWidth(self.fillTypeTextSize, fillTypeText);
                local fillLevelTextWidth = getTextWidth(self.fillLevelTextSize, data.fillLevelText);

                local neededWidth = fillTypeTextWidth + fillLevelTextWidth + self.fillTypeTextOffsetX + math.abs(self.fillLevelTextOffsetX) + self.typeLevelOffsetX + self:scalePixelToScreenWidth(20);

                if neededWidth > self.bgTotalWidth then
                    local neededBoxWidth = InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH + math.ceil((neededWidth - self.bgTotalWidth) / g_pixelSizeX);
                    currentNeededBoxWidth = math.max(currentNeededBoxWidth, neededBoxWidth);
                    wantedBoxWidth = math.max(wantedBoxWidth, neededBoxWidth);
                end
            end
        end
    end

    wantedBoxWidth = math.min(wantedBoxWidth, InfoDisplayFillLevelsDisplayExtension.MAX_BOX_WIDTH);

    -- Timer reset wenn Breite noch gebraucht wird
    if currentNeededBoxWidth > InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH - InfoDisplayFillLevelsDisplayExtension.WIDTH_GROW_THRESHOLD then
        self.ideShrinkTimer = 0;
    end

    if wantedBoxWidth > InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH + InfoDisplayFillLevelsDisplayExtension.WIDTH_GROW_THRESHOLD then
        InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH = wantedBoxWidth;
        InfoDisplayFillLevelsDisplayExtension.BAR_WIDTH = wantedBoxWidth - 53;

        self:storeScaledValues();
    end

    -- Shrink alle X ms
    if self.ideShrinkTimer ~= nil and self.ideShrinkTimer >= InfoDisplayFillLevelsDisplayExtension.SHRINK_DELAY then
        InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH = math.max(
            InfoDisplayFillLevelsDisplayExtension.MIN_BOX_WIDTH,
            InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH - InfoDisplayFillLevelsDisplayExtension.WIDTH_GROW_THRESHOLD
        );

        InfoDisplayFillLevelsDisplayExtension.BAR_WIDTH = InfoDisplayFillLevelsDisplayExtension.BOX_WIDTH - 53;

        self:storeScaledValues();

        self.ideShrinkTimer = 0;
    end

    superFunc(self);
end

FillLevelsDisplay.draw = Utils.overwrittenFunction(FillLevelsDisplay.draw, InfoDisplayFillLevelsDisplayExtension.draw);

function InfoDisplayFillLevelsDisplayExtension:update(superFunc, dt)
    superFunc(self, dt);

    self.ideShrinkTimer = (self.ideShrinkTimer or 0) + dt;
end

FillLevelsDisplay.update = Utils.overwrittenFunction(FillLevelsDisplay.update, InfoDisplayFillLevelsDisplayExtension.update);