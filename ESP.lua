-- ESP.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Ctx = nil

local COLORS = {
    Murderer = Color3.fromRGB(255, 40, 40),
    Sheriff  = Color3.fromRGB(60, 140, 255),
    Innocent = Color3.fromRGB(80, 255, 120),
}

local state = {
    players      = false,
    showName     = true,
    showRole     = true,
    showDist     = false,
    fillAlpha    = 0.55,
    outlineAlpha = 0,
}

local function isAlive()
    if not Ctx then return false end
    return Ctx.Alive == true
end

local function getRole(player)
    local char = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")

    local function hasTool(toolName)
        local target = toolName:lower()
        for _, container in ipairs({char, backpack}) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and item.Name:lower() == target then
                        return true
                    end
                end
            end
        end
        return false
    end

    if hasTool("Knife") then return "Murderer" end
    if hasTool("Gun") or hasTool("Revolver") then return "Sheriff" end
    return "Innocent"
end

local function roleText(role)
    if role == "Murderer" then return "Murderer 🔪" end
    if role == "Sheriff" then return "Sheriff 🔫" end
    return "Innocent 👤"
end

local function distanceTo(player)
    local myChar = LocalPlayer.Character
    local hisChar = player.Character
    if not myChar or not hisChar then return 0 end
    local a = myChar:FindFirstChild("HumanoidRootPart")
    local b = hisChar:FindFirstChild("HumanoidRootPart")
    if not a or not b then return 0 end
    return math.floor((a.Position - b.Position).Magnitude)
end

local function clearPlayer(player)
    local char = player.Character
    if not char then return end
    local hl = char:FindFirstChild("MM2_ESP")
    if hl then hl:Destroy() end
    local head = char:FindFirstChild("Head")
    if head then
        local bb = head:FindFirstChild("MM2_ESP_Name")
        if bb then bb:Destroy() end
    end
end

local function applyPlayer(player)
    if not isAlive() then return end
    if not state.players then return end
    if player == LocalPlayer then return end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local role = getRole(player)
    local color = COLORS[role] or COLORS.Innocent

    local hl = char:FindFirstChild("MM2_ESP")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "MM2_ESP"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
    end
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = state.fillAlpha
    hl.OutlineTransparency = state.outlineAlpha

    local head = char:FindFirstChild("Head")
    if not head then return end

    local lines = {}
    if state.showName then table.insert(lines, player.Name) end
    if state.showRole then table.insert(lines, roleText(role)) end
    if state.showDist then table.insert(lines, distanceTo(player) .. " studs") end

    if #lines == 0 then
        local bb = head:FindFirstChild("MM2_ESP_Name")
        if bb then bb:Destroy() end
        return
    end

    local bb = head:FindFirstChild("MM2_ESP_Name")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "MM2_ESP_Name"
        bb.Size = UDim2.new(0, 220, 0, 60)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = bb
    end

    local label = bb:FindFirstChild("Label")
    if label then label.Text = table.concat(lines, "\n") end
end

local function clearAllPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        clearPlayer(p)
    end
end

local function refreshPlayers()
    clearAllPlayers()
    if state.players and isAlive() then
        for _, p in ipairs(Players:GetPlayers()) do
            applyPlayer(p)
        end
    end
end

local function bindPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if isAlive() then applyPlayer(player) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do bindPlayer(p) end
Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(clearPlayer)

task.spawn(function()
    while isAlive() do
        task.wait(0.4)
        if isAlive() and state.players then
            for _, p in ipairs(Players:GetPlayers()) do
                applyPlayer(p)
            end
        end
    end
    clearAllPlayers()
end)

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("ESP", function(c)
            state.players = false
            clearAllPlayers()
            task.wait(0.15)
        end)

        Tab:CreateSection("Игроки")

        local espToggle = Tab:CreateToggle({
            Name = "Player ESP",
            CurrentValue = false,
            Flag = "esp_players",
            Callback = function(v)
                state.players = v
                if v then
                    for _, p in ipairs(Players:GetPlayers()) do
                        applyPlayer(p)
                    end
                else
                    clearAllPlayers()
                end
            end,
        })
        ctx.RegisterToggle(espToggle)

        Tab:CreateToggle({
            Name = "Show Name",
            CurrentValue = true,
            Flag = "esp_name",
            Callback = function(v) state.showName = v; refreshPlayers() end,
        })

        Tab:CreateToggle({
            Name = "Show Role",
            CurrentValue = true,
            Flag = "esp_role",
            Callback = function(v) state.showRole = v; refreshPlayers() end,
        })

        Tab:CreateToggle({
            Name = "Show Distance",
            CurrentValue = false,
            Flag = "esp_dist",
            Callback = function(v) state.showDist = v; refreshPlayers() end,
        })

        Tab:CreateSection("Настройки цвета")

        Tab:CreateSlider({
            Name = "Fill Transparency",
            Range = {0, 1},
            Increment = 0.05,
            CurrentValue = 0.55,
            Flag = "esp_fill",
            Callback = function(v)
                state.fillAlpha = v
                refreshPlayers()
            end,
        })

        Tab:CreateSlider({
            Name = "Outline Transparency",
            Range = {0, 1},
            Increment = 0.05,
            CurrentValue = 0,
            Flag = "esp_outline",
            Callback = function(v)
                state.outlineAlpha = v
                refreshPlayers()
            end,
        })
    end
}
