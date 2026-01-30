-- Notifier
RegisterNetEvent('CoreBilling:clientNotify', function(message, type, duration)
    lib.notify({
        description = message,
        type = type or "success",
        duration = duration or 5000,
    })
end)
-- openPOS, Creates a lib.inputDialog for price input and populates it with nearby players by ID
local function openPOS(shopName, radius)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local nearbyPlayers = lib.getNearbyPlayers(pos, radius or 10.0, true) -- True means include self
    local myServerId = GetPlayerServerId(PlayerId())

    if not nearbyPlayers or #nearbyPlayers == 0 then
        return lib.notify({ description = 'No nearby players found', type = 'error' })
    end

    -- Prepare customer list
    local targetOptions = {}
    for _, player in ipairs(nearbyPlayers) do
        local serverId = (player.ped == ped) and myServerId or player.id
        targetOptions[#targetOptions+1] = { label = 'ID ' .. serverId, value = serverId }
    end

    -- Input price and select target
    local input = lib.inputDialog(('POS - %s'):format(shopName), {
        { type = 'number', label = 'Price (base)', required = true, min = 1, max = 50000000 },
        { type = 'select', label = 'Select Customer', options = targetOptions, required = true }
    })

    if not input then return end

    local price = input[1]
    local targetId = input[2]

    -- Pricing breakdown
    local basePrice = price
    local profit = math.floor(basePrice * 0.10) -- This is for client side visuals only, the server will handle the actual calculation
    local total = basePrice + profit            -- Just make sure they are both the same

    local confirm = lib.alertDialog({
        header = 'Confirm Sale',
        content = ('Base: $%s\nEmployee Profit: $%s\nTotal Charged: $%s\n\nSend bill to ID %s?'):format(
            basePrice, profit, total, targetId
        ),
        centered = true,
        cancel = true
    })

    if confirm ~= 'confirm' then return end

    TriggerServerEvent('CoreBilling:sendBill', targetId, basePrice, profit, shopName)
end

-- Wraps the openPOS function in a server callback to check job
local function tryOpenPOS(shopName)
    local allowed, reason = lib.callback.await('CoreBilling:canOpenPOS', false, shopName)

    if allowed then
        openPOS(shopName)
    else
        lib.notify({
            description = reason or "You cannot open the POS here.",
            type = "error"
        })
    end
end

-- This is a lib.alertDialog with the bill that was calculated on the server
RegisterNetEvent('CoreBilling:receiveBill', function(billerId, shopName, amount, upcharge, total, billId)
    -- Look up restaurant label from Config
    local label = (Config.Shops[shopName] and Config.Shops[shopName].label)

    -- Show only total to customer
    local accept = lib.alertDialog({
        header = ('Bill from %s'):format(label),
        content = ('Total: $%s\nDo you want to pay?'):format(total),
        centered = true,
        cancel = true
    })

    if accept == 'confirm' then
        -- send full info to server
            TriggerServerEvent('CoreBilling:acceptBill', billerId, amount, upcharge, shopName, billId)
    else
        lib.notify({ description = 'You declined the bill.', type = 'error' })
        TriggerServerEvent('CoreBilling:cancelledPayment', billId)
    end
end)
-- Creates a thread that sets up all POS from config
CreateThread(function()
    for shopName, shopData in pairs(Config.Shops) do
        if not shopData.location then
            print(('[CoreBilling] Warning: %s has no location defined!'):format(shopName))
        else
            exports.ox_target:addBoxZone({
                coords = shopData.location,
                size = shopData.size or vec3(2.0, 2.0, 2.0),
                rotation = shopData.rotation or 0.0,
                debug = shopData.debug or false,
                options = {
                    {
                        name = ('open_pos_%s'):format(shopName),
                        icon = 'fa-solid fa-cash-register',
                        label = ('Open POS (%s)'):format(shopData.label or shopName),
                        distance = 1.5,
                        onSelect = function()
                            tryOpenPOS(shopName)
                        end,
                    }
                }
            })
        end
    end
end)