-- RoleReveal.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Ctx = nil

local state = {
    enabled = false,
    gui     = nil,
    list    = nil,
    rows    = {},
}

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 80, 80),
    Sheriff  = Color3.fromRGB(80, 150, 255),
    Innocent = Color3.fromRGB(120, 255, 140),
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

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function buildGui()
    if state.gui then return end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2_RoleReveal"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 280, 0, 400)
    frame.Position = UDim2.new(0, 20, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 1
    stroke.Parent = frame

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Role Reveal"
    titleLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -30, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        state.enabled = false
        if state.gui then state.gui.Enabled = false end
        pcall(function() Rayfield.Flags["rr_enabled"] = false end)
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "List"
    scroll.Size = UDim2.new(1, -16, 1, -44)
    scroll.Position = UDim2.new(0, 8, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = scroll

    state.gui = gui
    state.list = scroll

    makeDraggable(frame, titleBar)
end

local function getOrCreateRow(player)
    if state.rows[player] and state.rows[player].Parent then
        return state.rows[player]
    end
    if not state.list then return nil end

    local row = Instance.new("Frame")
    row.Name = player.Name
    row.Size = UDim2.new(1, -8, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent = state.list

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 5)
    rc.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(0.6, -8, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 12
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = row

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "Role"
    roleLabel.Size = UDim2.new(0.4, -8, 1, 0)
    roleLabel.Position = UDim2.new(0.6, 0, 0, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = "Innocent"
    roleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    roleLabel.TextXAlignment = Enum.TextXAlignment.Right
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.TextSize = 12
    roleLabel.Parent = row

    state.rows[player] = row
    return row
end

local function clearRow(player)
    local row = state.rows[player]
    if row then
        pcall(function() row:Destroy() end)
        state.rows[player] = nil
    end
end

local function refresh()
    if not state.gui then return end
    if not state.enabled then
        state.gui.Enabled = false
        return
    end

    state.gui.Enabled = true

    local current = {}
    for _, player in ipairs(Players:GetPlayers()) do
        current[player] = true
        local row = getOrCreateRow(player)
        if row then
            local role = getRole(player)
            local roleLabel = row:FindFirstChild("Role")
            if roleLabel then
                roleLabel.Text = role
                roleLabel.TextColor3 = ROLE_COLORS[role] or Color3.new(1, 1, 1)
            end
        end
    end

    for player in pairs(state.rows) do
        if not current[player] then
            clearRow(player)
        end
    end
end

Players.PlayerRemoving:Connect(clearRow)

task.spawn(function()
    while isAlive() do
        task.wait(0.5)
        pcall(refresh)
    end
end)

return {
    Init = function(ctx, Tab)
        Ctx = ctx

        ctx.RegisterShutdown("RoleReveal", function(c)
            state.enabled = false
            if state.gui then
                pcall(function() state.gui:Destroy() end)
                state.gui = nil
            end
            state.list = nil
            state.rows = {}
            task.wait(0.1)
        end)

        Tab:CreateSection("Role Reveal")

        local toggle = Tab:CreateToggle({
            Name = "Enable Role Reveal",
            CurrentValue = false,
            Flag = "rr_enabled",
            Callback = function(v)
                state.enabled = v
                if v then
                    buildGui()
                    if state.gui then state.gui.Enabled = true end
                    task.spawn(function()
                        task.wait(0.1)
                        pcall(refresh)
                    end)
                else
                    if state.gui then state.gui.Enabled = false end
                end
            end,
        })
        ctx.RegisterToggle(toggle)

        Tab:CreateParagraph({
            Title = "Инфо",
            Content = "Окно перетаскивается за заголовок. X — закрыть."
        })
    end
}
