Config = {}

Config.Locale = 'en' -- 'en' or 'cs'

-- Key to toggle engine on/off while in driver seat
Config.EngineKey = 'G'

-- Delay before engine starts after entering vehicle with key (ms)
Config.EngineStartDelay = 800

-- ox_target interaction distance for locking/unlocking
Config.TargetDistance = 3.0

-- Play lock/unlock animation
Config.LockAnimation = true
Config.AnimDict = 'anim@mp_player_intmenu@key_fob@'
Config.AnimName = 'fob_click'

-- Flash vehicle lights on locking/unlocking
Config.FlashLights = true

-- Play horn sound on locking/unlocking
Config.LockSound = true

-- How many times to flash lights
Config.LockFlashes = 2
Config.UnlockFlashes = 1

Locales = Locales or {}

function L(key)
    local locale = Locales[Config.Locale]
    if locale and locale[key] then
        return locale[key]
    end
    return Locales['en'][key] or key
end