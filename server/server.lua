-- Sample lib.callback
lib.callback.register('qbx_resource:getSomething', function(source, shopIndex)
    local p = QBOX:GetPlayer(source)
    if not p then return end
    local shop = Config.Wholesale[shopIndex or 1]
    if not shop then
        print("[qbx_gunstore] Shop index not found for allotment:", shopIndex)
        return
    end
    local shopName = shop.name
    if not shop then return end

    local allotments = {}
    for _, cat in ipairs(shop.categories or {}) do
        local record = ensureReset(getShopRecord(shopName, cat))
        allotments[cat] = {
            total = record.weekly_allotment,
            used = record.purchased_this_week
        }
    end
    return something
end)