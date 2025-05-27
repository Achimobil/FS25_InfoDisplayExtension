IdeWearableExtension = {};

---Update the info table
-- @param function superFunc
-- @param InfoDisplayKeyValueBox box
function IdeWearableExtension:WearableShowInfo(superFunc, box)
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

    if self.ideNeededPowerValue ~= nil and self.ideNeededPowerValue ~= 0 then
        local hp, kw = g_i18n:getPower(self.ideNeededPowerValue);
        local neededPower = string.format(g_i18n:getText("shop_neededPowerValue"), MathUtil.round(kw), MathUtil.round(hp));
        box:addLine(g_i18n:getText("shop_neededPower"):gsub(":", ""), neededPower);
    end

    if self.ideSpeedLimit == nil then
--         InfoDisplayExtension.DebugTable("SpeedLimit", self);
        self.ideSpeedLimit = Vehicle.loadSpecValueSpeedLimit(self.xmlFile);

        if self.configurations ~= nil and self.configurations.adjustWorkingSpeed ~= nil then
            local configId = self.configurations.adjustWorkingSpeed - 11;
--             InfoDisplayExtension.DebugText("configId: %s", configId)
            self.ideAdjustWorkingSpeed = math.max(self.ideSpeedLimit + configId, 1);
        end

        if self.ideSpeedLimit == nil then
            self.ideSpeedLimit = 0;
        end
    end

    if self.ideSpeedLimit ~= nil and self.ideSpeedLimit ~= 0 then
        local formatedSpeedLimit = string.format("%1d", g_i18n:getSpeed(self.ideSpeedLimit));

        -- hinzufügen der anpassung vom mod zur Anzeige. orignal in klammern
        if self.ideAdjustWorkingSpeed ~= nil and self.ideAdjustWorkingSpeed ~= self.ideSpeedLimit then
            formatedSpeedLimit = string.format("%1d (%1d)", g_i18n:getSpeed(self.ideAdjustWorkingSpeed), g_i18n:getSpeed(self.ideSpeedLimit));
        end
        local speedLimit = string.format(g_i18n:getText("shop_maxSpeed"), formatedSpeedLimit, g_i18n:getSpeedMeasuringUnit())
        box:addLine(g_i18n:getText("helpLine_IconOverview_WorkingSpeed"), speedLimit)
    end

    -- auslesen der Arbeitsbreite wie bei der benötigten Leistung, da config file gelesen werden muss per cache
    if self.ideWorkingWidthValue == nil then

        -- basis daten ohne config auslesen als ersten wert
        self.ideWorkingWidthValue = Vehicle.loadSpecValueWorkingWidth(self.xmlFile)
        InfoDisplayExtension.DebugText("ideWorkingWidthValue: %s", self.ideWorkingWidthValue);

        -- alle configs durch gehen und die Werte von den passenden nutzen
        local workingWidthConfigurations = Vehicle.loadSpecValueWorkingWidthConfig(self.xmlFile);
        if workingWidthConfigurations ~= nil then
            InfoDisplayExtension.DebugTable("workingWidthConfigurations", workingWidthConfigurations, 3)
            for configName, config in pairs(self.configurations) do
                if workingWidthConfigurations[configName] ~= nil then
                    local configWorkingWidth = workingWidthConfigurations[configName][config];

                    if configWorkingWidth ~= nil then
                        self.ideWorkingWidthValue = configWorkingWidth.width;
                        InfoDisplayExtension.DebugText("configWorkingWidth: %s", self.ideWorkingWidthValue);
                    end
                end
            end
        end

        if self.ideWorkingWidthValue == nil then
            self.ideWorkingWidthValue = 0;
        end
    end

    if self.ideWorkingWidthValue ~= nil and self.ideWorkingWidthValue ~= 0 then
        InfoDisplayExtension.DebugText("ideWorkingWidthValue: %s", self.ideWorkingWidthValue);
        local workingWidth = string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(self.ideWorkingWidthValue, 1, true));
        box:addLine(g_i18n:getText("shop_workingWidth"):gsub(":", ""), workingWidth)
    end
end
Wearable.showInfo = Utils.appendedFunction(Wearable.showInfo, IdeWearableExtension.WearableShowInfo)