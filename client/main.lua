local isInVehicle = false
local currentVehicle = nil
local engineAllowed = false
local hasAnyKey = false

---@param vehicle number
---@return string|nil
local function GetPlate(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    return string.gsub(GetVehicleNumberPlateText(vehicle), '^%s+', ''):gsub('%s+$', '')
end

---@param ped number
---@param vehicle number
---@return boolean
local function IsDriver(ped, vehicle)
    return GetPedInVehicleSeat(vehicle, -1) == ped
end

local function PlayLockAnim()
    if not Config.LockAnimation then return end
    local ped = PlayerPedId()
    lib.requestAnimDict(Config.AnimDict)
    TaskPlayAnim(ped, Config.AnimDict, Config.AnimName, 8.0, -8.0, 800, 49, 0, false, false, false)
    Wait(800)
    ClearPedTasks(ped)
end

---@param vehicle number
---@param times number
local function FlashLights(vehicle, times)
    if not Config.FlashLights or not DoesEntityExist(vehicle) then return end
    CreateThread(function()
        for i = 1, times do
            SetVehicleLights(vehicle, 2)
            Wait(120)
            SetVehicleLights(vehicle, 0)
            if i < times then Wait(120) end
        end
    end)
end

---@param vehicle number
local function PlayLockSound(vehicle)
    if not Config.LockSound or not DoesEntityExist(vehicle) then return end
    local model = GetEntityModel(vehicle)
    local hash = GetHashKey('NORMAL')
    StartVehicleHorn(vehicle, 150, hash, false)
end

CreateThread(function()
    while true do
        Wait(2000)
        local count = exports.ox_inventory:Search('count', 'carkey')
        hasAnyKey = count and count > 0 or false
    end
end)

RegisterNetEvent('hejdrex_carlock:client:refreshKeyCache', function()
    Wait(100)
    local count = exports.ox_inventory:Search('count', 'carkey')
    hasAnyKey = count and count > 0 or false
end)

---@param entity number Vehicle entity
---@param lock boolean true = lock, false = unlock
local function ToggleLock(entity, lock)
    local plate = GetPlate(entity)
    if not plate then return end

    local netId = VehToNet(entity)
    local success, isLocked = lib.callback.await('hejdrex_carlock:server:toggleLock', false, plate, netId, lock)

    if success then
        PlayLockAnim()

        if isLocked then
            SetVehicleDoorsLocked(entity, 2)
            FlashLights(entity, Config.LockFlashes)
            PlayLockSound(entity)
            lib.notify({
                title = L('notify_title'),
                description = L('vehicle_locked'),
                type = 'success',
                icon = 'lock',
            })
        else
            SetVehicleDoorsLocked(entity, 1)
            FlashLights(entity, Config.UnlockFlashes)
            PlayLockSound(entity)
            lib.notify({
                title = L('notify_title'),
                description = L('vehicle_unlocked'),
                type = 'success',
                icon = 'lock-open',
            })
        end
    else
        lib.notify({
            title = L('notify_title'),
            description = L('no_key'),
            type = 'error',
            icon = 'key',
        })
    end
end

exports.ox_target:addGlobalVehicle({
    {
        name = 'hejdrex_carlock_lock',
        icon = 'fas fa-lock',
        label = L('lock_vehicle'),
        onSelect = function(data)
            ToggleLock(data.entity, true)
        end,
        canInteract = function(entity)
            if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
            if not hasAnyKey then return false end
            local lockStatus = GetVehicleDoorLockStatus(entity)
            return lockStatus ~= 2
        end,
        distance = Config.TargetDistance,
    },
    {
        name = 'hejdrex_carlock_unlock',
        icon = 'fas fa-lock-open',
        label = L('unlock_vehicle'),
        onSelect = function(data)
            ToggleLock(data.entity, false)
        end,
        canInteract = function(entity)
            if IsPedInAnyVehicle(PlayerPedId(), false) then return false end
            if not hasAnyKey then return false end
            local lockStatus = GetVehicleDoorLockStatus(entity)
            return lockStatus == 2
        end,
        distance = Config.TargetDistance,
    },
})

RegisterNetEvent('hejdrex_carlock:client:syncLock', function(netId, locked)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
    end
end)

RegisterNetEvent('hejdrex_carlock:client:vehicleSpawned', function(netId)
    Wait(500)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleEngineOn(vehicle, false, true, true)
    end
end)

local currentPlate = nil
local lastEngineStart = 0

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            if IsDriver(ped, vehicle) then
                if not isInVehicle then
                    isInVehicle = true
                    currentVehicle = vehicle
                    engineAllowed = false
                    currentPlate = GetPlate(vehicle)

                    SetVehicleEngineOn(vehicle, false, true, true)

                    if currentPlate then
                        local canStart, reason = lib.callback.await('hejdrex_carlock:server:canStartEngine', false, currentPlate)

                        if DoesEntityExist(vehicle) and IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) == vehicle then
                            if canStart then
                                if reason == 'free' then
                                    engineAllowed = true
                                    lastEngineStart = GetGameTimer()
                                    SetVehicleEngineOn(vehicle, true, false, false)
                                elseif reason == 'ignition' then
                                    engineAllowed = true
                                    lastEngineStart = GetGameTimer()
                                    SetVehicleEngineOn(vehicle, true, false, false)
                                end
                            end
                        end
                    else
                        engineAllowed = true
                        SetVehicleEngineOn(vehicle, true, false, false)
                    end
                end

                if not engineAllowed and DoesEntityExist(vehicle) then
                    SetVehicleEngineOn(vehicle, false, true, true)
                end

                if engineAllowed and DoesEntityExist(vehicle) and (GetGameTimer() - lastEngineStart > 1500) then
                    if not GetIsVehicleEngineRunning(vehicle) then
                        engineAllowed = false
                        if currentPlate then
                            TriggerServerEvent('hejdrex_carlock:server:engineOff', currentPlate)
                            lib.notify({
                                title = L('notify_title'),
                                description = L('engine_stopped'),
                                type = 'inform',
                                icon = 'power-off',
                            })
                        end
                    end
                end

                Wait(0)
            else
                Wait(500)
            end
        else
            if isInVehicle then
                if engineAllowed and currentPlate then
                    TriggerServerEvent('hejdrex_carlock:server:engineOff', currentPlate)
                end

                isInVehicle = false
                currentVehicle = nil
                currentPlate = nil
                engineAllowed = false
            end
            Wait(500)
        end
    end
end)


RegisterKeyMapping('hejdrex_engine', L('toggle_engine'), 'keyboard', Config.EngineKey)

RegisterCommand('hejdrex_engine', function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if not IsDriver(ped, vehicle) then return end

    local plate = GetPlate(vehicle)
    if not plate then return end

    local engineRunning = GetIsVehicleEngineRunning(vehicle)

    if engineRunning then
        SetVehicleEngineOn(vehicle, false, false, true)
        engineAllowed = false
        TriggerServerEvent('hejdrex_carlock:server:engineOff', plate)
        lib.notify({
            title = L('notify_title'),
            description = L('engine_stopped'),
            type = 'inform',
            icon = 'power-off',
        })
    else
        local success = lib.callback.await('hejdrex_carlock:server:tryStartEngine', false, plate)

        if success then
            engineAllowed = true
            lastEngineStart = GetGameTimer()
            SetVehicleEngineOn(vehicle, true, false, false)
            lib.notify({
                title = L('notify_title'),
                description = L('engine_started'),
                type = 'success',
                icon = 'key',
            })
        else
            lib.notify({
                title = L('notify_title'),
                description = L('no_key_engine'),
                type = 'error',
                icon = 'key',
            })
        end
    end
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if currentVehicle and DoesEntityExist(currentVehicle) then
        SetVehicleEngineOn(currentVehicle, true, false, false)
        SetVehicleDoorsLocked(currentVehicle, 1)
    end
end)
