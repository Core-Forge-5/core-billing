local renewed = exports['Renewed-Banking']
local PendingBills = {}

--Check for pending bills
local function HasPendingBillFrom(src)
    for _, bill in ipairs(PendingBills) do
        if bill.employee == src then
            return true
        end
    end
    return false
end
--Remove bill
local function RemoveBillById(billId)
    for i, bill in ipairs(PendingBills) do
        if bill.id == billId then
            table.remove(PendingBills, i)
            return true -- removed successfully
        end
    end
    return false -- bill not found
end
RegisterNetEvent('CoreBilling:cancelledPayment', function(billId)
    RemoveBillById(billId)
end)
-- canOpenPOS, Checks if shopName is in the config, and if source has the jobName for that shop
lib.callback.register('CoreBilling:canOpenPOS', function(source, shopName)
    local player = exports.qbx_core:GetPlayer(source)
    local shopData = Config.Shops[shopName]

    if not shopData then
        return false, "Invalid shop."
    end

    if not player then
        return false, "Player not found."
    end

    local jobName = player.PlayerData.job and player.PlayerData.job.name
    if jobName ~= shopData.job then
        return false, "Access denied: You must work here."
    end

    return true
end)

--Send bill to customer
RegisterNetEvent('CoreBilling:sendBill', function(targetId, sentBase, sentProfit, shopName)
    local src = source
    local employee = exports.qbx_core:GetPlayer(src)
    local target = exports.qbx_core:GetPlayer(targetId)
    if not employee or not target then return end

    if HasPendingBillFrom(src) then
        return TriggerClientEvent('CoreBilling:clientNotify', src, "You already have a pending bill. Wait until it's accepted or expired.", "error", 5000)
    end

    -- Quick Distance Check
    local employeePed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)
    local employeePos = GetEntityCoords(employeePed)
    local targetPos = GetEntityCoords(targetPed)
    if not employeePed or employeePed == 0 or not targetPed or targetPed == 0 then return end
    if #(employeePos - targetPos) > 5.0 then return end

    -- Validate input
    sentBase = tonumber(sentBase)
    sentProfit = tonumber(sentProfit)
    if not sentBase or sentBase <= 0 or not sentProfit or sentProfit < 0 then
        return print(("[qbx_billing] Invalid price input from %s"):format(src))
    end

    -- Recalculate
    local trueBase = sentBase
    local trueProfit = math.floor(trueBase * 0.10)
    local trueTotal = trueBase + trueProfit

    -- Check for manipulation
    if sentProfit ~= trueProfit then
        print(("[SECURITY] Player %s tried to send invalid bill data (client: %s/%s | server: %s/%s)")
            :format(src, sentBase, sentProfit, trueBase, trueProfit))
        return TriggerClientEvent('CoreBilling:clientNotify', src, "Invalid billing data. Transaction cancelled.", "error")
    end

    -- Everything valid, Continue
    local total = trueTotal
    local billId = os.time()*1000 + math.random(1,999)
    table.insert(PendingBills, {
    id = billId, -- unique bill ID
        employee = src,
        target = targetId,
        shopName = shopName,
        base = trueBase,
        profit = trueProfit,
        total = total,
        timestamp = os.time()
    })
    TriggerClientEvent('CoreBilling:receiveBill', targetId, src, shopName, trueBase, trueProfit, total, billId)
end)

--Customer accepts bill
RegisterNetEvent('CoreBilling:acceptBill', function(billerId, amount, upcharge, shopName, billId)
    local src = source
    local customer = exports.qbx_core:GetPlayer(src)
    local biller = exports.qbx_core:GetPlayer(billerId)
    if not customer or not biller then return end

    -- Retrieve the bill from server-side table
    local bill
    for i, b in ipairs(PendingBills) do
        if b.id == billId then
            bill = b
            table.remove(PendingBills, i)
            break
        end
    end

    if not bill then
        return TriggerClientEvent('CoreBilling:clientNotify', src, "Bill not found or already paid.", "error", 5000)
    end

    local total = bill.total
    local cash = customer.PlayerData.money.cash
    local bank = customer.PlayerData.money.bank
    local citizenid = customer.PlayerData.citizenid
    local employeecid = biller.PlayerData.citizenid
    local billerName = biller.PlayerData.charinfo.firstname .. ' ' .. biller.PlayerData.charinfo.lastname
    local amountToSociety = bill.base
    local profit = bill.profit

    if cash + bank < total then
        return TriggerClientEvent('CoreBilling:clientNotify', billerId, "Customer has insufficient funds", "error", 5000)
    end

    -- Deduct from customer
    if cash >= total then
        customer.Functions.RemoveMoney('cash', total, 'store-bill')
    else
        customer.Functions.RemoveMoney('cash', cash, 'store-bill')
        customer.Functions.RemoveMoney('bank', total - cash, 'store-bill')
    end

    -- Deposit into society
    exports['Renewed-Banking']:addAccountMoney(bill.shopName, amountToSociety)

    -- Pay employee profit
    biller.Functions.AddMoney('bank', profit, 'billing-upcharge')

    -- Log customer transaction
    exports['Renewed-Banking']:handleTransaction(
        citizenid,                                  -- account (customer)
        ('%s Purchase'):format(bill.shopName),      -- title
        total,                                      -- amount
        ('Successful Purchase'),                    -- message 
        billerName,                                 -- issuer
        bill.shopName,                              -- receiver (society)
        'withdraw'                                  -- type
    )

    -- Log society receipt
    exports['Renewed-Banking']:handleTransaction(
        shopName,                                                      -- account (society)  
        ('Sale to %s'):format(customer.PlayerData.charinfo.firstname), -- title 
        amount,                                                        -- amount
        ('Successful Sale'),                                           -- message 
        billerName,                                                    -- issuer (employee) 
        shopName,                                                      -- receiver (society) 
        'deposit'                                                      -- type 
    )
    
    -- Notify both players
    TriggerClientEvent('CoreBilling:clientNotify', src, 
        ('You paid $%s to %s.'):format(total, bill.shopName), 
        "success", 
        8000
    )

    TriggerClientEvent('CoreBilling:clientNotify', billerId, 
        ('Customer paid $%s ($%s to society, $%s to you).'):format(total, amountToSociety, profit), 
        "success", 
        8000
    )
end)

-- Expire old bills after 60 seconds
CreateThread(function()
    while true do
        Wait(60 * 1000) -- every 60 seconds
        local now = os.time()
        for i = #PendingBills, 1, -1 do
            if now - PendingBills[i].timestamp > 300 then -- 5 minutes
                table.remove(PendingBills, i)
            end
        end
    end
end)