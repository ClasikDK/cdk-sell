ESX.RegisterServerCallback("cdk-sell:server:reward", function (src, cb, args, sellAmount)
        local xPlayer = ESX.GetPlayerFromId(src)
        local randomPrice = math.random(args.priceMin, args.priceMax)
        xPlayer.removeInventoryItem(args.item, sellAmount)
        if Config.GiveBlackMoney then
            xPlayer.addAccountMoney('black_money', randomPrice * sellAmount)
        else
            xPlayer.addMoney(randomPrice * sellAmount)
        end
end)

ESX.RegisterServerCallback("cdk-sell:server:checkItem", function (src, cb, args)
    local xPlayer = ESX.GetPlayerFromId(src)
    local itemAmount = xPlayer.getInventoryItem(args.item).count

    if xPlayer.getInventoryItem(args.item).count >= 1 then
        cb(true, itemAmount)
    else
        cb(false, itemAmount)
    end
end)

ESX.RegisterServerCallback("cdk-sell:server:findItem", function (src, cb, item)
    local xPlayer = ESX.GetPlayerFromId(src)
    local itemAmount = xPlayer.getInventoryItem(item).count
    cb(itemAmount)
end)