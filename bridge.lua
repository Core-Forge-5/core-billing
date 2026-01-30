--Unused for now
Framework = {}
Framework.name = Config.Framework

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