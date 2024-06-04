local target = exports.ox_target
local selling = false
local hasAsked = {}
local option = {}

CreateThread(function()
    Wait(5000)
    lib.addRadialItem({
        {
            id = 'sell',
            label = 'Sælg',
            icon = 'fas fa-dollar-sign',
            onSelect = function()
                findItems(option)
            end,
        }
    })
end)

RegisterNetEvent('cdk-sell:client:sellProcess')
AddEventHandler('cdk-sell:client:sellProcess', function(args, entity)
    local targetEntity = entity.entity
    if IsEntityDead(targetEntity) then
        lib.notify({
            type = 'error',
            description = 'Personen er død',
        })
    else
        ESX.TriggerServerCallback("cdk-sell:server:checkItem", function(cb, itemAmount)
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
                        local pedCoords = GetEntityCoords(PlayerPedId())
                        local pedZone = GetNameOfZone(pedCoords.x, pedCoords.y, pedCoords.z)
                        local sellMultiplier = Config.Zones[pedZone].multiplier
                        local sellAmount = math.random(1, itemAmount)
                        lib.notify({
                            type = 'inform',
                            description = 'Du prøver at sælge ' .. sellAmount .. " " .. args.label .. ' til personen',
                        })

                        local playerPed = PlayerPedId()
                        local npcPed = entity.entity

                        ClearPedTasksImmediately(npcPed)

                        TaskTurnPedToFaceEntity(npcPed, playerPed, 1000)
                        TaskTurnPedToFaceEntity(playerPed, npcPed, 1000)

                        Wait(1000)
                        local animDict = "mp_common"
                        local cashModel = joaat("prop_cash_pile_01")
                        local drugModel = joaat("prop_meth_bag_01")
                        lib.requestAnimDict(animDict)
                        lib.requestModel(cashModel)
                        lib.requestModel(drugModel)
                        local cashProp = CreateObject(cashModel, 0, 0, 0, true, false, false)
                        local drugProp = CreateObject(drugModel, 0, 0, 0, true, false, false)
                        AttachEntityToEntity(cashProp, npcPed, GetPedBoneIndex(npcPed, 28422), 0.0, 0, 0.0, 18.12, 7.21,
                            -12.44, true, true, false, true, 1, true)
                        AttachEntityToEntity(drugProp, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0, 0.0, 18.12,
                            7.21, -12.44, true, true, false, true, 1, true)
                        TaskPlayAnim(npcPed, animDict, "givetake1_a", 8.0, 1.0, 3000, 0, 0, 0, 0, 0)
                        TaskPlayAnim(playerPed, animDict, "givetake1_a", 8.0, 1.0, 3000, 0, 0, 0, 0, 0)
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
                            ESX.TriggerServerCallback("cdk-sell:server:reward", function(cb)
                                if sellMultiplier < 1 then
                                    lib.notify({
                                        type = 'warning',
                                        description =
                                            "Der er ikke så meget efterspørgsel for stoffer i dette område, du fik " ..
                                            math.floor(sellMultiplier * 100) .. "% af normal prisen",
                                        duration = 7500,
                                    })
                                elseif sellMultiplier >= 1.5 then
                                    lib.notify({
                                        type = 'success',
                                        description = "Der er stor efterspørgsel for stoffer i dette område, du fik " ..
                                            math.floor(sellMultiplier * 100) .. "% af normal prisen",
                                        duration = 7500,
                                    })
                                end
                            end, args, sellAmount, sellMultiplier)
                            print(sellMultiplier)
                        else
                            lib.notify({
                                type = 'error',
                                description = 'Du afbrød salget',
                            })
                        end
                        DeleteEntity(cashProp)
                        DeleteEntity(drugProp)
                        Wait(100)
                        SetModelAsNoLongerNeeded(cashModel)
                        SetModelAsNoLongerNeeded(drugModel)
                        ClearPedTasksImmediately(npcPed)
                        ClearPedTasksImmediately(playerPed)
                        FreezeEntityPosition(playerPed, false)
                        FreezeEntityPosition(npcPed, false)
                    elseif randomNumber > Config.SellChance then
                        local npcPed = entity.entity
                        local dict = "cellphone@"
                        local anim = "cellphone_call_listen_base"
                        local phoneModel = joaat("prop_amb_phone")
                        ClearPedTasksImmediately(npcPed)
                        lib.requestAnimDict(dict)
                        lib.requestModel(phoneModel)
                        Wait(100)
                        TaskPlayAnim(npcPed, dict, anim, 8.0, 8.0, 3000, 0, 0, 0, 0, 0)
                        local phoneProp = CreateObject(phoneModel, 0, 0, 0, true, false, false)
                        AttachEntityToEntity(phoneProp, npcPed, GetPedBoneIndex(npcPed, 28422), 0.0, 0.0, 0.0, 18.12,
                            7.21, -12.44, true, true, false, true, 1, true)
                        lib.notify({
                            type = 'warning',
                            description = 'Person har ringet efter politet...',
                        })
                        Wait(3000)
                        ClearPedTasksImmediately(npcPed)
                        DeleteEntity(phoneProp)
                        Wait(100)
                        SetModelAsNoLongerNeeded(phoneModel)
                    end
                end
            end
            if not cb then
                lib.notify({
                    type = 'error',
                    description = 'Du har ikke noget ' .. args.label .. ' at sælge',
                })
            end
        end, args)
    end
end)

function findItems(option)
    option = {}
    for _, v in pairs(Config.Items) do
        local item = v.item
        ESX.TriggerServerCallback("cdk-sell:server:findItem", function(itemAmount)
            table.insert(option, {
                label = v.label .. ' - ' .. v.priceMin .. ' - ' .. v.priceMax .. 'kr' .. ' - ' .. itemAmount .. ' stk',
                icon = "nui://ox_inventory/web/images/" .. v.item .. ".png",
                args = { item = v.item, label = v.label, priceMin = v.priceMin, priceMax = v.priceMax },
            })
        end, item)
    end
    Wait(100)
    table.insert(option, {
        label = 'Stop med at sælge',
        icon = 'fas fa-times',
        args = { item = nil, stop = true },
    })

    lib.registerMenu({
        id = 'sell',
        title = 'Sælg',
        options = option,
    }, function(_, _, args)
        toggleSelling(args)
    end)

    lib.showMenu('sell')
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
                onSelect = function(entity)
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
