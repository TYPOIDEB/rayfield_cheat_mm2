-- Spejump.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Ctx = nil

local DEFAULTS = {
    walkSpeed = 16,
    jumpPower = 50,
    useJumpPower = true,
}

local state = {
    speedEnabled = false,
    speedValue   = 16,
    jumpEnabled  = false,
    jumpValue    = 50,
    savedSpeed   = nil,
    savedJump    = nil,
    savedUseJP   = nil,
}

local function isAlive()
    if not Ctx then return false end
    return Ctx.Alive == true
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function snapshot()
    local hum = getHumanoid()
    if not hum then return end
    state.savedSpeed = hum.WalkSpeed
    state.savedJump = hum.JumpPower
    state.savedUseJP = hum.UseJumpPower
end

local function applySpeed()
    local hum = getHumanoid()
    if not hum then return end
    hum.WalkSpeed = state.speedValue
end

local function applyJump()
    local hum = getHumanoid()
    if not hum then return end
    hum.UseJumpPower = true
    hum.JumpPower = state.jumpValue
end

local function restoreSpeed()
    local hum = getHumanoid()
    if not hum then return end
    if state.savedSpeed ~= nil then
        hum.WalkSpeed = state.savedSpeed
    else
        hum.WalkSpeed = DEFAULTS.walkSpeed
    end
end

local function restoreJump()
    local hum = getHumanoid()
    if not hum then return end
    if state.savedJump ~= nil then
        hum.JumpPower = state.savedJump
    else
        hum.JumpPower = DEFAULTS.jumpPower
    end
    if state.savedUseJP ~= nil then
        hum.UseJumpPower = state.savedUseJP
    end
end

local function applyAll()
    if not isAlive() then return end
    if state.speedEnabled then applySpeed() end
    if state.jumpEnabled then applyJump() end
end

RunService.Heartbeat:Connect(function()
    if not isAlive() then return end
    if state.speedEnabled or state.jumpEnabled then
        applyAll()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not isAlive() then return end
    -- сбрасываем сохранённые значения — на новом персонаже они дефолтные
    state.savedSpeed = nil
    state.savedJump = nil
    state.savedUseJP = nil
    if state.speedEnabled or state.jumpEnabled then
        applyAll()
    end
end)

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("Spejump", function(c)
            state.speedEnabled = false
            state.jumpEnabled = false
            restoreSpeed()
            restoreJump()
            task.wait(0.1)
        end)

        Tab:CreateSection("Скорость")

        Tab:CreateSlider({
            Name = "Walk Speed",
            Range = {16, 300},
            Increment = 1,
            Suffix = " studs",
            CurrentValue = 16,
            Flag = "sj_speed_value",
            Callback = function(v)
                state.speedValue = v
                if state.speedEnabled then applySpeed() end
            end,
        })

        local speedToggle = Tab:CreateToggle({
            Name = "Применить скорость",
            CurrentValue = false,
            Flag = "sj_speed_enabled",
            Callback = function(v)
                state.speedEnabled = v
                if v then
                    snapshot()
                    applySpeed()
                else
                    restoreSpeed()
                end
            end,
        })
        ctx.RegisterToggle(speedToggle)

        Tab:CreateSection("Прыжок")

        Tab:CreateSlider({
            Name = "Jump Power",
            Range = {50, 500},
            Increment = 1,
            Suffix = " power",
            CurrentValue = 50,
            Flag = "sj_jump_value",
            Callback = function(v)
                state.jumpValue = v
                if state.jumpEnabled then applyJump() end
            end,
        })

        local jumpToggle = Tab:CreateToggle({
            Name = "Применить прыжок",
            CurrentValue = false,
            Flag = "sj_jump_enabled",
            Callback = function(v)
                state.jumpEnabled = v
                if v then
                    snapshot()
                    applyJump()
                else
                    restoreJump()
                end
            end,
        })
        ctx.RegisterToggle(jumpToggle)

        Tab:CreateSection("Утилиты")

        Tab:CreateButton({
            Name = "Сбросить к дефолту",
            Callback = function()
                state.speedEnabled = false
                state.jumpEnabled = false
                state.speedValue = 16
                state.jumpValue = 50

                local hum = getHumanoid()
                if hum then
                    hum.WalkSpeed = DEFAULTS.walkSpeed
                    hum.JumpPower = DEFAULTS.jumpPower
                    hum.UseJumpPower = DEFAULTS.useJumpPower
                end

                pcall(function()
                    Rayfield.Flags["sj_speed_enabled"] = false
                    Rayfield.Flags["sj_jump_enabled"] = false
                    Rayfield.Flags["sj_speed_value"] = 16
                    Rayfield.Flags["sj_jump_value"] = 50
                end)
            end,
        })
    end
}
