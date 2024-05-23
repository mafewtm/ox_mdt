local config = require "config"
local ox = {}
local localOfficer = {}

ox.loadedEvent = 'ox:playerLoaded'
ox.logoutEvent = 'ox:playerLogout'
ox.setGroupEvent = 'ox:setGroup'

local function getGroupState(groupName)
    return GlobalState['group.' .. groupName] --[[@as OxGroupProperties]]
end

---@param name string
local function getGroupLabel(name)
    return getGroupState(name)?.label:gsub('[%U]', '')
end

---@param name string
local function getGroupGrades(name)
    return getGroupState(name)?.grades
end

---@param group string
---@param grade number
---@return string
local function getGradeLabel(group, grade)
    return ('%s %s'):format(getGroupLabel(group), getGroupGrades(group)?[grade])
end

function ox.getGroupInfo()
    local groupName, grade = player.hasGroup(config.policeGroups)

    if not groupName or not grade then return end

    return groupName, grade, getGradeLabel(groupName, grade)
end

---@param officer Officer
function ox.getGroupTitle(officer)
    return getGradeLabel(officer.group, officer.grade)
end

function ox.getOfficerData()
    localOfficer.stateId = QBX.PlayerData.citizenid
    localOfficer.firstName = QBX.PlayerData.charinfo.firstname
    localOfficer.lastName = QBX.PlayerData.charinfo.lastname
    localOfficer.group = QBX.PlayerData.job.name
    localOfficer.title = QBX.PlayerData.job.grade.name
    localOfficer.grade = QBX.PlayerData.job.grade.level


    return localOfficer
end

ox.getGroupLabel = getGroupLabel
ox.getGroupGrades = getGroupGrades

return ox
