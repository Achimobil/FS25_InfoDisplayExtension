
PlaceableFactoryInfoDisplayExtension = {};

function PlaceableFactoryInfoDisplayExtension:updateInfoPlaceableFactory(superFunc2, superFunc, infoTable)
--     InfoDisplayExtension.DebugText("%s, %s, %s, %s", self, superFunc2, superFunc, infoTable)
--     InfoDisplayExtension.DebugTable("self", self);
--     InfoDisplayExtension.DebugTable("infoTable", infoTable);
    superFunc(self, infoTable);

    local spec = self.spec_factory;

    if spec.hasInputMaterials then
        local fillTypeAndLevelCount = #spec.infoTriggerFillTypesAndLevels;
--         InfoDisplayExtension.DebugTable("fillTypeAndLevel", fillTypeAndLevelCount);
        local maxEntries = math.min(fillTypeAndLevelCount, 7);
        if maxEntries > 0 then
            local header = spec.infoTableEntryStorage;
            table.insert(infoTable, header);
            for v153 = 1, maxEntries do
                local fillTypeAndLevel = spec.infoTriggerFillTypesAndLevels[v153];
                local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeAndLevel.fillType);
                local capacity = spec:getCapacity(fillTypeAndLevel.fillType);
                local newEntry = {
                    ["title"] = fillType.title,
                    ["text"] = InfoDisplayExtension:formatCapacity(fillTypeAndLevel.fillLevel, capacity, 0, fillType.unitShort)
                }
                table.insert(infoTable, newEntry)
            end
        end
    else
        local newEntry = {
            ["title"] = g_i18n:getText("ui_production_status_materialsMissing"),
            ["accentuate"] = true
        }
        table.insert(infoTable, newEntry)
        for _, input in ipairs(spec.inputs) do
            local newInputEntry = {
                ["title"] = "   " .. g_fillTypeManager:getFillTypeTitleByIndex(input.fillType.index)
            }
            table.insert(infoTable, newInputEntry)
        end
    end
    local progressEntry = {
        ["title"] = g_i18n:getText("contract_progress"),
        ["text"] = string.format("%.1f%%", spec.progress * 100),
        ["accentuate"] = false
    }
    table.insert(infoTable, progressEntry)
--     InfoDisplayExtension.DebugTable("infoTable  ", infoTable);
end
PlaceableFactory.updateInfo = Utils.overwrittenFunction(PlaceableFactory.updateInfo, PlaceableFactoryInfoDisplayExtension.updateInfoPlaceableFactory)
