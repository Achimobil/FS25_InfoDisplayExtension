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

        -- Wenn etwas mehrere Erntestufen hat, dann sind es entweder tatsächliche mehrere wie bei Gras oder es sind weed oder andere states dabei.
        -- ich müsste immer max nehmen können solange es nicht ein sonderstatus ist.
        -- Idee ist may state prüfen und runter setzen wenn sonderstatus. Wenn dann max und min nicht gleich sind, dann ist sonderstatus
        -- da die sonderstatus aber gemixed sein können wo was ist, mehrfach durchlaufen
        -- oliven sind im basegame falsch definiert, da fehler bei der weed stufe das isWeed. Das ist aber nicht mein problem
        local maxStateToShow = fruitTypeDesc.minHarvestingGrowthState;
        local showSate = fruitTypeDesc:getIsGrowing(growthState);
        if fruitTypeDesc.yieldScales[fruitTypeDesc.minHarvestingGrowthState] ~= nil then
            -- for fruits like grass where the states have growing yields defined we use the max state to show.
            -- so when the min state has not full harvest amount, then change it
            -- this is more stable than on name and also respect new fruits based on grass or meadow
            if fruitTypeDesc.yieldScales[fruitTypeDesc.minHarvestingGrowthState] ~= 1 then
                maxStateToShow = fruitTypeDesc.maxHarvestingGrowthState;
                -- override grow state because in this case the state needs to be shown even it is not growing
                -- or other explained. When it is not fruit like grass then show only when is growing
                showSate = true
            end
        end
        if showSate and growthState < maxStateToShow then
            box:addLine(g_i18n:getText("ui_map_growth"), string.format("%s / %s", growthState, maxStateToShow))
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