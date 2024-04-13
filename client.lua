local target = exports.ox_target
local selling = false

local hasAsked = {}

RegisterCommand('salg', function()
    local option = {}

    findItems(option)

    lib.registerMenu({
        id = 'sell',
        title = 'Sælg',
        options = option,
    }, function(_, _, args)
        toggleSelling(args)
    end)

    lib.showMenu('sell')
end)

RegisterNetEvent('cdk-sell:client:sellProcess')
AddEventHandler('cdk-sell:client:sellProcess', function (args, entity)
    local targetEntity = entity.entity
    ESX.TriggerServerCallback("cdk-sell:server:checkItem", function (cb, itemAmount)
        if cb then
            if hasAsked[targetEntity] then
                lib.notify({
                    type = 'error',
                    description = 'Du har allerede spurgt denne person',
                })
            else
            hasAsked[targetEntity] = true
            local randomNumber = math.random(0, 100)
            if randomNumber <= Config.SellChance then
                if itemAmount > Config.MaxSellAmount then
                    itemAmount = Config.MaxSellAmount
                end
                local sellAmount = math.random(1, itemAmount)
                lib.notify({
                    type = 'inform',
                    description = 'Du prøver at sælge ' .. sellAmount .. " " .. args.label .. " til " .. entity.entity,
                })
            
                -- Freeze entity
                local playerPed = PlayerPedId()
                local playerPedHeading = GetEntityHeading(playerPed)
                local playerPedCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)
                local npcPed = entity.entity

                FreezeEntityPosition(playerPed, true)
                FreezeEntityPosition(npcPed, true)

                SetEntityHeading(npcPed, playerPedHeading - 180.1)
                SetEntityCoordsNoOffset(npcPed, playerPedCoords.x, playerPedCoords.y, playerPedCoords.z, 0)

                ClearPedTasksImmediately(npcPed)
                RequestAnimDict("mp_common")
                while not HasAnimDictLoaded("mp_common") do
                    Wait(100)
                end
                Wait(100)
                TaskPlayAnim(npcPed, "mp_common", "givetake1_a", 8.0, 1.0, 3000, 0, 0, 0, 0, 0)
                TaskPlayAnim(playerPed, "mp_common", "givetake1_b", 8.0, 1.0, 3000, 0, 0, 0, 0, 0)

                -- Start progress circle and animation to player
                if lib.progressCircle({
                    duration = 3000,
                    position = 'bottom',
                    useWhileDead = false,
                    label = "Sælger",
                    allowCuffed = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                        mouse = false,
                        sprint = false,
                    },
                }) then
                    -- Rewards player
                    ESX.TriggerServerCallback("cdk-sell:server:reward", function (cb)
                        if cb then
                            lib.notify({
                                type = 'success',
                                description = 'Du solgte ' .. sellAmount .. " " .. args.label .. ' for ' .. "(antal penge)" .. ',-',
                            })
                        end
                    end, args, sellAmount)
                else
                    
                    lib.notify({
                        type = 'error',
                        description = 'Du afbrød salget',
                    })
                end
                ClearPedTasksImmediately(npcPed)
                ClearPedTasksImmediately(playerPed)
                FreezeEntityPosition(playerPed, false)
                FreezeEntityPosition(npcPed, false)
        
                elseif randomNumber > Config.SellChance then
                    local npcPed = entity.entity
                    local dict = "cellphone@"
                    local anim = "cellphone_call_listen_base"
                    ClearPedTasksImmediately(npcPed)
                    RequestAnimDict(dict)
                    while not HasAnimDictLoaded(dict) do
                        Wait(100)
                    end
                    Wait(100)
                    TaskPlayAnim(npcPed, dict, anim, 8.0, 8.0, 3000, 0, 0, 0, 0, 0)
                        lib.notify({
                            type = 'warning',
                            description = 'Person har ringet efter politet...',
                        })
                    end
                end
            end
                if not cb then
                lib.notify({
                    type = 'error',
                    description = 'Du har ikke nogen ' .. args.label .. ' at sælge',
                })
        end
    end, args)
end)


-- Takes info from Config.Items and puts it into the option table
function findItems(option)
    for _, v in pairs(Config.Items) do
        local item = v.item
        ESX.TriggerServerCallback("cdk-sell:server:findItem", function (itemAmount)
            table.insert(option, {
                label = v.label .. ' - ' .. v.priceMin .. ' - ' .. v.priceMax .. 'kr' .. ' - ' .. itemAmount .. ' stk',
                icon = "nui://ox_inventory/web/images/" .. v.item .. ".png",
                args = {item = v.item, label = v.label, priceMin = v.priceMin, priceMax = v.priceMax},
            })
        end, item)
    end
    Wait(100)
    table.insert(option, {
        label = 'Stop med at sælge',
        icon = 'fas fa-times',
        args = {item = nil, stop = true},
    })
end


function toggleSelling(args)
    if args.stop then
        selling = false
        target:removeGlobalPed("sellPed")
        lib.notify({
            type = 'inform',
            description = 'Du er stoppet med at sælge',
        })
    else
        if selling then
            lib.notify({
                type = 'error',
                description = 'Du er allerede igang på at sælge noget',
            })
        else
            local options = {
                name = "sellPed",
                label = 'Sælg ' .. args.label,
                icon = 'fas fa-dollar-sign',
                distance = 2.0,
                onSelect = function (entity)
                    TriggerEvent('cdk-sell:client:sellProcess', args, entity)
                end,
            }
            target:addGlobalPed(options)
            selling = true
            lib.notify({
                type = 'inform',
                description = 'Du er startet på at sælge ' .. args.label,
            })
        end
    end
end