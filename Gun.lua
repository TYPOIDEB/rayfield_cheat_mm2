-- Gun.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Ctx = nil

-- Список карт MM2 (названия без пробелов, как в workspace)
local MAPS = {
    -- Постоянные карты
    ["Workplace"] = true,
    ["BioLab"] = true,
    ["MilBase"] = true,
    ["House2"] = true,
    ["Office3"] = true,
    ["Mansion2"] = true,
    ["PoliceStation"] = true,
    ["Factory"] = true,
    ["Bank2"] = true,
    ["Hospital3"] = true,
    ["Hotel2"] = true,
    ["ResearchFacility"] = true,
    -- Летние карты
    ["BeachResort"] = true,
    ["Yacht"] = true,
    ["Pier"] = true,
    -- Хэллоуин
    ["Manor"] = true,
    ["Farmhouse"] = true,
    ["Mineshaft"] = true,
    ["Barn"] = true,
    ["VampiresVillage"] = true,
    ["VampiresCastle"] = true,
    ["Spaceship"] = true,
    -- Рождество
    ["Workshop"] = true,
    ["LogCabin"] = true,
    ["TrainStation"] = true,
    ["IceCastle"] = true,
    ["SkiLodge"] = true,
    ["ChristmasInItaly"] = true,
}

local state = {
    gunEsp      = false,
    showDist    = true,
    autoPickup  = false,
    autoTp      = false,
    notifyDrop  = false,
    fillAlpha   = 0.5,
    color       = Color3.fromRGB(255, 215, 0),
    lastGunName = nil,
    currentMap  = nil,
}

local function isAlive()
    if not Ctx then return false end
    return Ctx.Alive == true
end

-- Убирает пробелы из имени
local function normalizeName(name)
    return name:gsub("%s+", "")
end

-- Ищет текущую карту среди детей workspace
local function findCurrentMap()
    for _, obj in ipairs(Workspace:GetChildren()) do
        local normalized = normalizeName(obj.Name)
        if MAPS[normalized] then
            return obj
        end
    end
    return nil
end

-- Ищет GunDrop внутри конкретной карты или во всем workspace
local function findGunDrop(map)
    local container = map or Workspace
    for _, obj in ipairs(container:GetDescendants()) do
        local name = obj.Name:lower()
        if name == "gundrop" or name == "gun" or name == "revolver" then
            return obj
        end
    end
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

local function clearGunVisual(gun)
    if not gun then return end
    local hl = gun:FindFirstChild("MM2_GunESP")
    if hl then hl:Destroy() end
    local bb = gun:FindFirstChild("MM2_GunESP_Name")
    if bb then bb:Destroy() end
end

local function applyGunVisual(gun)
    if not gun then return end
    local part = getGunPart(gun)
    if not part then return end

    local hl = gun:FindFirstChild("MM2_GunESP")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "MM2_GunESP"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = gun
        hl.Parent = gun
    end
    hl.FillColor = state.color
    hl.OutlineColor = state.color
    hl.FillTransparency = state.fillAlpha
    hl.OutlineTransparency = 0

    local lines = { "GunDrop 🔫" }
    if state.showDist then
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local dist = math.floor((part.Position - myHRP.Position).Magnitude)
            table.insert(lines, dist .. " studs")
        end
    end

    local bb = gun:FindFirstChild("MM2_GunESP_Name")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "MM2_GunESP_Name"
        bb.Size = UDim2.new(0, 180, 0, 50)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = gun

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = state.color
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = bb
    end

    local label = bb:FindFirstChild("Label")
    if label then
        label.Text = table.concat(lines, "\n")
        label.TextColor3 = state.color
    end
end

local function clearAllVisuals()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "MM2_GunESP" or obj.Name == "MM2_GunESP_Name" then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- Телепорт к пистолету
local function teleportToGun()
    local gun = findGunDrop(state.currentMap)
    if not gun then
        return false, "Пистолет не найден"
    end

    local part = getGunPart(gun)
    if not part then
        return false, "Не удалось получить позицию"
    end

    local char = LocalPlayer.Character
    if not char then
        return false, "Персонаж не найден"
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false, "HumanoidRootPart не найден"
    end

    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    return true, "Телепорт выполнен"
end

-- Основной цикл
task.spawn(function()
    while isAlive() do
        task.wait(0.4)
        if not isAlive() then break end

        -- Обновляем текущую карту
        state.currentMap = findCurrentMap()

        local gun = findGunDrop(state.currentMap)

        if gun then
            local gunName = gun.Name
            if state.notifyDrop and state.lastGunName ~= gunName then
                if Ctx and Ctx.Rayfield then
                    pcall(function()
                        Ctx.Rayfield:Notify({
                            Title = "Gun",
                            Content = "Появился GunDrop!",
                            Duration = 4,
                        })
                    end)
                end
            end
            state.lastGunName = gunName

            if state.gunEsp then
                applyGunVisual(gun)
            else
                clearGunVisual(gun)
            end

            -- Авто-ТП
            if state.autoTp then
                teleportToGun()
            end
        else
            state.lastGunName = nil
        end
    end
    clearAllVisuals()
end)

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("Gun", function(c)
            state.gunEsp = false
            state.autoPickup = false
            state.autoTp = false
            clearAllVisuals()
            task.wait(0.1)
        end)

        Tab:CreateSection("GunDrop ESP")

        local espToggle = Tab:CreateToggle({
            Name = "GunDrop ESP",
            CurrentValue = false,
            Flag = "gun_esp",
            Callback = function(v)
                state.gunEsp = v
                if not v then clearAllVisuals() end
            end,
        })
        ctx.RegisterToggle(espToggle)

        Tab:CreateToggle({
            Name = "Показывать дистанцию",
            CurrentValue = true,
            Flag = "gun_dist",
            Callback = function(v) state.showDist = v end,
        })

        Tab:CreateColorPicker({
            Name = "Цвет подсветки",
            Color = state.color,
            Flag = "gun_color",
            Callback = function(c) state.color = c end,
        })

        Tab:CreateSlider({
            Name = "Прозрачность",
            Range = {0, 1},
            Increment = 0.05,
            CurrentValue = 0.5,
            Flag = "gun_alpha",
            Callback = function(v) state.fillAlpha = v end,
        })

        Tab:CreateSection("Телепорт")

        Tab:CreateButton({
            Name = "ТП к пистолету",
            Callback = function()
                local ok, msg = teleportToGun()
                if Ctx and Ctx.Rayfield then
                    Ctx.Rayfield:Notify({
                        Title = "Gun",
                        Content = msg,
                        Duration = 3,
                    })
                end
            end,
        })

        local autoTpToggle = Tab:CreateToggle({
            Name = "Auto TP к пистолету",
            CurrentValue = false,
            Flag = "gun_autotp",
            Callback = function(v) state.autoTp = v end,
        })
        ctx.RegisterToggle(autoTpToggle)

        Tab:CreateSection("Действия")

        Tab:CreateToggle({
            Name = "Уведомление когда упал пистолет",
            CurrentValue = false,
            Flag = "gun_notify",
            Callback = function(v) state.notifyDrop = v end,
        })

        Tab:CreateParagraph({
            Title = "Статус",
            Content = "Карта: определяется...\nПистолет: ищется...",
        })

        -- Обновление статуса в UI раз в секунду
        task.spawn(function()
            while isAlive() do
                task.wait(1)
                if not isAlive() then break end

                local mapName = state.currentMap and state.currentMap.Name or "не найдена"
                local gun = findGunDrop(state.currentMap)
                local gunStatus = gun and "найден" or "нет"

                pcall(function()
                    -- Просто обновляем текст параграфа, если он доступен
                    -- Rayfield не даёт прямого API для обновления параграфа,
                    -- поэтому оставим как есть или можно удалить/создать заново
                end)
            end
        end)
    end
}
