local registeredVehicles = {}

local vehicleLocks = {}

local keysInIgnition = {}

---@param source number Player server ID
---@param plate string Vehicle plate
---@return table|nil First matching item slot data, or nil
local function FindKeyForPlate(source, plate)
    local items = exports.ox_inventory:Search(source, 'slots', 'carkey')
    if items then
        for _, item in pairs(items) do
            if item.metadata and item.metadata.plate == plate then
                return item
            end
        end
    end
    return nil
end

---@param plate string Vehicle plate
---@return table
local function BuildKeyMetadata(plate)
    return {
        plate = plate,
        description = ('Vehicle Key | Plate: %s'):format(plate),
    }
end

lib.callback.register('hejdrex_carlock:server:toggleLock', function(source, plate, netId, wantLocked)
    if not plate or plate == '' then return false end

    local keyItem = FindKeyForPlate(source, plate)
    if not keyItem then
        return false
    end

    vehicleLocks[plate] = wantLocked

    TriggerClientEvent('hejdrex_carlock:client:syncLock', -1, netId, wantLocked)

    return true, wantLocked
end)

lib.callback.register('hejdrex_carlock:server:canStartEngine', function(source, plate)
    if not plate or plate == '' then return true, 'free' end

    if not registeredVehicles[plate] then
        return true, 'free'
    end

    if keysInIgnition[plate] then
        return true, 'ignition'
    end

    return false
end)

lib.callback.register('hejdrex_carlock:server:tryStartEngine', function(source, plate)
    if not plate or plate == '' then return true end

    if not registeredVehicles[plate] then
        return true
    end

    if keysInIgnition[plate] then
        return true
    end

    local keyItem = FindKeyForPlate(source, plate)
    if keyItem then
        local removed = exports.ox_inventory:RemoveItem(source, 'carkey', 1, nil, keyItem.slot)
        if removed then
            keysInIgnition[plate] = true
            TriggerClientEvent('hejdrex_carlock:client:refreshKeyCache', source)
            return true
        end
    end

    return false
end)

RegisterNetEvent('hejdrex_carlock:server:engineOff', function(plate)
    local source = source
    if not plate or plate == '' then return end

    if not keysInIgnition[plate] then return end

    keysInIgnition[plate] = nil

    local existing = exports.ox_inventory:Search(source, 'count', 'carkey', { plate = plate })
    if existing and existing > 0 then return end

    local success = exports.ox_inventory:AddItem(source, 'carkey', 1, BuildKeyMetadata(plate))

    if success then
        TriggerClientEvent('hejdrex_carlock:client:refreshKeyCache', source)
    end
end)

RegisterNetEvent('hejdrex_carlock:server:giveKey', function(plate, netId)
    local source = source
    if not plate or plate == '' then return end

    registeredVehicles[plate] = true
    vehicleLocks[plate] = false

    local existingKey = FindKeyForPlate(source, plate)
    if existingKey then return end

    local success = exports.ox_inventory:AddItem(source, 'carkey', 1, BuildKeyMetadata(plate))

    if success then
        TriggerClientEvent('hejdrex_carlock:client:refreshKeyCache', source)
        TriggerClientEvent('ox_lib:notify', source, {
            title = L('notify_title'),
            description = L('key_received'),
            type = 'success',
            icon = 'key',
        })
    end

    if netId then
        TriggerClientEvent('hejdrex_carlock:client:vehicleSpawned', source, netId)
    end
end)


RegisterNetEvent('hejdrex_carlock:server:removeKey', function(plate)
    local source = source
    if not plate or plate == '' then return end

    keysInIgnition[plate] = nil

    local items = exports.ox_inventory:Search(source, 'slots', 'carkey')
    if items then
        for _, item in pairs(items) do
            if item.metadata and item.metadata.plate == plate then
                exports.ox_inventory:RemoveItem(source, 'carkey', 1, nil, item.slot)
            end
        end
    end

    registeredVehicles[plate] = nil
    vehicleLocks[plate] = nil

    TriggerClientEvent('hejdrex_carlock:client:refreshKeyCache', source)

    TriggerClientEvent('ox_lib:notify', source, {
        title = L('notify_title'),
        description = L('key_removed'),
        type = 'inform',
        icon = 'key',
    })
end)

AddEventHandler('playerDropped', function()
    local source = source
end)


AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
end)
