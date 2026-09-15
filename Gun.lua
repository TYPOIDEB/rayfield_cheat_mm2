-- Gun.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Ctx = nil

local MAPS = {
    ["workplace"] = true,
    ["biolab"] = true,
    ["milbase"] = true,
    ["house2"] = true,
    ["office3"] = true,
    ["mansion2"] = true,
    ["policestation"] = true,
    ["factory"] = true,
    ["bank2"] = true,
    ["hospital3"] = true,
    ["hotel2"] = true,
    ["researchfacility"] = true,
    ["beachresort"] = true,
    ["yacht"] = true,
    ["pier"] = true,
    ["manor"] = true,
    ["farmhouse"] = true,
    ["mineshaft"] = true,
    ["barn"] = true,
    ["vampiresvillage"] = true,
    ["vampirescastle"] = true,
    ["spaceship"] = true,
    ["workshop"] = true,
    ["logcabin"] = true,
    ["trainstation"] = true,
    ["icecastle"] = true,
    ["skilodge"] = true,
    ["christmasinitaly"] = true,
    -- Русские
    ["рабочееместо"] = true,
    ["биолаборатория"] = true,
    ["военнаябаза"] = true,
    ["дом2"] = true,
    ["офис3"] = true,
    ["особняк2"] = true,
    ["полицейскийучасток"] = true,
    ["завод"] = true,
    ["банк2"] = true,
    ["больница3"] = true,
    ["отель2"] = true,
    ["исследовательскийцентр"] = true,
    ["пляжныйкурорт"] = true,
    ["яхта"] = true,
    ["пирс"] = true,
    ["поместье"] = true,
    ["ферма"] = true,
    ["шахта"] = true,
    ["амбар"] = true,
    ["деревнявампиров"] = true,
    ["замоквампиров"] = true,
    ["космическийкорабль"] = true,
    ["мастерская"] = true,
    ["бревенчатаяхижина"] = true,
    ["вокзал"] = true,
    ["ледянойзамок"] = true,
    ["лыжныйдомик"] = true,
    ["рождествов италии"] = true,
}

local state = {
    autoTp     = false,
    currentMap = nil,
}

local function isAlive()
    if not Ctx then return false end
    return Ctx.Alive == true
end

local function normalizeName(name)
    return name:gsub("%s+", ""):lower()
end

local function findCurrentMap()
    for _, obj in ipairs(Workspace:GetChildren()) do
        local normalized = normalizeName(obj.Name)
        if MAPS[normalized] then
            return obj
        end
    end
    return nil
end

local function findGunDrop(map)
    if map then
        local found = map:FindFirstChild("GunDrop", true)
        if found then return found end
        found = map:FindFirstChild("Gun", true)
        if found then return found end
        found = map:FindFirstChild("Revolver", true)
        if found then return found end
    end

    local found = Workspace:FindFirstChild("GunDrop")
    if found then return found end
    found = Workspace:FindFirstChild("Gun")
    if found then return found end
    found = Workspace:FindFirstChild("Revolver")
    if found then return found end

    return nil
end

local function getGunPart(gun)
    if not gun then return nil end
    if gun:IsA("BasePart") then return gun end
    if gun:IsA("Model") then
        return gun.PrimaryPart or gun:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function teleportToGun()
    local gun = findGunDrop(state.currentMap)
    if not gun then return false end

    local part = getGunPart(gun)
    if not part then return false end

    local char = LocalPlayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    return true
end

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("Gun", function(c)
            state.autoTp = false
            task.wait(0.1)
        end)

        Tab:CreateSection("Телепорт")

        Tab:CreateButton({
            Name = "ТП к пистолету",
            Callback = function()
                teleportToGun()
            end,
        })

        local autoTpToggle = Tab:CreateToggle({
            Name = "Auto TP к пистолету",
            CurrentValue = false,
            Flag = "gun_autotp",
            Callback = function(v) state.autoTp = v end,
        })
        ctx.RegisterToggle(autoTpToggle)

        -- Главный цикл внутри Init
        task.spawn(function()
            while isAlive() do
                task.wait(0.4)

                state.currentMap = findCurrentMap()

                if state.autoTp then
                    teleportToGun()
                end
            end
        end)
    end
}
