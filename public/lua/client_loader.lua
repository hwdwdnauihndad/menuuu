local LibraryURL = "http://82.22.7.19:25005/public/lua/library.lua"
local status, LibraryCode = Susano.HttpGet(LibraryURL)

if status ~= 200 then
    return
end


if not string.find(LibraryCode, "Menu.OnRender") then
    -- Look for the SubmitFrame call and insert OnRender before it
    LibraryCode = string.gsub(LibraryCode, "if Susano%.SubmitFrame then", [[
    if Menu.OnRender then
        local success, err = pcall(Menu.OnRender)
        if not success then print("Error in Menu.OnRender: " .. tostring(err)) end
    end
    if Susano.SubmitFrame then]])
end


if string.find(LibraryCode, "Susano%.ResetFrame") then
    LibraryCode = string.gsub(LibraryCode, "if Susano%.ResetFrame then", [[
    if Susano.ResetFrame and not Menu.PreventResetFrame then]])
end

local Menu = load(LibraryCode)()

-- Magic Bullet & Draw FOV variables
local magicbulletEnabled = false
local drawFovEnabled = false
local fovRadius = 150.0
local shooteyesEnabled = false

-- Weapon spawn system (same as oldmenu.lua)
local selectedWeaponIndex = {
    melee = 1,
    pistol = 1,
    smg = 1,
    shotgun = 1,
    ar = 1,
    sniper = 1,
    heavy = 1
}

local weaponLists = {
    melee = {
        {name = "WEAPON_KNIFE", display = "Knife"},
        {name = "WEAPON_BAT", display = "Baseball Bat"},
        {name = "WEAPON_CROWBAR", display = "Crowbar"},
        {name = "WEAPON_GOLFCLUB", display = "Golf Club"},
        {name = "WEAPON_HAMMER", display = "Hammer"},
        {name = "WEAPON_HATCHET", display = "Hatchet"},
        {name = "WEAPON_KNUCKLE", display = "Brass Knuckles"},
        {name = "WEAPON_MACHETE", display = "Machete"},
        {name = "WEAPON_SWITCHBLADE", display = "Switchblade"},
        {name = "WEAPON_NIGHTSTICK", display = "Nightstick"},
        {name = "WEAPON_WRENCH", display = "Wrench"},
        {name = "WEAPON_BATTLEAXE", display = "Battle Axe"},
        {name = "WEAPON_POOLCUE", display = "Pool Cue"},
        {name = "WEAPON_STONE_HATCHET", display = "Stone Hatchet"}
    },
    pistol = {
        {name = "WEAPON_PISTOL", display = "Pistol"},
        {name = "WEAPON_PISTOL_MK2", display = "Pistol MK2"},
        {name = "WEAPON_COMBATPISTOL", display = "Combat Pistol"},
        {name = "WEAPON_PISTOL50", display = "Pistol .50"},
        {name = "WEAPON_SNSPISTOL", display = "SNS Pistol"},
        {name = "WEAPON_SNSPISTOL_MK2", display = "SNS Pistol MK2"},
        {name = "WEAPON_HEAVYPISTOL", display = "Heavy Pistol"},
        {name = "WEAPON_VINTAGEPISTOL", display = "Vintage Pistol"},
        {name = "WEAPON_FLAREGUN", display = "Flare Gun"},
        {name = "WEAPON_MARKSMANPISTOL", display = "Marksman Pistol"},
        {name = "WEAPON_REVOLVER", display = "Heavy Revolver"},
        {name = "WEAPON_REVOLVER_MK2", display = "Heavy Revolver MK2"},
        {name = "WEAPON_DOUBLEACTION", display = "Double Action Revolver"},
        {name = "WEAPON_APPISTOL", display = "AP Pistol"},
        {name = "WEAPON_STUNGUN", display = "Stun Gun"},
        {name = "WEAPON_CERAMICPISTOL", display = "Ceramic Pistol"},
        {name = "WEAPON_NAVYREVOLVER", display = "Navy Revolver"}
    },
    smg = {
        {name = "WEAPON_MICROSMG", display = "Micro SMG"},
        {name = "WEAPON_SMG", display = "SMG"},
        {name = "WEAPON_SMG_MK2", display = "SMG MK2"},
        {name = "WEAPON_ASSAULTSMG", display = "Assault SMG"},
        {name = "WEAPON_COMBATPDW", display = "Combat PDW"},
        {name = "WEAPON_MACHINEPISTOL", display = "Machine Pistol"},
        {name = "WEAPON_MINISMG", display = "Mini SMG"},
        {name = "WEAPON_GUSENBERG", display = "Gusenberg Sweeper"}
    },
    shotgun = {
        {name = "WEAPON_PUMPSHOTGUN", display = "Pump Shotgun"},
        {name = "WEAPON_PUMPSHOTGUN_MK2", display = "Pump Shotgun MK2"},
        {name = "WEAPON_SAWNOFFSHOTGUN", display = "Sawed-Off Shotgun"},
        {name = "WEAPON_ASSAULTSHOTGUN", display = "Assault Shotgun"},
        {name = "WEAPON_BULLPUPSHOTGUN", display = "Bullpup Shotgun"},
        {name = "WEAPON_MUSKET", display = "Musket"},
        {name = "WEAPON_HEAVYSHOTGUN", display = "Heavy Shotgun"},
        {name = "WEAPON_DBSHOTGUN", display = "Double Barrel Shotgun"},
        {name = "WEAPON_AUTOSHOTGUN", display = "Auto Shotgun"},
        {name = "WEAPON_COMBATSHOTGUN", display = "Combat Shotgun"}
    },
    ar = {
        {name = "WEAPON_ASSAULTRIFLE", display = "Assault Rifle"},
        {name = "WEAPON_ASSAULTRIFLE_MK2", display = "Assault Rifle MK2"},
        {name = "WEAPON_CARBINERIFLE", display = "Carbine Rifle"},
        {name = "WEAPON_CARBINERIFLE_MK2", display = "Carbine Rifle MK2"},
        {name = "WEAPON_ADVANCEDRIFLE", display = "Advanced Rifle"},
        {name = "WEAPON_SPECIALCARBINE", display = "Special Carbine"},
        {name = "WEAPON_SPECIALCARBINE_MK2", display = "Special Carbine MK2"},
        {name = "WEAPON_BULLPUPRIFLE", display = "Bullpup Rifle"},
        {name = "WEAPON_BULLPUPRIFLE_MK2", display = "Bullpup Rifle MK2"},
        {name = "WEAPON_COMPACTRIFLE", display = "Compact Rifle"},
        {name = "WEAPON_MILITARYRIFLE", display = "Military Rifle"},
        {name = "WEAPON_HEAVYRIFLE", display = "Heavy Rifle"},
        {name = "WEAPON_TACTICALRIFLE", display = "Tactical Rifle"}
    },
    sniper = {
        {name = "WEAPON_SNIPERRIFLE", display = "Sniper Rifle"},
        {name = "WEAPON_HEAVYSNIPER", display = "Heavy Sniper"},
        {name = "WEAPON_HEAVYSNIPER_MK2", display = "Heavy Sniper MK2"},
        {name = "WEAPON_MARKSMANRIFLE", display = "Marksman Rifle"},
        {name = "WEAPON_MARKSMANRIFLE_MK2", display = "Marksman Rifle MK2"},
        {name = "WEAPON_PRECISIONRIFLE", display = "Precision Rifle"}
    },
    heavy = {
        {name = "WEAPON_RPG", display = "RPG"},
        {name = "WEAPON_GRENADELAUNCHER", display = "Grenade Launcher"},
        {name = "WEAPON_GRENADELAUNCHER_SMOKE", display = "Grenade Launcher Smoke"},
        {name = "WEAPON_MINIGUN", display = "Minigun"},
        {name = "WEAPON_FIREWORK", display = "Firework Launcher"},
        {name = "WEAPON_RAILGUN", display = "Railgun"},
        {name = "WEAPON_HOMINGLAUNCHER", display = "Homing Launcher"},
        {name = "WEAPON_COMPACTLAUNCHER", display = "Compact Grenade Launcher"},
        {name = "WEAPON_RAYMINIGUN", display = "Widowmaker"},
        {name = "WEAPON_EMPLAUNCHER", display = "Compact EMP Launcher"},
        {name = "WEAPON_RAILGUNXM3", display = "Railgun XM3"}
    }
}

-- Give weapon to player by name (for Give Weapon to Player input) - Must be defined before menu
local function GiveWeaponToPlayerByName(weaponName, targetServerId)
    -- Option désactivée
end

-- Weapon spawn by name (for Give Weapon input) - Must be defined before menu
local function SpawnWeaponByName(weaponName)
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local susano = rawget(_G, "Susano")
            
            -- Hooker les natives pour bypasser les vérifications
            if susano and type(susano) == "table" and type(susano.HookNative) == "function" and not _weapon_spawn_hooks_applied then
                _weapon_spawn_hooks_applied = true
                
                -- Bypass IsEntityVisible
                susano.HookNative(0x2B40A976, function(entity) return true end)
                -- Bypass IsEntityVisibleToScript
                susano.HookNative(0x5324A0E3E4CE3570, function(entity) return true end)
                -- Bypass NetworkHasControlOfEntity
                susano.HookNative(0x8DE82BC774F3B862, function() return true end)
                
                -- Bypass HasPedGotWeapon
                susano.HookNative(0x8DECB02F88F428BC, function(ped, weaponHash, p2)
                    return false, false
                end)
                
                -- Bypass GetWeapontypeGroup
                susano.HookNative(0xC82758D1, function(weaponHash)
                    return false, 0
                end)
                
                -- Bypass IsWeaponValid
                susano.HookNative(0x937C71162CF43879, function(weaponHash)
                    return false, true
                end)
                
                -- Bypass NetworkCanControlEntity
                susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                    local entityType = GetEntityType(entity)
                    if entityType == 1 then
                        return false
                    end
                    return true
                end)
                
                -- Bypass CanUseWeaponOnVehicle
                susano.HookNative(0xE169B653, function(weaponHash)
                    return false, true
                end)
                
                -- Bypass GetWeaponDamageType
                susano.HookNative(0x3BE1257F, function(weaponHash)
                    return false, 0
                end)
            end
            
            CreateThread(function()
                Wait(300)
                local ped = PlayerPedId()
                local weaponHash = GetHashKey("%s")
                RequestWeaponAsset(weaponHash, 31, 0)
                local timeout = 0
                while not HasWeaponAssetLoaded(weaponHash) and timeout < 100 do
                    Wait(10)
                    timeout = timeout + 1
                end
                if HasWeaponAssetLoaded(weaponHash) then
                    Wait(100)
                    GiveWeaponToPed(ped, weaponHash, 250, false, true)
                end
            end)
        ]], weaponName))
    end
end

local function GenerateNativeHooks(nativesList)
    local hooks = [[
local function hNative(nativeName, newFunction)
    local originalNative = _G[nativeName]
    if not originalNative or type(originalNative) ~= "function" then return end
    _G[nativeName] = function(...) return newFunction(originalNative, ...) end
end
]]
    for _, nativeName in ipairs(nativesList) do
        hooks = hooks .. string.format('hNative("%s", function(originalFn, ...) return originalFn(...) end)\n', nativeName)
    end
    return hooks
end


local COMMON_NATIVES = {
    "GetActivePlayers", "GetPlayerServerId", "GetPlayerPed", "DoesEntityExist", 
    "PlayerPedId", "GetEntityCoords", "SetEntityCoordsNoOffset", "GetEntityHeading",
    "SetEntityHeading", "IsPedInAnyVehicle", "GetVehiclePedIsIn"
}


local VEHICLE_NATIVES = {
    "TaskWarpPedIntoVehicle", "SetVehicleDoorsLocked", "SetVehicleDoorsLockedForAllPlayers",
    "IsVehicleSeatFree", "ClearPedTasksImmediately", "TaskEnterVehicle", 
    "GetClosestVehicle", "SetPedIntoVehicle", "SetEntityAsMissionEntity",
    "NetworkGetEntityIsNetworked", "NetworkRequestControlOfEntity", "AttachEntityToEntity",
    "DetachEntity", "AttachEntityToEntityPhysically", "GetOffsetFromEntityInWorldCoords",
    "SetEntityRotation", "FreezeEntityPosition", "TaskLeaveVehicle", "DeletePed",
    "GetPedInVehicleSeat", "NetworkHasControlOfEntity"
}

-- Génère le code avec hooks pour une fonction véhicule
local function WrapWithVehicleHooks(code)
    local allNatives = {}
    for _, n in ipairs(COMMON_NATIVES) do table.insert(allNatives, n) end
    for _, n in ipairs(VEHICLE_NATIVES) do table.insert(allNatives, n) end
    return GenerateNativeHooks(allNatives) .. "\n" .. code
end

Menu.Categories = {
    { name = "Main Menu", icon = "P" },
    { name = "Player", icon = "👤", hasTabs = true, tabs = {
        { name = "Self", items = {
            { name = "", isSeparator = true, separatorText = "Health" },
            { name = "Godmode", type = "toggle", value = false },
            { name = "Anti Headshot", type = "toggle", value = false },
            { name = "Revive", type = "action" },
            { name = "Max Health", type = "action" },
            { name = "Max Armor", type = "action" },
            { name = "", isSeparator = true, separatorText = "other" },
            { name = "Bypass Driveby", type = "toggle", value = false },
            { name = "Detach All Entitys", type = "action" },
            { name = "Solo Session", type = "toggle", value = false },
            { name = "Misc Target", type = "action" }
        }},
        { name = "Movement", items = {
            { name = "", isSeparator = true, separatorText = "noclip" },
            { name = "Noclip", type = "toggle", value = false, hasSlider = true, sliderValue = 1.0, sliderMin = 1.0, sliderMax = 20.0, sliderStep = 0.5 },
            { name = "Noclip Type", type = "selector", options = {"None", "Invisible", "Desync"}, selected = 1 },
            { name = "", isSeparator = true, separatorText = "freecam" },
            { name = "Freecam", type = "toggle", value = false, hasSlider = true, sliderValue = 0.5, sliderMin = 0.1, sliderMax = 5.0, sliderStep = 0.1 },
            { name = "", isSeparator = true, separatorText = "other" },
            { name = "Invisible", type = "toggle", value = false },
            { name = "Fast Run", type = "toggle", value = false },
            { name = "Super Jump", type = "toggle", value = false },
            { name = "No Ragdoll", type = "toggle", value = false },
            { name = "Anti Freeze", type = "toggle", value = false }
        }},
        { name = "Wardrobe", items = {
            { name = "Random Outfit", type = "action" },
            { name = "", isSeparator = true, separatorText = "Clothing" },
            { name = "Hat", type = "selector", options = {}, selected = 1 },
            { name = "Mask", type = "selector", options = {}, selected = 1 },
            { name = "Glasses", type = "selector", options = {}, selected = 1 },
            { name = "Torso", type = "selector", options = {}, selected = 1 },
            { name = "Tshirt", type = "selector", options = {}, selected = 1 },
            { name = "Pants", type = "selector", options = {}, selected = 1 },
            { name = "Shoes", type = "selector", options = {}, selected = 1 }
        }}
    }},
    { name = "Online", icon = "👥", hasTabs = true, tabs = {
        { name = "Player List", items = {
            { name = "Loading players...", type = "action" }
        }},
        { name = "Troll", items = {
            { name = "Copy Appearance", type = "action" },
            { name = "Shoot Player", type = "action" },
            { name = "Bug Player", type = "selector", options = {"Bug", "Launch"}, selected = 1 },
            { name = "Cage Player", type = "action" },
            { name = "Rain Nearby Vehicle", type = "action" },
            { name = "Drop Nearby Vehicle", type = "action" }
        }},
        { name = "risky", items = {
            { name = "Give Weapon to Player", type = "action" }
        }},
        { name = "Vehicle", items = {
            { name = "Bug Vehicle", type = "selector", options = {"V1", "V2"}, selected = 1 },
            { name = "Warp Vehicle", type = "action" },
            { name = "Warp+Boost", type = "action" },
            { name = "TP to", type = "selector", options = {"ocean", "mazebank", "sandyshores"}, selected = 1 },
            { name = "Steal Vehicle", type = "action" },
            { name = "Kick Vehicle", type = "selector", options = {"V1", "V2"}, selected = 1 },
            { name = "Hijack Player", type = "action" },
            { name = "Give Vehicle", type = "action" },
            { name = "Give Ramp", type = "action" }
        }}
    }},
    { name = "Visual", icon = "👁", hasTabs = true, tabs = {
        { name = "ESP", items = {
            { name = "", isSeparator = true, separatorText = "ESP" },
            { name = "Draw Self", type = "toggle", value = false },
            { name = "Draw Skeleton", type = "toggle", value = false },
            { name = "Draw Box", type = "toggle", value = false },
            { name = "Draw Line", type = "toggle", value = false },
            
            { name = "", isSeparator = true, separatorText = "color" },
            { name = "Skeleton Color", type = "selector", options = {"White", "Red", "Green", "Blue", "Yellow", "Purple", "Cyan"}, selected = 1 },
            { name = "Box Color", type = "selector", options = {"White", "Red", "Green", "Blue", "Yellow", "Purple", "Cyan"}, selected = 1 },
            { name = "Line Color", type = "selector", options = {"White", "Red", "Green", "Blue", "Yellow", "Purple", "Cyan"}, selected = 1 },
            
            { name = "", isSeparator = true, separatorText = "Extra" },
            { name = "Enable Player ESP", type = "toggle", value = false },
            { name = "Draw Name", type = "toggle", value = false },
            { name = "Name Position", type = "selector", options = {"Top", "Bottom", "Left", "Right"}, selected = 1 },
            { name = "Draw ID", type = "toggle", value = false },
            { name = "ID Position", type = "selector", options = {"Top", "Bottom", "Left", "Right"}, selected = 1 },
            { name = "Draw Distance", type = "toggle", value = false },
            { name = "Distance Position", type = "selector", options = {"Top", "Bottom", "Left", "Right"}, selected = 1 },
            { name = "Draw Weapon", type = "toggle", value = false },
            { name = "Weapon Position", type = "selector", options = {"Top", "Bottom", "Left", "Right"}, selected = 1 },
            { name = "Draw Health", type = "toggle", value = false },
            { name = "Draw Armor", type = "toggle", value = false },
        }},
        { name = "World", items = {
            { name = "FPS Boost", type = "toggle", value = false },
            { name = "Time", type = "slider", value = 12.0, min = 0.0, max = 23.0 },
            { name = "Freeze Time", type = "toggle", value = false },
            { name = "Weather", type = "selector", options = {"Extrasunny", "Clear", "Clouds", "Smog", "Fog", "Overcast", "Rain", "Thunder", "Clearing", "Neutral", "Snow", "Blizzard", "Snowlight", "Xmas", "Halloween"}, selected = 1 },
            { name = "", isSeparator = true, separatorText = "Effects" },
            { name = "Blackout", type = "toggle", value = false },
            { name = "Night Vision", type = "toggle", value = false },
            { name = "Thermal Vision", type = "toggle", value = false }
        }}
    }},
    { name = "Combat", icon = "🔫", hasTabs = true, tabs = {
        { name = "General", items = {
            { name = "", isSeparator = true, separatorText = "Magic Bullet" },
            { name = "Magic Bullet", type = "toggle", value = false },
            { name = "Draw FOV", type = "toggle", value = false, hasSlider = true, sliderValue = 100.0, sliderMin = 0.0, sliderMax = 500.0, sliderStep = 5.0 },
            { name = "FOV Color", type = "selector", options = {"White", "Red", "Green", "Blue", "Yellow", "Purple", "Cyan"}, selected = 2 },
            { name = "", isSeparator = true, separatorText = "other" },
            { name = "Shoot Eyes", type = "toggle", value = false },
            { name = "Infinite Ammo", type = "toggle", value = false }
        }},
        { name = "Spawn", items = {
            { name = "Protect Weapon", type = "toggle", value = false },
            { name = "", isSeparator = true, separatorText = "Categories" },
            { name = "Give Weapon", type = "action", onClick = function()
                Menu.OpenInput("Give Weapon", function(text)
                    if text and text ~= "" then
                        -- Convert to uppercase and add WEAPON_ prefix if needed
                        local searchText = string.upper(text:gsub("^%s*(.-)%s*$", "%1")) -- Trim and uppercase
                        local weaponName = nil
                        
                        -- If it doesn't start with WEAPON_, add it
                        if not string.find(searchText, "^WEAPON_") then
                            weaponName = "WEAPON_" .. searchText
                        else
                            weaponName = searchText
                        end
                        
                        -- Search in all weapon lists
                        local found = false
                        for category, weapons in pairs(weaponLists) do
                            for _, weapon in ipairs(weapons) do
                                if weapon.name == weaponName then
                                    found = true
                                    SpawnWeaponByName(weaponName)
                                    break
                                end
                            end
                            if found then break end
                        end
                        
                        if not found then
                            -- Try direct spawn anyway
                            SpawnWeaponByName(weaponName)
                        end
                    end
                end)
            end },
            { name = "Melee", type = "selector", options = {"Knife", "Baseball Bat", "Crowbar", "Golf Club", "Hammer", "Hatchet", "Brass Knuckles", "Machete", "Switchblade", "Nightstick", "Wrench", "Battle Axe", "Pool Cue", "Stone Hatchet"}, selected = 1 },
            { name = "Pistol", type = "selector", options = {"Pistol", "Pistol MK2", "Combat Pistol", "Pistol .50", "SNS Pistol", "SNS Pistol MK2", "Heavy Pistol", "Vintage Pistol", "Flare Gun", "Marksman Pistol", "Heavy Revolver", "Heavy Revolver MK2", "Double Action Revolver", "AP Pistol", "Stun Gun", "Ceramic Pistol", "Navy Revolver"}, selected = 1 },
            { name = "SMG", type = "selector", options = {"Micro SMG", "SMG", "SMG MK2", "Assault SMG", "Combat PDW", "Machine Pistol", "Mini SMG", "Gusenberg Sweeper"}, selected = 1 },
            { name = "Shotgun", type = "selector", options = {"Pump Shotgun", "Pump Shotgun MK2", "Sawed-Off Shotgun", "Assault Shotgun", "Bullpup Shotgun", "Musket", "Heavy Shotgun", "Double Barrel Shotgun", "Auto Shotgun", "Combat Shotgun"}, selected = 1 },
            { name = "Assault Rifle", type = "selector", options = {"Assault Rifle", "Assault Rifle MK2", "Carbine Rifle", "Carbine Rifle MK2", "Advanced Rifle", "Special Carbine", "Special Carbine MK2", "Bullpup Rifle", "Bullpup Rifle MK2", "Compact Rifle", "Military Rifle", "Heavy Rifle", "Tactical Rifle"}, selected = 1 },
            { name = "Sniper", type = "selector", options = {"Sniper Rifle", "Heavy Sniper", "Heavy Sniper MK2", "Marksman Rifle", "Marksman Rifle MK2", "Precision Rifle"}, selected = 1 },
            { name = "Heavy", type = "selector", options = {"RPG", "Grenade Launcher", "Grenade Launcher Smoke", "Minigun", "Firework Launcher", "Railgun", "Homing Launcher", "Compact Grenade Launcher", "Widowmaker", "Compact EMP Launcher", "Railgun XM3"}, selected = 1 }
        }}
    }},
    { name = "Vehicle", icon = "🚗", hasTabs = true, tabs = {
        { name = "Spawn", items = {
            { name = "Teleport Into", type = "toggle", value = false },
            { name = "", isSeparator = true, separatorText = "spawn" },
            { name = "Car", type = "selector", options = {"Adder", "Zentorno", "T20", "Osiris", "Entity XF"}, selected = 1 },
            { name = "Moto", type = "selector", options = {"Bati 801", "Sanchez", "Akuma", "Hakuchou"}, selected = 1 },
            { name = "Plane", type = "selector", options = {"Luxor", "Hydra", "Lazer", "Besra"}, selected = 1 },
            { name = "Boat", type = "selector", options = {"Seashark", "Speeder", "Jetmax", "Toro"}, selected = 1 },
            { name = "Addon", type = "selector", options = {"Addon 1", "Addon 2"}, selected = 1 }
        }},
        { name = "Performance", items = {
            { name = "Max Upgrade", type = "action" },
            { name = "Repair Vehicle", type = "action" },
            { name = "Force Vehicle Engine", type = "toggle", value = false },
            { name = "Boost Vehicle", type = "toggle", value = false, hasSlider = true, sliderValue = 50.0, sliderMin = 10.0, sliderMax = 200.0, sliderStep = 5.0 }
        }},
        { name = "Extra", items = {
            { name = "Clean Vehicle", type = "action" },
            { name = "Delete Vehicle", type = "action" },
            { name = "Unlock Closest Vehicle", type = "action" },
            { name = "Teleport into Closest Vehicle", type = "action" },
            { name = "Gravitate Vehicle", type = "toggle", value = false },
            { name = "No Collision", type = "toggle", value = false },
            { name = "Give Nearest Vehicle", type = "action" },
            { name = "Ramp Vehicle", type = "action" }
        }}
    }},
    { name = "Miscellaneous", icon = "📄", hasTabs = true, tabs = {
        { name = "General", items = {
            { name = "", isSeparator = true, separatorText = "Teleport" },
            { name = "TP to Waypoint", type = "action" },
            { name = "FIB Building", type = "action" },
            { name = "Mission Row PD", type = "action" },
            { name = "Pillbox Hospital", type = "action" },
            { name = "Grove Street", type = "action" },
            { name = "Legion Square", type = "action" },
            { name = "", isSeparator = true, separatorText = "Server Stuff" },
            { name = "Triggers Finder (F8)", type = "toggle", value = false },
            { name = "Event Logger", type = "toggle", value = false },
            { name = "", isSeparator = true, separatorText = "tx exploit" },
            { name = "txAdmin Player IDs", type = "toggle", value = false },
            { name = "txAdmin Noclip", type = "toggle", value = false },
            { name = "Disable All txAdmin", type = "action" },
            { name = "Disable txAdmin Teleport", type = "action" },
            { name = "Disable txAdmin Freeze", type = "action" }
        }},
        { name = "Bypasses", items = {
            { name = "", isSeparator = true, separatorText = "Anti Cheat" },
            { name = "Anti Cheat Finder", type = "action" }
        }},
        { name = "BypassAC", items = {
        }},
        { name = "Resources", items = {
            { name = "Loading...", type = "action" }
        }}
    }},
    { name = "Settings", icon = "⚙", hasTabs = true, tabs = {
        { name = "General", items = {
            { name = "Editor Mode", type = "toggle", value = false },
            { name = "Smooth Menu", type = "slider", value = 20.0, min = 1.0, max = 100.0 },
            { name = "Menu Size", type = "slider", value = 1.0, min = 0.5, max = 2.0, step = 0.1 },
            { name = "", isSeparator = true, separatorText = "Design" },
            { name = "Menu Theme", type = "selector", options = {"Purple", "pink", "Green", "Red"}, selected = 1 },
            { name = "Flocon", type = "toggle", value = false },
            { name = "Gradient", type = "selector", options = {"1", "2"}, selected = 1 },
            { name = "Scroll Bar Position", type = "selector", options = {"Left", "Right"}, selected = 1 }
        }},
        { name = "Config", items = {
            { name = "Create Config", type = "action", onClick = function()
                Menu.OpenInput("Create Config", function(text)
                    print("Creating config: " .. text)
                end)
            end },
            { name = "Load Config", type = "action", onClick = function()
                print("Load Config")
            end },
            { name = "Overwrite Config", type = "action", onClick = function()
                print("Overwrite Config")
            end },
            { name = "Delete Config", type = "action", onClick = function()
                print("Delete Config")
            end }
        }},
        { name = "Keybinds", items = {
            { name = "Change Menu Keybind", type = "action" },
            { name = "Show Menu Keybinds", type = "toggle", value = false }
        }}
    }}
}

-- Initialiser le menu
Menu.Visible = false

-- Player List variables
Menu.SelectedPlayer = nil
Menu.SelectedPlayers = {}
Menu.PlayerListSelectIndex = 1
Menu.PlayerListTeleportIndex = 1
Menu.PlayerListSpectateEnabled = false

-- Skeleton ESP Implementation
local Bones = {
    Pelvis = 11816,
    SKEL_Head = 31086,
    SKEL_Neck_1 = 39317,
    SKEL_L_Clavicle = 64729,
    SKEL_L_UpperArm = 45509,
    SKEL_L_Forearm = 61163,
    SKEL_L_Hand = 18905,
    SKEL_R_Clavicle = 10706,
    SKEL_R_UpperArm = 40269,
    SKEL_R_Forearm = 28252,
    SKEL_R_Hand = 57005,
    SKEL_L_Thigh = 58271,
    SKEL_L_Calf = 63931,
    SKEL_L_Foot = 14201,
    SKEL_R_Thigh = 51826,
    SKEL_R_Calf = 36864,
    SKEL_R_Foot = 52301,
}

local SkeletonConnections = {
    {Bones.Pelvis, Bones.SKEL_Neck_1},
    {Bones.SKEL_Neck_1, Bones.SKEL_Head},
    {Bones.SKEL_Neck_1, Bones.SKEL_L_Clavicle},
    {Bones.SKEL_L_Clavicle, Bones.SKEL_L_UpperArm},
    {Bones.SKEL_L_UpperArm, Bones.SKEL_L_Forearm},
    {Bones.SKEL_L_Forearm, Bones.SKEL_L_Hand},
    {Bones.SKEL_Neck_1, Bones.SKEL_R_Clavicle},
    {Bones.SKEL_R_Clavicle, Bones.SKEL_R_UpperArm},
    {Bones.SKEL_R_UpperArm, Bones.SKEL_R_Forearm},
    {Bones.SKEL_R_Forearm, Bones.SKEL_R_Hand},
    {Bones.Pelvis, Bones.SKEL_L_Thigh},
    {Bones.SKEL_L_Thigh, Bones.SKEL_L_Calf},
    {Bones.SKEL_L_Calf, Bones.SKEL_L_Foot},
    {Bones.Pelvis, Bones.SKEL_R_Thigh},
    {Bones.SKEL_R_Thigh, Bones.SKEL_R_Calf},
    {Bones.SKEL_R_Calf, Bones.SKEL_R_Foot},
}

-- Predefined Colors
local ESPColors = {
    {1.0, 1.0, 1.0}, -- White
    {1.0, 0.0, 0.0}, -- Red
    {0.0, 1.0, 0.0}, -- Green
    {0.0, 0.0, 1.0}, -- Blue
    {1.0, 1.0, 0.0}, -- Yellow
    {1.0, 0.0, 1.0}, -- Purple
    {0.0, 1.0, 1.0}, -- Cyan
}

-- Function to get settings from the menu
local function GetESPSettings()
    local settings = {}
    for _, cat in ipairs(Menu.Categories) do
        if cat.name == "Visual" and cat.tabs then
            for _, tab in ipairs(cat.tabs) do
                if tab.name == "ESP" and tab.items then
                    for _, item in ipairs(tab.items) do
                        settings[item.name] = item
                    end
                end
            end
        end
    end
    return settings
end

local espSettings = nil

-- Helper function to get screen resolution
local function GetScreenSize()
    if Susano and Susano.GetScreenWidth and Susano.GetScreenHeight then
        local w, h = Susano.GetScreenWidth(), Susano.GetScreenHeight()
        if w and h and w > 0 and h > 0 then
            return w, h
        end
    end
    
    -- Fallback to GTA Native
    local w, h = GetActiveScreenResolution()
    return w, h
end

-- Draw 2D Box
local function Draw2DBox(x1, y1, x2, y2, r, g, b, a, screenW, screenH)
    if not Susano.DrawLine then return end
    
    local w = x2 - x1
    local h = y2 - y1
    
    -- Top
    Susano.DrawLine(x1 * screenW, y1 * screenH, x2 * screenW, y1 * screenH, r, g, b, a, 1)
    -- Bottom
    Susano.DrawLine(x1 * screenW, y2 * screenH, x2 * screenW, y2 * screenH, r, g, b, a, 1)
    -- Left
    Susano.DrawLine(x1 * screenW, y1 * screenH, x1 * screenW, y2 * screenH, r, g, b, a, 1)
    -- Right
    Susano.DrawLine(x2 * screenW, y1 * screenH, x2 * screenW, y2 * screenH, r, g, b, a, 1)
end

-- Draw Filled Rect (Wrapper)
local function DrawFilledRect(x, y, w, h, r, g, b, a)
    if Susano.DrawRectFilled then
        Susano.DrawRectFilled(x, y, w, h, r, g, b, a, 0)
    elseif Susano.DrawRect then
        -- Fallback if DrawRectFilled is missing but DrawRect exists (loop lines)
        for i = 0, h do
            Susano.DrawRect(x, y + i, w, 1, r, g, b, a)
        end
    end
end

-- Render ESP for a single ped
local function RenderPedESP(targetPed, playerIdx, settings, screenW, screenH, myPos)
    if not DoesEntityExist(targetPed) then return end

    local targetPos = GetEntityCoords(targetPed)
    local dist = #(myPos - targetPos)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(targetPos.x, targetPos.y, targetPos.z)
    
    if onScreen or dist < 100.0 then
        -- Config Values
        local drawSkeleton = settings["Draw Skeleton"] and settings["Draw Skeleton"].value
        local drawBox = settings["Draw Box"] and settings["Draw Box"].value
        local drawLine = settings["Draw Line"] and settings["Draw Line"].value
        local drawHealth = settings["Draw Health"] and settings["Draw Health"].value
        local drawArmor = settings["Draw Armor"] and settings["Draw Armor"].value

        -- Get Selector Settings
        local drawNameItem = settings["Draw Name"]
        local drawName = drawNameItem and drawNameItem.value
        local drawNamePosItem = settings["Name Position"]
        local drawNamePos = (drawNamePosItem and drawNamePosItem.selected) or 1
        
        local drawIDItem = settings["Draw ID"]
        local drawID = drawIDItem and drawIDItem.value
        local drawIDPosItem = settings["ID Position"]
        local drawIDPos = (drawIDPosItem and drawIDPosItem.selected) or 1
        
        local drawDistItem = settings["Draw Distance"]
        local drawDist = drawDistItem and drawDistItem.value
        local drawDistPosItem = settings["Distance Position"]
        local drawDistPos = (drawDistPosItem and drawDistPosItem.selected) or 1
        
        local drawWeaponItem = settings["Draw Weapon"]
        local drawWeapon = drawWeaponItem and drawWeaponItem.value
        local drawWeaponPosItem = settings["Weapon Position"]
        local drawWeaponPos = (drawWeaponPosItem and drawWeaponPosItem.selected) or 1
        
        -- Colors
        local skelColor = ESPColors[1]
        if settings["Skeleton Color"] then skelColor = ESPColors[settings["Skeleton Color"].selected] or skelColor end
        
        local boxColor = ESPColors[1]
        if settings["Box Color"] then boxColor = ESPColors[settings["Box Color"].selected] or boxColor end
        
        local lineColor = ESPColors[1]
        if settings["Line Color"] then lineColor = ESPColors[settings["Line Color"].selected] or lineColor end

        -- Skeleton
        if drawSkeleton then
            for _, connection in ipairs(SkeletonConnections) do
                local bone1 = connection[1]
                local bone2 = connection[2]
                local pos1 = GetPedBoneCoords(targetPed, bone1, 0.0, 0.0, 0.0)
                local pos2 = GetPedBoneCoords(targetPed, bone2, 0.0, 0.0, 0.0)
                local os1, x1, y1 = GetScreenCoordFromWorldCoord(pos1.x, pos1.y, pos1.z)
                local os2, x2, y2 = GetScreenCoordFromWorldCoord(pos2.x, pos2.y, pos2.z)

                if os1 and os2 and Susano.DrawLine then
                    -- Draw thin black outline
                    Susano.DrawLine(x1 * screenW, y1 * screenH, x2 * screenW, y2 * screenH, 0.0, 0.0, 0.0, 1.0, 2)
                    -- Draw main skeleton line
                    Susano.DrawLine(x1 * screenW, y1 * screenH, x2 * screenW, y2 * screenH, skelColor[1], skelColor[2], skelColor[3], 1.0, 1)
                end
            end
        end
        
        -- Calculate 2D Box & Info Positions
        local headPos = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
        local footPos = GetEntityCoords(targetPed)
        footPos = vector3(footPos.x, footPos.y, footPos.z - 1.0) -- Adjust for bottom
        
        local _, headX, headY = GetScreenCoordFromWorldCoord(headPos.x, headPos.y, headPos.z + 0.3)
        local _, footX, footY = GetScreenCoordFromWorldCoord(footPos.x, footPos.y, footPos.z)
        
        local height = math.abs(headY - footY)
        local width = height * 0.35 -- Thinner box (was 0.5)
        
        local boxX1 = headX - width * 0.5
        local boxX2 = headX + width * 0.5
        local boxY1 = headY
        local boxY2 = footY
        
        -- Fix Y order if inverted
        if boxY1 > boxY2 then boxY1, boxY2 = boxY2, boxY1 end

        -- Box
        if drawBox then
            -- Draw thin black outline
            Draw2DBox(boxX1 - 0.0005, boxY1 - 0.0005, boxX2 + 0.0005, boxY2 + 0.0005, 0.0, 0.0, 0.0, 1.0, screenW, screenH)
            -- Draw main box
            Draw2DBox(boxX1, boxY1, boxX2, boxY2, boxColor[1], boxColor[2], boxColor[3], 1.0, screenW, screenH)
        end
        
        -- Snapline
        if drawLine and Susano.DrawLine then
             Susano.DrawLine(screenW / 2, screenH, footX * screenW, footY * screenH, lineColor[1], lineColor[2], lineColor[3], 1.0, 1)
        end
        
        -- Info Text Buckets
        -- 2=Top, 3=Bottom, 4=Left, 5=Right
        local textBuckets = { [2] = "", [3] = "", [4] = "", [5] = "" }
        
        local function AddToBucket(sel, text)
            if sel > 1 and textBuckets[sel] then
                textBuckets[sel] = textBuckets[sel] .. text .. "\n"
            end
        end
        
        if drawName then AddToBucket(drawNamePos + 1, GetPlayerName(playerIdx)) end
        if drawID then AddToBucket(drawIDPos + 1, "ID: " .. GetPlayerServerId(playerIdx)) end
        if drawDist then AddToBucket(drawDistPos + 1, math.floor(dist) .. "m") end
        if drawWeapon then
             local _, weaponHash = GetCurrentPedWeapon(targetPed, true)
             if weaponHash ~= -1569615261 then -- Unarmed
                 AddToBucket(drawWeaponPos + 1, "Armed")
             end
        end
        
        if Susano.DrawText then
            local function DrawTextWithOutline(x, y, text, size, r, g, b, a)
                -- Draw black outline (8 directions)
                Susano.DrawText(x - 1, y - 1, text, size, 0.0, 0.0, 0.0, 1.0) -- Top-left
                Susano.DrawText(x, y - 1, text, size, 0.0, 0.0, 0.0, 1.0) -- Top
                Susano.DrawText(x + 1, y - 1, text, size, 0.0, 0.0, 0.0, 1.0) -- Top-right
                Susano.DrawText(x - 1, y, text, size, 0.0, 0.0, 0.0, 1.0) -- Left
                Susano.DrawText(x + 1, y, text, size, 0.0, 0.0, 0.0, 1.0) -- Right
                Susano.DrawText(x - 1, y + 1, text, size, 0.0, 0.0, 0.0, 1.0) -- Bottom-left
                Susano.DrawText(x, y + 1, text, size, 0.0, 0.0, 0.0, 1.0) -- Bottom
                Susano.DrawText(x + 1, y + 1, text, size, 0.0, 0.0, 0.0, 1.0) -- Bottom-right
                -- Draw main text
                Susano.DrawText(x, y, text, size, r, g, b, a)
            end
            
            -- Top (Centered above box)
            if textBuckets[2] ~= "" then
                local textX = (boxX1 + boxX2)/2 * screenW
                local textY = boxY1 * screenH - 15
                DrawTextWithOutline(textX, textY, textBuckets[2], 14, 1.0, 1.0, 1.0, 1.0)
            end
            
            -- Bottom (Centered below box)
            if textBuckets[3] ~= "" then
                local textX = (boxX1 + boxX2)/2 * screenW
                local textY = boxY2 * screenH + 5
                DrawTextWithOutline(textX, textY, textBuckets[3], 14, 1.0, 1.0, 1.0, 1.0)
            end
            
            -- Left (Right of boxX1? No, Left of boxX1)
            if textBuckets[4] ~= "" then
                local textX = boxX1 * screenW - 50
                local textY = boxY1 * screenH
                DrawTextWithOutline(textX, textY, textBuckets[4], 14, 1.0, 1.0, 1.0, 1.0)
            end
            
            -- Right (Right of boxX2)
            if textBuckets[5] ~= "" then
                local textX = boxX2 * screenW + 5
                local textY = boxY1 * screenH
                DrawTextWithOutline(textX, textY, textBuckets[5], 14, 1.0, 1.0, 1.0, 1.0)
            end
        end
        
        -- Health & Armor Bars
        local barW = 2 -- Thinner bar
        
        if drawHealth then
            local health = GetEntityHealth(targetPed)
            local maxHealth = GetEntityMaxHealth(targetPed)
            local healthPct = (health - 100) / (maxHealth - 100)
            if healthPct < 0 then healthPct = 0 end
            if healthPct > 1 then healthPct = 1 end
            
            local barH = (boxY2 - boxY1) * screenH
            local barX = (boxX1 * screenW) - (barW + 2)
            local barY = boxY1 * screenH
            
            -- Outline (Black, larger)
            DrawFilledRect(barX - 1, barY - 1, barW + 2, barH + 2, 0.0, 0.0, 0.0, 1.0)
            
            -- Fill (Green)
            local fillH = barH * healthPct
            DrawFilledRect(barX, barY + (barH - fillH), barW, fillH, 0.0, 1.0, 0.0, 1.0)
        end
        
        if drawArmor then
            local armor = GetPedArmour(targetPed)
            local armorPct = armor / 100.0
            if armorPct > 1 then armorPct = 1 end
            
            if armorPct > 0 then
                local barH = (boxY2 - boxY1) * screenH
                -- Position: Left of health bar (if health is on) or Left of box
                local offset = (barW + 2)
                if drawHealth then offset = offset + (barW + 2) end
                
                local barX = (boxX1 * screenW) - offset
                local barY = boxY1 * screenH
                
                -- Outline
                DrawFilledRect(barX - 1, barY - 1, barW + 2, barH + 2, 0.0, 0.0, 0.0, 1.0)
                
                -- Fill (Blue)
                local fillH = barH * armorPct
                DrawFilledRect(barX, barY + (barH - fillH), barW, fillH, 0.0, 0.0, 1.0, 1.0)
            end
        end
    end
end

-- Function to get world settings
local function GetWorldSettings()
    local settings = {}
    for _, cat in ipairs(Menu.Categories) do
        if cat.name == "Visual" and cat.tabs then
            for _, tab in ipairs(cat.tabs) do
                if tab.name == "World" and tab.items then
                    for _, item in ipairs(tab.items) do
                        settings[item.name] = item
                    end
                end
            end
        end
    end
    return settings
end

local worldSettings = nil

local function RenderWorldVisuals(settings)
    if not settings then return end

    -- FPS Boost
    local fpsBoostItem = settings["FPS Boost"]
    if fpsBoostItem and fpsBoostItem.value then
        -- Textures & LOD
        if OverrideLodscaleThisFrame then OverrideLodscaleThisFrame(0.35) end
        if SetDisableDecalRenderingThisFrame then SetDisableDecalRenderingThisFrame() end
        
        -- Shadows & Lights
        if RopeDrawShadowEnabled then RopeDrawShadowEnabled(false) end
        if CascadeShadowsClearShadow then CascadeShadowsClearShadow() end
        
        -- Performance Tweaks
        if SetReducePedModelBudget then SetReducePedModelBudget(true) end
        if SetReduceVehicleModelBudget then SetReduceVehicleModelBudget(true) end
        if DisableVehicleDistantlights then DisableVehicleDistantlights(true) end
        if SetDeepOceanScaler then SetDeepOceanScaler(0.0) end
        if SetGrassCullDistanceScale then SetGrassCullDistanceScale(0.0) end -- Remove bushes/grass
    else
        -- Restore Defaults
        if RopeDrawShadowEnabled then RopeDrawShadowEnabled(true) end
        if SetReducePedModelBudget then SetReducePedModelBudget(false) end
        if SetReduceVehicleModelBudget then SetReduceVehicleModelBudget(false) end
        if DisableVehicleDistantlights then DisableVehicleDistantlights(false) end
        if SetDeepOceanScaler then SetDeepOceanScaler(1.0) end
        if SetGrassCullDistanceScale then SetGrassCullDistanceScale(1.0) end
    end

    -- Time
    local timeItem = settings["Time"]
    local freezeItem = settings["Freeze Time"]
    
    if freezeItem and freezeItem.value then
        if timeItem then
            NetworkOverrideClockTime(math.floor(timeItem.value), 0, 0)
        end
    end
    
    -- Weather
    local weatherItem = settings["Weather"]
    if weatherItem and weatherItem.options then
        local selectedWeather = weatherItem.options[weatherItem.selected]
        if selectedWeather then
             SetWeatherTypeNowPersist(selectedWeather)
        end
    end
    
    -- Blackout
    local blackoutItem = settings["Blackout"]
    if blackoutItem then
        SetBlackout(blackoutItem.value)
    end
    
    -- Vision
    local nightVisionItem = settings["Night Vision"]
    if nightVisionItem then
        SetNightvision(nightVisionItem.value)
    end
    
    local thermalVisionItem = settings["Thermal Vision"]
    if thermalVisionItem then
        SetSeethrough(thermalVisionItem.value)
    end
end

-- Helper to find item (Moved up for access in OnRender)
local function FindItem(categoryName, tabName, itemName)
    for _, cat in ipairs(Menu.Categories) do
        if cat.name == categoryName and cat.tabs then
            for _, tab in ipairs(cat.tabs) do
                if tab.name == tabName and tab.items then
                    for _, item in ipairs(tab.items) do
                        if item.name == itemName then return item end
                    end
                end
            end
        end
    end
    return nil
end

local lastNoclipSpeed = 1.0

-- Spectate Player Function (must be defined before UpdatePlayerList)
local spectateActive = false

local function ToggleSpectate(enable)
    if enable then
        if not Menu.SelectedPlayer then
            Menu.PlayerListSpectateEnabled = false
            return
        end
        
        spectateActive = true
        local targetServerId = Menu.SelectedPlayer
        
        if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
            Susano.InjectResource("any", string.format([[
                local targetServerId = %d
                
                if not _G.spectate_active then
                    _G.spectate_active = false
                end
                if not _G.spectate_cam then
                    _G.spectate_cam = nil
                end
                if not _G.spectate_distance then
                    _G.spectate_distance = 5.0
                end
                if not _G.spectate_angle_x then
                    _G.spectate_angle_x = 0.0
                end
                if not _G.spectate_angle_z then
                    _G.spectate_angle_z = 0.0
                end
                
                _G.spectate_active = true
                _G.spectate_target = targetServerId
                
                CreateThread(function()
                    local myPed = PlayerPedId()
                    
                    _G.spectate_cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                    
                    local susano = rawget(_G, "Susano")
                    if susano and type(susano.GetCameraAngles) == "function" then
                        _G.spectate_angle_x, _, _G.spectate_angle_z = susano.GetCameraAngles()
                    else
                        local camRot = GetGameplayCamRot(2)
                        _G.spectate_angle_x = camRot.x
                        _G.spectate_angle_z = camRot.z
                    end
                    
                    while _G.spectate_active do
                        Wait(0)
                        
                        local targetPlayerId = nil
                        for _, player in ipairs(GetActivePlayers()) do
                            if GetPlayerServerId(player) == _G.spectate_target then
                                targetPlayerId = player
                                break
                            end
                        end
                        
                        if not targetPlayerId or targetPlayerId == -1 then
                            _G.spectate_active = false
                            break
                        end
                        
                        local targetPed = GetPlayerPed(targetPlayerId)
                        if not DoesEntityExist(targetPed) then
                            _G.spectate_active = false
                            break
                        end
                        
                        local targetCoords = GetEntityCoords(targetPed)
                        
                        local rightAxisX = GetDisabledControlNormal(0, 220)
                        local rightAxisY = GetDisabledControlNormal(0, 221)
                        
                        _G.spectate_angle_z = _G.spectate_angle_z - rightAxisX * 5.0
                        _G.spectate_angle_x = _G.spectate_angle_x - rightAxisY * 5.0
                        
                        if _G.spectate_angle_x > 89.0 then _G.spectate_angle_x = 89.0 end
                        if _G.spectate_angle_x < -89.0 then _G.spectate_angle_x = -89.0 end
                        
                        if IsControlPressed(0, 241) then
                            _G.spectate_distance = _G.spectate_distance - 0.5
                            if _G.spectate_distance < 1.0 then _G.spectate_distance = 1.0 end
                        end
                        if IsControlPressed(0, 242) then
                            _G.spectate_distance = _G.spectate_distance + 0.5
                            if _G.spectate_distance > 20.0 then _G.spectate_distance = 20.0 end
                        end
                        
                        local radZ = math.rad(_G.spectate_angle_z)
                        local radX = math.rad(_G.spectate_angle_x)
                        
                        local offsetX = -math.sin(radZ) * math.cos(radX) * _G.spectate_distance
                        local offsetY = math.cos(radZ) * math.cos(radX) * _G.spectate_distance
                        local offsetZ = math.sin(radX) * _G.spectate_distance
                        
                        local camX = targetCoords.x + offsetX
                        local camY = targetCoords.y + offsetY
                        local camZ = targetCoords.z + offsetZ + 1.0
                        
                        local susano = rawget(_G, "Susano")
                        if susano and type(susano.SetCameraPos) == "function" then
                            susano.SetCameraPos(camX, camY, camZ)
                        else
                            SetCamCoord(_G.spectate_cam, camX, camY, camZ)
                        end
                        
                        PointCamAtCoord(_G.spectate_cam, targetCoords.x, targetCoords.y, targetCoords.z + 1.0)
                        SetCamActive(_G.spectate_cam, true)
                        RenderScriptCams(true, false, 0, true, false)
                        
                        DisableAllControlActions(0)
                        EnableControlAction(0, 1, true)
                        EnableControlAction(0, 2, true)
                        EnableControlAction(0, 220, true)
                        EnableControlAction(0, 221, true)
                        EnableControlAction(0, 241, true)
                        EnableControlAction(0, 242, true)
                    end
                    
                    if _G.spectate_cam then
                        SetCamActive(_G.spectate_cam, false)
                        RenderScriptCams(false, false, 0, true, false)
                        DestroyCam(_G.spectate_cam, true)
                        _G.spectate_cam = nil
                    end
                    
                    _G.spectate_active = false
                end)
            ]], targetServerId))
        end
    else
        spectateActive = false
        Menu.PlayerListSpectateEnabled = false
        
        if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
            Susano.InjectResource("any", [[
                if not _G.spectate_active then
                    _G.spectate_active = false
                end
                _G.spectate_active = false
                
                if _G.spectate_cam then
                    SetCamActive(_G.spectate_cam, false)
                    RenderScriptCams(false, false, 0, true, false)
                    DestroyCam(_G.spectate_cam, true)
                    _G.spectate_cam = nil
                end
            ]])
        end
    end
end

-- Update Player List
local function UpdatePlayerList()
    -- Find the Player List tab
    for _, cat in ipairs(Menu.Categories) do
        if cat.name == "Online" and cat.tabs then
            for tabIdx, tab in ipairs(cat.tabs) do
                if tab.name == "Player List" then
                    -- Save current selector and toggle states BEFORE clearing
                    for _, item in ipairs(tab.items) do
                        if item.type == "selector" then
                            if item.name == "Select" then
                                Menu.PlayerListSelectIndex = item.selected or 1
                            elseif item.name == "Teleport" then
                                Menu.PlayerListTeleportIndex = item.selected or 1
                            end
                        elseif item.type == "toggle" and item.name == "Spectate Player" then
                            Menu.PlayerListSpectateEnabled = item.value or false
                        end
                    end
                    
                    -- Clear existing items
                    tab.items = {}
                    
                    -- Add top options
                    local spectateItem = {
                        name = "Spectate Player",
                        type = "toggle",
                        value = Menu.PlayerListSpectateEnabled
                    }
                    spectateItem.onClick = function(value)
                        Menu.PlayerListSpectateEnabled = value
                        ToggleSpectate(value)
                    end
                    table.insert(tab.items, spectateItem)
                    
                    local teleportItem = {
                        name = "Teleport",
                        type = "selector",
                        options = {"To Player", "Into Vehicle"},
                        selected = Menu.PlayerListTeleportIndex
                    }
                    teleportItem.onClick = function(index, option)
                        if not Menu.SelectedPlayer then return end
                        
                        if index == 1 then -- To Player
                            for _, player in ipairs(GetActivePlayers()) do
                                if GetPlayerServerId(player) == Menu.SelectedPlayer then
                                    local targetPed = GetPlayerPed(player)
                                    if DoesEntityExist(targetPed) then
                                        local coords = GetEntityCoords(targetPed)
                                        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
                                    end
                                    break
                                end
                            end
                        elseif index == 2 then -- Into Vehicle
                            for _, player in ipairs(GetActivePlayers()) do
                                if GetPlayerServerId(player) == Menu.SelectedPlayer then
                                    local targetPed = GetPlayerPed(player)
                                    if DoesEntityExist(targetPed) then
                                        local vehicle = GetVehiclePedIsIn(targetPed, false)
                                        if vehicle and vehicle ~= 0 then
                                            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -2)
                                        end
                                    end
                                    break
                                end
                            end
                        end
                    end
                    table.insert(tab.items, teleportItem)
                    
                    -- Collect all players first
                    local localPed = PlayerPedId()
                    if not localPed or localPed == 0 then return end
                    
                    local localCoords = GetEntityCoords(localPed)
                    local myPlayerId = PlayerId()
                    local myServerId = GetPlayerServerId(myPlayerId)
                    local myName = GetPlayerName(myPlayerId)
                    
                    -- Get all other players
                    local otherPlayers = {}
                    for _, player in ipairs(GetActivePlayers()) do
                        if player ~= myPlayerId then
                            local targetPed = GetPlayerPed(player)
                            if targetPed and DoesEntityExist(targetPed) then
                                local targetCoords = GetEntityCoords(targetPed)
                                local distance = #(localCoords - targetCoords)
                                
                                local playerId = GetPlayerServerId(player)
                                local playerName = GetPlayerName(player)
                                table.insert(otherPlayers, {
                                    id = playerId,
                                    name = playerName,
                                    distance = math.floor(distance)
                                })
                            end
                        end
                    end
                    
                    -- Sort by distance
                    table.sort(otherPlayers, function(a, b) return a.distance < b.distance end)
                    
                    -- Add Select option BEFORE separator (avec onClick au lieu de onChange)
                    local selectModeItem = {
                        name = "Select",
                        type = "selector",
                        options = {"Select All", "Unselect All"},
                        selected = Menu.PlayerListSelectIndex
                    }
                    selectModeItem.onClick = function(index, option)
                        if index == 1 then -- Select All
                            Menu.SelectedPlayers = {}
                            -- Add self
                            table.insert(Menu.SelectedPlayers, myServerId)
                            Menu.SelectedPlayer = myServerId
                            -- Add all other players
                            for _, playerData in ipairs(otherPlayers) do
                                table.insert(Menu.SelectedPlayers, playerData.id)
                            end
                        elseif index == 2 then -- Unselect All
                            Menu.SelectedPlayer = nil
                            Menu.SelectedPlayers = {}
                        end
                    end
                    table.insert(tab.items, selectModeItem)
                    
                    -- Add separator
                    table.insert(tab.items, {
                        name = "",
                        isSeparator = true,
                        separatorText = "Player List"
                    })
                    
                    -- Helper function to check if player is selected
                    local function isPlayerSelected(playerId)
                        for _, selectedId in ipairs(Menu.SelectedPlayers) do
                            if selectedId == playerId then
                                return true
                            end
                        end
                        return false
                    end
                    
                    -- Helper function to toggle player selection
                    local function togglePlayerSelection(playerId)
                        local found = false
                        for i, selectedId in ipairs(Menu.SelectedPlayers) do
                            if selectedId == playerId then
                                table.remove(Menu.SelectedPlayers, i)
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(Menu.SelectedPlayers, playerId)
                            Menu.SelectedPlayer = playerId
                        else
                            if Menu.SelectedPlayer == playerId then
                                Menu.SelectedPlayer = Menu.SelectedPlayers[1] or nil
                            end
                        end
                    end
                    
                    -- Add self first in the player list
                    local selfToggle = {
                        name = myName .. " (You)",
                        type = "toggle",
                        value = isPlayerSelected(myServerId),
                        playerId = myServerId,
                        isSelf = true
                    }
                    selfToggle.onClick = function(value)
                        togglePlayerSelection(selfToggle.playerId)
                    end
                    table.insert(tab.items, selfToggle)
                    
                    -- Add other players with toggles
                    for _, playerData in ipairs(otherPlayers) do
                        local playerToggle = {
                            name = playerData.name .. " (" .. playerData.distance .. "m)",
                            type = "toggle",
                            value = isPlayerSelected(playerData.id),
                            playerId = playerData.id
                        }
                        playerToggle.onClick = function(value)
                            togglePlayerSelection(playerToggle.playerId)
                        end
                        table.insert(tab.items, playerToggle)
                    end
                    
                    return
                end
            end
        end
    end
end

-- Auto-update player list
Citizen.CreateThread(function()
    Wait(500)
    while true do
        UpdatePlayerList()
        Wait(0) -- Update every frame (instant)
    end
end)

Menu.OnRender = function()
    local noclipItem = FindItem("Player", "Movement", "Noclip")
    if noclipItem and noclipItem.value then
        local currentSpeed = noclipItem.sliderValue or 1.0
        if lastNoclipSpeed ~= currentSpeed then
            -- Mettre à jour la vitesse dynamiquement sans recréer le thread
            if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
                Susano.InjectResource("any", string.format([[
                    if _G then
                        _G.NoclipSpeed = %s
                    end
                ]], tostring(currentSpeed)))
            end
            lastNoclipSpeed = currentSpeed
        end
    end

    
    if not espSettings then espSettings = GetESPSettings() end
    if not worldSettings then worldSettings = GetWorldSettings() end

    
    RenderWorldVisuals(worldSettings)

    local drawSelf = espSettings["Draw Self"] and espSettings["Draw Self"].value
    local enablePlayerESP = espSettings["Enable Player ESP"] and espSettings["Enable Player ESP"].value
    
    
    if drawSelf or enablePlayerESP then
        Menu.PreventResetFrame = true
        
        local ped = PlayerPedId()
        local screenW, screenH = GetScreenSize()
        if not screenW or not screenH then return end
        
        local myPos = GetEntityCoords(ped)

        
        if drawSelf then
            RenderPedESP(ped, PlayerId(), espSettings, screenW, screenH, myPos)
        end

        
        if enablePlayerESP then
            for _, player in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(player)
                
                
                if targetPed ~= ped then
                    RenderPedESP(targetPed, player, espSettings, screenW, screenH, myPos)
                end
            end
        end
    else
        Menu.PreventResetFrame = false
    end
end



local function ToggleGodmode(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        -- Global state for this resource (persisted across injections if same resource)
        if _G.GodmodeEnabled == nil then _G.GodmodeEnabled = false end
        _G.GodmodeEnabled = %s
        
        if not _G.GodmodeHooksInstalled and susano and type(susano.HookNative) == "function" then
            _G.GodmodeHooksInstalled = true
            
            -- Hook ApplyDamageToPed (Block script damage)
            susano.HookNative(0x697157CED63F18D4, function(ped, damage, armorDamage)
                if _G.GodmodeEnabled and ped == PlayerPedId() then
                    return false -- Block
                end
                return true -- Allow
            end)
            
            -- Hook SetEntityHealth (Prevent setting health < 200)
            susano.HookNative(0x6B76DC1F3AE6E6A3, function(entity, health)
                if _G.GodmodeEnabled and entity == PlayerPedId() and health < 200 then
                    return false
                end
                return true
            end)
            
            -- Hook SetPedToRagdoll (Prevent knockdown)
            susano.HookNative(0xAE99FB955581844A, function(ped)
                if _G.GodmodeEnabled and ped == PlayerPedId() then
                    return false
                end
                return true
            end)
            
            -- Hook ExplodePedHead
            susano.HookNative(0x7C6BCA42, function(ped)
                if _G.GodmodeEnabled and ped == PlayerPedId() then
                    return false
                end
                return true
            end)
        end
        
        if not _G.GodmodeLoopStarted then
            _G.GodmodeLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.GodmodeEnabled then
                        local ped = PlayerPedId()
                        
                        -- Use SetEntityProofs instead of SetEntityInvincible for stealth
                        SetEntityProofs(ped, true, true, true, true, true, true, true, true)
                        SetEntityCanBeDamaged(ped, false)
                        SetPedCanRagdoll(ped, false)
                        SetPedCanRagdollFromPlayerImpact(ped, false)
                        ClearPedBloodDamage(ped)
                        ResetPedVisibleDamage(ped)
                        
                        -- Auto-heal if something bypasses hooks
                        if GetEntityHealth(ped) < 200 then
                            SetEntityHealth(ped, 200)
                        end
                    else
                        -- Restore (Optional, might conflict if other scripts set proofs)
                        -- Only restore if we disabled it THIS frame? No, just once when disabled?
                        -- We check a flag change? No, simple polling.
                        -- If disabled, we stop enforcing proofs.
                        -- We can't easily revert to "previous" state without tracking.
                        -- Just let the game/other scripts take over.
                    end
                end
            end)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function ToggleAntiHeadshot(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        if _G.AntiHeadshotEnabled == nil then _G.AntiHeadshotEnabled = false end
        _G.AntiHeadshotEnabled = %s
        
        if not _G.AntiHeadshotHooksInstalled and susano and type(susano.HookNative) == "function" then
            _G.AntiHeadshotHooksInstalled = true
            
            -- Hook SetPedSuffersCriticalHits (Prevent enabling critical hits)
            -- Hash: 0xE3B05614DCE1D099 (SetPedSuffersCriticalHits)
            susano.HookNative(0x2D343D2219CD027A, function(ped, toggle)
                if _G.AntiHeadshotEnabled and ped == PlayerPedId() and toggle == true then
                    return false -- Block enabling critical hits
                end
                return true
            end)
            
            -- Hook GetPedLastDamageBone (Spoof headshot bone)
            -- Hash: 0xD75960F6BD9EA49C (GetPedLastDamageBone)
            susano.HookNative(0xD75960F6BD9EA49C, function(ped, bonePtr)
                -- We can't easily modify the pointer value in Lua without FFI/Memory access
                -- But we can try to intercept the return value if Susano supports it (likely not for pointers)
                -- Alternatively, if this native returns the bone ID directly in some versions? No it returns bool and out int.
                -- So we can't easily spoof it here without memory access.
                -- Let's stick to SetPedSuffersCriticalHits.
                return true
            end)
        end
        
        if not _G.AntiHeadshotLoopStarted then
            _G.AntiHeadshotLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.AntiHeadshotEnabled then
                        local ped = PlayerPedId()
                        SetPedSuffersCriticalHits(ped, false)
                    end
                end
            end)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

-- Compteur de version pour forcer l'arrêt des anciens threads
local noclipVersion = 0

local function ToggleNoclip(enable, speed)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    speed = speed or 1.0
    
    -- Incrémenter la version à chaque appel pour forcer l'arrêt des anciens threads
    noclipVersion = noclipVersion + 1
    local currentVersion = noclipVersion
    
    -- Injecter le code qui met à jour les variables et crée un nouveau thread si nécessaire
    -- On capture la vitesse directement dans le thread pour éviter les problèmes de contexte isolé
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        -- Mettre à jour les variables avec les nouvelles valeurs
        _G.NoclipEnabled = %s
        _G.NoclipSpeed = %s
        _G.NoclipVersion = %s
        
        -- Si on désactive, nettoyer immédiatement et arrêter tous les threads
        if not _G.NoclipEnabled then
            _G.NoclipStopAll = true
            Wait(50)
            _G.NoclipStopAll = false
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                SetEntityCollision(ped, true, true)
                FreezeEntityPosition(ped, false)
                
                -- Nettoyer aussi le véhicule si on est dedans
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                    SetEntityCollision(vehicle, true, true)
                    FreezeEntityPosition(vehicle, false)
                end
            end
        else
            -- Installer les hooks une seule fois (ils persistent entre les injections)
        if not _G.NoclipHooksInstalled and susano and type(susano.HookNative) == "function" then
            _G.NoclipHooksInstalled = true
            
            -- Hook ApplyForceToEntity (Prevent external forces)
            susano.HookNative(0xC5F68BE37759D056, function(entity) 
                if _G.NoclipEnabled then
                    local ped = PlayerPedId()
                    if entity == ped then
                        return false
                    end
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if vehicle and vehicle ~= 0 and entity == vehicle then
                        return false
                    end
                end
                return true
            end)
        end
        
            -- Créer un nouveau thread avec la vitesse capturée au moment de la création
            -- L'ancien thread s'arrêtera quand il détecte que la version a changé
            CreateThread(function()
                local myVersion = %s  -- Capturer la version au moment de la création
                local mySpeed = %s    -- Capturer la vitesse au moment de la création
                
                while true do
                    Wait(0)
                    
                    -- Vérifier si on doit arrêter (version changée ou désactivé)
                    if _G.NoclipStopAll or ( _G.NoclipVersion and _G.NoclipVersion ~= myVersion) or not _G.NoclipEnabled then
                        -- Arrêter ce thread
                        local ped = PlayerPedId()
                        if DoesEntityExist(ped) then
                            SetEntityCollision(ped, true, true)
                            FreezeEntityPosition(ped, false)
                            
                            -- Nettoyer aussi le véhicule si on est dedans
                            local vehicle = GetVehiclePedIsIn(ped, false)
                            if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                                SetEntityCollision(vehicle, true, true)
                                FreezeEntityPosition(vehicle, false)
                            end
                        end
                        break
                    end
                    
                    local ped = PlayerPedId()
                    if not DoesEntityExist(ped) then
                        Wait(100)
                    else
                        -- Vérifier si on est dans un véhicule
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        local entity = vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and vehicle or ped
                        
                        -- Noclip actif - utiliser la vitesse capturée
                        SetEntityCollision(entity, false, false)
                        FreezeEntityPosition(entity, true)
                        
                        local coords = GetEntityCoords(entity)
                        local camRot = GetGameplayCamRot(2)
                        
                        local pitch = math.rad(camRot.x)
                        local yaw = math.rad(camRot.z)
                        
                        -- Forward Vector
                        local vx = -math.sin(yaw) * math.abs(math.cos(pitch))
                        local vy = math.cos(yaw) * math.abs(math.cos(pitch))
                        local vz = math.sin(pitch)
                        
                        -- Right Vector
                        local rx = math.cos(yaw)
                        local ry = math.sin(yaw)
                        
                        -- Lire la vitesse depuis _G (mise à jour dynamique) avec fallback sur la vitesse capturée
                        local currentSpeed = mySpeed
                        if _G and _G.NoclipSpeed then
                            currentSpeed = _G.NoclipSpeed
                        end
                        
                        -- Détecter Shift pour augmenter la vitesse
                        local moveSpeed = currentSpeed
                        if IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21) then -- Shift (Speed Boost)
                            moveSpeed = currentSpeed * 2.5
                        end
                        
                        local newPos = coords
                        
                        -- Inputs (utiliser moveSpeed pour tous les mouvements)
                        if IsControlPressed(0, 32) then -- W
                            newPos = vector3(newPos.x + vx * moveSpeed, newPos.y + vy * moveSpeed, newPos.z + vz * moveSpeed)
                        end
                        if IsControlPressed(0, 33) then -- S
                            newPos = vector3(newPos.x - vx * moveSpeed, newPos.y - vy * moveSpeed, newPos.z - vz * moveSpeed)
                        end
                        if IsControlPressed(0, 34) then -- A
                            newPos = vector3(newPos.x - rx * moveSpeed, newPos.y - ry * moveSpeed, newPos.z)
                        end
                        if IsControlPressed(0, 35) then -- D
                            newPos = vector3(newPos.x + rx * moveSpeed, newPos.y + ry * moveSpeed, newPos.z)
                        end
                        
                        if IsControlPressed(0, 22) then -- Space (Up)
                            newPos = vector3(newPos.x, newPos.y, newPos.z + moveSpeed)
                        end
                        if IsControlPressed(0, 36) then -- Ctrl (Down)
                            newPos = vector3(newPos.x, newPos.y, newPos.z - moveSpeed)
                        end
                        
                        SetEntityCoordsNoOffset(entity, newPos.x, newPos.y, newPos.z, true, true, true)
                        if entity == ped then
                            SetEntityHeading(ped, camRot.z)
                        end
                    end
                end
            end)
        end
    ]], tostring(enable), tostring(speed), tostring(currentVersion), tostring(currentVersion), tostring(speed))
    
    -- Injecter pour créer un nouveau thread avec la nouvelle vitesse
    Susano.InjectResource("any", code)
end

local function ActionRevive()
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        local ped = PlayerPedId()
        if not ped or not DoesEntityExist(ped) then return end
        
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        SetEntityHealth(ped, 200)
        return 
    end
    
    Susano.InjectResource("any", [[
        local function hNative(nativeName, newFunction)
            local originalNative = _G[nativeName]
            if not originalNative or type(originalNative) ~= "function" then return end
            _G[nativeName] = function(...) return newFunction(originalNative, ...) end
        end
        
        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
        hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
        hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
        hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
        hNative("NetworkResurrectLocalPlayer", function(originalFn, ...) return originalFn(...) end)
        hNative("SetEntityHealth", function(originalFn, ...) return originalFn(...) end)
        
        local ped = PlayerPedId()
        if not ped or not DoesEntityExist(ped) then return end
        
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        SetEntityHealth(ped, 200)
        ClearPedBloodDamage(ped)
        ClearPedTasksImmediately(ped)
        SetPlayerInvincible(PlayerId(), false)
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, true)
        SetPedCanRagdollFromPlayerImpact(ped, true)
        SetPedRagdollOnCollision(ped, true)
        
        if GetResourceState("scripts") == 'started' then
            TriggerEvent('deathscreen:revive')
        end
        
        if GetResourceState("framework") == 'started' then
            TriggerEvent('deathscreen:revive')
        end
        
        if GetResourceState("qb-jail") == 'started' then
            TriggerEvent('hospital:client:Revive')
        end
    ]])
end

local function ActionMaxHealth()
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            SetEntityHealth(ped, 200)
        end
        return 
    end
    
    Susano.InjectResource("any", [[
        local function hNative(nativeName, newFunction)
            local originalNative = _G[nativeName]
            if not originalNative or type(originalNative) ~= "function" then return end
            _G[nativeName] = function(...) return newFunction(originalNative, ...) end
        end
        
        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
        hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
        hNative("SetEntityHealth", function(originalFn, ...) return originalFn(...) end)
        
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            SetEntityHealth(ped, 200)
        end
    ]])
end

local function ActionMaxArmor()
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            SetPedArmour(ped, 100)
        end
        return 
    end
    
    Susano.InjectResource("any", [[
        local function hNative(nativeName, newFunction)
            local originalNative = _G[nativeName]
            if not originalNative or type(originalNative) ~= "function" then return end
            _G[nativeName] = function(...) return newFunction(originalNative, ...) end
        end
        
        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
        hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
        hNative("SetPedArmour", function(originalFn, ...) return originalFn(...) end)
        
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            SetPedArmour(ped, 100)
        end
    ]])
end

local function ActionDetachAllEntitys()
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            ClearPedTasks(ped)
            DetachEntity(ped, true, true)
        end
        return 
    end
    
    Susano.InjectResource("any", [[
        local function hNative(nativeName, newFunction)
            local originalNative = _G[nativeName]
            if not originalNative or type(originalNative) ~= "function" then return end
            _G[nativeName] = function(...) return newFunction(originalNative, ...) end
        end
        
        hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
        hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
        hNative("ClearPedTasks", function(originalFn, ...) return originalFn(...) end)
        hNative("DetachEntity", function(originalFn, ...) return originalFn(...) end)
        
        local ped = PlayerPedId()
        if ped and DoesEntityExist(ped) then
            ClearPedTasks(ped)
            DetachEntity(ped, true, true)
        end
    ]])
end

local function ToggleSoloSession(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        if enable then
            NetworkStartSoloTutorialSession()
        else
            NetworkEndTutorialSession()
        end
        return 
    end
    
    local code = string.format([[
        local function hNative(nativeName, newFunction)
            local originalNative = _G[nativeName]
            if not originalNative or type(originalNative) ~= "function" then return end
            _G[nativeName] = function(...) return newFunction(originalNative, ...) end
        end
        
        hNative("NetworkStartSoloTutorialSession", function(originalFn, ...) return originalFn(...) end)
        hNative("NetworkEndTutorialSession", function(originalFn, ...) return originalFn(...) end)
        
        if %s then
            NetworkStartSoloTutorialSession()
        else
            NetworkEndTutorialSession()
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function ToggleMiscTarget(enable)
    -- Cette fonction nécessite une interface UI complexe
    -- Pour l'instant, on laisse juste le toggle sans implémentation
    -- L'implémentation complète nécessiterait l'interface de ciblage
end

local function ToggleInvisible(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        if not _G.InvisibilityHooksInstalled and susano and type(susano.HookNative) == "function" then
            if susano.HasNativeHookInitializationFailed and susano.HasNativeHookInitializationFailed() then
                return
            end
            
            _G.InvisibilityHooksInstalled = true
            
            -- Hook IsEntityVisible (0x47D6F43D77935838)
            susano.HookNative(0x47D6F43D77935838, function(entity)
                return true
            end)
            
            -- Hook IsEntityVisibleToScript (0xD796CB5D48C1949E)
            susano.HookNative(0xD796CB5D48C1949E, function(entity)
                return true
            end)
            
            -- Hook SetEntityVisible (0xEA1C610A04DB6BBB)
            susano.HookNative(0xEA1C610A04DB6BBB, function(entity, toggle, unk)
                if _G.InvisibilityEnabled and entity == PlayerPedId() then
                    return false
                end
                return true
            end)
        end
        
        if _G.InvisibilityEnabled == nil then _G.InvisibilityEnabled = false end
        _G.InvisibilityEnabled = %s
        
        if not _G.InvisibilityLoopStarted then
            _G.InvisibilityLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(500)
                    if _G.InvisibilityEnabled then
                        local ped = PlayerPedId()
                        if ped and DoesEntityExist(ped) then
                            SetEntityVisible(ped, false, false)
                        end
                    else
                        local ped = PlayerPedId()
                        if ped and DoesEntityExist(ped) then
                            SetEntityVisible(ped, true, false)
                        end
                    end
                end
            end)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function ToggleFastRun(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        if _G.FastRunActive == nil then _G.FastRunActive = false end
        _G.FastRunActive = %s
        
        if not _G.FastRunLoopStarted then
            _G.FastRunLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.FastRunActive then
                        local ped = PlayerPedId()
                        if ped and ped ~= 0 then
                            SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
                            SetPedMoveRateOverride(ped, 1.49)
                        end
                    else
                        Wait(500)
                    end
                end
            end)
        end
        
        if not _G.FastRunActive then
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
            SetPedMoveRateOverride(PlayerPedId(), 1.0)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function ToggleSuperJump(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        if _G.SuperJumpEnabled == nil then _G.SuperJumpEnabled = false end
        _G.SuperJumpEnabled = %s
        
        if not _G.SuperJumpLoopStarted then
            _G.SuperJumpLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.SuperJumpEnabled then
                        SetSuperJumpThisFrame(PlayerId())
                    else
                        Wait(500)
                    end
                end
            end)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function ToggleNoRagdoll(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        if _G.NoRagdollEnabled == nil then _G.NoRagdollEnabled = false end
        _G.NoRagdollEnabled = %s
        
        if not _G.NoRagdollHooksInstalled and susano and type(susano.HookNative) == "function" then
            if susano.HasNativeHookInitializationFailed and susano.HasNativeHookInitializationFailed() then
                return
            end
            
            _G.NoRagdollHooksInstalled = true
            
            -- Hook SetPedToRagdoll (0xAE99FB955581844A)
            susano.HookNative(0xAE99FB955581844A, function(ped)
                if _G.NoRagdollEnabled and ped == PlayerPedId() then
                    return false
                end
                return true
            end)
            
            -- Hook SetPedToRagdollWithFall (0xD76632D99E4966C8)
            susano.HookNative(0xD76632D99E4966C8, function(ped)
                if _G.NoRagdollEnabled and ped == PlayerPedId() then
                    return false
                end
                return true
            end)
        end
        
        if not _G.NoRagdollLoopStarted then
            _G.NoRagdollLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.NoRagdollEnabled then
                        local ped = PlayerPedId()
                        if ped and ped ~= 0 then
                            SetPedCanRagdoll(ped, false)
                            SetPedRagdollOnCollision(ped, false)
                            SetPedCanRagdollFromPlayerImpact(ped, false)
                            if IsPedRagdoll(ped) then
                                ClearPedTasksImmediately(ped)
                            end
                        end
                    else
                        Wait(500)
                        local ped = PlayerPedId()
                        if ped and ped ~= 0 then
                            SetPedCanRagdoll(ped, true)
                            SetPedRagdollOnCollision(ped, true)
                            SetPedCanRagdollFromPlayerImpact(ped, true)
                        end
                    end
                end
            end)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function ActionRandomOutfit()
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        local ped = PlayerPedId()
        if not ped or not DoesEntityExist(ped) then return end
        
        -- Random components
        local torsoMax = GetNumberOfPedDrawableVariations(ped, 11)
        local shoesMax = GetNumberOfPedDrawableVariations(ped, 6)
        local pantsMax = GetNumberOfPedDrawableVariations(ped, 4)
        
        SetPedComponentVariation(ped, 11, math.random(0, torsoMax - 1), 0, 2) -- Torso
        SetPedComponentVariation(ped, 6, math.random(0, shoesMax - 1), 0, 2) -- Shoes
        SetPedComponentVariation(ped, 8, 15, 0, 2) -- Tshirt
        SetPedComponentVariation(ped, 3, 0, 0, 2) -- Arms
        SetPedComponentVariation(ped, 4, math.random(0, pantsMax - 1), 0, 2) -- Pants
        
        -- Clear accessories
        ClearPedProp(ped, 0) -- Hat
        ClearPedProp(ped, 1) -- Glasses
        return
    end
    
    Susano.InjectResource("any", [[
        local ped = PlayerPedId()
        if not ped or not DoesEntityExist(ped) then return end
        
        local function GetRandomVariation(component, exclude)
            local total = GetNumberOfPedDrawableVariations(ped, component)
            if total <= 1 then return 0 end
            local choice = exclude
            while choice == exclude do
                choice = math.random(0, total - 1)
            end
            return choice
        end
        
        local function GetRandomComponent(component)
            local total = GetNumberOfPedDrawableVariations(ped, component)
            return total > 1 and math.random(0, total - 1) or 0
        end
        
        -- Apply random outfit
        SetPedComponentVariation(ped, 11, GetRandomVariation(11, 15), 0, 2) -- Torso
        SetPedComponentVariation(ped, 6, GetRandomVariation(6, 15), 0, 2) -- Shoes
        SetPedComponentVariation(ped, 8, 15, 0, 2) -- Tshirt
        SetPedComponentVariation(ped, 3, 0, 0, 2) -- Arms
        SetPedComponentVariation(ped, 4, GetRandomComponent(4), 0, 2) -- Pants
        
        -- Random face
        local face = math.random(0, 45)
        local skin = math.random(0, 45)
        SetPedHeadBlendData(ped, face, skin, 0, face, skin, 0, 1.0, 1.0, 0.0, false)
        
        -- Random hair
        local hairMax = GetNumberOfPedDrawableVariations(ped, 2)
        local hair = hairMax > 1 and math.random(0, hairMax - 1) or 0
        SetPedComponentVariation(ped, 2, hair, 0, 2)
        SetPedHairColor(ped, 0, 0)
        
        -- Random eyebrows
        local brows = GetNumHeadOverlayValues(2)
        SetPedHeadOverlay(ped, 2, brows > 1 and math.random(0, brows - 1) or 0, 1.0)
        SetPedHeadOverlayColor(ped, 2, 1, 0, 0)
        
        -- Clear accessories
        ClearPedProp(ped, 0) -- Hat
        ClearPedProp(ped, 1) -- Glasses
    ]])
end

local function SetPedClothing(componentId, drawableId, textureId)
    local ped = PlayerPedId()
    if ped and DoesEntityExist(ped) then
        SetPedComponentVariation(ped, componentId, drawableId or 0, textureId or 0, 0)
    end
end

local function SetPedAccessory(propId, drawableId, textureId)
    local ped = PlayerPedId()
    if ped and DoesEntityExist(ped) then
        if drawableId == -1 or not drawableId then
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, drawableId, textureId or 0, true)
        end
    end
end

local function ToggleAntiFreeze(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        if _G.AntiFreezeEnabled == nil then _G.AntiFreezeEnabled = false end
        _G.AntiFreezeEnabled = %s
        
        if not _G.AntiFreezeHooksInstalled and susano and type(susano.HookNative) == "function" then
            if susano.HasNativeHookInitializationFailed and susano.HasNativeHookInitializationFailed() then
                return
            end
            
            _G.AntiFreezeHooksInstalled = true
            
            -- Hook FreezeEntityPosition (0x428CA6DBD1094446)
            susano.HookNative(0x428CA6DBD1094446, function(entity, toggle)
                if _G.AntiFreezeEnabled and entity == PlayerPedId() and toggle == true then
                    return false
                end
                return true
            end)
        end
        
        if not _G.AntiFreezeLoopStarted then
            _G.AntiFreezeLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.AntiFreezeEnabled then
                        local ped = PlayerPedId()
                        if ped and ped ~= 0 and IsEntityPositionFrozen(ped) then
                            FreezeEntityPosition(ped, false)
                            ClearPedTasks(ped)
                        end
                    else
                        Wait(500)
                    end
                end
            end)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function ToggleBypassDriveby(enable)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        if _G.BypassDrivebyEnabled == nil then _G.BypassDrivebyEnabled = false end
        _G.BypassDrivebyEnabled = %s
        
        if not _G.BypassDrivebyHooksInstalled and susano and type(susano.HookNative) == "function" then
            -- Vérifier que l'initialisation des hooks a réussi
            if susano.HasNativeHookInitializationFailed and susano.HasNativeHookInitializationFailed() then
                return
            end
            
            _G.BypassDrivebyHooksInstalled = true
            
            -- Hook SetPlayerCanDoDriveBy (0xDC0A64FE)
            -- Native: SET_PLAYER_CAN_DO_DRIVE_BY
            -- Params: Player player, BOOL toggle
            -- This native controls whether the player can perform driveby shooting
            susano.HookNative(0xDC0A64FE, function(player, toggle)
                if _G.BypassDrivebyEnabled and player == PlayerId() then
                    -- Si le bypass est activé et qu'on essaie de DÉSACTIVER le driveby
                    if toggle == false or toggle == 0 then
                        -- Bloquer cet appel (ne pas appeler la native originale)
                        return false
                    end
                    -- Si on essaie de l'activer, laisser passer
                    return true
                end
                -- Pour les autres joueurs ou si bypass désactivé, laisser passer normalement
                return true
            end)
        end
        
        if not _G.BypassDrivebyLoopStarted then
            _G.BypassDrivebyLoopStarted = true
            Citizen.CreateThread(function()
                while true do
                    Wait(0)
                    if _G.BypassDrivebyEnabled then
                        local player = PlayerId()
                        if player and player ~= -1 then
                            -- Force continuellement l'activation du driveby
                            SetPlayerCanDoDriveBy(player, true)
                        end
                    end
                end
            end)
        end
    ]], tostring(enable))
    
    Susano.InjectResource("any", code)
end

local function SpawnVehicle(modelName)
    if not modelName then return end

    
    local tpItem = FindItem("Vehicle", "Spawn", "Teleport Into")
    local shouldTeleport = tpItem and tpItem.value or false
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then 
         Susano.InjectResource("any", string.format([[ 
             local susano = rawget(_G, "Susano") 
             
             
             if susano and type(susano) == "table" and type(susano.HookNative) == "function" then 
                 
                 susano.HookNative(0x2B40A976, function(entity) return true end) 
                 
                 susano.HookNative(0x5324A0E3E4CE3570, function(entity) return true end) 
                 
                 susano.HookNative(0x8DE82BC774F3B862, function() return true end) 
                 
                 susano.HookNative(0x2B1813BA58063D36, function() return true end) 
                 
                 
                 susano.HookNative(0x35FB78DC42B7BD21, function(modelHash) return false, true end) 
                 
                 susano.HookNative(0x392C8D8E07B70EFC, function(modelHash) return false, true end) 
                  
                 susano.HookNative(0x98A4EB5D89A0C952, function(modelHash) return false, true end) 
                 
                 susano.HookNative(0x963D27A58DF860AC, function(modelHash) return false end) 
                  
                 susano.HookNative(0xEA386986E786A54F, function(vehicle) return false end) 
                 
                  
                 susano.HookNative(0xAE3CBE5BF394C9C9, function(entity) 
                     local entityType = GetEntityType(entity) 
                     if entityType == 2 then 
                         return false 
                     end 
                     return true 
                 end) 
                 
                 
                 susano.HookNative(0x7D9EFB7AD6B19754, function(vehicle, toggle) return false end) 
                  
                 susano.HookNative(0x1CF38D529D7441D9, function(vehicle, toggle) return false end) 
                 
                 susano.HookNative(0x99AD4CCCB128CBC9, function(vehicle) return false end) 
                  
                 susano.HookNative(0xE5810AC70602F2F5, function(vehicle, speed) return false end) 
             end 
             
             
             Citizen.CreateThread(function() 
                 Wait(1000) 
                 
                 local ped = PlayerPedId() 
                 local coords = GetEntityCoords(ped) 
                 local heading = GetEntityHeading(ped) 
                 local offsetX = coords.x + math.sin(math.rad(heading)) * 3.0 
                 local offsetY = coords.y + math.cos(math.rad(heading)) * 3.0 
                 local offsetZ = coords.z 
                 
                 local modelHash = GetHashKey("%s") 
                 if modelHash == 0 then 
                     return 
                 end 
                 
                 RequestModel(modelHash) 
                 local timeout = 0 
                 while not HasModelLoaded(modelHash) and timeout < 200 do 
                     Citizen.Wait(10) 
                     timeout = timeout + 1 
                 end 
                 
                 if HasModelLoaded(modelHash) then 
                     Citizen.Wait(200) 
                     
                     -- Trouver le sol 
                     local groundZ = offsetZ 
                     local found, ground = GetGroundZFor_3dCoord(offsetX, offsetY, offsetZ + 10.0, groundZ, false) 
                     if found then 
                         offsetZ = groundZ + 0.5 
                     end 
                     
                     local vehicle = CreateVehicle(modelHash, offsetX, offsetY, offsetZ, heading, true, false) 
                     if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then 
                         local netId = NetworkGetNetworkIdFromEntity(vehicle) 
                         if netId and netId ~= 0 then 
                             SetNetworkIdCanMigrate(netId, false) 
                             SetNetworkIdExistsOnAllMachines(netId, true) 
                         end 
                         SetEntityAsMissionEntity(vehicle, true, true) 
                         SetVehicleHasBeenOwnedByPlayer(vehicle, true) 
                         SetVehicleNeedsToBeHotwired(vehicle, false) 
                         SetVehicleEngineOn(vehicle, true, true, false) 
                         SetVehicleOnGroundProperly(vehicle) 
                         
                         if %s then
                             Citizen.Wait(300) 
                             TaskWarpPedIntoVehicle(ped, vehicle, -1) 
                         end
                         
                         SetModelAsNoLongerNeeded(modelHash) 
                     end 
                 end 
             end) 
         ]], modelName, tostring(shouldTeleport))) 
     end
end


-- Max Upgrade function
local function MaxUpgrade()
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", [[
            local susano = rawget(_G, "Susano")
            
            -- Hooker les natives pour bypasser les vérifications
            if susano and type(susano) == "table" and type(susano.HookNative) == "function" and not _max_upgrade_hooks_applied then
                _max_upgrade_hooks_applied = true
                
                -- Bypass NetworkHasControlOfEntity
                susano.HookNative(0x8DE82BC774F3B862, function(entity)
                    return true
                end)
                
                -- Bypass NetworkRequestControlOfEntity
                susano.HookNative(0x4CEBC1ED31E8925E, function(entity)
                    return true
                end)
                
                -- Bypass NetworkCanControlEntity
                susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                    return true
                end)
                
                -- Bypass IsEntityVisible
                susano.HookNative(0x2B40A976, function(entity)
                    return true
                end)
                
                -- Bypass SetEntityAsMissionEntity
                susano.HookNative(0xAD738C3085FE7E11, function(entity, p1, p2)
                    return true
                end)
            end
            
            CreateThread(function()
                Wait(100)
                
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                if not vehicle or vehicle == 0 then
                    return
                end
                
                -- Obtenir le contrôle du véhicule
                if not NetworkHasControlOfEntity(vehicle) then
                    NetworkRequestControlOfEntity(vehicle)
                    local timeout = 0
                    while not NetworkHasControlOfEntity(vehicle) and timeout < 200 do
                        Wait(10)
                        timeout = timeout + 1
                        NetworkRequestControlOfEntity(vehicle)
                    end
                end
                
                -- Marquer comme mission entity
                SetEntityAsMissionEntity(vehicle, true, true)
                
                -- Configurer le kit de mod
                SetVehicleModKit(vehicle, 0)
                
                -- Type de roues (sport)
                SetVehicleWheelType(vehicle, 7)
                
                -- Appliquer toutes les modifications (0-16)
                for modType = 0, 16 do
                    local numMods = GetNumVehicleMods(vehicle, modType)
                    if numMods and numMods > 0 then
                        SetVehicleMod(vehicle, modType, numMods - 1, false)
                    end
                end
                
                -- Modifications spéciales
                SetVehicleMod(vehicle, 14, 16, false) -- Horn
                
                -- Livery
                local numLivery = GetNumVehicleMods(vehicle, 15)
                if numLivery and numLivery > 1 then
                    SetVehicleMod(vehicle, 15, numLivery - 2, false)
                end
                
                -- Activer les améliorations (17-22: Turbo, Xenon, etc.)
                for modType = 17, 22 do
                    ToggleVehicleMod(vehicle, modType, true)
                end
                
                -- Pneus personnalisés
                SetVehicleMod(vehicle, 23, 1, false)
                SetVehicleMod(vehicle, 24, 1, false)
                
                -- Désactiver les extras
                for extra = 1, 12 do
                    if DoesExtraExist(vehicle, extra) then
                        SetVehicleExtra(vehicle, extra, false)
                    end
                end
                
                -- Teinte des vitres (limousine)
                SetVehicleWindowTint(vehicle, 1)
                
                -- Pneus increvables
                SetVehicleTyresCanBurst(vehicle, false)
                
                Wait(100)
                
                -- Nettoyer
                SetEntityAsMissionEntity(vehicle, false, true)
            end)
        ]])
    end
end


-- Repair Vehicle function
local function RepairVehicle()
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", [[
            local susano = rawget(_G, "Susano")
            
            -- Hooker les natives pour bypasser les vérifications
            if susano and type(susano) == "table" and type(susano.HookNative) == "function" and not _repair_vehicle_hooks_applied then
                _repair_vehicle_hooks_applied = true
                
                -- Bypass NetworkHasControlOfEntity
                susano.HookNative(0x8DE82BC774F3B862, function(entity)
                    return true
                end)
                
                -- Bypass NetworkRequestControlOfEntity
                susano.HookNative(0x4CEBC1ED31E8925E, function(entity)
                    return true
                end)
                
                -- Bypass NetworkCanControlEntity
                susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                    return true
                end)
                
                -- Bypass IsEntityVisible
                susano.HookNative(0x2B40A976, function(entity)
                    return true
                end)
                
                -- Bypass SetEntityAsMissionEntity
                susano.HookNative(0xAD738C3085FE7E11, function(entity, p1, p2)
                    return true
                end)
                
                -- Bypass SetVehicleFixed
                susano.HookNative(0x115722B1B9C14C1C, function(vehicle)
                    return true
                end)
            end
            
            CreateThread(function()
                Wait(100)
                
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                if not vehicle or vehicle == 0 then
                    return
                end
                
                -- Obtenir le contrôle du véhicule
                if not NetworkHasControlOfEntity(vehicle) then
                    NetworkRequestControlOfEntity(vehicle)
                    local timeout = 0
                    while not NetworkHasControlOfEntity(vehicle) and timeout < 200 do
                        Wait(10)
                        timeout = timeout + 1
                        NetworkRequestControlOfEntity(vehicle)
                    end
                end
                
                -- Marquer comme mission entity
                SetEntityAsMissionEntity(vehicle, true, true)
                
                -- Réparer le véhicule
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleUndriveable(vehicle, false)
                SetVehicleEngineOn(vehicle, true, true, false)
                
                -- Réparer les pneus
                SetVehicleTyresCanBurst(vehicle, true)
                for i = 0, 3 do
                    SetVehicleTyreFixed(vehicle, i)
                end
                
                -- Réparer les portes
                SetVehicleDoorsLocked(vehicle, 1)
                SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                
                -- Réparer les dommages
                SetVehicleEngineHealth(vehicle, 1000.0)
                SetVehicleBodyHealth(vehicle, 1000.0)
                SetVehiclePetrolTankHealth(vehicle, 1000.0)
                
                -- Nettoyer le véhicule
                SetVehicleDirtLevel(vehicle, 0.0)
                WashDecalsFromVehicle(vehicle, 1.0)
                
                Wait(100)
                
                -- Nettoyer
                SetEntityAsMissionEntity(vehicle, false, true)
            end)
        ]])
    end
end


-- Ramp Vehicle function
local function RampVehicle()
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", [[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end
                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("IsPedInAnyVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPedInVehicleSeat", function(originalFn, ...) return originalFn(...) end)
            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityHeading", function(originalFn, ...) return originalFn(...) end)
            hNative("FindFirstVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("FindNextVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("EndFindVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("GetVehicleClass", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedIntoVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityAsMissionEntity", function(originalFn, ...) return originalFn(...) end)
            hNative("NetworkGetEntityIsNetworked", function(originalFn, ...) return originalFn(...) end)
            hNative("NetworkRequestControlOfEntity", function(originalFn, ...) return originalFn(...) end)
            hNative("NetworkHasControlOfEntity", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityForwardVector", function(originalFn, ...) return originalFn(...) end)
            hNative("AttachEntityToEntity", function(originalFn, ...) return originalFn(...) end)
            
            local playerPed = PlayerPedId()
            if not IsPedInAnyVehicle(playerPed, false) then
                return
            end
            
            local myVehicle = GetVehiclePedIsIn(playerPed, false)
            if not DoesEntityExist(myVehicle) or GetPedInVehicleSeat(myVehicle, -1) ~= playerPed then
                return
            end
            
            CreateThread(function()
                local myCoords = GetEntityCoords(myVehicle)
                local myHeading = GetEntityHeading(myVehicle)
                local vehicles = {}
                local searchRadius = 100.0
                local vehHandle, veh = FindFirstVehicle()
                local success
                
                repeat
                    local vehCoords = GetEntityCoords(veh)
                    local distance = #(myCoords - vehCoords)
                    local vehClass = GetVehicleClass(veh)
                    if distance <= searchRadius and veh ~= myVehicle and vehClass ~= 8 and vehClass ~= 13 then
                        table.insert(vehicles, {handle = veh, distance = distance})
                    end
                    success, veh = FindNextVehicle(vehHandle)
                until not success
                EndFindVehicle(vehHandle)
                
                if #vehicles < 3 then
                    return
                end
                
                table.sort(vehicles, function(a, b) return a.distance < b.distance end)
                local selectedVehicles = {vehicles[1].handle, vehicles[2].handle, vehicles[3].handle}
                
                local function takeControl(veh)
                    SetPedIntoVehicle(playerPed, veh, -1)
                    Wait(150)
                    SetEntityAsMissionEntity(veh, true, true)
                    if NetworkGetEntityIsNetworked(veh) then
                        NetworkRequestControlOfEntity(veh)
                        local timeout = 0
                        while not NetworkHasControlOfEntity(veh) and timeout < 50 do
                            NetworkRequestControlOfEntity(veh)
                            Wait(10)
                            timeout = timeout + 1
                        end
                    end
                end
                
                for i = 1, 3 do
                    if DoesEntityExist(selectedVehicles[i]) then
                        takeControl(selectedVehicles[i])
                    end
                end
                
                SetPedIntoVehicle(playerPed, myVehicle, -1)
                Wait(100)
                
                local heading = GetEntityHeading(myVehicle)
                local forwardVector = GetEntityForwardVector(myVehicle)
                local vehCoords = GetEntityCoords(myVehicle)
                local rampPositions = {
                    {offsetX = -2.0, offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
                    {offsetX = 0.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
                    {offsetX = 2.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
                }
                
                for i = 1, 3 do
                    if DoesEntityExist(selectedVehicles[i]) then
                        local pos = rampPositions[i]
                        AttachEntityToEntity(selectedVehicles[i], myVehicle, 0, pos.offsetX, pos.offsetY, pos.offsetZ, pos.rotX, pos.rotY, pos.rotZ, false, false, true, false, 2, true)
                    end
                end
            end)
        ]])
    else
        local playerPed = PlayerPedId()
        if not IsPedInAnyVehicle(playerPed, false) then
            return
        end
        
        local myVehicle = GetVehiclePedIsIn(playerPed, false)
        if not DoesEntityExist(myVehicle) or GetPedInVehicleSeat(myVehicle, -1) ~= playerPed then
            return
        end
        
        CreateThread(function()
            local myCoords = GetEntityCoords(myVehicle)
            local myHeading = GetEntityHeading(myVehicle)
            local vehicles = {}
            local searchRadius = 100.0
            local vehHandle, veh = FindFirstVehicle()
            local success
            
            repeat
                local vehCoords = GetEntityCoords(veh)
                local distance = #(myCoords - vehCoords)
                local vehClass = GetVehicleClass(veh)
                if distance <= searchRadius and veh ~= myVehicle and vehClass ~= 8 and vehClass ~= 13 then
                    table.insert(vehicles, {handle = veh, distance = distance})
                end
                success, veh = FindNextVehicle(vehHandle)
            until not success
            EndFindVehicle(vehHandle)
            
            if #vehicles < 3 then
                return
            end
            
            table.sort(vehicles, function(a, b) return a.distance < b.distance end)
            local selectedVehicles = {vehicles[1].handle, vehicles[2].handle, vehicles[3].handle}
            
            local function takeControl(veh)
                SetPedIntoVehicle(playerPed, veh, -1)
                Wait(150)
                SetEntityAsMissionEntity(veh, true, true)
                if NetworkGetEntityIsNetworked(veh) then
                    NetworkRequestControlOfEntity(veh)
                    local timeout = 0
                    while not NetworkHasControlOfEntity(veh) and timeout < 50 do
                        NetworkRequestControlOfEntity(veh)
                        Wait(10)
                        timeout = timeout + 1
                    end
                end
            end
            
            for i = 1, 3 do
                if DoesEntityExist(selectedVehicles[i]) then
                    takeControl(selectedVehicles[i])
                end
            end
            
            SetPedIntoVehicle(playerPed, myVehicle, -1)
            Wait(100)
            
            local heading = GetEntityHeading(myVehicle)
            local forwardVector = GetEntityForwardVector(myVehicle)
            local vehCoords = GetEntityCoords(myVehicle)
            local rampPositions = {
                {offsetX = -2.0, offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
                {offsetX = 0.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
                {offsetX = 2.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
            }
            
            for i = 1, 3 do
                if DoesEntityExist(selectedVehicles[i]) then
                    local pos = rampPositions[i]
                    AttachEntityToEntity(selectedVehicles[i], myVehicle, 0, pos.offsetX, pos.offsetY, pos.offsetZ, pos.rotX, pos.rotY, pos.rotZ, false, false, true, false, 2, true)
                end
            end
        end)
    end
end


-- Force Vehicle Engine function
local function ToggleForceVehicleEngine(enable)
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local susano = rawget(_G, "Susano")
            
            -- Hooker les natives pour bypasser les vérifications
            if susano and type(susano) == "table" and type(susano.HookNative) == "function" and not _force_engine_hooks_applied then
                _force_engine_hooks_applied = true
                
                -- Bypass NetworkHasControlOfEntity
                susano.HookNative(0x8DE82BC774F3B862, function(entity)
                    return true
                end)
                
                -- Bypass NetworkRequestControlOfEntity
                susano.HookNative(0x4CEBC1ED31E8925E, function(entity)
                    return true
                end)
                
                -- Bypass NetworkCanControlEntity
                susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                    return true
                end)
                
                -- Bypass IsEntityVisible
                susano.HookNative(0x2B40A976, function(entity)
                    return true
                end)
                
                -- Bypass SetEntityAsMissionEntity
                susano.HookNative(0xAD738C3085FE7E11, function(entity, p1, p2)
                    return true
                end)
            end
            
            -- Variable globale pour activer/désactiver
            _G.ForceVehicleEngineEnabled = %s
            
            -- Thread pour maintenir le moteur allumé
            if _G.ForceVehicleEngineThread then
                -- Arrêter l'ancienne thread si elle existe
            end
            
            _G.ForceVehicleEngineThread = CreateThread(function()
                while _G.ForceVehicleEngineEnabled do
                    Wait(0)
                    
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    
                    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                        -- Obtenir le contrôle du véhicule
                        if not NetworkHasControlOfEntity(vehicle) then
                            NetworkRequestControlOfEntity(vehicle)
                        end
                        
                        -- Forcer le moteur à rester allumé
                        SetVehicleEngineOn(vehicle, true, true, false)
                        
                        -- Maintenir la santé du moteur
                        SetVehicleEngineHealth(vehicle, 1000.0)
                        
                        -- Empêcher le moteur de s'éteindre
                        SetVehicleUndriveable(vehicle, false)
                    end
                end
                
                _G.ForceVehicleEngineThread = nil
            end)
        ]], tostring(enable)))
    end
end


-- Boost Vehicle function
local function ToggleBoostVehicle(enable, boostPower)
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        local power = boostPower or 50.0
        Susano.InjectResource("any", string.format([[
            local susano = rawget(_G, "Susano")
            
            -- Hooker les natives pour bypasser les vérifications
            if susano and type(susano) == "table" and type(susano.HookNative) == "function" and not _boost_vehicle_hooks_applied then
                _boost_vehicle_hooks_applied = true
                
                -- Bypass NetworkHasControlOfEntity
                susano.HookNative(0x8DE82BC774F3B862, function(entity)
                    return true
                end)
                
                -- Bypass NetworkRequestControlOfEntity
                susano.HookNative(0x4CEBC1ED31E8925E, function(entity)
                    return true
                end)
                
                -- Bypass NetworkCanControlEntity
                susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                    return true
                end)
                
                -- Bypass IsEntityVisible
                susano.HookNative(0x2B40A976, function(entity)
                    return true
                end)
                
                -- Bypass SetEntityAsMissionEntity
                susano.HookNative(0xAD738C3085FE7E11, function(entity, p1, p2)
                    return true
                end)
            end
            
            -- Variable globale pour activer/désactiver
            if not _G then _G = {} end
            _G.BoostVehicleEnabled = %s
            _G.BoostVehiclePower = %s
            
            -- Thread pour détecter Shift et booster
            if _G.BoostVehicleThread then
                -- Arrêter l'ancienne thread si elle existe
            end
            
            _G.BoostVehicleThread = CreateThread(function()
                while _G.BoostVehicleEnabled do
                    Wait(0)
                    
                    local ped = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    
                    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                        -- Obtenir le contrôle du véhicule
                        if not NetworkHasControlOfEntity(vehicle) then
                            NetworkRequestControlOfEntity(vehicle)
                        end
                        
                        -- Détecter si Shift est pressé (contrôle 21)
                        if IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21) then
                            -- Obtenir la direction du véhicule
                            local forwardVector = GetEntityForwardVector(vehicle)
                            
                            -- Lire la puissance depuis _G à chaque frame
                            local boostPower = %s
                            if _G and _G.BoostVehiclePower then
                                local newPower = tonumber(_G.BoostVehiclePower)
                                if newPower then
                                    boostPower = newPower
                                end
                            end
                            
                            -- Appliquer une force dans la direction du véhicule (proportionnelle à la puissance)
                            -- Plus la valeur est haute, plus le boost est fort
                            -- Réduire la force pour un boost plus doux
                            local forceMultiplier = boostPower / 20.0
                            ApplyForceToEntity(
                                vehicle,
                                1,
                                forwardVector.x * forceMultiplier,
                                forwardVector.y * forceMultiplier,
                                forwardVector.z * forceMultiplier * 0.1,
                                0.0,
                                0.0,
                                0.0,
                                0,
                                false,
                                true,
                                true,
                                false,
                                true
                            )
                            
                            -- Augmenter aussi la vitesse directement (proportionnel à la puissance)
                            -- Plus la valeur est haute, plus le boost est fort
                            -- Réduire la vitesse pour un boost plus doux
                            local speedBoost = boostPower / 30.0
                            local currentSpeed = GetEntitySpeed(vehicle)
                            SetVehicleForwardSpeed(vehicle, currentSpeed + speedBoost)
                        end
                    end
                end
                
                _G.BoostVehicleThread = nil
            end)
        ]], tostring(enable), tostring(power), tostring(power)))
    end
end


local spawnItems = {"Car", "Moto", "Plane", "Boat", "Addon"}
for _, itemName in ipairs(spawnItems) do
    local item = FindItem("Vehicle", "Spawn", itemName)
    if item then
        item.onClick = function(index, option)
            SpawnVehicle(option)
        end
    end
end


-- Max Upgrade handler
local maxUpgradeItem = FindItem("Vehicle", "Performance", "Max Upgrade")
if maxUpgradeItem then
    maxUpgradeItem.onClick = function()
        MaxUpgrade()
    end
end


-- Repair Vehicle handler
local repairVehicleItem = FindItem("Vehicle", "Performance", "Repair Vehicle")
if repairVehicleItem then
    repairVehicleItem.onClick = function()
        RepairVehicle()
    end
end


-- Force Vehicle Engine handler
local forceEngineItem = FindItem("Vehicle", "Performance", "Force Vehicle Engine")
if forceEngineItem then
    forceEngineItem.onClick = function(value)
        ToggleForceVehicleEngine(value)
    end
end


-- No Collision function
local function ToggleNoCollision(enable)
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end
                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end
            hNative("CreateThread", function(originalFn, ...) return originalFn(...) end)
            hNative("Wait", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("IsPedInAnyVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("GetVehiclePedIsIn", function(originalFn, ...) return originalFn(...) end)
            hNative("SetEntityNoCollisionEntity", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("FindFirstVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("FindNextVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("EndFindVehicle", function(originalFn, ...) return originalFn(...) end)
            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
            
            if not _G.no_vehicle_collision_active then
                _G.no_vehicle_collision_active = false
            end
            _G.no_vehicle_collision_active = %s
            
            if _G.no_vehicle_collision_active then
                CreateThread(function()
                    while _G.no_vehicle_collision_active do
                        Wait(0)
                        
                        local ped = PlayerPedId()
                        if IsPedInAnyVehicle(ped, false) then
                            local veh = GetVehiclePedIsIn(ped, false)
                            if veh and veh ~= 0 then
                                SetEntityNoCollisionEntity(veh, veh, false)
                                
                                local myCoords = GetEntityCoords(veh)
                                local vehHandle, otherVeh = FindFirstVehicle()
                                local success
                                
                                repeat
                                    if otherVeh ~= veh and DoesEntityExist(otherVeh) then
                                        local otherCoords = GetEntityCoords(otherVeh)
                                        local distance = #(myCoords - otherCoords)
                                        
                                        if distance < 50.0 then
                                            SetEntityNoCollisionEntity(veh, otherVeh, true)
                                            SetEntityNoCollisionEntity(otherVeh, veh, true)
                                        end
                                    end
                                    
                                    success, otherVeh = FindNextVehicle(vehHandle)
                                until not success
                                
                                EndFindVehicle(vehHandle)
                            end
                        end
                    end
                end)
            end
        ]], tostring(enable)))
    else
        if enable then
            rawset(_G, 'no_vehicle_collision_active', true)
            
            CreateThread(function()
                while rawget(_G, 'no_vehicle_collision_active') do
                    Wait(0)
                    
                    local ped = PlayerPedId()
                    if IsPedInAnyVehicle(ped, false) then
                        local veh = GetVehiclePedIsIn(ped, false)
                        if veh and veh ~= 0 then
                            SetEntityNoCollisionEntity(veh, veh, false)
                            
                            local myCoords = GetEntityCoords(veh)
                            local vehHandle, otherVeh = FindFirstVehicle()
                            local success
                            
                            repeat
                                if otherVeh ~= veh and DoesEntityExist(otherVeh) then
                                    local otherCoords = GetEntityCoords(otherVeh)
                                    local distance = #(myCoords - otherCoords)
                                    
                                    if distance < 50.0 then
                                        SetEntityNoCollisionEntity(veh, otherVeh, true)
                                        SetEntityNoCollisionEntity(otherVeh, veh, true)
                                    end
                                end
                                
                                success, otherVeh = FindNextVehicle(vehHandle)
                            until not success
                            
                            EndFindVehicle(vehHandle)
                        end
                    end
                end
            end)
        else
            rawset(_G, 'no_vehicle_collision_active', false)
        end
    end
end


-- Ramp Vehicle handler
local rampVehicleItem = FindItem("Vehicle", "Extra", "Ramp Vehicle")
if rampVehicleItem then
    rampVehicleItem.onClick = function()
        RampVehicle()
    end
end


-- No Collision handler
local noCollisionItem = FindItem("Vehicle", "Extra", "No Collision")
if noCollisionItem then
    noCollisionItem.onClick = function(value)
        ToggleNoCollision(value)
    end
end


-- Boost Vehicle handler
local boostVehicleItem = FindItem("Vehicle", "Performance", "Boost Vehicle")
if boostVehicleItem then
    boostVehicleItem.onClick = function(value)
        local boostPower = boostVehicleItem.sliderValue or 50.0
        ToggleBoostVehicle(value, boostPower)
    end
    
    boostVehicleItem.onSliderChange = function(value)
        -- Mettre à jour la puissance en temps réel
        if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
            Susano.InjectResource("any", string.format([[
                if not _G then _G = {} end
                _G.BoostVehiclePower = %s
            ]], tostring(value)))
        end
    end
end

-- Weapon spawn functions (same as oldmenu.lua)
local function SpawnWeapon(category, index)
    local weaponList = weaponLists[category]
    if not weaponList or not weaponList[index] then return end
    
    local weaponName = weaponList[index].name
    selectedWeaponIndex[category] = index
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local susano = rawget(_G, "Susano")
            
            -- Hooker les natives pour bypasser les vérifications
            if susano and type(susano) == "table" and type(susano.HookNative) == "function" and not _weapon_spawn_hooks_applied then
                _weapon_spawn_hooks_applied = true
                
                -- Bypass IsEntityVisible
                susano.HookNative(0x2B40A976, function(entity) return true end)
                -- Bypass IsEntityVisibleToScript
                susano.HookNative(0x5324A0E3E4CE3570, function(entity) return true end)
                -- Bypass NetworkHasControlOfEntity
                susano.HookNative(0x8DE82BC774F3B862, function() return true end)
                
                -- Bypass HasPedGotWeapon
                susano.HookNative(0x8DECB02F88F428BC, function(ped, weaponHash, p2)
                    return false, false
                end)
                
                -- Bypass GetWeapontypeGroup
                susano.HookNative(0xC82758D1, function(weaponHash)
                    return false, 0
                end)
                
                -- Bypass IsWeaponValid
                susano.HookNative(0x937C71162CF43879, function(weaponHash)
                    return false, true
                end)
                
                -- Bypass NetworkCanControlEntity
                susano.HookNative(0xAE3CBE5BF394C9C9, function(entity)
                    local entityType = GetEntityType(entity)
                    if entityType == 1 then
                        return false
                    end
                    return true
                end)
                
                -- Bypass CanUseWeaponOnVehicle
                susano.HookNative(0xE169B653, function(weaponHash)
                    return false, true
                end)
                
                -- Bypass GetWeaponDamageType
                susano.HookNative(0x3BE1257F, function(weaponHash)
                    return false, 0
                end)
            end
            
            CreateThread(function()
                Wait(300)
                local ped = PlayerPedId()
                local weaponHash = GetHashKey("%s")
                RequestWeaponAsset(weaponHash, 31, 0)
                local timeout = 0
                while not HasWeaponAssetLoaded(weaponHash) and timeout < 100 do
                    Wait(10)
                    timeout = timeout + 1
                end
                if HasWeaponAssetLoaded(weaponHash) then
                    Wait(100)
                    GiveWeaponToPed(ped, weaponHash, 250, false, true)
                end
            end)
        ]], weaponName))
    end
end

-- Setup weapon selectors
local weaponCategories = {
    {name = "Melee", category = "melee"},
    {name = "Pistol", category = "pistol"},
    {name = "SMG", category = "smg"},
    {name = "Shotgun", category = "shotgun"},
    {name = "Assault Rifle", category = "ar"},
    {name = "Sniper", category = "sniper"},
    {name = "Heavy", category = "heavy"}
}

for _, weaponCat in ipairs(weaponCategories) do
    local item = FindItem("Combat", "Spawn", weaponCat.name)
    if item then
        -- Update options from weaponLists
        local options = {}
        if weaponLists[weaponCat.category] then
            for _, weapon in ipairs(weaponLists[weaponCat.category]) do
                table.insert(options, weapon.display)
            end
            item.options = options
        end
        
        item.onClick = function(index, option)
            SpawnWeapon(weaponCat.category, index)
        end
    end
end


local godmodeItem = FindItem("Player", "Self", "Godmode")
if godmodeItem then
    godmodeItem.onClick = function(value)
        ToggleGodmode(value)
    end
end


local antiHeadshotItem = FindItem("Player", "Self", "Anti Headshot")
if antiHeadshotItem then
    antiHeadshotItem.onClick = function(value)
        ToggleAntiHeadshot(value)
    end
end


local noclipItem = FindItem("Player", "Movement", "Noclip")
if noclipItem then
    noclipItem.onClick = function(value)
        local speed = noclipItem.sliderValue or 1.0
        ToggleNoclip(value, speed)
        
        lastNoclipSpeed = speed
    end
end

-- Bypass Driveby hook
local bypassDrivebyItem = FindItem("Player", "Self", "Bypass Driveby")
if bypassDrivebyItem then
    bypassDrivebyItem.onClick = function(value)
        ToggleBypassDriveby(value)
    end
end

-- Revive action
local reviveItem = FindItem("Player", "Self", "Revive")
if reviveItem then
    reviveItem.onClick = function()
        ActionRevive()
    end
end

-- Max Health action
local maxHealthItem = FindItem("Player", "Self", "Max Health")
if maxHealthItem then
    maxHealthItem.onClick = function()
        ActionMaxHealth()
    end
end

-- Max Armor action
local maxArmorItem = FindItem("Player", "Self", "Max Armor")
if maxArmorItem then
    maxArmorItem.onClick = function()
        ActionMaxArmor()
    end
end

-- Detach All Entitys action
local detachItem = FindItem("Player", "Self", "Detach All Entitys")
if detachItem then
    detachItem.onClick = function()
        ActionDetachAllEntitys()
    end
end

-- Solo Session toggle
local soloSessionItem = FindItem("Player", "Self", "Solo Session")
if soloSessionItem then
    soloSessionItem.onClick = function(value)
        ToggleSoloSession(value)
    end
end

-- Misc Target toggle
local miscTargetItem = FindItem("Player", "Self", "Misc Target")
if miscTargetItem then
    miscTargetItem.onClick = function(value)
        ToggleMiscTarget(value)
    end
end

-- Invisible toggle
local invisibleItem = FindItem("Player", "Movement", "Invisible")
if invisibleItem then
    invisibleItem.onClick = function(value)
        ToggleInvisible(value)
    end
end

-- Fast Run toggle
local fastRunItem = FindItem("Player", "Movement", "Fast Run")
if fastRunItem then
    fastRunItem.onClick = function(value)
        ToggleFastRun(value)
    end
end

-- Super Jump toggle
local superJumpItem = FindItem("Player", "Movement", "Super Jump")
if superJumpItem then
    superJumpItem.onClick = function(value)
        ToggleSuperJump(value)
    end
end

-- No Ragdoll toggle
local noRagdollItem = FindItem("Player", "Movement", "No Ragdoll")
if noRagdollItem then
    noRagdollItem.onClick = function(value)
        ToggleNoRagdoll(value)
    end
end

-- Anti Freeze toggle
local antiFreezeItem = FindItem("Player", "Movement", "Anti Freeze")
if antiFreezeItem then
    antiFreezeItem.onClick = function(value)
        ToggleAntiFreeze(value)
    end
end

-- Random Outfit action
local randomOutfitItem = FindItem("Player", "Wardrobe", "Random Outfit")
if randomOutfitItem then
    randomOutfitItem.onClick = function()
        ActionRandomOutfit()
    end
end

-- Freecam toggle
local freecamVersion = 0

local function ToggleFreecam(enable, speed)
    if type(Susano) ~= "table" or type(Susano.InjectResource) ~= "function" then 
        return 
    end
    
    speed = speed or 0.5
    
    -- Incrémenter la version à chaque appel pour forcer l'arrêt des anciens threads
    freecamVersion = freecamVersion + 1
    local currentVersion = freecamVersion
    
    local code = string.format([[
        local susano = rawget(_G, "Susano")
        
        -- Mettre à jour les variables avec les nouvelles valeurs
        _G.FreecamEnabled = %s
        _G.FreecamSpeed = %s
        _G.FreecamVersion = %s
        
        -- Initialiser l'index de sélection des options
        if not _G.FreecamSelectedOption then
            _G.FreecamSelectedOption = 1
        end
        
        -- Options de freecam
        _G.FreecamOptions = {"Teleport", "Warp Vehicle", "Steal Vehicle", "Fuck Vehicle", "Warp + Boost", "Kick Vehicle V1", "Kick Vehicle V2", "Give Ramp"}
        
        -- Si on désactive, nettoyer immédiatement et arrêter tous les threads
        if not _G.FreecamEnabled then
            _G.FreecamStopAll = true
            Wait(50)
            _G.FreecamStopAll = false
            
            if _G.FreecamCamera and DoesCamExist(_G.FreecamCamera) then
                SetCamActive(_G.FreecamCamera, false)
                RenderScriptCams(false, true, 500, false, false)
                DestroyCam(_G.FreecamCamera)
                _G.FreecamCamera = nil
            end
            
            local ped = PlayerPedId()
            if ped and DoesEntityExist(ped) then
                ClearPedTasksImmediately(ped)
                SetFocusEntity(ped)
            end
        else
            -- Installer les hooks une seule fois (ils persistent entre les injections)
            if not _G.FreecamHooksInstalled and susano and type(susano.HookNative) == "function" then
                _G.FreecamHooksInstalled = true
                
                -- Hook GetGameplayCamCoord (0xA67C9C75) - Retourne les coordonnées de la freecam
                susano.HookNative(0xA67C9C75, function()
                    if _G.FreecamEnabled and _G.FreecamCamera and DoesCamExist(_G.FreecamCamera) then
                        local coords = GetCamCoord(_G.FreecamCamera)
                        return false, coords.x, coords.y, coords.z
                    end
                    return true
                end)
                
                -- Hook GetGameplayCamRot (0x594BFC40) - Retourne la rotation de la freecam
                susano.HookNative(0x594BFC40, function(rotationOrder)
                    if _G.FreecamEnabled and _G.FreecamCamera and DoesCamExist(_G.FreecamCamera) then
                        local rot = GetCamRot(_G.FreecamCamera, rotationOrder or 2)
                        return false, rot.x, rot.y, rot.z
                    end
                    return true
                end)
                
                -- Hook GetGameplayCamFov (0x65019750) - Retourne le FOV de la freecam
                susano.HookNative(0x65019750, function()
                    if _G.FreecamEnabled and _G.FreecamCamera and DoesCamExist(_G.FreecamCamera) then
                        local fov = GetCamFov(_G.FreecamCamera)
                        return false, fov
                    end
                    return true
                end)
                
                -- Hook toutes les natives utilisées dans le thread pour éviter les conflits
                -- Hook PlayerPedId (0xD80958FC74E988A6)
                susano.HookNative(0xD80958FC74E988A6, function()
                    return true
                end)
                
                -- Hook DoesEntityExist (0x7239B21A)
                susano.HookNative(0x7239B21A, function(entity)
                    return true
                end)
                
                -- Hook DoesCamExist (0x1537DFED)
                susano.HookNative(0x1537DFED, function(cam)
                    return true
                end)
                
                -- Hook GetCamCoord (0xDB88D5E1)
                susano.HookNative(0xDB88D5E1, function(cam)
                    return true
                end)
                
                -- Hook GetCamRot (0x7D9EFB7A)
                susano.HookNative(0x7D9EFB7A, function(cam, rotationOrder)
                    return true
                end)
                
                -- Hook SetCamCoord (0x4D41783F)
                susano.HookNative(0x4D41783F, function(cam, x, y, z)
                    return true
                end)
                
                -- Hook SetCamRot (0x8597368B)
                susano.HookNative(0x8597368B, function(cam, rotX, rotY, rotZ, rotationOrder)
                    return true
                end)
                
                -- Hook SetCamActive (0x026FB97B0ECB9EA8)
                susano.HookNative(0x026FB97B0ECB9EA8, function(cam, active)
                    return true
                end)
                
                -- Hook RenderScriptCams (0x07E3A977)
                susano.HookNative(0x07E3A977, function(render, ease, easeTime, p3, p4, p5)
                    return true
                end)
                
                -- Hook DestroyCam (0x4E096588B31FF993)
                susano.HookNative(0x4E096588B31FF993, function(cam, bScriptHostCam)
                    return true
                end)
                
                -- Hook CreateCamWithParams (0xED4C67AD)
                susano.HookNative(0xED4C67AD, function(camName, posX, posY, posZ, rotX, rotY, rotZ, fov, p8, p9)
                    return true
                end)
                
                -- Hook TaskStandStill (0x919BE26E)
                susano.HookNative(0x919BE26E, function(ped, time)
                    return true
                end)
                
                -- Hook SetFocusEntity (0x198F77705FA0931D)
                susano.HookNative(0x198F77705FA0931D, function(entity)
                    return true
                end)
                
                -- Hook SetFocusPosAndVel (0x1A492C4C)
                susano.HookNative(0x1A492C4C, function(x, y, z, offsetX, offsetY, offsetZ)
                    return true
                end)
                
                -- Hook ClearPedTasksImmediately (0xAAA34F8A7CB32098)
                susano.HookNative(0xAAA34F8A7CB32098, function(ped)
                    return true
                end)
                
                -- Hook GetDisabledControlNormal (0x11E019C8F43ACC8A)
                susano.HookNative(0x11E019C8F43ACC8A, function(inputGroup, control)
                    return true
                end)
                
                -- Hook IsDisabledControlPressed (0xE2587F8CBEB87E74)
                susano.HookNative(0xE2587F8CBEB87E74, function(inputGroup, control)
                    return true
                end)
                
                -- Hook DisableControlAction (0xFE99B5B6)
                susano.HookNative(0xFE99B5B6, function(inputGroup, control, disable)
                    return true
                end)
                
                -- Hook IsDisabledControlJustPressed (0x532C99DCFB083E17)
                susano.HookNative(0x532C99DCFB083E17, function(inputGroup, control)
                    return true
                end)
                
                -- Hook StartExpensiveSynchronousShapeTestLosProbe (0x377906D8)
                susano.HookNative(0x377906D8, function(originalFn, x1, y1, z1, x2, y2, z2, flags, entity, p8)
                    return originalFn(x1, y1, z1, x2, y2, z2, flags, entity, p8)
                end)
                
                -- Hook GetShapeTestResult (0x3D87450E)
                susano.HookNative(0x3D87450E, function(originalFn, rayHandle)
                    return originalFn(rayHandle)
                end)
                
                -- Hook SetEntityCoords (0x06843E90)
                susano.HookNative(0x06843E90, function(originalFn, entity, x, y, z, alive, deadX, deadY, deadZ)
                    return originalFn(entity, x, y, z, alive, deadX, deadY, deadZ)
                end)
                
                -- Hook DrawText (Susano API)
                -- Note: DrawText est une fonction Susano, pas une native GTA
                
                -- Hook GetScreenWidth et GetScreenHeight (Susano API)
                -- Note: Ce sont des fonctions Susano, pas des natives GTA
            end
            
            -- Créer un nouveau thread avec la vitesse capturée au moment de la création
            CreateThread(function()
                local myVersion = %s  -- Capturer la version au moment de la création
                local mySpeed = %s    -- Capturer la vitesse au moment de la création
                
                -- Initialiser la caméra
                if not _G.FreecamCamera or not DoesCamExist(_G.FreecamCamera) then
                    local ped = PlayerPedId()
                    local camCoords = GetGameplayCamCoord()
                    local camRot = GetGameplayCamRot(2)
                    
                    _G.FreecamCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 
                        camCoords.x, camCoords.y, camCoords.z, 
                        0.0, 0.0, camRot.z, 
                        70.0, false, 0)
                    
                    SetCamActive(_G.FreecamCamera, true)
                    RenderScriptCams(true, true, 500, false, false)
                    SetFocusEntity(ped)
                end
                
                while true do
                    Wait(0)
                    
                    -- Vérifier si on doit arrêter (version changée ou désactivé)
                    if _G.FreecamStopAll or (_G.FreecamVersion and _G.FreecamVersion ~= myVersion) or not _G.FreecamEnabled then
                        if _G.FreecamCamera and DoesCamExist(_G.FreecamCamera) then
                            SetCamActive(_G.FreecamCamera, false)
                            RenderScriptCams(false, true, 500, false, false)
                            DestroyCam(_G.FreecamCamera)
                            _G.FreecamCamera = nil
                        end
                        
                        local ped = PlayerPedId()
                        if ped and DoesEntityExist(ped) then
                            ClearPedTasksImmediately(ped)
                            SetFocusEntity(ped)
                        end
                        break
                    end
                    
                    if not _G.FreecamCamera or not DoesCamExist(_G.FreecamCamera) then
                        Wait(100)
                    else
                        -- Lire la vitesse depuis _G (mise à jour dynamique) avec fallback sur la vitesse capturée
                        local currentSpeed = mySpeed
                        if _G and _G.FreecamSpeed then
                            currentSpeed = _G.FreecamSpeed
                        end
                        
                        local ped = PlayerPedId()
                        if not ped or not DoesEntityExist(ped) then
                            Wait(100)
                        else
                            -- Garder le joueur immobile
                            TaskStandStill(ped, 10)
                            
                            -- Obtenir la position et rotation actuelles de la caméra
                            local camCoords = GetCamCoord(_G.FreecamCamera)
                            local camRot = GetCamRot(_G.FreecamCamera, 2)
                            
                            -- Calculer la direction de la caméra
                            local radiansZ = math.rad(camRot.z)
                            local radiansX = math.rad(camRot.x)
                            local cosX = math.cos(radiansX)
                            local direction = vector3(
                                -math.sin(radiansZ) * cosX,
                                math.cos(radiansZ) * cosX,
                                math.sin(radiansX)
                            )
                            
                            -- Rotation de la caméra avec la souris
                            local hMove = GetDisabledControlNormal(0, 1) * 12.0
                            local vMove = GetDisabledControlNormal(0, 2) * 12.0
                            
                            if hMove ~= 0.0 or vMove ~= 0.0 then
                                local newPitch = camRot.x - vMove
                                local newYaw = camRot.z - hMove
                                newPitch = math.max(-89.0, math.min(89.0, newPitch))
                                SetCamRot(_G.FreecamCamera, newPitch, 0.0, newYaw, 2)
                                
                                -- Mettre à jour la rotation pour le calcul de direction
                                camRot = vector3(newPitch, 0.0, newYaw)
                                radiansZ = math.rad(camRot.z)
                                radiansX = math.rad(camRot.x)
                                cosX = math.cos(radiansX)
                                direction = vector3(
                                    -math.sin(radiansZ) * cosX,
                                    math.cos(radiansZ) * cosX,
                                    math.sin(radiansX)
                                )
                            end
                            
                            -- Vitesse de déplacement (Shift pour aller plus vite)
                            local moveSpeed = currentSpeed
                            if IsDisabledControlPressed(0, 21) then -- Shift
                                moveSpeed = currentSpeed * 3.0
                            end
                            
                            -- Calculer le vecteur de mouvement
                            local moveVector = vector3(0.0, 0.0, 0.0)
                            
                            -- W/S - Avancer/Reculer
                            if IsDisabledControlPressed(0, 32) then -- W
                                moveVector = moveVector + direction
                            end
                            if IsDisabledControlPressed(0, 33) then -- S
                                moveVector = moveVector - direction
                            end
                            
                            -- A/D - Gauche/Droite
                            local rightVector = vector3(
                                math.cos(radiansZ),
                                math.sin(radiansZ),
                                0.0
                            )
                            if IsDisabledControlPressed(0, 34) then -- A
                                moveVector = moveVector - rightVector
                            end
                            if IsDisabledControlPressed(0, 35) then -- D
                                moveVector = moveVector + rightVector
                            end
                            
                            -- Space/Ctrl - Monter/Descendre
                            if IsDisabledControlPressed(0, 22) then -- Space
                                moveVector = moveVector + vector3(0.0, 0.0, 1.0)
                            end
                            if IsDisabledControlPressed(0, 36) then -- Ctrl
                                moveVector = moveVector + vector3(0.0, 0.0, -1.0)
                            end
                            
                            -- Appliquer le mouvement
                            if moveVector.x ~= 0.0 or moveVector.y ~= 0.0 or moveVector.z ~= 0.0 then
                                local normalizedMove = moveVector
                                local length = math.sqrt(moveVector.x * moveVector.x + moveVector.y * moveVector.y + moveVector.z * moveVector.z)
                                if length > 0.0 then
                                    normalizedMove = vector3(
                                        moveVector.x / length,
                                        moveVector.y / length,
                                        moveVector.z / length
                                    )
                                end
                                
                                local newPosition = vector3(
                                    camCoords.x + normalizedMove.x * moveSpeed,
                                    camCoords.y + normalizedMove.y * moveSpeed,
                                    camCoords.z + normalizedMove.z * moveSpeed
                                )
                                
                                SetCamCoord(_G.FreecamCamera, newPosition.x, newPosition.y, newPosition.z)
                                SetFocusPosAndVel(newPosition.x, newPosition.y, newPosition.z, 0.0, 0.0, 0.0)
                            else
                                SetFocusPosAndVel(camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0)
                            end
                            
                            -- Désactiver les contrôles de caméra par défaut
                            DisableControlAction(0, 14, true) -- Look Left/Right
                            DisableControlAction(0, 15, true) -- Look Up/Down
                            DisableControlAction(0, 16, true) -- Look Left/Right (Alt)
                            DisableControlAction(0, 17, true) -- Look Up/Down (Alt)
                            
                            -- Navigation entre les options (Flèches gauche/droite)
                            if IsDisabledControlJustPressed(0, 174) then -- Flèche gauche
                                _G.FreecamSelectedOption = _G.FreecamSelectedOption - 1
                                if _G.FreecamSelectedOption < 1 then
                                    _G.FreecamSelectedOption = #_G.FreecamOptions
                                end
                            elseif IsDisabledControlJustPressed(0, 175) then -- Flèche droite
                                _G.FreecamSelectedOption = _G.FreecamSelectedOption + 1
                                if _G.FreecamSelectedOption > #_G.FreecamOptions then
                                    _G.FreecamSelectedOption = 1
                                end
                            end
                            
                            -- Téléportation si "Teleport" est sélectionné et clic gauche
                            local selectedOptionIndex = _G.FreecamSelectedOption or 1
                            
                            -- Vérifier strictement que c'est "Teleport" (index 1) et que le clic gauche est pressé
                            if selectedOptionIndex == 1 then
                                if _G.FreecamOptions and _G.FreecamOptions[1] then
                                    local selectedOptionName = tostring(_G.FreecamOptions[1] or "")
                                    if selectedOptionName == "Teleport" then
                                        if IsDisabledControlJustPressed(0, 24) then -- Clic gauche
                                        -- Faire un raycast depuis la caméra dans la direction où elle regarde
                                        local raycastStart = camCoords
                                        local raycastEnd = vector3(
                                            camCoords.x + direction.x * 1000.0,
                                            camCoords.y + direction.y * 1000.0,
                                            camCoords.z + direction.z * 1000.0
                                        )
                                        
                                        local raycast = StartExpensiveSynchronousShapeTestLosProbe(
                                            raycastStart.x, raycastStart.y, raycastStart.z,
                                            raycastEnd.x, raycastEnd.y, raycastEnd.z,
                                            -1, -- Tous les types d'entités
                                            ped, -- Ignorer le joueur
                                            7 -- Flags
                                        )
                                        
                                        local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(raycast)
                                        
                                        if hit and endCoords and endCoords.x ~= 0.0 and endCoords.y ~= 0.0 and endCoords.z ~= 0.0 then
                                            -- Téléporter le joueur à l'endroit où le raycast touche
                                            SetEntityCoords(ped, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
                                        else
                                            -- Si pas de hit, téléporter à une distance fixe devant la caméra
                                            local teleportPos = vector3(
                                                camCoords.x + direction.x * 5.0,
                                                camCoords.y + direction.y * 5.0,
                                                camCoords.z + direction.z * 5.0
                                            )
                                            SetEntityCoords(ped, teleportPos.x, teleportPos.y, teleportPos.z, false, false, false, false)
                                        end
                                    end
                                end
                            end
                        end
                        end
                    end
                end
            end)
        end
    ]], tostring(enable), tostring(speed), tostring(currentVersion), tostring(currentVersion), tostring(speed))
    
    -- Injecter pour créer un nouveau thread avec la nouvelle vitesse
    Susano.InjectResource("any", code)
end

-- Freecam toggle hook
local freecamItem = FindItem("Player", "Movement", "Freecam")
if freecamItem then
    freecamItem.onClick = function(value)
        local speed = freecamItem.sliderValue or 0.5
        ToggleFreecam(value, speed)
    end
    
    freecamItem.onSliderChange = function(value)
        if freecamItem.value then
            -- Mettre à jour la vitesse dynamiquement
            if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
                Susano.InjectResource("any", string.format([[
                    if _G then
                        _G.FreecamSpeed = %s
                    end
                ]], tostring(value)))
            end
        end
    end
end

-- Thread de rendu des options freecam (séparé, comme Draw FOV)
CreateThread(function()
    local lastScrollTime = 0
    local lastScrollValue = 0.0
    while true do
        Wait(0)
        local freecamItem = FindItem("Player", "Movement", "Freecam")
        if freecamItem and freecamItem.value == true and not Menu.isOpen then
            local options = _G.FreecamOptions or {"Teleport", "Warp Vehicle", "Steal Vehicle", "Fuck Vehicle", "Warp + Boost", "Kick Vehicle V1", "Kick Vehicle V2", "Give Ramp"}
            local selectedIndex = _G.FreecamSelectedOption or 1
            
            -- Détection du scroll de la souris (molette)
            -- Contrôle 14 = Molette de la souris (scroll)
            local currentTime = GetGameTimer()
            local scrollValue = GetDisabledControlNormal(0, 14) -- Molette de la souris
            
            -- Détecter le changement de valeur avec un seuil
            local scrollDelta = scrollValue - lastScrollValue
            if (currentTime - lastScrollTime) > 100 then
                if scrollDelta > 0.1 then
                    -- Scroll vers le bas (augmentation de valeur)
                    _G.FreecamSelectedOption = selectedIndex + 1
                    if _G.FreecamSelectedOption > #options then
                        _G.FreecamSelectedOption = 1
                    end
                    lastScrollTime = currentTime
                    lastScrollValue = scrollValue
                elseif scrollDelta < -0.1 then
                    -- Scroll vers le haut (diminution de valeur)
                    _G.FreecamSelectedOption = selectedIndex - 1
                    if _G.FreecamSelectedOption < 1 then
                        _G.FreecamSelectedOption = #options
                    end
                    lastScrollTime = currentTime
                    lastScrollValue = scrollValue
                end
            end
            
            -- Mettre à jour la valeur précédente même si pas de changement détecté
            if math.abs(scrollValue) < 0.05 then
                lastScrollValue = scrollValue
            end
            
            if Susano and Susano.BeginFrame and Susano.DrawText and Susano.SubmitFrame then
                Susano.BeginFrame()
                
                local screenWidth = 1920.0
                local screenHeight = 1080.0
                if Susano.GetScreenWidth and Susano.GetScreenHeight then
                    local w, h = Susano.GetScreenWidth(), Susano.GetScreenHeight()
                    if w and h and w > 0 and h > 0 then
                        screenWidth = w
                        screenHeight = h
                    end
                end
                
                -- Mettre à jour l'index après le scroll
                selectedIndex = _G.FreecamSelectedOption or 1
                
                -- Nombre d'options à afficher à la fois
                local maxVisibleOptions = 4
                
                -- Initialiser l'index de départ de la fenêtre si nécessaire
                if not _G.FreecamWindowStart then
                    _G.FreecamWindowStart = 1
                end
                
                local startOptionIndex = _G.FreecamWindowStart
                
                -- Si la sélection est en dessous de la fenêtre visible, faire descendre la fenêtre
                if selectedIndex > startOptionIndex + maxVisibleOptions - 1 then
                    startOptionIndex = selectedIndex - maxVisibleOptions + 1
                    _G.FreecamWindowStart = startOptionIndex
                end
                
                -- Si la sélection est au-dessus de la fenêtre visible, faire monter la fenêtre
                if selectedIndex < startOptionIndex then
                    startOptionIndex = selectedIndex
                    _G.FreecamWindowStart = startOptionIndex
                end
                
                -- S'assurer qu'on ne dépasse pas les limites
                if startOptionIndex + maxVisibleOptions - 1 > #options then
                    startOptionIndex = math.max(1, #options - maxVisibleOptions + 1)
                    _G.FreecamWindowStart = startOptionIndex
                end
                if startOptionIndex < 1 then
                    startOptionIndex = 1
                    _G.FreecamWindowStart = 1
                end
                
                -- Créer la liste des options visibles
                local visibleOptions = {}
                local visibleIndices = {}
                for i = startOptionIndex, math.min(startOptionIndex + maxVisibleOptions - 1, #options) do
                    table.insert(visibleOptions, options[i])
                    table.insert(visibleIndices, i)
                end
                
                -- Couleurs du menu (par défaut purple)
                local selectedR, selectedG, selectedB = 148.0 / 255.0, 0.0 / 255.0, 211.0 / 255.0
                local normalR, normalG, normalB = 200.0 / 255.0, 200.0 / 255.0, 200.0 / 255.0
                
                -- Taille des textes
                local selectedSize = 24.0
                local normalSize = 18.0
                
                -- Espacement vertical entre les options
                local spacing = 35.0
                
                -- Calculer la position de départ (centré horizontalement, en bas verticalement)
                local totalHeight = (#visibleOptions - 1) * spacing + selectedSize
                local startY = screenHeight - 150.0
                
                -- Trouver la largeur maximale du texte pour aligner tous les textes
                local maxTextWidth = 0
                for i = 1, #visibleOptions do
                    local textWidth = string.len(visibleOptions[i]) * 10
                    if textWidth > maxTextWidth then
                        maxTextWidth = textWidth
                    end
                end
                
                -- Position X centrée basée sur la largeur maximale
                local centerX = screenWidth / 2
                
                -- Dessiner l'indicateur de position au-dessus des options
                local indicatorText = string.format("%d / %d", selectedIndex, #options)
                local indicatorSize = 14.0
                local indicatorY = startY - 25.0
                -- Centrer directement sur centerX (le texte sera centré automatiquement)
                local indicatorX = centerX
                
                -- Contour noir pour l'indicateur
                local indicatorOutlineOffset = 1.0
                local indicatorOutlineAlpha = 0.5
                Susano.DrawText(indicatorX - indicatorOutlineOffset, indicatorY - indicatorOutlineOffset, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                Susano.DrawText(indicatorX, indicatorY - indicatorOutlineOffset, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                Susano.DrawText(indicatorX + indicatorOutlineOffset, indicatorY - indicatorOutlineOffset, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                Susano.DrawText(indicatorX - indicatorOutlineOffset, indicatorY, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                Susano.DrawText(indicatorX + indicatorOutlineOffset, indicatorY, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                Susano.DrawText(indicatorX - indicatorOutlineOffset, indicatorY + indicatorOutlineOffset, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                Susano.DrawText(indicatorX, indicatorY + indicatorOutlineOffset, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                Susano.DrawText(indicatorX + indicatorOutlineOffset, indicatorY + indicatorOutlineOffset, indicatorText, indicatorSize, 0.0, 0.0, 0.0, indicatorOutlineAlpha)
                
                -- Texte principal de l'indicateur
                Susano.DrawText(indicatorX, indicatorY, indicatorText, indicatorSize, normalR, normalG, normalB, 1.0)
                
                -- Dessiner les options visibles verticalement
                for i = 1, #visibleOptions do
                    local actualIndex = visibleIndices[i]
                    local isSelected = (actualIndex == selectedIndex)
                    local textSize = isSelected and selectedSize or normalSize
                    local r, g, b = normalR, normalG, normalB
                    
                    if isSelected then
                        r, g, b = selectedR, selectedG, selectedB
                    end
                    
                    local yPos = startY + (i - 1) * spacing
                    
                    -- Calculer la position X du texte (tous les textes alignés à gauche du bloc centré)
                    local xPos = centerX - (maxTextWidth / 2)
                    
                    -- Dessiner le contour noir autour du texte (8 directions) - plus léger
                    local outlineOffset = 1.0
                    local outlineAlpha = 0.5
                    Susano.DrawText(xPos - outlineOffset, yPos - outlineOffset, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    Susano.DrawText(xPos, yPos - outlineOffset, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    Susano.DrawText(xPos + outlineOffset, yPos - outlineOffset, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    Susano.DrawText(xPos - outlineOffset, yPos, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    Susano.DrawText(xPos + outlineOffset, yPos, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    Susano.DrawText(xPos - outlineOffset, yPos + outlineOffset, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    Susano.DrawText(xPos, yPos + outlineOffset, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    Susano.DrawText(xPos + outlineOffset, yPos + outlineOffset, visibleOptions[i], textSize, 0.0, 0.0, 0.0, outlineAlpha)
                    
                    -- Dessiner le texte principal
                    Susano.DrawText(xPos, yPos, visibleOptions[i], textSize, r, g, b, 1.0)
                end
                
                Susano.SubmitFrame()
            end
        else
            if Susano and Susano.ResetFrame then
                Susano.ResetFrame()
            end
        end
    end
end)

-- Magic Bullet toggle
local magicBulletItem = FindItem("Combat", "General", "Magic Bullet")
if magicBulletItem then
    magicBulletItem.onClick = function(value)
        magicbulletEnabled = value
        if value then
            -- Inject magic bullet thread (same as oldmenu.lua)
            if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
                Susano.InjectResource("any", [[
                    if not _G.magicbullet_thread_started then
                        _G.magicbullet_thread_started = true
                        
                        -- Weapon base damage table
                        local weaponDamageTable = {
                            [GetHashKey("WEAPON_PISTOL")] = 25.0,
                            [GetHashKey("WEAPON_PISTOL_MK2")] = 30.0,
                            [GetHashKey("WEAPON_COMBATPISTOL")] = 27.0,
                            [GetHashKey("WEAPON_APPISTOL")] = 30.0,
                            [GetHashKey("WEAPON_STUNGUN")] = 1.0,
                            [GetHashKey("WEAPON_PISTOL50")] = 40.0,
                            [GetHashKey("WEAPON_SNSPISTOL")] = 20.0,
                            [GetHashKey("WEAPON_SNSPISTOL_MK2")] = 25.0,
                            [GetHashKey("WEAPON_HEAVYPISTOL")] = 40.0,
                            [GetHashKey("WEAPON_VINTAGEPISTOL")] = 30.0,
                            [GetHashKey("WEAPON_MARKSMANPISTOL")] = 50.0,
                            [GetHashKey("WEAPON_REVOLVER")] = 50.0,
                            [GetHashKey("WEAPON_REVOLVER_MK2")] = 55.0,
                            [GetHashKey("WEAPON_DOUBLEACTION")] = 45.0,
                            [GetHashKey("WEAPON_UP_ATOMIZER")] = 1.0,
                            [GetHashKey("WEAPON_CERAMICPISTOL")] = 32.0,
                            [GetHashKey("WEAPON_NAVYREVOLVER")] = 50.0,
                            [GetHashKey("WEAPON_GADGETPISTOL")] = 25.0,
                            [GetHashKey("WEAPON_STUNGUN_MP")] = 1.0,
                            [GetHashKey("WEAPON_PISTOLXM3")] = 28.0,
                            [GetHashKey("WEAPON_MICROSMG")] = 20.0,
                            [GetHashKey("WEAPON_SMG")] = 22.0,
                            [GetHashKey("WEAPON_SMG_MK2")] = 25.0,
                            [GetHashKey("WEAPON_ASSAULTSMG")] = 25.0,
                            [GetHashKey("WEAPON_COMBATPDW")] = 24.0,
                            [GetHashKey("WEAPON_MACHINEPISTOL")] = 23.0,
                            [GetHashKey("WEAPON_MINISMG")] = 18.0,
                            [GetHashKey("WEAPON_RAYCARBINE")] = 30.0,
                            [GetHashKey("WEAPON_PUMPSHOTGUN")] = 30.0,
                            [GetHashKey("WEAPON_PUMPSHOTGUN_MK2")] = 35.0,
                            [GetHashKey("WEAPON_SAWNOFFSHOTGUN")] = 40.0,
                            [GetHashKey("WEAPON_ASSAULTSHOTGUN")] = 35.0,
                            [GetHashKey("WEAPON_BULLPUPSHOTGUN")] = 32.0,
                            [GetHashKey("WEAPON_MUSKET")] = 50.0,
                            [GetHashKey("WEAPON_HEAVYSHOTGUN")] = 40.0,
                            [GetHashKey("WEAPON_DBSHOTGUN")] = 45.0,
                            [GetHashKey("WEAPON_AUTOSHOTGUN")] = 30.0,
                            [GetHashKey("WEAPON_COMBATSHOTGUN")] = 35.0,
                            [GetHashKey("WEAPON_ASSAULTRIFLE")] = 30.0,
                            [GetHashKey("WEAPON_ASSAULTRIFLE_MK2")] = 35.0,
                            [GetHashKey("WEAPON_CARBINERIFLE")] = 32.0,
                            [GetHashKey("WEAPON_CARBINERIFLE_MK2")] = 37.0,
                            [GetHashKey("WEAPON_ADVANCEDRIFLE")] = 34.0,
                            [GetHashKey("WEAPON_SPECIALCARBINE")] = 32.0,
                            [GetHashKey("WEAPON_SPECIALCARBINE_MK2")] = 37.0,
                            [GetHashKey("WEAPON_BULLPUPRIFLE")] = 32.0,
                            [GetHashKey("WEAPON_BULLPUPRIFLE_MK2")] = 37.0,
                            [GetHashKey("WEAPON_COMPACTRIFLE")] = 30.0,
                            [GetHashKey("WEAPON_MILITARYRIFLE")] = 40.0,
                            [GetHashKey("WEAPON_HEAVYRIFLE")] = 45.0,
                            [GetHashKey("WEAPON_SNIPERRIFLE")] = 101.0,
                            [GetHashKey("WEAPON_HEAVYSNIPER")] = 150.0,
                            [GetHashKey("WEAPON_HEAVYSNIPER_MK2")] = 160.0,
                            [GetHashKey("WEAPON_MARKSMANRIFLE")] = 75.0,
                            [GetHashKey("WEAPON_MARKSMANRIFLE_MK2")] = 80.0,
                            [GetHashKey("WEAPON_MG")] = 40.0,
                            [GetHashKey("WEAPON_COMBATMG")] = 45.0,
                            [GetHashKey("WEAPON_COMBATMG_MK2")] = 50.0,
                            [GetHashKey("WEAPON_GUSENBERG")] = 35.0,
                            [GetHashKey("WEAPON_RPG")] = 100.0,
                            [GetHashKey("WEAPON_GRENADELAUNCHER")] = 100.0,
                            [GetHashKey("WEAPON_MINIGUN")] = 30.0,
                            [GetHashKey("WEAPON_RAILGUN")] = 200.0
                        }
                        
                        local function GetWeaponBaseDamage(weaponHash)
                            return weaponDamageTable[weaponHash] or 40.0
                        end
                        
                        CreateThread(function()
                            while true do
                                Wait(0)
                                if _G.magicbulletEnabled then
                                    local playerPed = PlayerPedId()
                                    if IsPedShooting(playerPed) then
                                        if not rawget(_G, 'magic_bullet_cooldown') or GetGameTimer() > rawget(_G, 'magic_bullet_cooldown') then
                                            local function IsPedInFOV(pedCoords)
                                                if not _G.drawFovEnabled then
                                                    return true 
                                                end
                                                
                                                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(pedCoords.x, pedCoords.y, pedCoords.z)
                                                
                                                if not onScreen then
                                                    return false 
                                                end
                                                
                                                local centerX = 0.5
                                                local centerY = 0.5
                                                local screenWidth = 1920.0
                                                local screenHeight = 1080.0
                                                local radiusX = _G.fovRadius / screenWidth
                                                local radiusY = _G.fovRadius / screenHeight
                                                
                                                local dx = screenX - centerX
                                                local dy = screenY - centerY
                                                
                                                local distance = math.sqrt((dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY))
                                                return distance <= 1.0
                                            end
                                            
                                            local currentWeapon = GetSelectedPedWeapon(playerPed)
                                            
                                            if currentWeapon == GetHashKey("WEAPON_UNARMED") or currentWeapon == 0 then
                                                local weapons = {
                                                    "WEAPON_PISTOL", "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL",
                                                    "WEAPON_PISTOL50", "WEAPON_SNSPISTOL", "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL",
                                                    "WEAPON_MICROSMG", "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_ASSAULTSMG",
                                                    "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2", "WEAPON_CARBINERIFLE", "WEAPON_CARBINERIFLE_MK2",
                                                    "WEAPON_ADVANCEDRIFLE", "WEAPON_SPECIALCARBINE", "WEAPON_BULLPUPRIFLE", "WEAPON_COMPACTRIFLE",
                                                    "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_HEAVYSNIPER_MK2", "WEAPON_MARKSMANRIFLE",
                                                    "WEAPON_PUMPSHOTGUN", "WEAPON_PUMPSHOTGUN_MK2", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_ASSAULTSHOTGUN",
                                                    "WEAPON_MG", "WEAPON_COMBATMG", "WEAPON_COMBATMG_MK2", "WEAPON_GUSENBERG",
                                                    "WEAPON_RPG", "WEAPON_GRENADELAUNCHER", "WEAPON_MINIGUN", "WEAPON_RAILGUN"
                                                }
                                                for _, weaponName in ipairs(weapons) do
                                                    local weaponHash = GetHashKey(weaponName)
                                                    if HasPedGotWeapon(playerPed, weaponHash, false) then
                                                        currentWeapon = weaponHash
                                                        break
                                                    end
                                                end
                                            end
                                            
                                            if currentWeapon ~= GetHashKey("WEAPON_UNARMED") and currentWeapon ~= 0 then
                                                local playerCoords = GetEntityCoords(playerPed)
                                                local camCoords = GetGameplayCamCoord()
                                                local camRot = GetGameplayCamRot(0)
                                                local z = math.rad(camRot.z)
                                                local x = math.rad(camRot.x)
                                                local num = math.abs(math.cos(x))
                                                local dirX = -math.sin(z) * num
                                                local dirY = math.cos(z) * num
                                                local dirZ = math.sin(x)
                                                
                                                local peds = GetGamePool('CPed')
                                                local targetPed = nil
                                                local bestScore = 999999
                                                local pedCount = 0
                                                
                                                for _, ped in ipairs(peds) do
                                                    if pedCount >= 50 then break end 
                                                    if ped ~= playerPed and DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
                                                        pedCount = pedCount + 1
                                                        local pedCoords = GetEntityCoords(ped)
                                                        local distToPlayer = #(pedCoords - playerCoords)
                                                        
                                                        if distToPlayer < 200.0 then 
                                                            if IsPedInFOV(pedCoords) then
                                                                local vecX = pedCoords.x - camCoords.x
                                                                local vecY = pedCoords.y - camCoords.y
                                                                local vecZ = pedCoords.z - camCoords.z
                                                                local distToCam = math.sqrt(vecX * vecX + vecY * vecY + vecZ * vecZ)
                                                                
                                                                if distToCam > 0 then
                                                                    local normX = vecX / distToCam
                                                                    local normY = vecY / distToCam
                                                                    local normZ = vecZ / distToCam
                                                                    local dotProduct = dirX * normX + dirY * normY + dirZ * normZ
                                                                    local angle = math.acos(math.max(-1, math.min(1, dotProduct)))
                                                                    local angleDeg = math.deg(angle)
                                                                    
                                                                    if angleDeg < 15 then
                                                                        local score = angleDeg * 10 + distToPlayer * 0.1
                                                                        if score < bestScore then
                                                                            bestScore = score
                                                                            targetPed = ped
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                
                                                if targetPed and DoesEntityExist(targetPed) then
                                                    local boneIndex = 31086
                                                    local targetBone = GetPedBoneIndex(targetPed, boneIndex)
                                                    local targetCoords = GetWorldPositionOfEntityBone(targetPed, targetBone)
                                                    local offsetX = math.random(-10, 10) / 100.0
                                                    local offsetY = math.random(-10, 10) / 100.0
                                                    
                                                    -- Get weapon base damage
                                                    local weaponDamage = GetWeaponBaseDamage(currentWeapon)
                                                    
                                                    ShootSingleBulletBetweenCoords(
                                                        targetCoords.x + offsetX, targetCoords.y + offsetY, targetCoords.z + 0.1,
                                                        targetCoords.x, targetCoords.y, targetCoords.z,
                                                        weaponDamage, true, currentWeapon, playerPed, true, false, 1000.0
                                                    )
                                                end
                                                
                                                rawset(_G, 'magic_bullet_cooldown', GetGameTimer() + 100) 
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                    _G.magicbulletEnabled = true
                ]])
            end
        else
            if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
                Susano.InjectResource("any", [[
                    _G.magicbulletEnabled = false
                ]])
            end
        end
    end
end

-- Draw FOV toggle
local drawFovItem = FindItem("Combat", "General", "Draw FOV")
if drawFovItem then
    drawFovItem.onClick = function(value)
        drawFovEnabled = value
        if value then
            fovRadius = drawFovItem.sliderValue or 150.0
            if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
                Susano.InjectResource("any", string.format([[
                    _G.drawFovEnabled = true
                    _G.fovRadius = %s
                ]], tostring(fovRadius)))
            end
        else
            if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
                Susano.InjectResource("any", [[
                    _G.drawFovEnabled = false
                ]])
            end
        end
    end
    
    drawFovItem.onSliderChange = function(value)
        fovRadius = value
        if drawFovEnabled then
            if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
                Susano.InjectResource("any", string.format([[
                    _G.fovRadius = %s
                ]], tostring(fovRadius)))
            end
        end
    end
end

-- Draw FOV rendering thread (exact same as oldmenu.lua - separate thread, not in Menu.OnRender)
CreateThread(function()
    while true do
        Wait(0)
        local drawFovItem = FindItem("Combat", "General", "Draw FOV")
        if drawFovItem and drawFovItem.value == true and not Menu.isOpen then
            -- Read slider value directly each frame for real-time updates
            local currentFovRadius = drawFovItem.sliderValue or 150.0
            fovRadius = currentFovRadius
            
            -- Get FOV color from selector
            local fovColorItem = FindItem("Combat", "General", "FOV Color")
            local fovColor = ESPColors[2] -- Default to Red (index 2)
            if fovColorItem then
                fovColor = ESPColors[fovColorItem.selected] or ESPColors[2]
            end
            
            if Susano and Susano.BeginFrame then
                Susano.BeginFrame()
                
                local centerX = 1920 / 2
                local centerY = 1080 / 2
                
                local circumference = 2 * math.pi * currentFovRadius
                local numPoints = math.max(250, math.floor(circumference / 1.5))
                
                local rectSize = 1.5
                
                for i = 0, numPoints - 1 do
                    local angle = (i / numPoints) * 2 * math.pi
                    local x = centerX + math.cos(angle) * currentFovRadius
                    local y = centerY + math.sin(angle) * currentFovRadius
                    
                    Susano.DrawRectFilled(x - rectSize/2, y - rectSize/2, rectSize, rectSize,
                        fovColor[1], fovColor[2], fovColor[3], 1.0,
                        rectSize / 2)
                end
                
                Susano.SubmitFrame()
            end
        else
            -- Ensure frame is reset when FOV is disabled
            if Susano and Susano.ResetFrame then
                Susano.ResetFrame()
            end
        end
    end
end)

-- Shoot Eyes handler
local shootEyesItem = FindItem("Combat", "General", "Shoot Eyes")
if shootEyesItem then
    shootEyesItem.onClick = function(value)
        shooteyesEnabled = value
    end
end

-- Shoot Eyes rendering thread
CreateThread(function()
    while true do
        Wait(0)
        
        if shooteyesEnabled then
            local screenW, screenH = GetActiveScreenResolution()
            local centerX = screenW / 2
            local centerY = screenH / 2
            
            -- Draw small rectangle at center
            if Susano and Susano.DrawRectFilled then
                Susano.DrawRectFilled(centerX - 1, centerY - 1.5, 2, 3, 157, 0, 255, 255, 0.0)
            end
            
            -- Check if E key is pressed (control 38)
            if IsControlPressed(0, 38) then
                local playerPed = PlayerPedId()
                local currentWeapon = GetSelectedPedWeapon(playerPed)
                
                if currentWeapon == GetHashKey("WEAPON_UNARMED") or currentWeapon == 0 then
                    local weapons = {
                        "WEAPON_PISTOL", "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL",
                        "WEAPON_PISTOL50", "WEAPON_SNSPISTOL", "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL",
                        "WEAPON_MICROSMG", "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_ASSAULTSMG",
                        "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2", "WEAPON_CARBINERIFLE", "WEAPON_CARBINERIFLE_MK2",
                        "WEAPON_ADVANCEDRIFLE", "WEAPON_SPECIALCARBINE", "WEAPON_BULLPUPRIFLE", "WEAPON_COMPACTRIFLE",
                        "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_HEAVYSNIPER_MK2", "WEAPON_MARKSMANRIFLE",
                        "WEAPON_PUMPSHOTGUN", "WEAPON_PUMPSHOTGUN_MK2", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_ASSAULTSHOTGUN",
                        "WEAPON_MG", "WEAPON_COMBATMG", "WEAPON_COMBATMG_MK2", "WEAPON_GUSENBERG",
                        "WEAPON_RPG", "WEAPON_GRENADELAUNCHER", "WEAPON_MINIGUN", "WEAPON_RAILGUN"
                    }
                    
                    for _, weaponName in ipairs(weapons) do
                        local weaponHash = GetHashKey(weaponName)
                        if HasPedGotWeapon(playerPed, weaponHash, false) then
                            currentWeapon = weaponHash
                            break
                        end
                    end
                end
                
                if currentWeapon ~= GetHashKey("WEAPON_UNARMED") and currentWeapon ~= 0 then
                    if not rawget(_G, 'shoot_eyes_cooldown') or GetGameTimer() > rawget(_G, 'shoot_eyes_cooldown') then
                        local camCoords = GetGameplayCamCoord()
                        local camRot = GetGameplayCamRot(0)
                        
                        local z = math.rad(camRot.z)
                        local x = math.rad(camRot.x)
                        local num = math.abs(math.cos(x))
                        local dirX = -math.sin(z) * num
                        local dirY = math.cos(z) * num
                        local dirZ = math.sin(x)
                        
                        local distance = 1000.0
                        local endX = camCoords.x + dirX * distance
                        local endY = camCoords.y + dirY * distance
                        local endZ = camCoords.z + dirZ * distance
                        
                        local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endX, endY, endZ, -1, playerPed, 0)
                        local retval, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
                        
                        local weaponCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.5, 1.0, 0.5)
                        local targetCoords = vector3(endX, endY, endZ)
                        
                        if hit and hitCoords then
                            targetCoords = hitCoords
                        end
                        
                        -- Get weapon base damage
                        local weaponDamage = GetWeaponDamage(currentWeapon)
                        if not weaponDamage or weaponDamage <= 0 then
                            weaponDamage = 40.0 -- Fallback to 40 if damage can't be retrieved
                        end
                        
                        ShootSingleBulletBetweenCoords(
                            weaponCoords.x, weaponCoords.y, weaponCoords.z,
                            targetCoords.x, targetCoords.y, targetCoords.z,
                            weaponDamage, true, currentWeapon, playerPed, true, false, 1000.0
                        )
                        
                        rawset(_G, 'shoot_eyes_cooldown', GetGameTimer() + 350)
                    end
                end
            end
        end
    end
end)

-- Initialize global variables for Magic Bullet and Draw FOV
if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
    Susano.InjectResource("any", [[
        if not _G.magicbulletEnabled then _G.magicbulletEnabled = false end
        if not _G.drawFovEnabled then _G.drawFovEnabled = false end
        if not _G.fovRadius then _G.fovRadius = 150.0 end
        if not _G.FreecamEnabled then _G.FreecamEnabled = false end
        if not _G.FreecamOptions then _G.FreecamOptions = {"Teleport", "Warp Vehicle", "Steal Vehicle", "Fuck Vehicle", "Warp + Boost", "Kick Vehicle V1", "Kick Vehicle V2", "Give Ramp"} end
        if not _G.FreecamSelectedOption then _G.FreecamSelectedOption = 1 end
        if not _G.FreecamWindowStart then _G.FreecamWindowStart = 1 end
    ]])
end

-- ========================================
-- SPECTATE FUNCTION
-- ========================================

-- ========================================
-- TROLL FUNCTIONS
-- ========================================

local function ActionCopyAppearance()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then return end
                _G[nativeName] = function(...) return newFunction(originalNative, ...) end
            end
            
            hNative("GetActivePlayers", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPlayerServerId", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPlayerPed", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedComponentVariation", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPedDrawableVariation", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPedTextureVariation", function(originalFn, ...) return originalFn(...) end)
            hNative("SetPedPropIndex", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPedPropIndex", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPedPropTextureIndex", function(originalFn, ...) return originalFn(...) end)
            
            local targetServerId = %d
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            local myPed = PlayerPedId()
            
            if not DoesEntityExist(targetPed) or not DoesEntityExist(myPed) then return end
            
            SetPedComponentVariation(myPed, 1, GetPedDrawableVariation(targetPed, 1), GetPedTextureVariation(targetPed, 1), 0)
            SetPedComponentVariation(myPed, 3, GetPedDrawableVariation(targetPed, 3), GetPedTextureVariation(targetPed, 3), 0)
            SetPedComponentVariation(myPed, 4, GetPedDrawableVariation(targetPed, 4), GetPedTextureVariation(targetPed, 4), 0)
            SetPedComponentVariation(myPed, 6, GetPedDrawableVariation(targetPed, 6), GetPedTextureVariation(targetPed, 6), 0)
            SetPedComponentVariation(myPed, 8, GetPedDrawableVariation(targetPed, 8), GetPedTextureVariation(targetPed, 8), 0)
            SetPedComponentVariation(myPed, 11, GetPedDrawableVariation(targetPed, 11), GetPedTextureVariation(targetPed, 11), 0)
            
            SetPedPropIndex(myPed, 0, GetPedPropIndex(targetPed, 0), GetPedPropTextureIndex(targetPed, 0), true)
            SetPedPropIndex(myPed, 1, GetPedPropIndex(targetPed, 1), GetPedPropTextureIndex(targetPed, 1), true)
            SetPedPropIndex(myPed, 2, GetPedPropIndex(targetPed, 2), GetPedPropTextureIndex(targetPed, 2), true)
        ]], targetServerId))
    end
end

local function ActionShootPlayer()
    if not Menu.SelectedPlayer then
        return
    end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            function hNative(nativeName, newFunction)
                local originalNative = _G[nativeName]
                if not originalNative or type(originalNative) ~= "function" then
                    return
                end
                _G[nativeName] = function(...)
                    return newFunction(originalNative, ...)
                end
            end
            
            hNative("GetActivePlayers", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPlayerServerId", function(originalFn, ...) return originalFn(...) end)
            hNative("GetPlayerPed", function(originalFn, ...) return originalFn(...) end)
            hNative("DoesEntityExist", function(originalFn, ...) return originalFn(...) end)
            hNative("PlayerPedId", function(originalFn, ...) return originalFn(...) end)
            hNative("GetSelectedPedWeapon", function(originalFn, ...) return originalFn(...) end)
            hNative("GetHashKey", function(originalFn, ...) return originalFn(...) end)
            hNative("HasPedGotWeapon", function(originalFn, ...) return originalFn(...) end)
            hNative("GetEntityCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("GetOffsetFromEntityInWorldCoords", function(originalFn, ...) return originalFn(...) end)
            hNative("ShootSingleBulletBetweenCoords", function(originalFn, ...) return originalFn(...) end)
            
            local targetServerId = %d
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then
                return
            end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then
                return
            end
            
            local playerPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            
            if currentWeapon == GetHashKey("WEAPON_UNARMED") or currentWeapon == 0 then
                local weapons = {
                    "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_PISTOL50",
                    "WEAPON_MICROSMG", "WEAPON_SMG", "WEAPON_ASSAULTSMG",
                    "WEAPON_ASSAULTRIFLE", "WEAPON_CARBINERIFLE", "WEAPON_ADVANCEDRIFLE",
                    "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER", "WEAPON_MARKSMANRIFLE",
                    "WEAPON_PUMPSHOTGUN", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_ASSAULTSHOTGUN"
                }
                
                for _, weaponName in ipairs(weapons) do
                    local weaponHash = GetHashKey(weaponName)
                    if HasPedGotWeapon(playerPed, weaponHash, false) then
                        currentWeapon = weaponHash
                        break
                    end
                end
                
                if currentWeapon == GetHashKey("WEAPON_UNARMED") or currentWeapon == 0 then
                    currentWeapon = GetHashKey("WEAPON_PISTOL")
                end
            end
            
            local targetCoords = GetEntityCoords(targetPed)
            local bodyCoords = vector3(targetCoords.x, targetCoords.y, targetCoords.z)
            local offsetCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.5, 0.0, 0.0)
            
            ShootSingleBulletBetweenCoords(
                offsetCoords.x, offsetCoords.y, offsetCoords.z,
                bodyCoords.x, bodyCoords.y, bodyCoords.z,
                40, true, currentWeapon, playerPed, true, false, 1000.0
            )
        ]], targetServerId))
    end
end

-- Copy Appearance hook
local copyAppearanceItem = FindItem("Online", "Troll", "Copy Appearance")
if copyAppearanceItem then
    copyAppearanceItem.onClick = function()
        ActionCopyAppearance()
    end
end

-- Shoot Player hook
local shootPlayerItem = FindItem("Online", "Troll", "Shoot Player")
if shootPlayerItem then
    shootPlayerItem.onClick = function()
        ActionShootPlayer()
    end
end

-- Bug Player (selector)
Menu.BugPlayerMode = "Bug"

local function ActionBugPlayer()
    if not Menu.SelectedPlayer then return end
    
    local bugPlayerMode = Menu.BugPlayerMode or "Bug"
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            local bugPlayerMode = string.lower("%s")
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end
            
            if bugPlayerMode == "bug" then
                CreateThread(function()
                    local playerPed = PlayerPedId()
                    local myCoords = GetEntityCoords(playerPed)
                    local myHeading = GetEntityHeading(playerPed)
                    
                    local closestVeh = GetClosestVehicle(myCoords.x, myCoords.y, myCoords.z, 100.0, 0, 70)
                    if not closestVeh or closestVeh == 0 then return end
                    
                    SetPedIntoVehicle(playerPed, closestVeh, -1)
                    Wait(150)
                    
                    SetEntityAsMissionEntity(closestVeh, true, true)
                    if NetworkGetEntityIsNetworked(closestVeh) then
                        NetworkRequestControlOfEntity(closestVeh)
                    end
                    
                    SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                    Wait(100)
                    
                    for i = 1, 30 do
                        DetachEntity(closestVeh, true, true)
                        Wait(5)
                        AttachEntityToEntityPhysically(closestVeh, targetPed, 0, 0, 0, 1800.0, 1600.0, 1200.0, 300.0, 300.0, 300.0, true, true, true, false, 0)
                        Wait(5)
                    end
                end)
            elseif bugPlayerMode == "launch" then
                CreateThread(function()
                    local clientId = GetPlayerFromServerId(targetServerId)
                    if not clientId or clientId == -1 then
                        return
                    end
                    
                    local targetPed = GetPlayerPed(clientId)
                    if not targetPed or not DoesEntityExist(targetPed) then
                        return
                    end
                    
                    local myPed = PlayerPedId()
                    if not myPed then
                        return
                    end
                    
                    local myCoords = GetEntityCoords(myPed)
                    local targetCoords = GetEntityCoords(targetPed)
                    if not myCoords or not targetCoords then
                        return
                    end
                    
                    local distance = #(myCoords - targetCoords)
                    local teleported = false
                    local originalCoords = nil
                    
                    if distance > 10.0 then
                        originalCoords = myCoords
                        local angle = math.random() * 2 * math.pi
                        local radiusOffset = math.random(5, 9)
                        local xOffset = math.cos(angle) * radiusOffset
                        local yOffset = math.sin(angle) * radiusOffset
                        local newCoords = vector3(targetCoords.x + xOffset, targetCoords.y + yOffset, targetCoords.z)
                        SetEntityCoordsNoOffset(myPed, newCoords.x, newCoords.y, newCoords.z, false, false, false)
                        SetEntityVisible(myPed, false, 0)
                        teleported = true
                        Wait(100)
                    end
                    
                    ClearPedTasksImmediately(myPed)
                    for i = 1, 5 do
                        if not DoesEntityExist(targetPed) then
                            break
                        end
                        
                        local curTargetCoords = GetEntityCoords(targetPed)
                        if not curTargetCoords then
                            break
                        end
                        
                        SetEntityCoords(myPed, curTargetCoords.x, curTargetCoords.y, curTargetCoords.z + 0.5, false, false, false, false)
                        Wait(100)
                        AttachEntityToEntityPhysically(myPed, targetPed, 0, 0.0, 0.0, 0.0, 150.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, false, false, 1, 2)
                        Wait(100)
                        DetachEntity(myPed, true, true)
                        Wait(200)
                    end
                    
                    Wait(500)
                    ClearPedTasksImmediately(myPed)
                    
                    if originalCoords then
                        SetEntityCoords(myPed, originalCoords.x, originalCoords.y, originalCoords.z + 1.0, false, false, false, false)
                        Wait(100)
                        SetEntityCoords(myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
                    end
                    
                    if teleported then
                        SetEntityVisible(myPed, true, 0)
                    end
                end)
            end
        ]], targetServerId, bugPlayerMode))
    end
end

-- Cage Player
local function ActionCagePlayer()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end
            
            CreateThread(function()
                local playerPed = PlayerPedId()
                local myCoords = GetEntityCoords(playerPed)
                local myHeading = GetEntityHeading(playerPed)
                
                local vehicles = {}
                local searchRadius = 150.0
                local vehHandle, veh = FindFirstVehicle()
                local success
                
                repeat
                    local vehCoords = GetEntityCoords(veh)
                    local distance = #(myCoords - vehCoords)
                    local vehClass = GetVehicleClass(veh)
                    if distance <= searchRadius and veh ~= GetVehiclePedIsIn(playerPed, false) and vehClass ~= 8 and vehClass ~= 13 then
                        table.insert(vehicles, {handle = veh, distance = distance})
                    end
                    success, veh = FindNextVehicle(vehHandle)
                until not success
                
                EndFindVehicle(vehHandle)
                
                if #vehicles < 4 then return end
                
                table.sort(vehicles, function(a, b) return a.distance < b.distance end)
                local selectedVehicles = {vehicles[1].handle, vehicles[2].handle, vehicles[3].handle, vehicles[4].handle}
                
                local function takeControl(veh)
                    SetPedIntoVehicle(playerPed, veh, -1)
                    Wait(150)
                    SetEntityAsMissionEntity(veh, true, true)
                    if NetworkGetEntityIsNetworked(veh) then
                        NetworkRequestControlOfEntity(veh)
                    end
                    SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                    Wait(100)
                end
                
                for i = 1, 4 do
                    if DoesEntityExist(selectedVehicles[i]) then
                        takeControl(selectedVehicles[i])
                    end
                end
                
                local targetCoords = GetEntityCoords(targetPed)
                local positions = {
                    {x = targetCoords.x + 1.2, y = targetCoords.y, z = targetCoords.z, rotX = 90.0, rotY = 0.0, rotZ = 90.0},
                    {x = targetCoords.x - 1.2, y = targetCoords.y, z = targetCoords.z, rotX = 90.0, rotY = 0.0, rotZ = -90.0},
                    {x = targetCoords.x, y = targetCoords.y + 1.2, z = targetCoords.z, rotX = 90.0, rotY = 0.0, rotZ = 0.0},
                    {x = targetCoords.x, y = targetCoords.y - 1.2, z = targetCoords.z, rotX = 90.0, rotY = 0.0, rotZ = 180.0},
                }
                
                for i = 1, 4 do
                    if DoesEntityExist(selectedVehicles[i]) then
                        local pos = positions[i]
                        SetEntityCoordsNoOffset(selectedVehicles[i], pos.x, pos.y, pos.z, false, false, false)
                        SetEntityRotation(selectedVehicles[i], pos.rotX, pos.rotY, pos.rotZ, 2, true)
                        FreezeEntityPosition(selectedVehicles[i], true)
                    end
                end
            end)
        ]], targetServerId))
    end
end

-- Rain Nearby Vehicle
local function ActionRainVehicle()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end
            
            CreateThread(function()
                local playerPed = PlayerPedId()
                local myCoords = GetEntityCoords(playerPed)
                
                local nearbyVehicles = {}
                local vehHandle, veh = FindFirstVehicle()
                local success
                
                repeat
                    if DoesEntityExist(veh) then
                        local vehCoords = GetEntityCoords(veh)
                        local distance = #(myCoords - vehCoords)
                        if distance <= 200.0 and distance > 5.0 and veh ~= GetVehiclePedIsIn(playerPed, false) then
                            table.insert(nearbyVehicles, veh)
                        end
                    end
                    success, veh = FindNextVehicle(vehHandle)
                until not success
                
                EndFindVehicle(vehHandle)
                
                if #nearbyVehicles == 0 then return end
                
                for i, veh in ipairs(nearbyVehicles) do
                    if DoesEntityExist(veh) then
                        SetPedIntoVehicle(playerPed, veh, -1)
                        Wait(50)
                        SetEntityAsMissionEntity(veh, true, true)
                        if NetworkGetEntityIsNetworked(veh) then
                            NetworkRequestControlOfEntity(veh)
                        end
                        local targetCoords = GetEntityCoords(targetPed)
                        SetEntityCoordsNoOffset(veh, targetCoords.x, targetCoords.y, targetCoords.z + 50.0, false, false, false)
                        SetEntityHasGravity(veh, true)
                        Wait(10)
                    end
                end
            end)
        ]], targetServerId))
    end
end

-- Drop Nearby Vehicle
local function ActionDropVehicle()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) then return end
            
            CreateThread(function()
                local playerPed = PlayerPedId()
                local myCoords = GetEntityCoords(playerPed)
                local myHeading = GetEntityHeading(playerPed)
                
                local closestVeh = GetClosestVehicle(myCoords.x, myCoords.y, myCoords.z, 100.0, 0, 70)
                if not closestVeh or closestVeh == 0 then return end
                
                SetPedIntoVehicle(playerPed, closestVeh, -1)
                Wait(150)
                
                SetEntityAsMissionEntity(closestVeh, true, true)
                if NetworkGetEntityIsNetworked(closestVeh) then
                    NetworkRequestControlOfEntity(closestVeh)
                end
                
                SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                Wait(100)
                
                local targetCoords = GetEntityCoords(targetPed)
                SetEntityCoordsNoOffset(closestVeh, targetCoords.x, targetCoords.y, targetCoords.z + 15.0, false, false, false)
                SetEntityRotation(closestVeh, 0.0, -90.0, 0.0, 2, true)
                SetEntityVelocity(closestVeh, 0.0, 0.0, -100.0)
            end)
        ]], targetServerId))
    end
end

-- Vehicle Functions
Menu.BugVehicleMode = "V1"
Menu.KickVehicleMode = "V1"

-- Bug Vehicle (selector)
local function ActionBugVehicle()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    local bugVehicleMode = Menu.BugVehicleMode or "V1"
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            local bugVehicleMode = "%s"
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) or not IsPedInAnyVehicle(targetPed, false) then
                return
            end
            
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if not DoesEntityExist(targetVehicle) then return end
            
            CreateThread(function()
                local playerPed = PlayerPedId()
                local myCoords = GetEntityCoords(playerPed)
                
                local closestVeh = GetClosestVehicle(myCoords.x, myCoords.y, myCoords.z, 100.0, 0, 70)
                if not closestVeh or closestVeh == 0 then return end
                
                SetPedIntoVehicle(playerPed, closestVeh, -1)
                Wait(150)
                
                SetEntityAsMissionEntity(closestVeh, true, true)
                if NetworkGetEntityIsNetworked(closestVeh) then
                    NetworkRequestControlOfEntity(closestVeh)
                end
                
                SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                Wait(100)
                
                for i = 1, 30 do
                    DetachEntity(closestVeh, true, true)
                    Wait(5)
                    AttachEntityToEntityPhysically(closestVeh, targetVehicle, 0, 0, 0, 2000.0, 1460.0, 1000.0, 10.0, 88.0, 600.0, true, true, true, false, 0)
                    Wait(5)
                end
            end)
        ]], targetServerId, bugVehicleMode))
    end
end

-- Kick Vehicle (selector)
local function ActionKickVehicle()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) or not IsPedInAnyVehicle(targetPed, false) then
                return
            end
            
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if not DoesEntityExist(targetVehicle) then return end
            
            CreateThread(function()
                local player = PlayerPedId()
                
                if DoesEntityExist(targetVehicle) then
                    local driver = GetPedInVehicleSeat(targetVehicle, -1)
                    if driver ~= 0 and DoesEntityExist(driver) then
                        SetPedIntoVehicle(player, targetVehicle, 0)
                        Wait(10)
                        NetworkRequestControlOfEntity(targetVehicle)
                        DeletePed(driver)
                        SetPedIntoVehicle(player, targetVehicle, -1)
                        Wait(25)
                        TaskLeaveVehicle(player, targetVehicle, 16)
                        Wait(450)
                    end
                end
            end)
        ]], targetServerId))
    end
end

-- Give Vehicle
local function ActionGiveVehicle()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        local code = string.format([[
CreateThread(function()
    local targetServerId = %d
    
    local targetPlayerId = nil
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(player) == targetServerId then
            targetPlayerId = player
            break
        end
    end
    
    if not targetPlayerId then
        return
    end
    
    local targetPed = GetPlayerPed(targetPlayerId)
    if not DoesEntityExist(targetPed) then
        return
    end
    
    local playerPed = PlayerPedId()
    local myCoords = GetEntityCoords(playerPed)
    local myHeading = GetEntityHeading(playerPed)
    
    local giveCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    SetCamCoord(giveCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(giveCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamFov(giveCam, GetGameplayCamFov())
    SetCamActive(giveCam, true)
    RenderScriptCams(true, false, 0, true, true)
    
    local playerModel = GetEntityModel(playerPed)
    RequestModel(playerModel)
    local timeout = 0
    while not HasModelLoaded(playerModel) and timeout < 50 do
        Wait(50)
        timeout = timeout + 1
    end
    
    local groundZ = myCoords.z
    local rayHandle = StartShapeTestRay(myCoords.x, myCoords.y, myCoords.z + 2.0, myCoords.x, myCoords.y, myCoords.z - 100.0, 1, 0, 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)
    if hit then
        groundZ = hitCoords.z
    end
    
    local clonePed = CreatePed(4, playerModel, myCoords.x, myCoords.y, groundZ, myHeading, false, false)
    SetEntityCollision(clonePed, false, false)
    FreezeEntityPosition(clonePed, true)
    SetEntityInvincible(clonePed, true)
    SetBlockingOfNonTemporaryEvents(clonePed, true)
    SetPedCanRagdoll(clonePed, false)
    ClonePedToTarget(playerPed, clonePed)
    
    SetEntityVisible(playerPed, false, false)
    SetEntityLocallyInvisible(playerPed)
    
    local closestVeh = GetClosestVehicle(myCoords.x, myCoords.y, myCoords.z, 100.0, 0, 70)
    
    if not closestVeh or closestVeh == 0 then
        SetEntityVisible(playerPed, true, false)
        SetCamActive(giveCam, false)
        if not rawget(_G, 'isSpectating') then
            RenderScriptCams(false, false, 0, true, true)
        end
        DestroyCam(giveCam, true)
        if DoesEntityExist(clonePed) then
            DeleteEntity(clonePed)
        end
        SetModelAsNoLongerNeeded(playerModel)
        return
    end
    
    SetPedIntoVehicle(playerPed, closestVeh, -1)
    Wait(150)
    SetEntityAsMissionEntity(closestVeh, true, true)
    if NetworkGetEntityIsNetworked(closestVeh) then
        NetworkRequestControlOfEntity(closestVeh)
        local timeout = 0
        while not NetworkHasControlOfEntity(closestVeh) and timeout < 50 do
            NetworkRequestControlOfEntity(closestVeh)
            Wait(10)
            timeout = timeout + 1
        end
    end
    
    SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
    SetEntityHeading(playerPed, myHeading)
    Wait(100)
    
    if not DoesEntityExist(targetPed) or not DoesEntityExist(closestVeh) then
        SetEntityVisible(playerPed, true, false)
        SetCamActive(giveCam, false)
        if not rawget(_G, 'isSpectating') then
            RenderScriptCams(false, false, 0, true, true)
        end
        DestroyCam(giveCam, true)
        if DoesEntityExist(clonePed) then
            DeleteEntity(clonePed)
        end
        SetModelAsNoLongerNeeded(playerModel)
        return
    end
    
    local targetCoords = GetEntityCoords(targetPed)
    local targetHeading = GetEntityHeading(targetPed)
    local offsetCoords = GetOffsetFromEntityInWorldCoords(targetPed, 3.0, 0.0, 0.0)
    
    SetEntityCoordsNoOffset(closestVeh, offsetCoords.x, offsetCoords.y, offsetCoords.z, false, false, false)
    SetEntityHeading(closestVeh, targetHeading)
    SetVehicleOnGroundProperly(closestVeh)
    
    Wait(500)
    SetEntityVisible(playerPed, true, false)
    SetCamActive(giveCam, false)
    if not rawget(_G, 'isSpectating') then
        RenderScriptCams(false, false, 0, true, true)
    end
    DestroyCam(giveCam, true)
    if DoesEntityExist(clonePed) then
        DeleteEntity(clonePed)
    end
    SetModelAsNoLongerNeeded(playerModel)
end)
        ]], targetServerId)
        
        Susano.InjectResource("any", WrapWithVehicleHooks(code))
    end
end

-- Give Ramp
local function ActionGiveRamp()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        local code = string.format([[
local targetServerId = %d
local targetPlayerId = nil
for _, player in ipairs(GetActivePlayers()) do
    if GetPlayerServerId(player) == targetServerId then
        targetPlayerId = player
        break
    end
end

if not targetPlayerId then
    return
end

local targetPed = GetPlayerPed(targetPlayerId)
if not DoesEntityExist(targetPed) then
    return
end

if not IsPedInAnyVehicle(targetPed, false) then
    return
end

local targetVehicle = GetVehiclePedIsIn(targetPed, false)
if not DoesEntityExist(targetVehicle) then
    return
end

CreateThread(function()
    local playerPed = PlayerPedId()
    local myCoords = GetEntityCoords(playerPed)
    local myHeading = GetEntityHeading(playerPed)
    
    local rampCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    SetCamCoord(rampCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(rampCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamFov(rampCam, GetGameplayCamFov())
    SetCamActive(rampCam, true)
    RenderScriptCams(true, false, 0, true, true)
    
    local playerModel = GetEntityModel(playerPed)
    RequestModel(playerModel)
    local timeout = 0
    while not HasModelLoaded(playerModel) and timeout < 50 do
        Wait(50)
        timeout = timeout + 1
    end

    local groundZ = myCoords.z
    local rayHandle = StartShapeTestRay(myCoords.x, myCoords.y, myCoords.z + 2.0, myCoords.x, myCoords.y, myCoords.z - 100.0, 1, 0, 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)
    if hit then
        groundZ = hitCoords.z
    end
    
    local clonePed = CreatePed(4, playerModel, myCoords.x, myCoords.y, groundZ, myHeading, false, false)
    SetEntityCollision(clonePed, false, false)
    FreezeEntityPosition(clonePed, true)
    SetEntityInvincible(clonePed, true)
    SetBlockingOfNonTemporaryEvents(clonePed, true)
    SetPedCanRagdoll(clonePed, false)
    ClonePedToTarget(playerPed, clonePed)
    
    SetEntityVisible(playerPed, false, false)
    
    local targetCoords = GetEntityCoords(targetVehicle)
    local vehicles = {}
    local searchRadius = 100.0
    local vehHandle, veh = FindFirstVehicle()
    local success
    
    repeat
        local vehCoords = GetEntityCoords(veh)
        local distance = #(targetCoords - vehCoords)
        local vehClass = GetVehicleClass(veh)
        if distance <= searchRadius and veh ~= targetVehicle and vehClass ~= 8 and vehClass ~= 13 then
            table.insert(vehicles, {handle = veh, distance = distance})
        end
        success, veh = FindNextVehicle(vehHandle)
    until not success
    EndFindVehicle(vehHandle)
    
    if #vehicles < 3 then
        SetEntityVisible(playerPed, true, false)
        SetCamActive(rampCam, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(rampCam, true)
        if DoesEntityExist(clonePed) then
            DeleteEntity(clonePed)
        end
        SetModelAsNoLongerNeeded(playerModel)
        return
    end
    
    table.sort(vehicles, function(a, b) return a.distance < b.distance end)
    local selectedVehicles = {vehicles[1].handle, vehicles[2].handle, vehicles[3].handle}
    
    local function takeControl(veh)
        SetPedIntoVehicle(playerPed, veh, -1)
        Wait(150)
        SetEntityAsMissionEntity(veh, true, true)
        if NetworkGetEntityIsNetworked(veh) then
            NetworkRequestControlOfEntity(veh)
            local timeout = 0
            while not NetworkHasControlOfEntity(veh) and timeout < 50 do
                NetworkRequestControlOfEntity(veh)
                Wait(10)
                timeout = timeout + 1
            end
        end
        SetEntityCoordsNoOffset(playerPed, myCoords.x, myCoords.y, myCoords.z, false, false, false)
        SetEntityHeading(playerPed, myHeading)
        Wait(100)
    end
    
    for i = 1, 3 do
        if DoesEntityExist(selectedVehicles[i]) then
            takeControl(selectedVehicles[i])
        end
    end
    
    local rampPositions = {
        {offsetX = -2.0, offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
        {offsetX = 0.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
        {offsetX = 2.0,  offsetY = 2.5, offsetZ = 0.2, rotX = 160.0, rotY = 0.0, rotZ = 0.0},
    }
    
    for i = 1, 3 do
        if DoesEntityExist(selectedVehicles[i]) and DoesEntityExist(targetVehicle) then
            local pos = rampPositions[i]
            AttachEntityToEntity(selectedVehicles[i], targetVehicle, 0, pos.offsetX, pos.offsetY, pos.offsetZ, pos.rotX, pos.rotY, pos.rotZ, false, false, true, false, 2, true)
        end
    end
    
    Wait(500)
    SetEntityVisible(playerPed, true, false)
    SetCamActive(rampCam, false)
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(rampCam, true)
    if DoesEntityExist(clonePed) then
        DeleteEntity(clonePed)
    end
    SetModelAsNoLongerNeeded(playerModel)
end)
        ]], targetServerId)
        
        Susano.InjectResource("any", WrapWithVehicleHooks(code))
    end
end

-- TP to (ocean, mazebank, sandyshores)
Menu.TPLocation = "ocean"

local function ActionTPTo()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    local tpLocation = Menu.TPLocation or "ocean"
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        local code = string.format([[
local targetServerId = %d
local tpLocation = "%s"

local targetPlayerId = nil
for _, player in ipairs(GetActivePlayers()) do
    if GetPlayerServerId(player) == targetServerId then
        targetPlayerId = player
        break
    end
end

if not targetPlayerId then
    return
end

local targetPed = GetPlayerPed(targetPlayerId)
if not DoesEntityExist(targetPed) then
    return
end

if not IsPedInAnyVehicle(targetPed, false) then
    return
end

local targetVehicle = GetVehiclePedIsIn(targetPed, false)
if not DoesEntityExist(targetVehicle) then
    return
end

local locations = {
    ocean = {coords = vector3(-3000.0, -3000.0, 0.0), name = "Ocean"},
    mazebank = {coords = vector3(-75.0, -818.0, 326.0), name = "Maze Bank"},
    sandyshores = {coords = vector3(1960.0, 3740.0, 32.0), name = "Sandy Shores"}
}

local destCoords = locations[tpLocation].coords
local destName = locations[tpLocation].name

local playerPed = PlayerPedId()
local savedCoords = GetEntityCoords(playerPed)
local savedHeading = GetEntityHeading(playerPed)

local function RequestControl(entity, timeoutMs)
    if not entity or not DoesEntityExist(entity) then return false end
    local start = GetGameTimer()
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) do
        Wait(0)
        if GetGameTimer() - start > (timeoutMs or 500) then
            return false
        end
        NetworkRequestControlOfEntity(entity)
    end
    return true
end

local function tryEnterSeat(seatIndex)
    SetPedIntoVehicle(playerPed, targetVehicle, seatIndex)
    Wait(0)
    return IsPedInVehicle(playerPed, targetVehicle, false) and GetPedInVehicleSeat(targetVehicle, seatIndex) == playerPed
end

local function getFirstFreeSeat(v)
    local numSeats = GetVehicleModelNumberOfSeats(GetEntityModel(v))
    if not numSeats or numSeats <= 0 then return -1 end
    for seat = 0, (numSeats - 2) do
        if IsVehicleSeatFree(v, seat) then return seat end
    end
    return -1
end

ClearPedTasksImmediately(playerPed)
SetVehicleDoorsLocked(targetVehicle, 1)
SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)

if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
    TaskLeaveVehicle(playerPed, targetVehicle, 0)
    Wait(500)
    
    SetEntityCoordsNoOffset(targetVehicle, destCoords.x, destCoords.y, destCoords.z, false, false, false)
    
    Wait(100)
    SetEntityCoordsNoOffset(playerPed, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false)
    SetEntityHeading(playerPed, savedHeading)
    
    return
end

if GetPedInVehicleSeat(targetVehicle, -1) == playerPed then
    TaskLeaveVehicle(playerPed, targetVehicle, 0)
    Wait(500)
    
    SetEntityCoordsNoOffset(targetVehicle, destCoords.x, destCoords.y, destCoords.z, false, false, false)
    
    Wait(100)
    SetEntityCoordsNoOffset(playerPed, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false)
    SetEntityHeading(playerPed, savedHeading)
    
    return
end

local fallbackSeat = getFirstFreeSeat(targetVehicle)
if fallbackSeat ~= -1 and tryEnterSeat(fallbackSeat) then
    local drv = GetPedInVehicleSeat(targetVehicle, -1)
    if drv ~= 0 and drv ~= playerPed and DoesEntityExist(drv) then
        RequestControl(drv, 750)
        ClearPedTasksImmediately(drv)
        SetEntityAsMissionEntity(drv, true, true)
        SetEntityCoords(drv, 0.0, 0.0, -100.0, false, false, false, false)
        Wait(50)
        DeleteEntity(drv)
        
        for i=1,80 do
            local occ = GetPedInVehicleSeat(targetVehicle, -1)
            if occ == 0 or (occ ~= 0 and not DoesEntityExist(occ)) then break end
            Wait(0)
        end
    end
    
    for attempt = 1, 30 do
        if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
            TaskLeaveVehicle(playerPed, targetVehicle, 0)
            Wait(500)
            
            SetEntityCoordsNoOffset(targetVehicle, destCoords.x, destCoords.y, destCoords.z, false, false, false)
            
            Wait(100)
            SetEntityCoordsNoOffset(playerPed, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false)
            SetEntityHeading(playerPed, savedHeading)
            
            return
        end
        Wait(0)
    end
end
        ]], targetServerId, tpLocation)
        
        Susano.InjectResource("any", WrapWithVehicleHooks(code))
    end
end

-- Warp Vehicle
local function ActionWarpVehicle()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        local code = string.format([[
local targetServerId = %d

local targetPlayerId = nil
for _, player in ipairs(GetActivePlayers()) do
    if GetPlayerServerId(player) == targetServerId then
        targetPlayerId = player
        break
    end
end

if not targetPlayerId then
    return
end

local targetPed = GetPlayerPed(targetPlayerId)
if not DoesEntityExist(targetPed) then
    return
end

if not IsPedInAnyVehicle(targetPed, false) then
    return
end

local targetVehicle = GetVehiclePedIsIn(targetPed, false)
if not DoesEntityExist(targetVehicle) then
    return
end

local playerPed = PlayerPedId()

local function RequestControl(entity, timeoutMs)
    if not entity or not DoesEntityExist(entity) then return false end
    local start = GetGameTimer()
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) do
        Wait(0)
        if GetGameTimer() - start > (timeoutMs or 500) then
            return false
        end
        NetworkRequestControlOfEntity(entity)
    end
    return true
end

local function tryEnterSeat(seatIndex)
    SetPedIntoVehicle(playerPed, targetVehicle, seatIndex)
    Wait(0)
    return IsPedInVehicle(playerPed, targetVehicle, false) and GetPedInVehicleSeat(targetVehicle, seatIndex) == playerPed
end

local function getFirstFreeSeat(v)
    local numSeats = GetVehicleModelNumberOfSeats(GetEntityModel(v))
    if not numSeats or numSeats <= 0 then return -1 end
    for seat = 0, (numSeats - 2) do
        if IsVehicleSeatFree(v, seat) then return seat end
    end
    return -1
end

ClearPedTasksImmediately(playerPed)
SetVehicleDoorsLocked(targetVehicle, 1)
SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)

if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
    return
end

if GetPedInVehicleSeat(targetVehicle, -1) == playerPed then
    return
end

local fallbackSeat = getFirstFreeSeat(targetVehicle)
if fallbackSeat ~= -1 and tryEnterSeat(fallbackSeat) then
    local drv = GetPedInVehicleSeat(targetVehicle, -1)
    if drv ~= 0 and drv ~= playerPed and DoesEntityExist(drv) then
        RequestControl(drv, 750)
        ClearPedTasksImmediately(drv)
        SetEntityAsMissionEntity(drv, true, true)
        SetEntityCoords(drv, 0.0, 0.0, -100.0, false, false, false, false)
        Wait(50)
        DeleteEntity(drv)
        
        for i=1,80 do
            local occ = GetPedInVehicleSeat(targetVehicle, -1)
            if occ == 0 or (occ ~= 0 and not DoesEntityExist(occ)) then break end
            Wait(0)
        end
    end
    
    for attempt = 1, 30 do
        if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
            return
        end
        Wait(0)
    end
end
        ]], targetServerId)
        
        Susano.InjectResource("any", WrapWithVehicleHooks(code))
    end
end

-- Warp+Boost
local function ActionWarpBoost()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        local code = string.format([[
CreateThread(function()
    if rawget(_G, 'warp_boost_player_busy') then return end
    rawset(_G, 'warp_boost_player_busy', true)
    
    local targetServerId = %d
    
    local targetPlayerId = nil
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(player) == targetServerId then
            targetPlayerId = player
            break
        end
    end
    
    if not targetPlayerId then
        rawset(_G, 'warp_boost_player_busy', false)
        return
    end
    
    local targetPed = GetPlayerPed(targetPlayerId)
    if not DoesEntityExist(targetPed) then
        rawset(_G, 'warp_boost_player_busy', false)
        return
    end
    
    if not IsPedInAnyVehicle(targetPed, false) then
        rawset(_G, 'warp_boost_player_busy', false)
        return
    end
    
    local targetVehicle = GetVehiclePedIsIn(targetPed, false)
    if not DoesEntityExist(targetVehicle) then
        rawset(_G, 'warp_boost_player_busy', false)
        return
    end
    
    local playerPed = PlayerPedId()
    local initialCoords = GetEntityCoords(playerPed)
    local initialHeading = GetEntityHeading(playerPed)
    
    local warpBoostCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    SetCamCoord(warpBoostCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(warpBoostCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamFov(warpBoostCam, GetGameplayCamFov())
    SetCamActive(warpBoostCam, true)
    RenderScriptCams(true, false, 0, true, true)
    
    local playerModel = GetEntityModel(playerPed)
    RequestModel(playerModel)
    local timeout = 0
    while not HasModelLoaded(playerModel) and timeout < 50 do
        Wait(50)
        timeout = timeout + 1
    end
    
    local groundZ = initialCoords.z
    local rayHandle = StartShapeTestRay(initialCoords.x, initialCoords.y, initialCoords.z + 2.0, initialCoords.x, initialCoords.y, initialCoords.z - 100.0, 1, 0, 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)
    if hit then
        groundZ = hitCoords.z
    end
    
    local clonePed = CreatePed(4, playerModel, initialCoords.x, initialCoords.y, groundZ, initialHeading, false, false)
    SetEntityCollision(clonePed, false, false)
    FreezeEntityPosition(clonePed, true)
    SetEntityInvincible(clonePed, true)
    SetBlockingOfNonTemporaryEvents(clonePed, true)
    SetPedCanRagdoll(clonePed, false)
    ClonePedToTarget(playerPed, clonePed)
    
    SetEntityVisible(playerPed, false, false)
    SetEntityLocallyInvisible(playerPed)
    
    local function RequestControl(entity, timeoutMs)
        if not entity or not DoesEntityExist(entity) then return false end
        local start = GetGameTimer()
        NetworkRequestControlOfEntity(entity)
        while not NetworkHasControlOfEntity(entity) do
            Wait(0)
            if GetGameTimer() - start > (timeoutMs or 500) then
                return false
            end
            NetworkRequestControlOfEntity(entity)
        end
        return true
    end
    
    RequestControl(targetVehicle, 800)
    SetVehicleDoorsLocked(targetVehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
    
    local function tryEnterSeat(seatIndex)
        SetPedIntoVehicle(playerPed, targetVehicle, seatIndex)
        Wait(0)
        return IsPedInVehicle(playerPed, targetVehicle, false) and GetPedInVehicleSeat(targetVehicle, seatIndex) == playerPed
    end
    
    local function getFirstFreeSeat(v)
        local numSeats = GetVehicleModelNumberOfSeats(GetEntityModel(v))
        if not numSeats or numSeats <= 0 then return -1 end
        for seat = 0, (numSeats - 2) do
            if IsVehicleSeatFree(v, seat) then return seat end
        end
        return -1
    end
    
    ClearPedTasksImmediately(playerPed)
    SetVehicleDoorsLocked(targetVehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
    
    local takeoverSuccess = false
    local tStart = GetGameTimer()
    
    while (GetGameTimer() - tStart) < 1000 do
        RequestControl(targetVehicle, 400)
        
        if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
            takeoverSuccess = true
            break
        end
        
        if not IsPedInVehicle(playerPed, targetVehicle, false) then
            local fs = getFirstFreeSeat(targetVehicle)
            if fs ~= -1 then
                tryEnterSeat(fs)
            end
        end
        
        local drv = GetPedInVehicleSeat(targetVehicle, -1)
        if drv ~= 0 and drv ~= playerPed and DoesEntityExist(drv) then
            RequestControl(drv, 400)
            ClearPedTasksImmediately(drv)
            SetEntityAsMissionEntity(drv, true, true)
            SetEntityCoords(drv, 0.0, 0.0, -100.0, false, false, false, false)
            Wait(20)
            DeleteEntity(drv)
        end
        
        local t0 = GetGameTimer()
        while (GetGameTimer() - t0) < 400 do
            local occ = GetPedInVehicleSeat(targetVehicle, -1)
            if occ == 0 or (occ ~= 0 and not DoesEntityExist(occ)) then break end
            Wait(0)
        end
        
        local t1 = GetGameTimer()
        while (GetGameTimer() - t1) < 500 do
            if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
                takeoverSuccess = true
                break
            end
            Wait(0)
        end
        if takeoverSuccess then break end
        Wait(0)
    end
    
    if takeoverSuccess then
        if DoesEntityExist(targetVehicle) then
            FreezeEntityPosition(targetVehicle, true)
            SetVehicleEngineOn(targetVehicle, true, true, false)
            
            local targetSpeed = 140.0
            for i = 1, 4 do
                SetVehicleForwardSpeed(targetVehicle, targetSpeed)
                Wait(0)
            end
        end
        TaskLeaveVehicle(playerPed, targetVehicle, 0)
        for i = 1, 10 do
            if not IsPedInVehicle(playerPed, targetVehicle, false) then break end
            ClearPedTasksImmediately(playerPed)
            Wait(0)
        end
        
        SetEntityCoordsNoOffset(playerPed, initialCoords.x, initialCoords.y, initialCoords.z, false, false, false)
        SetEntityHeading(playerPed, initialHeading)
        Wait(50)
        
        if DoesEntityExist(targetVehicle) then
            FreezeEntityPosition(targetVehicle, false)
            NetworkRequestControlOfEntity(targetVehicle)
            
            CreateThread(function()
                local targetSpeed = 140.0
                for i = 1, 12 do
                    SetVehicleForwardSpeed(targetVehicle, targetSpeed)
                    Wait(0)
                end
            end)
        end
    end
    
    Wait(500)
    SetEntityVisible(playerPed, true, false)
    SetCamActive(warpBoostCam, false)
    if not rawget(_G, 'isSpectating') then
        RenderScriptCams(false, false, 0, true, true)
    end
    DestroyCam(warpBoostCam, true)
    if DoesEntityExist(clonePed) then
        DeleteEntity(clonePed)
    end
    SetModelAsNoLongerNeeded(playerModel)
    
    rawset(_G, 'warp_boost_player_busy', false)
end)
        ]], targetServerId)
        
        Susano.InjectResource("any", WrapWithVehicleHooks(code))
    end
end

-- Steal Vehicle
local function ActionStealVehicle()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        local code = string.format([[
CreateThread(function()
    if rawget(_G, 'warp_boost_busy') then return end
    rawset(_G, 'warp_boost_busy', true)
    
    local targetServerId = %d
    
    local targetPlayerId = nil
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(player) == targetServerId then
            targetPlayerId = player
            break
        end
    end
    
    if not targetPlayerId then
        rawset(_G, 'warp_boost_busy', false)
        return
    end
    
    local targetPed = GetPlayerPed(targetPlayerId)
    if not DoesEntityExist(targetPed) then
        rawset(_G, 'warp_boost_busy', false)
        return
    end
    
    if not IsPedInAnyVehicle(targetPed, false) then
        rawset(_G, 'warp_boost_busy', false)
        return
    end
    
    local targetVehicle = GetVehiclePedIsIn(targetPed, false)
    if not DoesEntityExist(targetVehicle) then
        rawset(_G, 'warp_boost_busy', false)
        return
    end
    
    local playerPed = PlayerPedId()
    local initialCoords = GetEntityCoords(playerPed)
    local initialHeading = GetEntityHeading(playerPed)
    
    local function RequestControl(entity, timeoutMs)
        if not entity or not DoesEntityExist(entity) then return false end
        local start = GetGameTimer()
        NetworkRequestControlOfEntity(entity)
        while not NetworkHasControlOfEntity(entity) do
            Wait(0)
            if GetGameTimer() - start > (timeoutMs or 500) then
                return false
            end
            NetworkRequestControlOfEntity(entity)
        end
        return true
    end
    
    RequestControl(targetVehicle, 800)
    SetVehicleDoorsLocked(targetVehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
    
    local function tryEnterSeat(seatIndex)
        SetPedIntoVehicle(playerPed, targetVehicle, seatIndex)
        Wait(0)
        return IsPedInVehicle(playerPed, targetVehicle, false) and GetPedInVehicleSeat(targetVehicle, seatIndex) == playerPed
    end
    
    local function getFirstFreeSeat(v)
        local numSeats = GetVehicleModelNumberOfSeats(GetEntityModel(v))
        if not numSeats or numSeats <= 0 then return -1 end
        for seat = 0, (numSeats - 2) do
            if IsVehicleSeatFree(v, seat) then return seat end
        end
        return -1
    end
    
    ClearPedTasksImmediately(playerPed)
    SetVehicleDoorsLocked(targetVehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(targetVehicle, false)
    
    local takeoverSuccess = false
    local tStart = GetGameTimer()
    
    while (GetGameTimer() - tStart) < 1000 do
        RequestControl(targetVehicle, 400)
        
        if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
            takeoverSuccess = true
            break
        end
        
        if not IsPedInVehicle(playerPed, targetVehicle, false) then
            local fs = getFirstFreeSeat(targetVehicle)
            if fs ~= -1 then
                tryEnterSeat(fs)
            end
        end
        
        local drv = GetPedInVehicleSeat(targetVehicle, -1)
        if drv ~= 0 and drv ~= playerPed and DoesEntityExist(drv) then
            RequestControl(drv, 400)
            ClearPedTasksImmediately(drv)
            SetEntityAsMissionEntity(drv, true, true)
            SetEntityCoords(drv, 0.0, 0.0, -100.0, false, false, false, false)
            Wait(20)
            DeleteEntity(drv)
        end
        
        local t0 = GetGameTimer()
        while (GetGameTimer() - t0) < 400 do
            local occ = GetPedInVehicleSeat(targetVehicle, -1)
            if occ == 0 or (occ ~= 0 and not DoesEntityExist(occ)) then break end
            Wait(0)
        end
        
        local t1 = GetGameTimer()
        while (GetGameTimer() - t1) < 500 do
            if IsVehicleSeatFree(targetVehicle, -1) and tryEnterSeat(-1) then
                takeoverSuccess = true
                break
            end
            Wait(0)
        end
        if takeoverSuccess then break end
        Wait(0)
    end
    
    if takeoverSuccess then
        if DoesEntityExist(targetVehicle) and IsPedInVehicle(playerPed, targetVehicle, false) then
            RequestControl(targetVehicle, 1000)
            if NetworkHasControlOfEntity(targetVehicle) then
                FreezeEntityPosition(targetVehicle, true)
                SetVehicleEngineOn(targetVehicle, true, true, false)
                SetEntityCoordsNoOffset(targetVehicle, initialCoords.x, initialCoords.y, initialCoords.z + 1.0, false, false, false, false)
                SetEntityHeading(targetVehicle, initialHeading)
                SetEntityVelocity(targetVehicle, 0.0, 0.0, 0.0)
                Wait(100)
                FreezeEntityPosition(targetVehicle, false)
                SetVehicleOnGroundProperly(targetVehicle)
            end
        end
    end
    
    rawset(_G, 'warp_boost_busy', false)
end)
        ]], targetServerId)
        
        Susano.InjectResource("any", WrapWithVehicleHooks(code))
    end
end

-- Hijack Player
local function ActionHijackPlayer()
    if not Menu.SelectedPlayer then return end
    
    local targetServerId = Menu.SelectedPlayer
    
    if type(Susano) == "table" and type(Susano.InjectResource) == "function" then
        Susano.InjectResource("any", string.format([[
            local targetServerId = %d
            
            local targetPlayerId = nil
            for _, player in ipairs(GetActivePlayers()) do
                if GetPlayerServerId(player) == targetServerId then
                    targetPlayerId = player
                    break
                end
            end
            
            if not targetPlayerId then return end
            
            local targetPed = GetPlayerPed(targetPlayerId)
            if not DoesEntityExist(targetPed) or not IsPedInAnyVehicle(targetPed, false) then
                return
            end
            
            local targetVehicle = GetVehiclePedIsIn(targetPed, false)
            if not DoesEntityExist(targetVehicle) then return end
            
            local playerPed = PlayerPedId()
            local tpCoords = GetOffsetFromEntityInWorldCoords(targetVehicle, -1.2, 0.5, 0.0)
            SetEntityCoordsNoOffset(playerPed, tpCoords.x, tpCoords.y, tpCoords.z, false, false, false)
            Wait(50)
            TaskEnterVehicle(playerPed, targetVehicle, -1, -1, 2.0, 8, 0)
        ]], targetServerId))
    end
end

-- Hooks pour Troll
local bugPlayerItem = FindItem("Online", "Troll", "Bug Player")
if bugPlayerItem then
    bugPlayerItem.onClick = function(index, option)
        Menu.BugPlayerMode = option
        ActionBugPlayer()
    end
end

local cagePlayerItem = FindItem("Online", "Troll", "Cage Player")
if cagePlayerItem then
    cagePlayerItem.onClick = function()
        ActionCagePlayer()
    end
end

local rainVehicleItem = FindItem("Online", "Troll", "Rain Nearby Vehicle")
if rainVehicleItem then
    rainVehicleItem.onClick = function()
        ActionRainVehicle()
    end
end

local dropVehicleItem = FindItem("Online", "Troll", "Drop Nearby Vehicle")
if dropVehicleItem then
    dropVehicleItem.onClick = function()
        ActionDropVehicle()
    end
end

-- Give Weapon to Player (risky)
local giveWeaponToPlayerItem = FindItem("Online", "risky", "Give Weapon to Player")
if giveWeaponToPlayerItem then
    giveWeaponToPlayerItem.onClick = function()
        if not Menu.SelectedPlayer then
            print("^1✗ Aucun joueur sélectionné^0")
            return
        end
        
        -- Donner directement un minigun
        GiveWeaponToPlayerByName("WEAPON_MINIGUN", Menu.SelectedPlayer)
        print("^2✓ Minigun donné au joueur^0")
    end
end

-- Hooks pour Vehicle
local bugVehicleItem = FindItem("Online", "Vehicle", "Bug Vehicle")
if bugVehicleItem then
    bugVehicleItem.onClick = function(index, option)
        if option then
            Menu.BugVehicleMode = option
        end
        ActionBugVehicle()
    end
end

local warpVehicleItem = FindItem("Online", "Vehicle", "Warp Vehicle")
if warpVehicleItem then
    warpVehicleItem.onClick = function()
        ActionWarpVehicle()
    end
end

local warpBoostItem = FindItem("Online", "Vehicle", "Warp+Boost")
if warpBoostItem then
    warpBoostItem.onClick = function()
        ActionWarpBoost()
    end
end

local stealVehicleItem = FindItem("Online", "Vehicle", "Steal Vehicle")
if stealVehicleItem then
    stealVehicleItem.onClick = function()
        ActionStealVehicle()
    end
end

local kickVehicleItem = FindItem("Online", "Vehicle", "Kick Vehicle")
if kickVehicleItem then
    kickVehicleItem.onClick = function(index, option)
        if option then
            Menu.KickVehicleMode = option
        end
        ActionKickVehicle()
    end
end

local hijackPlayerItem = FindItem("Online", "Vehicle", "Hijack Player")
if hijackPlayerItem then
    hijackPlayerItem.onClick = function()
        ActionHijackPlayer()
    end
end

local giveVehicleItem = FindItem("Online", "Vehicle", "Give Vehicle")
if giveVehicleItem then
    giveVehicleItem.onClick = function()
        ActionGiveVehicle()
    end
end

local giveRampItem = FindItem("Online", "Vehicle", "Give Ramp")
if giveRampItem then
    giveRampItem.onClick = function()
        ActionGiveRamp()
    end
end

local tpToItem = FindItem("Online", "Vehicle", "TP to")
if tpToItem then
    tpToItem.onClick = function(index, option)
        if option then
            Menu.TPLocation = option
        end
        ActionTPTo()
    end
end

