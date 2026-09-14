-- RoleReveal.lua

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Ctx = nil

local state = {
    enabled  = false,
    showDist = false,
}

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

local roleLines = nil

local function buildText()
    if not state.enabled then return "Отключено" end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    local lines = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local role = getRole(player)
        local line = ("%s — %s"):format(player.Name, role)

        if state.showDist and myHRP and player.Character then
            local hisHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if hisHRP then
                local dist = math.floor((hisHRP.Position - myHRP.Position).Magnitude)
                line = line .. (" [%d studs]"):format(dist)
            end
        end

        table.insert(lines, line)
    end

    return table.concat(lines, "\n")
end

task.spawn(function()
    while isAlive() do
        task.wait(0.5)
        if roleLines and state.enabled then
            pcall(function() roleLines:Set(buildText()) end)
        elseif roleLines then
            pcall(function() roleLines:Set("Отключено") end)
        end
    end
end)

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("RoleReveal", function(c)
            state.enabled = false
            if roleLines then
                pcall(function() roleLines:Set("Отключено") end)
            end
            task.wait(0.1)
        end)

        Tab:CreateSection("Role Reveal")

        local toggle = Tab:CreateToggle({
            Name = "Enable Role Reveal",
            CurrentValue = false,
            Flag = "rr_enabled",
            Callback = function(v) state.enabled = v end,
        })
        ctx.RegisterToggle(toggle)

        Tab:CreateToggle({
            Name = "Показывать дистанцию",
            CurrentValue = false,
            Flag = "rr_dist",
            Callback = function(v) state.showDist = v end,
        })

        roleLines = Tab:CreateParagraph({
            Title = "Игроки",
            Content = "Отключено",
        })
    end
}
