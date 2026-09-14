-- SilentAim.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Ctx = nil

local state = {
    enabled     = false,
    targetRole  = "Murderer",
    part        = "Head",
    fov         = 150,
    maxDist     = 500,
    visibleOnly = true,
    showFov     = true,
    fovColor    = Color3.fromRGB(255, 100, 100),
    currentTarget = nil,
}

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.NumSides = 72
fovCircle.Color = state.fovColor
fovCircle.Transparency = 1
fovCircle.Filled = false
fovCircle.Visible = false

local hookInstalled = false

local function isAlive()
    if not Ctx then return false end
    return Ctx.Alive == true
end

local function getRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    if char:FindFirstChild("Knife") then return "Murderer" end
    if char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") then return "Sheriff" end
    return "Innocent"
end

local function roleValid(player)
    if state.targetRole == "All" then return true end
    return getRole(player) == state.targetRole
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
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
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
                            best = part
                        end
                    end
                end
            end
        end
    end

    return best
end

local function installHook()
    if hookInstalled then return true end

    if type(getrawmetatable) ~= "function" then
        return false
    end

    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then
        return false
    end

    local oldIndex = mt.__index
    if not oldIndex then
        return false
    end

    local function hookFn(self, key)
        -- пропускаем вызовы от нашего скрипта
        if type(checkcaller) == "function" and checkcaller() then
            return oldIndex(self, key)
        end

        if state.enabled and state.currentTarget and isAlive() then
            if key == "Hit" then
                return CFrame.new(state.currentTarget.Position)
            elseif key == "Target" then
                return state.currentTarget
            end
        end

        return oldIndex(self, key)
    end

    if type(hookmetamethod) == "function" then
        local okHook = pcall(hookmetamethod, game, "__index", hookFn)
        if okHook then
            hookInstalled = true
            return true
        end
    end

    -- fallback: вручную через setreadonly
    if type(setreadonly) ~= "function" then
        return false
    end

    local ok1 = pcall(setreadonly, mt, false)
    if not ok1 then return false end

    local wrapped = hookFn
    if type(newcclosure) == "function" then
        wrapped = newcclosure(hookFn)
    end

    mt.__index = wrapped

    pcall(setreadonly, mt, true)

    hookInstalled = true
    return true
end

RunService.RenderStepped:Connect(function()
    if not isAlive() then
        pcall(function() fovCircle.Visible = false end)
        return
    end

    if state.enabled then
        state.currentTarget = pickTarget()
    else
        state.currentTarget = nil
    end

    if state.showFov and state.enabled then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius = state.fov
        fovCircle.Color = state.fovColor
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("SilentAim", function(c)
            state.enabled = false
            state.currentTarget = nil
            pcall(function() fovCircle.Visible = false end)
            pcall(function() fovCircle:Remove() end)
            task.wait(0.1)
        end)

        Tab:CreateSection("Silent Aim")

        local toggle = Tab:CreateToggle({
            Name = "Enable Silent Aim",
            CurrentValue = false,
            Flag = "sa_enabled",
            Callback = function(v)
                if v then
                    if not hookInstalled then
                        local ok = installHook()
                        if not ok then
                            Rayfield:Notify({
                                Title = "SilentAim",
                                Content = "Инжектор не поддерживает hook метаметода game.__index",
                                Duration = 6
                            })
                        end
                    end
                end
                state.enabled = v
                if not v then state.currentTarget = nil end
            end,
        })
        ctx.RegisterToggle(toggle)

        Tab:CreateDropdown({
            Name = "Кого аимить",
            Options = {"Murderer", "Sheriff", "Innocent", "All"},
            CurrentOption = {"Murderer"},
            Flag = "sa_role",
            Callback = function(opt) state.targetRole = opt end,
        })

        Tab:CreateDropdown({
            Name = "Часть тела",
            Options = {"Head", "Torso", "Root", "Nearest"},
            CurrentOption = {"Head"},
            Flag = "sa_part",
            Callback = function(opt) state.part = opt end,
        })

        Tab:CreateToggle({
            Name = "Только видимые",
            CurrentValue = true,
            Flag = "sa_visible",
            Callback = function(v) state.visibleOnly = v end,
        })

        Tab:CreateSlider({
            Name = "FOV",
            Range = {10, 800},
            Increment = 5,
            Suffix = " px",
            CurrentValue = 150,
            Flag = "sa_fov",
            Callback = function(v) state.fov = v end,
        })

        Tab:CreateSlider({
            Name = "Макс. дистанция",
            Range = {50, 2000},
            Increment = 50,
            Suffix = " studs",
            CurrentValue = 500,
            Flag = "sa_maxdist",
            Callback = function(v) state.maxDist = v end,
        })

        Tab:CreateToggle({
            Name = "FOV круг",
            CurrentValue = true,
            Flag = "sa_showfov",
            Callback = function(v) state.showFov = v end,
        })

        Tab:CreateColorPicker({
            Name = "FOV цвет",
            Color = state.fovColor,
            Flag = "sa_fovcolor",
            Callback = function(c) state.fovColor = c end,
        })
    end
}
