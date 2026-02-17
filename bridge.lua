Framework = {}
Framework.name = Config.Framework

local QBCore = Config.Framework == 'qbcore' and exports['qb-core']:GetCoreObject() or nil
local ESX = Config.Framework == 'esx' and exports['es_extended']:getSharedObject() or nil
-- Get a player object from source
function Framework.GetPlayer(src)
    if Framework.name == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif Framework.name == 'qbcore' then
        return QBCore.Functions.GetPlayer(src)
    elseif Framework.name == 'esx' then
        return ESX.GetPlayerFromId(src)
    else
        return nil
    end
end
