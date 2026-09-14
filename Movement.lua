-- Movement.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Ctx = nil

local fly = {
    enabled = false,
    speed = 50,
    bv = nil,
}

local noclip = {
    enabled = false,
}

local function isAlive()
    if not Ctx then return false end
    return Ctx.Alive == true
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if fly.bv then fly.bv:Destroy() end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "MM2_Fly"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    fly.bv = bv

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
end

local function stopFly()
    if fly.bv then
        fly.bv:Destroy()
        fly.bv = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

local function updateFly()
    if not fly.enabled or not isAlive() then
        if fly.bv then stopFly() end
        return
    end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not fly.bv or fly.bv.Parent ~= hrp then
        startFly()
    end
    if not fly.bv then return end

    local direction = Vector3.zero
    local cf = Camera.CFrame

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end

    if direction.Magnitude > 0 then
        fly.bv.Velocity = direction.Unit * fly.speed
    else
        fly.bv.Velocity = Vector3.zero
    end
end

local function updateNoclip()
    if not noclip.enabled or not isAlive() then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not isAlive() then
        if fly.bv then stopFly() end
        return
    end
    updateFly()
    updateNoclip()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if fly.enabled and isAlive() then startFly() end
end)

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("Movement", function(c)
            fly.enabled = false
            noclip.enabled = false
            stopFly()
            task.wait(0.1)
        end)

        Tab:CreateSection("Fly")

        local flyToggle = Tab:CreateToggle({
            Name = "Enable Fly",
            CurrentValue = false,
            Flag = "fly_enabled",
            Callback = function(v)
                fly.enabled = v
                if v then startFly() else stopFly() end
            end,
        })
        ctx.RegisterToggle(flyToggle)

        Tab:CreateSlider({
            Name = "Fly Speed",
            Range = {10, 300},
            Increment = 5,
            Suffix = " studs",
            CurrentValue = 50,
            Flag = "fly_speed",
            Callback = function(v) fly.speed = v end,
        })

        Tab:CreateParagraph({
            Title = "Управление",
            Content = "WASD — движение\nSpace — вверх\nLeftShift — вниз",
        })

        Tab:CreateSection("Noclip")

        local noclipToggle = Tab:CreateToggle({
            Name = "Enable Noclip",
            CurrentValue = false,
            Flag = "noclip_enabled",
            Callback = function(v) noclip.enabled = v end,
        })
        ctx.RegisterToggle(noclipToggle)
    end
}
