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

InfoDisplayInputHelpDisplayExtension = {}

---Show the name of the currently selected vehicle/implement next to the vehicle-selection schema
---@param superFunc function the class's own original drawVehicleSchema
---@param posX number screen x position
---@param posY number screen y position
---@param isShortVersion boolean true when the F1 menu itself is collapsed/hidden
function InfoDisplayInputHelpDisplayExtension:drawVehicleSchema(superFunc, posX, posY, isShortVersion)
    local newPosY, rowPosY = superFunc(self, posX, posY, isShortVersion)

    if not isShortVersion and self.vehicle ~= nil and self.vehicle.getSelectedVehicle ~= nil then
        local selectedVehicle = self.vehicle:getSelectedVehicle()
        if selectedVehicle ~= nil and selectedVehicle.getName ~= nil then
            local headerPosY = posY - self.comboBg.height
            local textX = posX + self.comboBg.width - self.comboTextOffsetX
            local textY = headerPosY - self.comboBg.height * 0.5 + self.comboTextOffsetY

            setTextBold(true)
            setTextAlignment(RenderText.ALIGN_RIGHT)
            setTextColor(1, 1, 1, 1)
            renderText(textX, textY, self.textSize, utf8ToUpper(selectedVehicle:getName()))
            setTextAlignment(RenderText.ALIGN_LEFT)
        end
    end

    return newPosY, rowPosY
end
InputHelpDisplay.drawVehicleSchema = Utils.overwrittenFunction(InputHelpDisplay.drawVehicleSchema, InfoDisplayInputHelpDisplayExtension.drawVehicleSchema)
