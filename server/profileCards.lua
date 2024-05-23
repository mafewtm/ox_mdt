local registerCallback = require 'server.utils.registerCallback'
local config = require 'config'
local framework = require(('server.framework.%s'):format(config.framework))
local VEHICLES = exports.qbx_core:GetVehiclesByName()

---@class CustomProfileCard
---@field id string
---@field title string
---@field icon string
---@field getData fun(parameters: {search: string}): string[]

---@type CustomProfileCard[]
local customProfileCards = {}

---@param newCard CustomProfileCard
local function checkCardExists(newCard)
    for i = 1, #customProfileCards do
        local card = customProfileCards[i]

        if card.id == newCard.id then
            assert(false, ("Custom card with id `%s` already exists!"):format(card.id))
            return true
         end
    end

    return false
end

---@param data CustomProfileCard | CustomProfileCard[]
local function createProfileCard(data)
    local arrLength = #data
    if arrLength > 0 then
        for i = 1, arrLength do
            local newCard = data[i]
            if not checkCardExists(newCard) then
                customProfileCards[#customProfileCards+1] = newCard
            end
        end
        return
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    if not checkCardExists(data.id) then
        customProfileCards[#customProfileCards+1] = data
     end
end
exports('createProfileCard', createProfileCard)

local function getAll()
    return customProfileCards
end

---@param citizenId string
local function getLicenses(citizenId)
    local player = exports.qbx_core:GetPlayerByCitizenId(citizenId) or exports.qbx_core:GetOfflinePlayer(citizenId)

    return player.PlayerData.metadata.licences
end

---@param citizenId string
local function getVehicles(citizenId)
    local vehicles = MySQL.rawExecute.await('SELECT `plate`, `vehicle` from `player_vehicles` WHERE `citizenid` = ?', { citizenId }) or {}

    for _, v in pairs(vehicles) do
        v.label = ('%s %s'):format(VEHICLES[v.vehicle].brand, VEHICLES[v.vehicle].name) or v.vehicle
    end

    return vehicles
end

createProfileCard({
    {
        id = 'licenses',
        title = locale('licenses'),
        icon = 'certificate',
        getData = function(profile)
            local licenses = getLicenses(profile.stateId)
            local licenseLabels = {}

            for licenseType, hasLicense in pairs(licenses) do
                if hasLicense then
                    licenseLabels[#licenseLabels + 1] = qbx.string.capitalize(licenseType)
                end
            end

            return licenseLabels
        end
    },
    {
        id = 'vehicles',
        title = locale('vehicles'),
        icon = 'car',
        getData = function(profile)
            local vehicles = getVehicles(profile.stateId)
            local vehicleLabels = {}

            for i = 1, #vehicles do
                vehicleLabels[#vehicleLabels + 1] = ('%s (%s)'):format(vehicles[i].label, vehicles[i].plate)
            end

            return vehicleLabels
        end,
    },
    {
        id = 'pastCharges',
        title = locale("past_charges"),
        icon = 'gavel',
        getData = function(profile)
            local charges = MySQL.rawExecute.await('SELECT `charge` AS LABEL, SUM(`count`) AS count FROM `ox_mdt_reports_charges` WHERE `charge` IS NOT NULL AND `stateId` = ? GROUP BY `charge`', { profile.stateId }) or {}
            local chargeLabels = {}

            for i = 1, #charges do
                chargeLabels[#chargeLabels+1] = charges[i].count ..'x ' ..  charges[i].label
            end

            return chargeLabels
        end,
    },
})

registerCallback('ox_mdt:getCustomProfileCards', function()
    return customProfileCards
end)

return {
    getAll = getAll,
    create = createProfileCard
}