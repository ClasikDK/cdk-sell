Config = {}

Config.SellChance = 85 -- Chance of selling the item in percentage
Config.GiveBlackMoney = true -- If true, the player will receive black money, if false, the player will receive normal cash
Config.MaxSellAmount = 5 -- Max amount of items that can be sold at once

Config.Items = {
    ["cannabis"] = { -- Item name
        label = "Cannabis", -- Item label
        item = "cannabis", -- Item spawn id
        priceMax = 1500, -- Max sell price
        priceMin = 750 -- Min sell price
    },
    ["marijuana"] = {
        label = "Marijuana",
        item = "marijuana",
        priceMax = 1250,
        priceMin = 500
    }
}