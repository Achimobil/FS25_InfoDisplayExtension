IdePlayerHUDUpdaterExtension = {};

---append to PlayerHUDUpdater fieldAddField to add more information
-- @param table self
-- @param table fieldInfo
-- @param InfoDisplayKeyValueBox box
function IdePlayerHUDUpdaterExtension.fieldAddField(self, fieldInfo, box)

    local fruitTypeIndex = fieldInfo.fruitTypeIndex;
    local growthState = fieldInfo.growthState;

    if fruitTypeIndex ~= FruitType.UNKNOWN then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex);

        if (fruitTypeDesc.name == "GRASS" or fruitTypeDesc.name == "MEADOW") and growthState < fruitTypeDesc.maxHarvestingGrowthState then
            -- Gras hat 2 erntebare Wachstumsstufen. Oliven aber auch und die kann man nicht unterscheiden aktuell ob es noch mal wächst oder nur verdorrt.
            -- deshalb hier speziell für Gras eine Anzeige mit max state
            -- Wenn richtige Früchte mit vielen Erntestufen kommen müsste man hier mal schauen wie man die doch noch unterscheiden kann.
            box:addLine(g_i18n:getText("ui_map_growth"), string.format("%s / %s", growthState, fruitTypeDesc.maxHarvestingGrowthState))
        elseif fruitTypeDesc:getIsGrowing(growthState) then
            -- alles was keine Ausnahme ist kann über getIsGrowing geprüft werden ob eine Anzeige notwendig ist
            box:addLine(g_i18n:getText("ui_map_growth"), string.format("%s / %s", growthState, fruitTypeDesc.minHarvestingGrowthState))
        end
    end
end

PlayerHUDUpdater.fieldAddField = Utils.appendedFunction(PlayerHUDUpdater.fieldAddField, IdePlayerHUDUpdaterExtension.fieldAddField)

function IdePlayerHUDUpdaterExtension:fieldAddWeed(superFunc, data, box)
--     InfoDisplayExtension.DebugText("InfoDisplayExtension:fieldAddWeed(%s, %s, %s)", superFunc, data, box)
    if g_currentMission.missionInfo.weedsEnabled then
        local weedSystem = g_currentMission.weedSystem
        local fieldInfos = weedSystem:getFieldInfoStates()
        local weedState = data.weedState
        local fruitTypeIndex = data.fruitTypeIndex or FruitType.UNKNOWN
        local growthState = data.growthState or 0
        local toolText = nil
        if weedState ~= 0 then
--             InfoDisplayExtension.DebugTable("fieldInfos", fieldInfos)
            local fruitTypeDesc
            if fruitTypeIndex == nil then
                fruitTypeDesc = nil
            else
                fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
            end
            if Platform.gameplay.hasWeeder then
                if (fruitTypeDesc == nil or fruitTypeDesc:getIsWeedable(growthState)) and weedSystem:getWeederReplacements(false).weed.replacements[weedState] == 0 then
                    toolText = g_i18n:getText("weed_destruction_weeder")
                end
                if toolText == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsHoeable(growthState)) and weedSystem:getWeederReplacements(true).weed.replacements[weedState] == 0 then
                    toolText = g_i18n:getText("weed_destruction_hoe")
                end
            end
--             InfoDisplayExtension.DebugText("InfoDisplayExtension (%s, %s, %s)", Platform.gameplay.hasWeeder, growthState, toolText);
            if toolText == nil and (fruitTypeDesc == nil or fruitTypeDesc:getIsGrowing(growthState)) then
                toolText = g_i18n:getText("weed_destruction_herbicide")
            end
            local fieldInfo = fieldInfos[weedState]
--             InfoDisplayExtension.DebugText("InfoDisplayExtension (%s, %s)",toolText , fieldInfo);
            if fieldInfo ~= nil then
                box:addLine(fieldInfo, toolText or "-", false)
            end
        end
    else
        return
    end
end

PlayerHUDUpdater.fieldAddWeed = Utils.overwrittenFunction(PlayerHUDUpdater.fieldAddWeed, IdePlayerHUDUpdaterExtension.fieldAddWeed)