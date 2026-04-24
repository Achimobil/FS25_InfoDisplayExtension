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

HarvestMissionExtension = {}

function HarvestMissionExtension.isAvailableForField(field, superFunc, mission)
-- InfoDisplayExtension.DebugText("HarvestMissionExtension.isAvailableForField(%s, %s)", field, mission);
    if mission == nil then
        local fieldState = field:getFieldState();
        if not fieldState.isValid then
            return false;
        end
        local fruitTypeIndex = fieldState.fruitTypeIndex;
        if fruitTypeIndex == FruitType.UNKNOWN then
            return false;
        end
        local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex);
        if fruitDesc:getIsCatchCrop() then
            return false;
        end
        -- preparable means harvest mission can be done
        if fruitDesc:getIsPreparable(fieldState.growthState) then
            return true;
        end
        if not fruitDesc:getIsHarvestReady(fieldState.growthState) then
            return false;
        end
    end
    return true;
end

HarvestMission.isAvailableForField = Utils.overwrittenFunction(HarvestMission.isAvailableForField, HarvestMissionExtension.isAvailableForField)