--[[
Copyright (C) Achimobil, 2022-2024

Author: Achimobil

Contact:
https://github.com/Achimobil/FS22_InfoDisplayExtension


Important:
No copy and use in own mods allowed.

Das verändern und wiederöffentlichen, auch in Teilen, ist untersagt und wird abgemahnt.
]]

InfoDisplayExtension = {}
InfoDisplayExtension.Debug = false;

InfoDisplayExtension.metadata = {
    title = "InfoDisplayExtension",
    notes = "Erweiterung des Infodisplays für Silos und Produktionen",
    author = "Achimobil",
    info = "Das verändern und wiederöffentlichen, auch in Teilen, ist untersagt und wird abgemahnt."
};
InfoDisplayExtension.modDir = g_currentModDirectory;

source(InfoDisplayExtension.modDir.."scripts/PlaceableConstructibleInfoDisplayExtension.lua");
source(InfoDisplayExtension.modDir.."scripts/PlaceableFactoryInfoDisplayExtension.lua");
source(InfoDisplayExtension.modDir.."scripts/HarvestMissionExtension.lua");

--- Print the given Table to the log
-- @param string text parameter Text before the table
-- @param table myTable The table to print
-- @param number maxDepth depth of print, default 2
function InfoDisplayExtension.DebugTable(text, myTable, maxDepth)
    if not InfoDisplayExtension.Debug then return end
    if myTable == nil then
        print("InfoDisplayExtensionDebug: " .. text .. " is nil");
    else
        print("InfoDisplayExtensionDebug: " .. text)
        DebugUtil.printTableRecursively(myTable,"_",0, maxDepth or 2);
    end
end

---Print the text to the log. Example: InfoDisplayExtension.DebugText("Alter: %s", age)
-- @param string text the text to print formated
-- @param any ... format parameter
function InfoDisplayExtension.DebugText(text, ...)
    if not InfoDisplayExtension.Debug then return end
    print("InfoDisplayExtensionDebug: " .. string.format(text, ...));
end

---format a volume
-- @param float liters amount to format
-- @param integer precision how many decimals
-- @param string unit which unit should be used, default 2
-- @return string the formated value
function InfoDisplayExtension:formatVolume(liters, precision, unit)
    unit = unit ~= "" and (unit == false and "" or unit) or nil

    return g_i18n:formatVolume(liters, precision, unit)
end

---format a volume with capacity
-- @param float liters amount to format
-- @param float capacity capacity to format
-- @param integer precision how many decimals
-- @param string unit which unit should be used
-- @return string the formated value
function InfoDisplayExtension:formatCapacity(liters, capacity, precision, unit)
    return self:formatVolume(liters, precision, false) .. " / " .. self:formatVolume(capacity, precision, unit);
end

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableSilo(_, superFunc, infoTable)
    superFunc(self, infoTable)

    local spec = self.spec_silo;
    local farmId = g_currentMission:getFarmId();
    local totalFillLevel = 0;

    -- collect capacities
    local sourceStorages = spec.loadingStation:getSourceStorages();
    local totalCapacity = 0;
    local fillTypesCapacities = {}

    for _, sourceStorage in pairs(sourceStorages) do
        if spec.loadingStation:hasFarmAccessToStorage(farmId, sourceStorage) then
            totalCapacity = totalCapacity + sourceStorage.capacity;

            if(sourceStorage.capacities ~= nil) then
                for fillType, fillLevel in pairs(sourceStorage.fillLevels) do
                    if(sourceStorage.capacities[fillType] ~= nil) then
                        fillTypesCapacities[fillType] = Utils.getNoNil(fillTypesCapacities[fillType], 0) + sourceStorage.capacities[fillType]
                    end
                end
            end
        end
    end

    for fillType, fillLevel in pairs(spec.loadingStation:getAllFillLevels(farmId)) do
        spec.fillTypesAndLevelsAuxiliary[fillType] = (spec.fillTypesAndLevelsAuxiliary[fillType] or 0) + fillLevel
        totalFillLevel = totalFillLevel + fillLevel
    end

    table.clear(spec.infoTriggerFillTypesAndLevels)

    for fillType, fillLevel in pairs(spec.fillTypesAndLevelsAuxiliary) do
        if fillLevel > 0.1 then
            spec.fillTypeToFillTypeStorageTable[fillType] = spec.fillTypeToFillTypeStorageTable[fillType] or {
                fillType = fillType,
                fillLevel = fillLevel,
                capacity = fillTypesCapacities[fillType],
                title = g_fillTypeManager:getFillTypeTitleByIndex(fillType)
            }
            spec.fillTypeToFillTypeStorageTable[fillType].fillLevel = fillLevel

            table.insert(spec.infoTriggerFillTypesAndLevels, spec.fillTypeToFillTypeStorageTable[fillType])
        end
    end

    table.clear(spec.fillTypesAndLevelsAuxiliary)
    table.sort(spec.infoTriggerFillTypesAndLevels, function (a, b)
        return b.title > a.title
    end)

    local numEntries = math.min(#spec.infoTriggerFillTypesAndLevels, 25)

    if numEntries > 0 then
        for i = 1, numEntries do
            local fillTypeAndLevel = spec.infoTriggerFillTypesAndLevels[i]
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeAndLevel.fillType);
            if fillTypeAndLevel.capacity == nil then
                table.insert(infoTable, {
                    title = fillType.title,
                    text = InfoDisplayExtension:formatVolume(fillTypeAndLevel.fillLevel, 0, fillType.unitShort, fillType.name)
                })
            else
                table.insert(infoTable, {
                    title = fillType.title,
                    text = InfoDisplayExtension:formatCapacity(fillTypeAndLevel.fillLevel, fillTypeAndLevel.capacity, 0, fillType.unitShort, fillType.name)
                })
            end
        end
        if #spec.infoTriggerFillTypesAndLevels > 25 then
            table.insert(infoTable, {
                title = g_i18n:getText("infoDisplayExtension_MORE_ITEMS"),
                text = string.format("%d", #spec.infoTriggerFillTypesAndLevels - 25)
            })
        end
    else
        table.insert(infoTable, {
            text = "",
            title = g_i18n:getText("infohud_siloEmpty")
        })
    end

    table.insert(infoTable,
        {
            title = g_i18n:getText("infoDisplayExtension_TOTAL_CAPACITY_TITLE"),
            accentuate = true
        }
    )

    table.insert(infoTable,
        {
            title = g_i18n:getText("infoDisplayExtension_USED_CAPACITY"),
            text = InfoDisplayExtension:formatVolume(totalFillLevel, 0)
        }
    )

    if totalCapacity ~= 0 then
        table.insert(infoTable,
            {
                title = g_i18n:getText("infoDisplayExtension_TOTAL_CAPACITY"),
                text = InfoDisplayExtension:formatVolume(totalCapacity, 0)
            }
        )
    end

    -- print("test")
end
PlaceableSilo.updateInfo = Utils.overwrittenFunction(PlaceableSilo.updateInfo, InfoDisplayExtension.updateInfoPlaceableSilo)

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoProductionPoint(superFunc, infoTable)
    local owningFarm = g_farmManager:getFarmById(self:getOwnerFarmId())

    if owningFarm ~= nil then
        table.insert(infoTable, {
            title = g_i18n:getText("fieldInfo_ownedBy"),
            text = owningFarm.name
        })
    end

    if #self.activeProductions > 0 then
        table.insert(infoTable, self.infoTables.activeProds)

        local activeProduction = nil

        for i = 1, #self.activeProductions do
            activeProduction = self.activeProductions[i]
            local productionName = activeProduction.name or g_fillTypeManager:getFillTypeTitleByIndex(activeProduction.primaryProductFillType)

            table.insert(infoTable, {
                title = productionName,
                text = g_i18n:getText(ProductionPoint.PROD_STATUS_TO_L10N[self:getProductionStatus(activeProduction.id)])
            })
        end
    else
        table.insert(infoTable, self.infoTables.noActiveProd)
    end

    local fillTypeIndex, fillLevel, fillLevelCapacity = nil
    local fillTypesDisplayed = false

    --table.insert(infoTable, self.infoTables.storage)

    -- temp list of input and output filltypes to show the three types seperately
    local inputOutputType = {};
    local inputOutputTypeInfo = {};

    local titleAdded = false;
    for i = 1, #self.inputFillTypeIdsArray do
        fillTypeIndex = self.inputFillTypeIdsArray[i]

        local isOutput = false;
        for i = 1, #self.outputFillTypeIdsArray do
            local fillType2 = self.outputFillTypeIdsArray[i]
            if fillTypeIndex == fillType2 then
                inputOutputType[fillTypeIndex] = true
                isOutput = true;
            end
        end

        fillLevel = self:getFillLevel(fillTypeIndex)
        fillLevelCapacity = self:getCapacity(fillTypeIndex)

        if fillLevel > 1 then
            fillTypesDisplayed = true
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex);
            if isOutput then
                table.insert(inputOutputTypeInfo, {
                    title = fillType.title,
                    text = InfoDisplayExtension:formatCapacity(fillLevel, fillLevelCapacity, 0, fillType.unitShort, fillType.name)
                })
            else
                if not titleAdded then
                    table.insert(infoTable, {
                        accentuate = true,
                        title = g_i18n:getText("ui_productions_buildingStorage") .. " - " .. g_i18n:getText("infohud_Input")
                    })
                    titleAdded = true;
                end
                table.insert(infoTable, {
                    title = fillType.title,
                    text = InfoDisplayExtension:formatCapacity(fillLevel, fillLevelCapacity, 0, fillType.unitShort, fillType.name)
                })
            end
        end
    end

    titleAdded = false;
    for i = 1, #inputOutputTypeInfo do
        if not titleAdded then
            table.insert(infoTable, {
                accentuate = true,
                title = g_i18n:getText("ui_productions_buildingStorage") .. " - " .. g_i18n:getText("infohud_both")
            })
            titleAdded = true;
        end

        local inputOutputTypeInfoItem = inputOutputTypeInfo[i]
        table.insert(infoTable, inputOutputTypeInfoItem)
    end

    titleAdded = false;
    for i = 1, #self.outputFillTypeIdsArray do
        fillTypeIndex = self.outputFillTypeIdsArray[i]
        fillLevel = self:getFillLevel(fillTypeIndex)
        fillLevelCapacity = self:getCapacity(fillTypeIndex)

        if fillLevel > 1 and inputOutputType[fillTypeIndex] == nil then
            fillTypesDisplayed = true
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex);

            if not titleAdded then
                table.insert(infoTable, {
                    accentuate = true,
                    title = g_i18n:getText("ui_productions_buildingStorage") .. " - " .. g_i18n:getText("infohud_Output")
                })
                titleAdded = true;
            end

            table.insert(infoTable, {
                title = fillType.title,
                text = InfoDisplayExtension:formatCapacity(fillLevel, fillLevelCapacity, 0, fillType.unitShort, fillType.name)
            })
        end
    end

    if not fillTypesDisplayed then
        table.insert(infoTable, self.infoTables.storage)
        table.insert(infoTable, self.infoTables.storageEmpty)
    end

    if self.palletLimitReached then
        table.insert(infoTable, self.infoTables.palletLimitReached)
    end
end
ProductionPoint.updateInfo = Utils.overwrittenFunction(ProductionPoint.updateInfo, InfoDisplayExtension.updateInfoProductionPoint)

function InfoDisplayExtension:populateCellForItemInSection(superFunc, list, section, index, cell)
    if list == self.productionList then
        local productionPoint = self:getProductionPoints()[section]
        local production = productionPoint.productions[index]
        local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(production.primaryProductFillType)

        if fillTypeDesc ~= nil then
            cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
        end

        cell:getAttribute("icon"):setVisible(fillTypeDesc ~= nil)
        cell:getAttribute("name"):setText(production.name or fillTypeDesc.title)

        local status = production.status
        local activityElement = cell:getAttribute("activity")

        if status == ProductionPoint.PROD_STATUS.RUNNING then
            activityElement:applyProfile("ingameMenuProductionProductionActivityActive")
        elseif status == ProductionPoint.PROD_STATUS.MISSING_INPUTS or status == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE then
            activityElement:applyProfile("ingameMenuProductionProductionActivityIssue")
        else
            activityElement:applyProfile("ingameMenuProductionProductionActivity")
        end
    else
        local _, productionPoint = self:getSelectedProduction()
        local fillType, isInput = nil

        if section == 1 then
            fillType = self.selectedProductionPoint.inputFillTypeIdsArray[index]
            isInput = true
        else
            fillType = self.selectedProductionPoint.outputFillTypeIdsArray[index]
            isInput = false
        end

        if fillType ~= FillType.UNKNOWN then
            local fillLevel = self.selectedProductionPoint:getFillLevel(fillType)
            local capacity = self.selectedProductionPoint:getCapacity(fillType)
            local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)

-- für große breiten rechts ausrichten
            cell:getAttribute("fillLevel").textAlignment = RenderText.ALIGN_RIGHT
            cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
            cell:getAttribute("fillType"):setText(fillTypeDesc.title)
            cell:getAttribute("fillLevel"):setText(InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0, fillTypeDesc.unitShort, fillTypeDesc.name));

            if not isInput then
                local outputMode = productionPoint:getOutputDistributionMode(fillType)
                local outputModeText = g_i18n:getText("Revamp_Spawn")

                if outputMode == ProductionPoint.OUTPUT_MODE.DIRECT_SELL then
                    outputModeText = self.i18n:getText("ui_production_output_selling")
                elseif outputMode == ProductionPoint.OUTPUT_MODE.AUTO_DELIVER then
                    outputModeText = self.i18n:getText("ui_production_output_distributing")
                --Production Revamp: Hinzugefügt um die "Einlagern" Option anzeigen zu können
                elseif outputMode == ProductionPoint.OUTPUT_MODE.STORE then
                    outputModeText = g_i18n:getText("Revamp_Store");
                end

                cell:getAttribute("outputMode"):setText(outputModeText)
            end

            self:setStatusBarValue(cell:getAttribute("bar"), fillLevel / capacity, isInput)
        end
    end
end

function InfoDisplayExtension:getProductionPoints(superFunc)
    local productionPoints = self.chainManager:getProductionPointsForFarmId(self.playerFarm.farmId)

    local shownProductionPoint = {}
    for _, productionPoint in ipairs (productionPoints) do
        -- remove the hidden productions of GtX Extended production points
        if productionPoint.hiddenOnUI == nil or productionPoint.hiddenOnUI == false then
            table.insert(shownProductionPoint, productionPoint)
        end
    end

    table.sort(shownProductionPoint,compProductionPoints)
    return shownProductionPoint;
end
function compProductionPoints(w1,w2)
    return w1:getName() .. w1.id < w2:getName() .. w2.id;
end

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableHusbandryAnimals(_, superFunc, infoTable)
    superFunc(self, infoTable)

    local spec = self.spec_husbandryAnimals
    local health = 0
    local numAnimals = 0
    local maxNumAnimals = spec:getMaxNumOfAnimals()
    local clusters = spec.clusterSystem:getClusters()
    local numClusters = #clusters

    if numClusters > 0 then
        for _, cluster in ipairs(clusters) do
            health = health + cluster.health
            numAnimals = numAnimals + cluster.numAnimals
        end

        health = health / numClusters
    end

    spec.infoNumAnimals.text = string.format("%d", numAnimals) .. " / " .. string.format("%d", maxNumAnimals)
    -- spec.infoHealth.text = string.format("%d %%", health)

    table.insert(infoTable, spec.infoNumAnimals)
    -- table.insert(infoTable, spec.infoHealth)

    local isHorse = spec.animalTypeIndex == AnimalType.HORSE;
    local moreInfos = PlaceableHusbandryAnimals.setMoreInfos(clusters, isHorse);

    -- Alles irgendwie hübsch anzeigen
    if moreInfos.health ~= nil and moreInfos.highestHealth ~= nil and moreInfos.lowestHealth ~= nil then
        if moreInfos.health == moreInfos.highestHealth and moreInfos.health == moreInfos.lowestHealth then
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "health", string.format("%d %%", moreInfos.health))
        else
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "healthRange", string.format("%d - %d %%", moreInfos.lowestHealth, moreInfos.highestHealth))
        end
    end

    if moreInfos.duration ~= nil and moreInfos.lowestDuration ~= nil and moreInfos.highestDuration ~= nil then
        if moreInfos.duration == moreInfos.lowestDuration and moreInfos.duration == moreInfos.highestDuration then
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "duration", g_i18n:formatNumMonth(moreInfos.duration))
        else
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "durationRange", moreInfos.lowestDuration .. " - " .. g_i18n:formatNumMonth(moreInfos.highestDuration))
        end
    end

    if moreInfos.reproduction ~= nil and moreInfos.highestReproduction ~= nil and moreInfos.lowestReproduction ~= nil then
        if moreInfos.reproduction == moreInfos.highestReproduction and moreInfos.reproduction == moreInfos.lowestReproduction then
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "reproduction", string.format("%d %%", moreInfos.reproduction))
        else
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "reproductionRange", string.format("%d - %d %%", moreInfos.lowestReproduction, moreInfos.highestReproduction))
        end
    end

    if moreInfos.beforeReproduction ~= nil and moreInfos.highestBeforeReproduction ~= nil and moreInfos.lowestBeforeReproduction ~= nil then
        if moreInfos.beforeReproduction == moreInfos.highestBeforeReproduction and moreInfos.beforeReproduction == moreInfos.lowestBeforeReproduction then
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "beforeReproduction", string.format("%d %%", moreInfos.beforeReproduction))
        else
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "beforeReproductionRange", string.format("%d - %d %%", moreInfos.lowestBeforeReproduction, moreInfos.highestBeforeReproduction))
        end
    end

    if moreInfos.nextBirthIn ~= nil and moreInfos.nextBirthIn ~= 0 then
        PlaceableHusbandryAnimals.AddInfoText(infoTable, "nextBirthIn", g_i18n:formatNumMonth(moreInfos.nextBirthIn))
    end

    if moreInfos.dirt ~= nil and moreInfos.highestDirt ~= nil and moreInfos.lowestDirt ~= nil then
        if moreInfos.dirt == moreInfos.highestDirt and moreInfos.dirt == moreInfos.lowestDirt then
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "dirt", string.format("%d %%", moreInfos.dirt))
        else
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "dirtRange", string.format("%d - %d %%", moreInfos.lowestDirt, moreInfos.highestDirt))
        end
    end

    if moreInfos.riding ~= nil and moreInfos.highestRiding ~= nil and moreInfos.lowestRiding ~= nil then
        if moreInfos.riding == moreInfos.highestRiding and moreInfos.riding == moreInfos.lowestRiding then
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "riding", string.format("%d %%", moreInfos.riding))
        else
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "ridingRange", string.format("%d - %d %%", moreInfos.lowestRiding, moreInfos.highestRiding))
        end
    end

    if moreInfos.fitness ~= nil and moreInfos.highestFitness ~= nil and moreInfos.lowestFitness ~= nil then
        if moreInfos.fitness == moreInfos.highestFitness and moreInfos.fitness == moreInfos.lowestFitness then
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "fitness", string.format("%d %%", moreInfos.fitness))
        else
            PlaceableHusbandryAnimals.AddInfoText(infoTable, "fitnessRange", string.format("%d - %d %%", moreInfos.lowestFitness, moreInfos.highestFitness))
        end
    end
end
PlaceableHusbandryAnimals.updateInfo = Utils.overwrittenFunction(PlaceableHusbandryAnimals.updateInfo, InfoDisplayExtension.updateInfoPlaceableHusbandryAnimals)

function PlaceableHusbandryAnimals.AddInfoText(infoTable, title, text)
    table.insert(infoTable,
        {
            title = g_i18n:getText("infoDisplayExtension_animals_" .. title),
            -- title = title,
            text = tostring(text)
        }
    )
end

-- mor info from HappyLooser
function PlaceableHusbandryAnimals.setMoreInfos(clusters, isHorse)
    local moreInfos = {};
    if clusters ~= nil and type(clusters) == "table" and #clusters > 0 then
        local totalSellPrice = 0;
        local horseClusters = 0;
        local healthClusters = 0;
        local health = 0;
        local highestHealth = 0;
        local lowestHealth = 0;
        local reproductionClusters = 0;
        local reproduction = 0;
        local highestReproduction = 0;
        local lowestReproduction = nil;
        local beforeReproductionClusters = 0;
        local beforeReproduction = 0;
        local highestBeforeReproduction = 0;
        local lowestBeforeReproduction = nil;
        local durationClusters = 0;
        local duration = 0;
        local highestDuration = 0;
        local lowestDuration = nil;
        local fitness = 0;
        local highestFitness = 0;
        local lowestFitness = 0;
        local dirt = 0;
        local highestDirt = 0;
        local lowestDirt = 0;
        local riding = 0;
        local highestRiding = 0;
        local lowestRiding = 0;
        local nextBirthIn = 0;

        for _, cluster in ipairs(clusters) do
            totalSellPrice = totalSellPrice + cluster:getSellPrice();
            if cluster.health > highestHealth then highestHealth = cluster.health;end;
            if (cluster.health < lowestHealth) or lowestHealth == 0 then lowestHealth = cluster.health;end;
            health = health + cluster.health;
            healthClusters = healthClusters+1;
            local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex);
            if subType ~= nil then
                if subType.supportsReproduction and subType.reproductionMinHealth <= cluster:getHealthFactor() and subType.reproductionMinAgeMonth <= cluster.age then
                    -- reproduktionzeit der Tiere ausrechnen
                    duration = duration + subType.reproductionDurationMonth;
                    durationClusters = durationClusters+1;					
                    if subType.reproductionDurationMonth > highestDuration then highestDuration = subType.reproductionDurationMonth;end;
                    if lowestDuration == nil then lowestDuration = subType.reproductionDurationMonth;end;
                    if subType.reproductionDurationMonth < lowestDuration then lowestDuration = subType.reproductionDurationMonth;end;
                end;
                if cluster.age < subType.reproductionMinAgeMonth then
                    -- Rate für
                    local minAgeFactor = math.clamp(cluster.age / subType.reproductionMinAgeMonth, 0, 1) * 100
                    if minAgeFactor > highestBeforeReproduction then highestBeforeReproduction = minAgeFactor;end;
                    if lowestBeforeReproduction == nil then lowestBeforeReproduction = minAgeFactor;end;
                    if minAgeFactor < lowestBeforeReproduction then lowestBeforeReproduction = minAgeFactor;end;
                    beforeReproduction = beforeReproduction + minAgeFactor;
                    beforeReproductionClusters = beforeReproductionClusters+1;
                else
                    if cluster.reproduction > highestReproduction then highestReproduction = cluster.reproduction;end;
                    if lowestReproduction == nil then lowestReproduction = cluster.reproduction;end;
                    if cluster.reproduction < lowestReproduction then lowestReproduction = cluster.reproduction;end;
                    reproduction = reproduction + cluster.reproduction;
                    reproductionClusters = reproductionClusters+1;
                    -- wann der nächste Nachwuchs?

                    if cluster:getCanReproduce() then
                        local months = subType.reproductionDurationMonth - (subType.reproductionDurationMonth * cluster:getReproductionFactor())
                        if nextBirthIn == 0 then nextBirthIn = months;end;
                        if months < nextBirthIn then nextBirthIn = months;end;
                    end
                end;
            end;
            if isHorse and cluster.dirt ~= nil and cluster.fitness ~= nil and cluster.riding ~= nil then							
                horseClusters = horseClusters+1;
                if cluster.dirt > highestDirt then highestDirt = cluster.dirt;end;
                if (cluster.dirt < lowestDirt) or lowestDirt == 0 then lowestDirt = cluster.dirt;end;
                dirt = dirt + cluster.dirt;						
                if cluster.fitness > highestFitness then highestFitness = cluster.fitness;end;
                if (cluster.fitness < lowestFitness) or lowestFitness == 0 then lowestFitness = cluster.fitness;end;
                fitness = fitness + cluster.fitness;
                if cluster.riding > highestRiding then highestRiding = cluster.riding;end;
                if (cluster.riding < lowestRiding) or lowestRiding == 0 then lowestRiding = cluster.riding;end;
                riding = riding + cluster.riding;						
            end;
        end;

        moreInfos.totalSellPrice = totalSellPrice;

        if healthClusters == 0 then
            moreInfos.healthClusters = nil;
        else
            moreInfos.health = health / healthClusters;
        end
        moreInfos.highestHealth = highestHealth;
        moreInfos.lowestHealth = lowestHealth;

        if durationClusters == 0 then
            moreInfos.durationClusters = nil;
        else
            moreInfos.duration = duration / durationClusters;
        end
        moreInfos.highestDuration = highestDuration;
        moreInfos.lowestDuration = lowestDuration or 0;

        if reproductionClusters == 0 then
            moreInfos.reproductionClusters = nil;
        else
            moreInfos.reproduction = reproduction / reproductionClusters;
        end
        moreInfos.highestReproduction = highestReproduction;
        moreInfos.lowestReproduction = lowestReproduction or 0;

        if beforeReproduction == 0 then
            moreInfos.beforeReproduction = nil;
        else
            moreInfos.beforeReproduction = beforeReproduction / beforeReproductionClusters;
        end
        moreInfos.highestBeforeReproduction = highestBeforeReproduction;
        moreInfos.lowestBeforeReproduction = lowestBeforeReproduction or 0;
        moreInfos.nextBirthIn = nextBirthIn;

        if isHorse then
            if horseClusters == 0 then
                moreInfos.dirt = nil;
            else
                moreInfos.dirt = 100 - (dirt / horseClusters);
            end
            moreInfos.highestDirt = 100 - highestDirt;
            moreInfos.lowestDirt = 100 - lowestDirt;

            if horseClusters == 0 then
                moreInfos.fitness = nil;
            else
                moreInfos.fitness = fitness / horseClusters;
            end
            moreInfos.highestFitness = highestFitness;
            moreInfos.lowestFitness = lowestFitness;

            if horseClusters == 0 then
                moreInfos.riding = nil;
            else
                moreInfos.riding = riding / horseClusters;
            end
            moreInfos.highestRiding = highestRiding;
            moreInfos.lowestRiding = lowestRiding;
        end;				
    end;
    return moreInfos;
end;

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableHusbandryFood(_, superFunc, infoTable)
    superFunc(self, infoTable)

    if self.animalGrazing ~= nil and self.animalGrazing.outputFillTypes ~= nil then
        local grazingFoodBuffer = 0;
        local hasGrazing = false;
        for fillTypeName, outputFillType in pairs(self.animalGrazing.outputFillTypes) do
            grazingFoodBuffer = grazingFoodBuffer + outputFillType.foodBuffer;
            hasGrazing = true;
        end

        if hasGrazing and grazingFoodBuffer ~= 0 then
            table.insert(infoTable,
                {
                    title = g_i18n:getText("infoDisplayExtension_grazingFoodBuffer"),
                    text = InfoDisplayExtension:formatVolume(grazingFoodBuffer, 0)
                }
            )
        end
    end


    local spec = self.spec_husbandryFood
    local fillLevel = self:getTotalFood()
    local capacity = self:getFoodCapacity()
    spec.info.text = InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0);

    table.insert(infoTable, spec.info)
end
PlaceableHusbandryFood.updateInfo = Utils.overwrittenFunction(PlaceableHusbandryFood.updateInfo, InfoDisplayExtension.updateInfoPlaceableHusbandryFood)

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableHusbandryMilk(_, superFunc, infoTable)
    local spec = self.spec_husbandryMilk;

    superFunc(self, infoTable);

    for _, fillType in pairs(spec.activeFillTypes) do
        if spec.infos[fillType] ~= nil then
            local fillLevel = self:getHusbandryFillLevel(fillType);
            local capacity = self:getHusbandryCapacity(fillType);

            spec.infos[fillType].text = InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0, nil, g_fillTypeManager:getFillTypeNameByIndex(fillType));
            table.insert(infoTable, spec.infos[fillType])
        end
    end


end
PlaceableHusbandryMilk.updateInfo = Utils.overwrittenFunction(PlaceableHusbandryMilk.updateInfo, InfoDisplayExtension.updateInfoPlaceableHusbandryMilk)

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableHusbandryLiquidManure(_, superFunc, infoTable)
    superFunc(self, infoTable)

    local spec = self.spec_husbandryLiquidManure;
    local fillLevel = self:getHusbandryFillLevel(spec.fillType);
    local capacity = self:getHusbandryCapacity(spec.fillType);
    spec.info.text = InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0, nil, g_fillTypeManager:getFillTypeNameByIndex(spec.fillType));

    table.insert(infoTable, spec.info)
end
PlaceableHusbandryLiquidManure.updateInfo = Utils.overwrittenFunction(PlaceableHusbandryLiquidManure.updateInfo, InfoDisplayExtension.updateInfoPlaceableHusbandryLiquidManure)

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableHusbandryStraw(_, superFunc, infoTable)
    superFunc(self, infoTable)

    local spec = self.spec_husbandryStraw;
    local fillLevel = self:getHusbandryFillLevel(spec.inputFillType);
    local capacity = self:getHusbandryCapacity(spec.inputFillType);
    spec.info.text = InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0, nil, g_fillTypeManager:getFillTypeNameByIndex(spec.inputFillType));

    table.insert(infoTable, spec.info)

    local fillLevelOutput = self:getHusbandryFillLevel(spec.outputFillType);
    local capacityOutput = self:getHusbandryCapacity(spec.outputFillType);
    if capacityOutput ~= 0 then
        table.insert(infoTable,
            {
                title = g_fillTypeManager:getFillTypeTitleByIndex(spec.outputFillType),
                text = InfoDisplayExtension:formatCapacity(fillLevelOutput, capacityOutput, 0, nil);
            }
        )
    end
end
PlaceableHusbandryStraw.updateInfo = Utils.overwrittenFunction(PlaceableHusbandryStraw.updateInfo, InfoDisplayExtension.updateInfoPlaceableHusbandryStraw)

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableHusbandryWater(_, superFunc, infoTable)
    superFunc(self, infoTable)

    local spec = self.spec_husbandryWater

    if not spec.automaticWaterSupply then
        local fillLevel = self:getHusbandryFillLevel(spec.fillType);
        local capacity = self:getHusbandryCapacity(spec.fillType);
        spec.info.text = InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0, nil, g_fillTypeManager:getFillTypeNameByIndex(spec.fillType));

        table.insert(infoTable, spec.info)
    end
end
PlaceableHusbandryWater.updateInfo = Utils.overwrittenFunction(PlaceableHusbandryWater.updateInfo, InfoDisplayExtension.updateInfoPlaceableHusbandryWater)

---Update the info table
-- @param function superFunc
-- @param table infoTable
function InfoDisplayExtension:updateInfoPlaceableManureHeap(_, superFunc, infoTable)
    superFunc(self, infoTable)

    local spec = self.spec_manureHeap

    if spec.manureHeap == nil then
        return
    end

    local fillLevel = spec.manureHeap:getFillLevel(spec.manureHeap.fillTypeIndex);
    local capacity = spec.manureHeap:getCapacity(spec.manureHeap.fillTypeIndex);
    spec.infoFillLevel.text = InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0, nil, g_fillTypeManager:getFillTypeNameByIndex(spec.manureHeap.fillTypeIndex));

    table.insert(infoTable, spec.infoFillLevel)

    table.insert(infoTable,
        {
            title = g_i18n:getText("infoDisplayExtension_MANURE_HEAP_CONNECTED"),
            accentuate = true
        }
    )

    for j, unloadingStation in pairs (spec.manureHeap.unloadingStations) do
        table.insert(infoTable, {
            title = "",
            text = unloadingStation:getName()
        })
    end	
end
PlaceableManureHeap.updateInfo = Utils.overwrittenFunction(PlaceableManureHeap.updateInfo, InfoDisplayExtension.updateInfoPlaceableManureHeap)

function InfoDisplayExtension:updateInfoFeedingRobot(_, infoTable)
    if self.infos ~= nil then
        for _, info in ipairs(self.infos) do
            local fillLevel = 0
            local capacity = 0
            local fillTypeName = "UNKNOWN"

            for _, fillType in ipairs(info.fillTypes) do
                fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillType)
            end

            -- nur den ersten filltype abfragen, da die anderen da schon drin sind
            fillLevel = self:getFillLevel(info.fillTypes[1]);
            local spot = self.fillTypeToUnloadingSpot[info.fillTypes[1]]
            if spot ~= nil then
                capacity = spot.capacity;
            end

            info.text = InfoDisplayExtension:formatCapacity(fillLevel, capacity, 0, nil, fillTypeName);

            table.insert(infoTable, info)
        end
    end
end
FeedingRobot.updateInfo = Utils.overwrittenFunction(FeedingRobot.updateInfo, InfoDisplayExtension.updateInfoFeedingRobot)

---Update the info table
-- @param function superFunc
-- @param entityId splitShape
function InfoDisplayExtension:PlayerHUDUpdaterShowSplitShapeInfo(superFunc, splitShape)
    if not entityExists(splitShape) or not getHasClassId(splitShape, ClassIds.MESH_SPLIT_SHAPE) then
        return;
    end

    local splitTypeId = getSplitType(splitShape);

    if splitTypeId == 0 then
        return;
    end

    local isSplit = getIsSplitShapeSplit(splitShape);
    local isStatic = getRigidBodyType(splitShape) == RigidBodyType.STATIC;

    if isSplit and isStatic then
        return;
    end

    local sizeX, sizeY, sizeZ, _, _ = getSplitShapeStats(splitShape);
    local splitType = g_splitShapeManager:getSplitTypeByIndex(splitTypeId);
    local splitTypeName = splitType and splitType.title;
    local length = math.max(sizeX, sizeY, sizeZ);
    local box = self.objectBox;

    box:clear();

    if isSplit then
        box:setTitle(g_i18n:getText("infohud_wood"));
    else
        box:setTitle(g_i18n:getText("infohud_tree"));
    end

    if splitTypeName ~= nil then
        box:addLine(g_i18n:getText("infohud_type"), splitTypeName);
    end

    box:addLine(g_i18n:getText("infohud_length"), g_i18n:formatNumber(length, 1) .. " m");

    -- durchmesser ist auch interessant
    local diameter = math.min(sizeX, sizeY, sizeZ)
    box:addLine(g_i18n:getText("infohud_diameter"), g_i18n:formatNumber(diameter, 1) .. " m");

    if g_currentMission:getIsServer() and not isStatic then
        local mass = getMass(splitShape);

        box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(mass));
    end

    if not isSplit then
        -- Anzeigenzusätzlicher informationen
        local foundTree = nil;

        -- in 3 ebenen suchen erst mal
        local splitShapeParent = getParent(splitShape);
        local splitShapeGrandParent = getParent(splitShapeParent);

        -- suchen der Infos in den treesData.growingTrees
        for id, tree in pairs(g_treePlantManager.treesData.growingTrees) do
            if tree.node == splitShape or tree.node == splitShapeParent or tree.node == splitShapeGrandParent then
                foundTree = tree;
            end
        end
        for id, tree in pairs(g_treePlantManager.treesData.splitTrees) do
            if tree.node == splitShape or tree.node == splitShapeParent or tree.node == splitShapeGrandParent then
                foundTree = tree;
            end
        end

        if foundTree ~= nil then
            local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(foundTree.treeType);
--             InfoDisplayExtension.DebugTable("foundTree", foundTree);
--             InfoDisplayExtension.DebugTable("treeTypeDesc", treeTypeDesc);

            local fullGrown = true;
            local growStateText = g_i18n:getText("infohud_fullGrown");
            if foundTree.growthStateI ~= 1 and foundTree.isGrowing == true then
                local numOfGrowStates = #treeTypeDesc.stages;
                growStateText = tostring(foundTree.growthStateI) .. " / " .. tostring(numOfGrowStates);
                fullGrown = false;
            end
            box:addLine(g_i18n:getText("infohud_growthState"), growStateText);

            -- alter in Stunden mit Angabe des maximal alters
            local ageText = g_i18n:getText("infohud_fullGrown");
            if foundTree.growthStateI ~= 1 and foundTree.isGrowing == true and foundTree.nextGrowthTargetHour ~= nil then
                local numOfGrowStates = #treeTypeDesc.stages;
                local totalGrowHours = (treeTypeDesc.growthTimeHours * (numOfGrowStates - 1)) / g_currentMission.environment.timeAdjustment;
                local hoursNow = ((g_currentMission.environment.currentDay) * 24 ) + g_currentMission.environment.currentHour;
                local hoursLeftInThisStage = foundTree.nextGrowthTargetHour - hoursNow;
                local hoursInPreviousStages = (foundTree.growthStateI) * treeTypeDesc.growthTimeHours;
                local ageInHours = hoursInPreviousStages - hoursLeftInThisStage;
--                 InfoDisplayExtension.DebugText("hoursNow: %s - currentDay: %s - currentHour: %s - nextGrowthTargetHour: %s - hoursLeftInThisStage: %s - hoursInPreviousStages: %s", hoursNow, g_currentMission.environment.currentDay, g_currentMission.environment.currentHour, foundTree.nextGrowthTargetHour, hoursLeftInThisStage, hoursInPreviousStages)
                ageText = g_i18n:formatNumber(ageInHours) .. " / " .. g_i18n:formatNumber(totalGrowHours) .. "h";
            end

            if not fullGrown then
                box:addLine(g_i18n:getText("infohud_ageInHours"), ageText);
            end
        end
    end

    box:showNextFrame();
end
PlayerHUDUpdater.showSplitShapeInfo = Utils.overwrittenFunction(PlayerHUDUpdater.showSplitShapeInfo, InfoDisplayExtension.PlayerHUDUpdaterShowSplitShapeInfo)

-- hier brauche ich nicht überschreiben, nur direkt die funktion möglich machen reicht.
function InfoDisplayExtension:WearableShowInfo(superFunc, box)
    if self.ideNeededPowerValue == nil then

        local neededPower = PowerConsumer.loadSpecValueNeededPower(self.xmlFile)

        self.ideNeededPowerValue = neededPower.base;

        if self.configurations.powerConsumer ~= nil then
            self.ideNeededPowerValue = neededPower.config[self.configurations.powerConsumer];
        end

        if self.ideNeededPowerValue == nil then
            self.ideNeededPowerValue = 0;
        end
    end

    -- auslesen der Arbeitsbreite wie bei der benötigten Leistung, da config file gelesen werden muss per cache
    if self.ideWorkingWidthValue == nil then

        -- basis daten ohne config auslesen als ersten wert
        self.ideWorkingWidthValue = Vehicle.loadSpecValueWorkingWidth(self.xmlFile)

        -- config laden geht nur, wenn es auch per config geht, sonst ist das was kommt nil
        local workingWidth = Vehicle.loadSpecValueWorkingWidthConfig(self.xmlFile);		
        if workingWidth ~= nil then
            if self.configurations.workArea ~= nil and workingWidth.workArea ~= nil and workingWidth.workArea[self.configurations.workArea] ~= nil then
                self.ideWorkingWidthValue = workingWidth.workArea[self.configurations.workArea];
            end
        end
        if self.ideWorkingWidthValue == nil then
            self.ideWorkingWidthValue = 0;
        end
    end

    if self.ideNeededPowerValue ~= nil and self.ideNeededPowerValue ~= 0 then
        local hp, kw = g_i18n:getPower(self.ideNeededPowerValue)
        local neededPower = string.format(g_i18n:getText("shop_neededPowerValue"), MathUtil.round(kw), MathUtil.round(hp));
        box:addLine(g_i18n:getText("shop_neededPower"):gsub(":", ""), neededPower)
    end

    if self.ideWorkingWidthValue ~= nil and self.ideWorkingWidthValue ~= 0 then
        local workingWidth = string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(self.ideWorkingWidthValue, 1, true));
        box:addLine(g_i18n:getText("shop_workingWidth"):gsub(":", ""), workingWidth)
    end
end
Wearable.showInfo = Utils.appendedFunction(Wearable.showInfo, InfoDisplayExtension.WearableShowInfo)

---append to Vehicle showInfo to add more information
-- @param table box
function InfoDisplayExtension:showInfoVehicle(box)
    if self.ideHasPower == nil and self.isDeleted == false then

        local powerConfig = Motorized.loadSpecValuePowerConfig(self.xmlFile);

        -- set to sero to load it only one time
        self.ideHasPower = 0;

        if powerConfig ~= nil then
--             InfoDisplayExtension.DebugTable("self.configurations", self.configurations);
            for configName, config in pairs(self.configurations) do
--                 InfoDisplayExtension.DebugTable("powerConfig", powerConfig);
                if powerConfig[configName] ~= nil then
                    local configPower = powerConfig[configName][config];

                    if configPower ~= nil then
                        self.ideHasPower = configPower;
                    end
                end
            end
        end

--         InfoDisplayExtension.DebugTable("showInfoVehicle", self)

        self.ideCategoryNames = {};
        local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
        if storeItem ~= nil then
            for _, categoryName in pairs(storeItem.categoryNames) do
                local category = g_storeManager:getCategoryByName(categoryName)
                table.insert(self.ideCategoryNames, category.title)
            end
        end
    end

    if self.ideHasPower ~= nil and self.ideHasPower ~= 0 then
        local hp, kw = g_i18n:getPower(self.ideHasPower)
        local neededPower = string.format(g_i18n:getText("shop_neededPowerValue"), MathUtil.round(kw), MathUtil.round(hp));
        box:addLine(g_i18n:getText("infoDisplayExtension_currentPower"), neededPower)
    end

    box:addLine(g_i18n:getText("infohud_mass"), string.format("%1.2f t\n", self:getTotalMass()))

    if self.ideCategoryNames ~= nil and #self.ideCategoryNames ~= 0 then
        for _, categoryName in pairs(self.ideCategoryNames) do
            box:addLine(g_i18n:getText("infoDisplayExtension_category"), categoryName)
        end
    end
end
Vehicle.showInfo = Utils.appendedFunction(Vehicle.showInfo, InfoDisplayExtension.showInfoVehicle)

function InfoDisplayExtension:WashableShowInfo(superFunc, box)
    -- print(string.format("InfoDisplayExtension:WashableShowInfo(%s, %s)", superFunc, box));
    if self.getDirtAmount ~= nil then
        local dirt = self:getDirtAmount();

        if dirt ~= nil and dirt > 0.01 then
            box:addLine(g_i18n:getText("groundType_dirt"), string.format("%d %%", dirt * 100))
        end
    end

    superFunc(self, box)
end
function Washable.registerOverwrittenFunctions(vehicleType)
    -- Washable hat die funktion nicht, deshalb direkt rein müsste gehen
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", InfoDisplayExtension.WashableShowInfo)
end

AnimalItemStockExtension = {}

function AnimalItemStockExtension.new(cluster, superFunc)
    local self = superFunc(cluster);


    if cluster.numAnimals ~= nil and cluster.numAnimals >= 1 then
        table.insert(self.infos, {
            title = g_i18n:getText("infohud_numAnimals"),
            value = cluster.numAnimals
        })
    end

    return self
end

AnimalItemStock.new = Utils.overwrittenFunction(AnimalItemStock.new, AnimalItemStockExtension.new)

---append to PlayerHUDUpdater fieldAddField to add more information
-- @param table self
-- @param table fieldInfo
-- @param table box
function InfoDisplayExtension.PlayerHUDUpdaterFieldAddField(self, fieldInfo, box)

    local fruitTypeIndex = fieldInfo.fruitTypeIndex;
    local growthState = fieldInfo.growthState;

    if fruitTypeIndex ~= FruitType.UNKNOWN then
        local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex);

        if fruitTypeDesc:getIsGrowing(growthState) then
            box:addLine(g_i18n:getText("ui_map_growth"), string.format("%s / %s", growthState, fruitTypeDesc.numGrowthStates))
        end
    end
end

PlayerHUDUpdater.fieldAddField = Utils.appendedFunction(PlayerHUDUpdater.fieldAddField, InfoDisplayExtension.PlayerHUDUpdaterFieldAddField)


function InfoDisplayExtension:loadMap(name)
    Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, InfoDisplayExtension.onStartMission);
end

--- Anzahl der Elemente im F1 menü erhöhen
function InfoDisplayExtension:onStartMission()
    if not InfoDisplayExtension:getDetiServer() then
        local extendInputHUDcount = 1;
        local extendInputHUDcountHigh = 1;

        if g_gameSettings.uiScale < 1.26 and g_gameSettings.uiScale > 1.15 then
            extendInputHUDcount = 3;
            extendInputHUDcountHigh = 1;
        elseif g_gameSettings.uiScale <= 1.15 and g_gameSettings.uiScale > 1.05 then
            extendInputHUDcount = 5;
            extendInputHUDcountHigh = 2;
        elseif g_gameSettings.uiScale <= 1.05 and g_gameSettings.uiScale > 0.95 then
            extendInputHUDcount = 6;
            extendInputHUDcountHigh = 3;
        elseif g_gameSettings.uiScale <= 0.95 and g_gameSettings.uiScale > 0.90 then
            extendInputHUDcount = 7;
            extendInputHUDcountHigh = 3;
        elseif g_gameSettings.uiScale <= 0.90 and g_gameSettings.uiScale > 0.85 then
            extendInputHUDcount = 8;
            extendInputHUDcountHigh = 4;
        elseif g_gameSettings.uiScale <= 0.85 and g_gameSettings.uiScale > 0.75 then
            extendInputHUDcount = 9;
            extendInputHUDcountHigh = 4;
        elseif g_gameSettings.uiScale <= 0.75 and g_gameSettings.uiScale > 0.65 then
            extendInputHUDcount = 10;
            extendInputHUDcountHigh = 5;
        elseif g_gameSettings.uiScale <= 0.65 and g_gameSettings.uiScale > 0.55 then
            extendInputHUDcount = 10;
            extendInputHUDcountHigh = 5;
        elseif g_gameSettings.uiScale <= 0.55 then
            extendInputHUDcount = 10;
            extendInputHUDcountHigh = 5;
        end


        InputHelpDisplay.MAX_NUM_ELEMENTS = InputHelpDisplay.MAX_NUM_ELEMENTS + extendInputHUDcount;
        InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY = InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY + extendInputHUDcountHigh;
    end

    InfoDisplayExtension:ReconnectManureHeaps();
end

---Fix für giants fehler im LS25
function InfoDisplayExtension:ReconnectManureHeaps()

    for _, manureLoadingStation in pairs(g_currentMission.manureLoadingStations) do
--         InfoDisplayExtension.DebugTable("manureLoadingStation", manureLoadingStation);

        if manureLoadingStation.owningPlaceable ~= nil and manureLoadingStation.owningPlaceable.spec_manureHeap ~= nil then
            local spec = manureLoadingStation.owningPlaceable.spec_manureHeap;
            if #spec.manureHeap.unloadingStations == 0 then
                print("InfoDisplayExtension: reconnect ManureHeap " .. manureLoadingStation.owningPlaceable:getName());
                local storageSystem = g_currentMission.storageSystem;
                local farmId = manureLoadingStation.owningPlaceable.ownerFarmId;
                local lastFoundUnloadingStations = storageSystem:getExtendableUnloadingStationsInRange(spec.manureHeap, farmId)
                local lastFoundLoadingStations = storageSystem:getExtendableLoadingStationsInRange(spec.manureHeap, farmId)
                storageSystem:addStorageToUnloadingStations(spec.manureHeap, lastFoundUnloadingStations)
                storageSystem:addStorageToLoadingStations(spec.manureHeap, lastFoundLoadingStations)
            end
        end
    end
end

---Simple check if this is server and not client
-- @return boolean isDediServer
function InfoDisplayExtension:getDetiServer()
    return g_server ~= nil and g_client ~= nil and g_dedicatedServer ~= nil;
end;

addModEventListener(InfoDisplayExtension)
