-- Aimbot.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local state = {
    enabled     = false,
    targetMode  = "Murderer",
    part        = "Head",
    visibleOnly = true,
    maxDist     = 500,
    fov         = 120,
    smoothness  = 0.18,
    showFov     = true,
    showLine    = true,
    fovColor    = Color3.fromRGB(255, 255, 255),
    lineColor   = Color3.fromRGB(255, 60, 60),
    fovThick    = 1.5,
    lineThick   = 1,
}

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = state.fovThick
fovCircle.NumSides = 72
fovCircle.Color = state.fovColor
fovCircle.Transparency = 1
fovCircle.Filled = false
fovCircle.Visible = false

local aimLine = Drawing.new("Line")
aimLine.Thickness = state.lineThick
aimLine.Color = state.lineColor
aimLine.Transparency = 0.7
aimLine.Visible = false

local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    if char:FindFirstChild("Knife") then return "Murderer" end
    if char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then return "Sheriff" end
    return "Innocent"
end

local function roleValid(player)
    if state.targetMode == "All" then return true end
    return getRole(player) == state.targetMode
end

local function getPart(player)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end

    if state.part == "Head" then
        return char:FindFirstChild("Head")
    elseif state.part == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif state.part == "Root" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head then return hrp end
        if not hrp then return head end
        local camPos = Camera.CFrame.Position
        return ((head.Position - camPos).Magnitude < (hrp.Position - camPos).Magnitude) and head or hrp
    end
end

local function isVisible(part)
    if not state.visibleOnly then return true end

    local origin = Camera.CFrame.Position
    local dir = part.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }

    local hit = Workspace:Raycast(origin, dir, params)
    if not hit then return true end

    return hit.Instance:IsDescendantOf(part.Parent)
end

local function pickTarget()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bestScore = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and roleValid(player) then
            local part = getPart(player)
            if part then
                local worldDist = (part.Position - myHRP.Position).Magnitude
                if worldDist <= state.maxDist and isVisible(part) then
                    local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        if screenDist <= state.fov and screenDist < bestScore then
                            bestScore = screenDist
                            best = {
                                player = player,
                                part = part,
                                screen = screen,
                                worldDist = worldDist,
                                screenDist = screenDist,
                            }
                        end
                    end
                end
            end
        end
    end

    return best
end

local function hideVisuals()
    pcall(function() fovCircle.Visible = false end)
    pcall(function() aimLine.Visible = false end)
end

local function onRender()
    if not ctx.Alive then
        hideVisuals()
        return
    end

    if state.showFov and state.enabled then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = state.fov
        fovCircle.Color = state.fovColor
        fovCircle.Thickness = state.fovThick
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end

    if not state.enabled then
        aimLine.Visible = false
        return
    end

    local target = pickTarget()
    if not target then
        aimLine.Visible = false
        return
    end

    local camPos = Camera.CFrame.Position
    local newCF = CFrame.new(camPos, target.part.Position)
    local s = math.clamp(state.smoothness, 0.01, 1)
    Camera.CFrame = Camera.CFrame:Lerp(newCF, s)

    if state.showLine then
        local screen, _ = Camera:WorldToViewportPoint(target.part.Position)
        aimLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        aimLine.To = Vector2.new(screen.X, screen.Y)
        aimLine.Color = state.lineColor
        aimLine.Thickness = state.lineThick
        aimLine.Visible = true
    else
        aimLine.Visible = false
    end
end

RunService.RenderStepped:Connect(onRender)

return {
    Init = function(ctx, Tab)
        ctx.RegisterShutdown("Aimbot", function(c)
            state.enabled = false
            hideVisuals()
            pcall(function() fovCircle:Remove() end)
            pcall(function() aimLine:Remove() end)
            task.wait(0.1)
        end)

        Tab:CreateSection("Основное")

        local mainToggle = Tab:CreateToggle({
            Name = "Enable Aimbot",
            CurrentValue = false,
            Flag = "aim_enabled",
            Callback = function(v)
                state.enabled = v
                if not v then hideVisuals() end
            end,
        })
        ctx.RegisterToggle(mainToggle)

        Tab:CreateSection("Цель")

        Tab:CreateDropdown({
            Name = "Кого аимить",
            Options = {"Murderer", "Sheriff", "Innocent", "All"},
            CurrentOption = {"Murderer"},
            Flag = "aim_target",
            Callback = function(opt) state.targetMode = opt end,
        })

        Tab:CreateDropdown({
            Name = "Часть тела",
            Options = {"Head", "Torso", "Root", "Nearest"},
            CurrentOption = {"Head"},
            Flag = "aim_part",
            Callback = function(opt) state.part = opt end,
        })

        Tab:CreateToggle({
            Name = "Только видимые",
            CurrentValue = true,
            Flag = "aim_visible",
            Callback = function(v) state.visibleOnly = v end,
        })

        Tab:CreateSlider({
            Name = "Макс. дистанция",
            Range = {50, 2000},
            Increment = 50,
            Suffix = " studs",
            CurrentValue = 500,
            Flag = "aim_maxdist",
            Callback = function(v) state.maxDist = v end,
        })

        Tab:CreateSection("Настройки")

        Tab:CreateSlider({
            Name = "FOV",
            Range = {10, 800},
            Increment = 5,
            Suffix = " px",
            CurrentValue = 120,
            Flag = "aim_fov",
            Callback = function(v) state.fov = v end,
        })

        Tab:CreateSlider({
            Name = "Smoothness",
            Range = {0.01, 1},
            Increment = 0.01,
            CurrentValue = 0.18,
            Flag = "aim_smooth",
            Callback = function(v) state.smoothness = v end,
        })

        Tab:CreateSection("Визуал")

        Tab:CreateToggle({
            Name = "FOV круг",
            CurrentValue = true,
            Flag = "aim_showfov",
            Callback = function(v) state.showFov = v end,
        })

        Tab:CreateColorPicker({
            Name = "FOV цвет",
            Color = state.fovColor,
            Flag = "aim_fovcolor",
            Callback = function(c) state.fovColor = c end,
        })

        Tab:CreateSlider({
            Name = "FOV толщина",
            Range = {1, 5},
            Increment = 0.5,
            CurrentValue = 1.5,
            Flag = "aim_fovthick",
            Callback = function(v) state.fovThick = v end,
        })

        Tab:CreateToggle({
            Name = "Линия до цели",
            CurrentValue = true,
            Flag = "aim_showline",
            Callback = function(v) state.showLine = v end,
        })

        Tab:CreateColorPicker({
            Name = "Линия цвет",
            Color = state.lineColor,
            Flag = "aim_linecolor",
            Callback = function(c) state.lineColor = c end,
        })

        Tab:CreateSlider({
            Name = "Линия толщина",
            Range = {1, 5},
            Increment = 0.5,
            CurrentValue = 1,
            Flag = "aim_linethick",
            Callback = function(v) state.lineThick = v end,
        })
    end
}
