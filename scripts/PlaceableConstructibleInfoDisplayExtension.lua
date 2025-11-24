PlaceableConstructibleInfoDisplayExtension = {};

---Update the info table
-- @param function superFunc the original overwritten function
-- @param table infoTable the table with the infos to show
function PlaceableConstructibleInfoDisplayExtension:updateInfo(_, superFunc, infoTable)
    superFunc(self, infoTable);
    local spec = self.spec_constructible;

    local finishedStates, numConstructibleStates = self:getNumFinishedConstructibleStates()
    if finishedStates < numConstructibleStates then
        local newEntry = {
            ["title"] = g_i18n:getText("ui_construction_state"),
            ["text"] = string.format("(%d / %d)", finishedStates, numConstructibleStates)
        }
        table.insert(infoTable, newEntry)
    end

    spec.fillTypesAndLevelsAuxiliary = {}
    for fillTypeId, fillLevel in pairs(spec.storage:getFillLevels()) do
        spec.fillTypesAndLevelsAuxiliary[fillTypeId] = (spec.fillTypesAndLevelsAuxiliary[fillTypeId] or 0) + fillLevel
    end
    table.clear(spec.infoTriggerFillTypesAndLevels)
    for fillTypeId, fillLevel in pairs(spec.fillTypesAndLevelsAuxiliary) do
        if fillLevel > 0.1 then
            local fillTypeToFillTypeStorageTable = spec.fillTypeToFillTypeStorageTable
            local fillTypeToFillTypeStorageItem = spec.fillTypeToFillTypeStorageTable[fillTypeId]
            if not fillTypeToFillTypeStorageItem then
                fillTypeToFillTypeStorageItem = {
                    ["fillType"] = fillTypeId,
                    ["fillLevel"] = fillLevel,
                    ["capacity"] = spec.storage:getCapacity(fillTypeId);
                }
            end
            fillTypeToFillTypeStorageTable[fillTypeId] = fillTypeToFillTypeStorageItem
            spec.fillTypeToFillTypeStorageTable[fillTypeId].fillLevel = fillLevel;
            local infoTriggerFillTypesAndLevelsItem = spec.fillTypeToFillTypeStorageTable[fillTypeId]
            table.insert(spec.infoTriggerFillTypesAndLevels, infoTriggerFillTypesAndLevelsItem)
        end
    end

    table.clear(spec.fillTypesAndLevelsAuxiliary)
    table.sort(spec.infoTriggerFillTypesAndLevels, function(a, b)
        return a.fillLevel > b.fillLevel
    end)

    local numEntries = math.min(#spec.infoTriggerFillTypesAndLevels, 7)
    if numEntries > 0 then
        table.insert(infoTable, spec.infoTableEntryStorage)
        for i = 1, numEntries do
            local fillTypeAndLevel = spec.infoTriggerFillTypesAndLevels[i]
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeAndLevel.fillType);
            local newEntry = {
                ["title"] = fillType.title,
                ["text"] = InfoDisplayExtension:formatCapacity(fillTypeAndLevel.fillLevel, fillTypeAndLevel.capacity, 0, fillType.unitShort)
            }
            table.insert(infoTable, newEntry);
        end
    end
    local currentState = spec.stateMachine[spec.stateIndex]
    if currentState.updateInfo ~= nil then
        currentState:updateInfo(infoTable, spec.fillTypeToFillTypeStorageTable)
    end
end
PlaceableConstructible.updateInfo = Utils.overwrittenFunction(PlaceableConstructible.updateInfo, PlaceableConstructibleInfoDisplayExtension.updateInfo)

ConstructibleStateBuildingInfoDisplayExtension = {};

---Update the info table
-- @param function superFunc the original overwritten function
-- @param table infoTable the table with the infos to show
-- @param table fillTypeToFillTypeStorageTable with information about the fill types
function ConstructibleStateBuildingInfoDisplayExtension:updateInfo(superFunc, infoTable, fillTypeToFillTypeStorageTable)
    table.insert(infoTable, self.infoBoxRequiredGoods);
    for _, input in ipairs(self.inputs) do
        if input.remainingAmount > 0 then
            local entry = input.infoTableEntry;
            local missing = input.remainingAmount;
            if fillTypeToFillTypeStorageTable ~= nil and fillTypeToFillTypeStorageTable[input.fillType.index] ~= nil then
                missing = math.max(0, input.remainingAmount - fillTypeToFillTypeStorageTable[input.fillType.index].fillLevel);
            end
            if missing ~= 0 then
                entry.text = InfoDisplayExtension:formatVolume(input.remainingAmount, 0, "") .. " (" .. g_i18n:getText("infohud_missing") .. " " .. InfoDisplayExtension:formatVolume(missing, 0, input.fillType.unitShort) .. ")";
            end

--             entry.text = InfoDisplayExtension:formatCapacity(fillTypeToFillTypeStorageTable[input.fillType.index].fillLevel, input.remainingAmount, 0, input.fillType.unitShort);
            table.insert(infoTable, entry);
        end
    end
end
ConstructibleStateBuilding.updateInfo = Utils.overwrittenFunction(ConstructibleStateBuilding.updateInfo, ConstructibleStateBuildingInfoDisplayExtension.updateInfo)