-- ========================================================
-- MURDER MYSTERY 2 | ULTIMATE RAYFIELD ESP v6.6 (SOLARA)
-- Player ESP (Highlight + BoxAdornment) + Roles + Gun
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local isEspEnabled = false
local autoPickupActive = false

-- ========================================================
-- MAP NAME REGISTRY
-- ========================================================

local MAP_NAMES = {
    "Bank2", "Bank_2",
    "BioLab", "Bio_Lab",
    "Factory",
    "Hospital3", "Hospital_3",
    "Hotel2", "Hotel_2",
    "House2", "House_2",
    "Mansion2", "Mansion_2",
    "MilBase", "Mil_Base", "MilitaryBase",
    "Office3", "Office_3",
    "PoliceStation", "Police_Station",
    "ResearchFacility", "Research_Facility",
    "Workplace",
    "Manor",
    "Farmhouse", "Farm_House",
    "Mineshaft", "Mine_Shaft",
    "Barn", "BarnInfection",
    "VampiresVillage", "VampireVillage", "Vampires_Village",
    "VampiresCastle", "VampireCastle", "Vampires_Castle",
    "Spaceship", "SpaceShip",
    "Workshop", "WorkShop",
    "LogCabin", "Log_Cabin",
    "TrainStation", "Train_Station",
    "IceCastle", "Ice_Castle",
    "SkiLodge", "Ski_Lodge",
    "ChristmasInItaly", "Christmas_In_Italy", "Italy",
    "BeachResort", "Beach_Resort",
    "Yacht",
    "Bank",
    "Hospital", "Hospital2", "Hospital_2",
    "Hotel", "House",
    "Lab2", "Lab_2", "Lab",
    "Mansion",
    "Office2", "Office_2",
    "Pond",
    "NStudio", "N_Studio",
}

-- ========================================================
-- 1. CLEANUP OLD ESP TAGS
-- ========================================================

if getgenv().SolaraMM2Visuals then
    getgenv().SolaraMM2Visuals:Disconnect()
    getgenv().SolaraMM2Visuals = nil
end

local function cleanOldESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local head = char:FindFirstChild("Head")
            local oldTag = head and head:FindFirstChild("Solara_MM2_Tag")
            if oldTag then oldTag:Destroy() end
            local oldHl = char:FindFirstChild("Solara_Body_Highlight")
            if oldHl then oldHl:Destroy() end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local oldBox = hrp and hrp:FindFirstChild("Solara_Body_Box")
            if oldBox then oldBox:Destroy() end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Solara_Gun_Highlight" or obj.Name == "Solara_Gun_Tag" then
            obj:Destroy()
        end
    end
end
cleanOldESP()

-- ========================================================
-- 2. COLOR PALETTE
-- ========================================================

local COLOR_MURDERER  = Color3.fromRGB(255, 0, 50)
local COLOR_SHERIFF   = Color3.fromRGB(0, 150, 255)
local COLOR_INNOCENT  = Color3.fromRGB(0, 255, 150)
local COLOR_GUNDROP   = Color3.fromRGB(255, 215, 0)

-- ========================================================
-- 3. ROLE DETECTION
-- ========================================================

local function getPlayerRoleData(player)
    local bp = player:FindFirstChild("Backpack")
    local char = player.Character
    local hasKnife, hasGun = false, false

    if bp then
        if bp:FindFirstChild("Knife") then hasKnife = true end
        if bp:FindFirstChild("Gun") then hasGun = true end
    end
    if char then
        if char:FindFirstChild("Knife") then hasKnife = true end
        if char:FindFirstChild("Gun") then hasGun = true end
    end

    if hasKnife then
        return "MURDERER", COLOR_MURDERER
    elseif hasGun then
        return "SHERIFF", COLOR_SHERIFF
    else
        return "INNOCENT", COLOR_INNOCENT
    end
end

-- ========================================================
-- 4. PLAYER ESP (Highlight + BoxHandleAdornment + Billboard)
-- ========================================================

local function updateOrCreateESP(player, char, roleText, roleColor, distance)
    -- 4a. Highlight (character glow)
    local highlight = char:FindFirstChild("Solara_Body_Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Solara_Body_Highlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
    end
    highlight.FillColor = roleColor
    highlight.OutlineColor = roleColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0

    -- 4b. BoxHandleAdornment on HumanoidRootPart (reliable fallback)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local box = hrp:FindFirstChild("Solara_Body_Box")
        if not box then
            box = Instance.new("BoxHandleAdornment")
            box.Name = "Solara_Body_Box"
            box.Adornee = hrp
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Size = hrp.Size
            box.Transparency = 0.7
            box.Parent = hrp
        end
        box.Color3 = roleColor
    end

    -- 4c. Billboard with name + role + distance
    local head = char:FindFirstChild("Head")
    if not head then return end

    local billboard = head:FindFirstChild("Solara_MM2_Tag")
    local textLabel
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "Solara_MM2_Tag"
        billboard.Size = UDim2.new(0, 220, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3.0, 0)
        billboard.LightInfluence = 0
        billboard.MaxDistance = 500

        textLabel = Instance.new("TextLabel")
        textLabel.Name = "InfoLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 16
        textLabel.TextScaled = false
        textLabel.Parent = billboard
        billboard.Parent = head
    else
        textLabel = billboard:FindFirstChild("InfoLabel")
    end
    if textLabel then
        textLabel.TextColor3 = roleColor
        textLabel.Text = string.format("%s\n[%s] - %d m", player.Name, roleText, distance)
    end
end

-- ========================================================
-- 5. MAP LOOKUP + GUNDROP FINDER
-- ========================================================

local function findMapFolder()
    for _, mapName in ipairs(MAP_NAMES) do
        local folder = workspace:FindFirstChild(mapName)
        if folder then
            return folder, mapName
        end
    end
    return nil, nil
end

local function findGunDrop()
    local mapFolder = findMapFolder()
    if not mapFolder then return nil end
    return mapFolder:FindFirstChild("GunDrop")
end

-- ========================================================
-- 6. EXTRACT BasePart FROM GunDrop
-- ========================================================

local function getGunDropPart(gunDrop)
    if not gunDrop then return nil end

    if gunDrop:IsA("BasePart") then
        return gunDrop
    elseif gunDrop:IsA("Tool") then
        local handle = gunDrop:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then return handle end
        return gunDrop:FindFirstChildWhichIsA("BasePart")
    elseif gunDrop:IsA("Model") then
        return gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

-- ========================================================
-- 7. GUN ESP
-- ========================================================

local function updateGunESP(gunPart, myHrp)
    if not gunPart or not gunPart.Parent then return end

    local distance = math.floor((myHrp.Position - gunPart.Position).Magnitude)

    local highlight = gunPart:FindFirstChild("Solara_Gun_Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Solara_Gun_Highlight"
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = gunPart
    end
    highlight.FillColor = COLOR_GUNDROP
    highlight.OutlineColor = COLOR_GUNDROP

    local box = gunPart:FindFirstChild("Solara_Gun_Box")
    if not box then
        box = Instance.new("BoxHandleAdornment")
        box.Name = "Solara_Gun_Box"
        box.Adornee = gunPart
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = gunPart.Size
        box.Transparency = 0.6
        box.Parent = gunPart
    end
    box.Color3 = COLOR_GUNDROP

    local billboard = gunPart:FindFirstChild("Solara_Gun_Tag")
    local textLabel
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "Solara_Gun_Tag"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.LightInfluence = 0

        textLabel = Instance.new("TextLabel")
        textLabel.Name = "InfoLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 16
        textLabel.Parent = billboard
        billboard.Parent = gunPart
    else
        textLabel = billboard:FindFirstChild("InfoLabel")
    end
    if textLabel then
        textLabel.TextColor3 = COLOR_GUNDROP
        textLabel.Text = string.format("SHERIFF GUN\n[%d m]", distance)
    end
end

-- ========================================================
-- 8. RENDER LOOP
-- ========================================================

getgenv().SolaraMM2Visuals = RunService.RenderStepped:Connect(function()
    if not isEspEnabled then return end

    local myChar = localPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char and char.Parent then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = math.floor((myHrp.Position - hrp.Position).Magnitude)
                    local roleText, roleColor = getPlayerRoleData(player)
                    updateOrCreateESP(player, char, roleText, roleColor, distance)
                end
            end
        end
    end

    local gunDrop = findGunDrop()
    if gunDrop then
        local gunPart = getGunDropPart(gunDrop)
        if gunPart then
            updateGunESP(gunPart, myHrp)
        end
    end
end)

-- ========================================================
-- 9. RAYFIELD UI
-- ========================================================

local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then
    warn("[Solara ESP Error]: Failed to load Rayfield UI.")
    return
end

local Window = Rayfield:CreateWindow({
   Name = "Murder Mystery 2 | Custom ESP",
   LoadingTitle = "Loading Monolith ESP...",
   LoadingSubtitle = "by PROHOR & AUDITORS",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

local TabVisuals  = Window:CreateTab("Visuals", nil)
local TabGun      = Window:CreateTab("Gun", nil)
local TabSettings = Window:CreateTab("Settings", nil)

TabVisuals:CreateToggle({
   Name = "Enable Smart ESP (Players + Gun)",
   CurrentValue = false,
   Flag = "MM2EspMasterToggle",
   Callback = function(stateValue)
      isEspEnabled = stateValue
      if not isEspEnabled then cleanOldESP() end
   end,
})

TabGun:CreateButton({
   Name = "Detect Current Map",
   Callback = function()
       local folder, name = findMapFolder()
       if folder then
           print("[Map] Detected:", name, "| Class:", folder.ClassName)
           print("[Map] Full path:", folder:GetFullName())
           local gun = folder:FindFirstChild("GunDrop")
           print("[Map] GunDrop inside:", gun and gun:GetFullName() or "not present")
       else
           print("[Map] No map folder from MAP_NAMES found in workspace")
           print("[Map] Top-level folders:")
           for _, obj in ipairs(workspace:GetChildren()) do
               if not Players:GetPlayerFromCharacter(obj)
                  and (obj:IsA("Folder") or obj:IsA("Model")) then
                   print("   ", obj.Name, "|", obj.ClassName)
               end
           end
       end
   end,
})

TabGun:CreateButton({
   Name = "Diagnose: locate GunDrop",
   Callback = function()
       local folder, name = findMapFolder()
       if not folder then
           print("[Diagnose] No map folder detected. Use 'Detect Current Map'.")
           return
       end
       print("[Diagnose] Map:", name, "| Path:", folder:GetFullName())
       local gun = folder:FindFirstChild("GunDrop")
       if not gun then
           print("[Diagnose] GunDrop not inside map folder right now")
           return
       end
       print("=== GunDrop Found ===")
       print("Full path:", gun:GetFullName())
       print("Class:", gun.ClassName)
       print("Position:", tostring(gun:GetPivot().Position))
       for _, d in ipairs(gun:GetDescendants()) do
           print("  ->", d.Name, "|", d.ClassName)
       end
   end,
})

TabGun:CreateButton({
   Name = "Pickup Gun (teleport)",
   Callback = function()
       local gunDrop = findGunDrop()
       if not gunDrop then
           Rayfield:Notify({Title = "Gun", Content = "GunDrop not found", Duration = 2})
           return
       end
       local gunPart = getGunDropPart(gunDrop)
       if not gunPart then
           Rayfield:Notify({Title = "Gun", Content = "No BasePart inside GunDrop", Duration = 2})
           return
       end
       local myChar = localPlayer.Character
       local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
       if not myHrp then return end
       for i = 1, 3 do
           myHrp.CFrame = CFrame.new(gunPart.Position)
           task.wait(0.1)
       end
       Rayfield:Notify({Title = "Gun", Content = "Teleported", Duration = 2})
   end,
})

TabGun:CreateToggle({
   Name = "Auto Pickup Gun",
   CurrentValue = false,
   Flag = "MM2AutoPickupGun",
   Callback = function(stateValue)
       autoPickupActive = stateValue
       if not stateValue then return end
       task.spawn(function()
           while autoPickupActive do
               local gunDrop = findGunDrop()
               if gunDrop then
                   local gunPart = getGunDropPart(gunDrop)
                   if gunPart then
                       local myChar = localPlayer.Character
                       local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                       if myHrp then
                           myHrp.CFrame = CFrame.new(gunPart.Position)
                       end
                   end
               end
               task.wait(0.3)
           end
       end)
   end,
})

TabSettings:CreateButton({
   Name = "Close Hub Completely",
   Callback = function()
       isEspEnabled = false
       autoPickupActive = false
       if getgenv().SolaraMM2Visuals then
           getgenv().SolaraMM2Visuals:Disconnect()
           getgenv().SolaraMM2Visuals = nil
       end
       cleanOldESP()
       Rayfield:Destroy()
   end,
})

print("[Monolith v6.6] Loaded - ESP with Highlight + BoxAdornment")
