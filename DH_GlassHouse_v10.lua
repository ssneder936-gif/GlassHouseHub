-- ============================================================
--   DH DADDY'S GLASS HOUSE v10.1
--   WALLBANG | SILENT AIM | BOX/SKELETON FIX | NO LEAVER MSG
--   SNOWFLAKES FALL THROUGH MENU | NO AIMBOT THROUGH WALLS
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera

-- ===== DRAWING LIBRARY CHECK =====
local DrawingLib = nil
if Drawing and type(Drawing) == "table" and Drawing.new then
    DrawingLib = Drawing
end

-- ===== THEME PALETTE =====
local C = {
    accent      = Color3.fromRGB(148, 0, 255),
    accentDim   = Color3.fromRGB(90,  0, 160),
    accentHover = Color3.fromRGB(200, 60, 255),
    accentGlow  = Color3.fromRGB(180, 80, 255),
    bg          = Color3.fromRGB(12,  12,  18),
    bgPanel     = Color3.fromRGB(20,  20,  30),
    bgSection   = Color3.fromRGB(28,  28,  42),
    bgBtn       = Color3.fromRGB(38,  38,  55),
    bgBtnHover  = Color3.fromRGB(55,  30,  90),
    border      = Color3.fromRGB(80,  40, 140),
    borderGlow  = Color3.fromRGB(148, 0, 255),
    text        = Color3.fromRGB(235, 225, 255),
    textDim     = Color3.fromRGB(160, 145, 195),
    textHeader  = Color3.fromRGB(255, 255, 255),
    onGreen     = Color3.fromRGB(0,   210, 100),
    offRed      = Color3.fromRGB(200,  50,  50),
    snow        = Color3.fromRGB(230, 240, 255),
}

local espEnabled        = false
local mm2EspEnabled     = false
local mm2GunEspEnabled  = false
local skeletonEnabled   = false
local nameEnabled       = false
local healthEnabled     = false
local boxEnabled        = false
local chamsEnabled      = false
local teamEspEnabled    = false
local enemyColor        = C.accent
local enemyR, enemyG, enemyB = 148, 0, 255
local teamColor         = Color3.fromRGB(0, 220, 80)
local teamR, teamG, teamB = 0, 220, 80

local boxThickness      = 1.8   -- adjustable
local skeletonThickness = 1.4   -- adjustable
local tracerEnabled     = false
local tracerThickness   = 1.2

local aimbotFovColor    = C.accent
local fovR, fovG, fovB  = 148, 0, 255
local aimbotEnabled     = false
local wallbangEnabled   = false
local fov               = 200

local spinBotEnabled    = false
local spinSpeedDeg      = 360

local flickEnabled      = false
local flickInterval     = 0.5
local flickTargets, flickIndex, lastFlickTime = {}, 1, 0

local flightEnabled     = false
local flightSpeed       = 50
local flightConnection  = nil

local noclipEnabled     = false
local noclipSpeed       = 50
local noclipConnection  = nil
local originalCollisions= {}

local speedEnabled      = false
local walkSpeed         = 27
local defaultWalkSpeed  = 16

local jumpEnabled       = false
local jumpPower         = 50
local defaultJumpPower  = 50

-- ===== UTILITY =====
local function isBot(player)
    -- Roblox bots typically have no UserId or their name starts with "Bot" — game-specific heuristic
    -- Most common: NPC-style "players" added via script have a non-positive UserId
    return player.UserId <= 0
end

local function styleButton(btn, active)
    btn.BackgroundColor3 = active and C.accent or C.bgBtn
    btn.TextColor3       = C.text
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.ZIndex           = 3
    btn.AutoButtonColor  = false
    local corner = btn:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", btn)
    corner.CornerRadius  = UDim.new(0, 7)
    local stroke = btn:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", btn)
    stroke.Color         = active and C.borderGlow or C.border
    stroke.Thickness     = 1
    stroke.Transparency  = 0.5
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = C.bgBtnHover
        stroke.Color = C.accentGlow
        stroke.Transparency = 0
    end)
    btn.MouseLeave:Connect(function()
        local isActive = btn.BackgroundColor3 == C.accent
        btn.BackgroundColor3 = isActive and C.accent or C.bgBtn
        stroke.Color = C.border
        stroke.Transparency = 0.5
    end)
end

local function makeLabel(parent, text, size, pos, fontSize, bold, color)
    local lbl = Instance.new("TextLabel")
    lbl.Text                = text
    lbl.Size                = size
    lbl.Position            = pos
    lbl.BackgroundTransparency = 1
    lbl.TextColor3          = color or C.text
    lbl.Font                = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    lbl.TextSize            = fontSize or 13
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.ZIndex              = 3
    lbl.Parent              = parent
    return lbl
end

-- ===== FOV CIRCLE =====
local FOVCircleGui = Instance.new("ScreenGui")
FOVCircleGui.Name            = "DH_FOVCircle"
FOVCircleGui.Parent          = game.CoreGui
FOVCircleGui.IgnoreGuiInset  = true
FOVCircleGui.DisplayOrder    = 1000

local FOVCircleFrame         = Instance.new("Frame")
FOVCircleFrame.Size          = UDim2.new(0,0,0,0)
FOVCircleFrame.BackgroundTransparency = 1
FOVCircleFrame.BorderSizePixel = 0
FOVCircleFrame.Visible       = false
FOVCircleFrame.Parent        = FOVCircleGui

local FOVCorner              = Instance.new("UICorner")
FOVCorner.CornerRadius       = UDim.new(1,0)
FOVCorner.Parent             = FOVCircleFrame

local FOVStroke              = Instance.new("UIStroke")
FOVStroke.Thickness          = 2
FOVStroke.Color              = C.accent
FOVStroke.Transparency       = 0.35
FOVStroke.Parent             = FOVCircleFrame

local function updateFOVCircleAppearance(radius, visible)
    local screenSize = Camera.ViewportSize
    local center     = screenSize / 2
    local diameter   = radius * 2
    FOVCircleFrame.Size     = UDim2.new(0, diameter, 0, diameter)
    FOVCircleFrame.Position = UDim2.new(0, center.X - radius, 0, center.Y - radius)
    FOVCircleFrame.Visible  = visible
end

-- ===== MAIN GUI =====
local ScreenGui              = Instance.new("ScreenGui")
ScreenGui.Name               = "DH_Menu"
ScreenGui.Parent             = game.CoreGui
ScreenGui.DisplayOrder       = 100

local MENU_W, MENU_H         = 740, 580

local MainFrame              = Instance.new("Frame")
MainFrame.Size               = UDim2.new(0, MENU_W, 0, MENU_H)
MainFrame.Position           = UDim2.new(0.5, -MENU_W/2, 0.5, -MENU_H/2)
MainFrame.BackgroundColor3   = C.bg
MainFrame.BorderSizePixel    = 0
MainFrame.Active             = true
MainFrame.Draggable          = true
MainFrame.ClipsDescendants   = true
MainFrame.Parent             = ScreenGui

do -- outer glow stroke
    local s = Instance.new("UIStroke", MainFrame)
    s.Color       = C.borderGlow
    s.Thickness   = 1.5
    s.Transparency= 0.55
end
do
    local c = Instance.new("UICorner", MainFrame)
    c.CornerRadius = UDim.new(0, 12)
end

-- ===== DRIFTING ORBS ON MENU =====
local menuOrbData   = {}
local maxOrbs       = 30

local function spawnMenuOrb()
    local sz    = math.random(8, 20)
    local startY = math.random(-sz, MENU_H)
    local orb = Instance.new("Frame")
    orb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    orb.Size              = UDim2.new(0, sz, 0, sz)
    orb.Position          = UDim2.new(0, math.random(0, MENU_W - sz), 0, startY)
    orb.BorderSizePixel   = 0
    
    local corner = Instance.new("UICorner", orb)
    corner.CornerRadius = UDim.new(1, 0) -- Perfect circle
    
    -- ZIndex 2: above the menu bg (ZIndex 1) but below cards/buttons (ZIndex 3+)
    orb.ZIndex            = 2
    orb.Parent            = MainFrame
    
    local opacity = math.random(30, 70) / 100
    orb.BackgroundTransparency = 1 - opacity
    
    menuOrbData[orb] = {
        x       = math.random(0, MENU_W - sz),
        y       = startY,
        speed   = math.random(20, 50), -- Slower drift
        drift   = math.random(-15, 15),
    }
end

RunService.Heartbeat:Connect(function(dt)
    local count = 0
    for orb, d in pairs(menuOrbData) do
        count = count + 1
        d.y = d.y + (d.speed * dt)
        local newX = d.x + math.sin(tick() * 0.3 + d.drift) * 0.5
        orb.Position = UDim2.new(0, newX, 0, d.y)
        
        if d.y > MENU_H + 10 then
            orb:Destroy()
            menuOrbData[orb] = nil
        end
    end
    if count < maxOrbs then
        spawnMenuOrb()
    end
end)

-- ===== TITLE BAR =====
local TitleBar               = Instance.new("Frame")
TitleBar.Size                = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3    = C.bgPanel
TitleBar.BorderSizePixel     = 0
TitleBar.ZIndex              = 5
TitleBar.Parent              = MainFrame

do -- title bar bottom separator
    local sep = Instance.new("Frame", TitleBar)
    sep.Size             = UDim2.new(1,0,0,1)
    sep.Position         = UDim2.new(0,0,1,-1)
    sep.BackgroundColor3 = C.borderGlow
    sep.BorderSizePixel  = 0
    sep.BackgroundTransparency = 0.6
    sep.ZIndex = 6
end

-- Accent left stripe
local titleStripe = Instance.new("Frame", TitleBar)
titleStripe.Size             = UDim2.new(0, 4, 1, 0)
titleStripe.BackgroundColor3 = C.accent
titleStripe.BorderSizePixel  = 0
titleStripe.ZIndex           = 6
do
    local g = Instance.new("UIGradient", titleStripe)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accentGlow),
        ColorSequenceKeypoint.new(1, C.accentDim),
    })
    g.Rotation = 90
end

local TitleSnow  = Instance.new("TextLabel", TitleBar)
TitleSnow.Text   = "❄"
TitleSnow.Size   = UDim2.new(0, 28, 1, 0)
TitleSnow.Position = UDim2.new(0, 10, 0, 0)
TitleSnow.BackgroundTransparency = 1
TitleSnow.TextColor3 = C.snow
TitleSnow.Font   = Enum.Font.SourceSans
TitleSnow.TextSize = 22
TitleSnow.ZIndex = 6

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Text  = "DADDY'S GLASS HOUSE"
TitleLabel.Size  = UDim2.new(1, -160, 1, 0)
TitleLabel.Position = UDim2.new(0, 44, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = C.textHeader
TitleLabel.Font  = Enum.Font.GothamBlack
TitleLabel.TextSize = 17
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 6
do  -- gradient on title text color via a sub-label trick isn't possible in Roblox directly;
    -- so we add a version badge
    local ver = Instance.new("TextLabel", TitleBar)
    ver.Text  = "v10"
    ver.Size  = UDim2.new(0, 36, 0, 18)
    ver.Position = UDim2.new(0, 246, 0.5, -9)
    ver.BackgroundColor3 = C.accent
    ver.TextColor3 = Color3.new(1,1,1)
    ver.Font  = Enum.Font.GothamBold
    ver.TextSize = 11
    ver.ZIndex = 7
    ver.BackgroundTransparency = 0
    Instance.new("UICorner", ver).CornerRadius = UDim.new(0,4)
end

local TitleSnow2 = Instance.new("TextLabel", TitleBar)
TitleSnow2.Text  = "❄"
TitleSnow2.Size  = UDim2.new(0, 28, 1, 0)
TitleSnow2.Position = UDim2.new(0, 288, 0, 0)
TitleSnow2.BackgroundTransparency = 1
TitleSnow2.TextColor3 = C.snow
TitleSnow2.Font  = Enum.Font.SourceSans
TitleSnow2.TextSize = 18
TitleSnow2.ZIndex = 6

local function makeWinBtn(text, xOff, bgCol)
    local btn        = Instance.new("TextButton", TitleBar)
    btn.Text         = text
    btn.Size         = UDim2.new(0, 32, 0, 32)
    btn.Position     = UDim2.new(1, xOff, 0.5, -16)
    btn.BackgroundColor3 = bgCol
    btn.TextColor3   = Color3.new(1,1,1)
    btn.Font         = Enum.Font.GothamBold
    btn.TextSize     = 14
    btn.ZIndex       = 7
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.3 end)
    btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0 end)
    return btn
end

local MinimizeButton = makeWinBtn("—", -74, C.accentDim)
local CloseButton    = makeWinBtn("✕", -38, C.offRed)

local RestorePill    = Instance.new("TextButton", ScreenGui)
RestorePill.Text     = "❄ GH"
RestorePill.Size     = UDim2.new(0, 60, 0, 32)
RestorePill.Position = UDim2.new(0.88, 0, 0.04, 0)
RestorePill.BackgroundColor3 = C.accent
RestorePill.TextColor3 = Color3.new(1,1,1)
RestorePill.Font     = Enum.Font.GothamBold
RestorePill.TextSize = 13
RestorePill.Visible  = false
RestorePill.Draggable = true
RestorePill.ZIndex   = 10
Instance.new("UICorner", RestorePill).CornerRadius = UDim.new(0,16)

local function minimizeMenu() MainFrame.Visible = false; RestorePill.Visible = true end
local function restoreMenu()  MainFrame.Visible = true;  RestorePill.Visible = false end
MinimizeButton.MouseButton1Click:Connect(minimizeMenu)
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    FOVCircleGui:Destroy()
end)
RestorePill.MouseButton1Click:Connect(restoreMenu)

-- ===== TAB BAR =====
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size             = UDim2.new(1, 0, 0, 42)
TabBar.Position         = UDim2.new(0, 0, 0, 44)
TabBar.BackgroundColor3 = C.bgPanel
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 4

do -- tab bar bottom separator
    local sep = Instance.new("Frame", TabBar)
    sep.Size             = UDim2.new(1,0,0,1)
    sep.Position         = UDim2.new(0,0,1,-1)
    sep.BackgroundColor3 = C.border
    sep.BorderSizePixel  = 0
    sep.BackgroundTransparency = 0.4
    sep.ZIndex = 5
end

local tabDefs = {
    { key="AIMBOT", icon="🎯", label="AIMBOT" },
    { key="ESP",    icon="👁",  label="ESP"    },
    { key="PLAYER", icon="👤",  label="PLAYER" },
    { key="MISC",   icon="⚙",  label="MISC"   },
}
local tabButtons = {}

local function createTabBtn(def, idx)
    local btn            = Instance.new("TextButton", TabBar)
    btn.Text             = def.icon .. "  " .. def.label
    btn.Size             = UDim2.new(0, 120, 1, -6)
    btn.Position         = UDim2.new(0, 8 + (idx-1)*128, 0, 3)
    btn.BackgroundColor3 = C.bgBtn
    btn.TextColor3       = C.textDim
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.ZIndex           = 5
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    -- active indicator bar
    local indicator      = Instance.new("Frame", btn)
    indicator.Name       = "Indicator"
    indicator.Size       = UDim2.new(0.7, 0, 0, 3)
    indicator.Position   = UDim2.new(0.15, 0, 1, -3)
    indicator.BackgroundColor3 = C.accent
    indicator.BorderSizePixel  = 0
    indicator.BackgroundTransparency = 1
    indicator.ZIndex = 6
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0,2)
    tabButtons[def.key] = btn
    return btn
end

for i, def in ipairs(tabDefs) do createTabBtn(def, i) end

local function setActiveTab(key)
    for k, btn in pairs(tabButtons) do
        local active = (k == key)
        btn.BackgroundColor3 = active and C.bgSection or C.bgBtn
        btn.TextColor3       = active and C.textHeader or C.textDim
        local ind = btn:FindFirstChild("Indicator")
        if ind then ind.BackgroundTransparency = active and 0 or 1 end
    end
end

-- ===== TAB CONTENT =====
local TabContentFrame = Instance.new("Frame", MainFrame)
TabContentFrame.Size             = UDim2.new(1, -16, 1, -96)
TabContentFrame.Position         = UDim2.new(0, 8, 0, 90)
TabContentFrame.BackgroundTransparency = 1
TabContentFrame.ZIndex           = 3

local function makeScrollFrame(parent)
    local sf                  = Instance.new("ScrollingFrame", parent)
    sf.Size                   = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.ScrollBarThickness     = 4
    sf.ScrollBarImageColor3   = C.accent
    sf.CanvasSize             = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    sf.Visible                = false
    sf.ZIndex                 = 3
    sf.BorderSizePixel        = 0
    local layout = Instance.new("UIListLayout", sf)
    layout.SortOrder          = Enum.SortOrder.LayoutOrder
    layout.Padding            = UDim.new(0, 10) -- Increased padding between cards
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingLeft   = UDim.new(0, 2)
    pad.PaddingRight  = UDim.new(0, 2)
    pad.PaddingTop    = UDim.new(0, 4)
    return sf
end

local AimbotFrame = makeScrollFrame(TabContentFrame)
local ESPFrame    = makeScrollFrame(TabContentFrame)
local PlayerFrame = makeScrollFrame(TabContentFrame)
local MiscFrame   = makeScrollFrame(TabContentFrame)

local function switchTab(tab)
    AimbotFrame.Visible = (tab == "AIMBOT")
    ESPFrame.Visible    = (tab == "ESP")
    PlayerFrame.Visible = (tab == "PLAYER")
    MiscFrame.Visible   = (tab == "MISC")
    setActiveTab(tab)
    if tab == "MISC" then refreshPlayerList() end
end

tabButtons["AIMBOT"].MouseButton1Click:Connect(function() switchTab("AIMBOT") end)
tabButtons["ESP"].MouseButton1Click:Connect(function()    switchTab("ESP") end)
tabButtons["PLAYER"].MouseButton1Click:Connect(function() switchTab("PLAYER") end)
tabButtons["MISC"].MouseButton1Click:Connect(function()   switchTab("MISC") end)

-- ===== SECTION CARD BUILDER =====
local function makeCard(parent, lo)
    local card = Instance.new("Frame", parent)
    card.Size             = UDim2.new(1, -4, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.bgSection
    card.BorderSizePixel  = 0
    card.LayoutOrder      = lo
    card.ZIndex           = 3
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
    do
        local s = Instance.new("UIStroke", card)
        s.Color       = C.border
        s.Thickness   = 1
        s.Transparency= 0.55
    end
    local pad = Instance.new("UIPadding", card)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    local layout = Instance.new("UIListLayout", card)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 10) -- Increased padding between buttons inside the card
    return card
end

-- ===== UI CONFIG SETTERS =====
_G.ConfigSetters = {}

-- ===== TOGGLE ROW =====
local function makeToggleRow(parent, label, default, lo, callback)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = lo
    row.ZIndex           = 3

    -- Shifted label size to accommodate bind button
    local lbl = makeLabel(row, label, UDim2.new(1,-105,1,0), UDim2.new(0,0,0,0), 13, true, C.text)
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("TextButton", row)
    toggle.Size          = UDim2.new(0, 54, 0, 26)
    toggle.Position      = UDim2.new(1,-54,0.5,-13)
    toggle.Text          = default and "ON" or "OFF"
    toggle.BackgroundColor3 = default and C.onGreen or C.bgBtn
    toggle.TextColor3    = Color3.new(1,1,1)
    toggle.Font          = Enum.Font.GothamBold
    toggle.TextSize      = 12
    toggle.ZIndex        = 4
    toggle.AutoButtonColor = false
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,13)

    local state = default
    local toggleFunc = function()
        state = not state
        toggle.Text             = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state and C.onGreen or C.bgBtn
        callback(state)
    end
    toggle.MouseButton1Click:Connect(toggleFunc)

    _G.ConfigSetters[label] = function(v) 
        state = v
        toggle.Text = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state and C.onGreen or C.bgBtn
        callback(state)
    end

    -- Keybind Button
    local bindBtn = Instance.new("TextButton", row)
    bindBtn.Size          = UDim2.new(0, 42, 0, 20)
    bindBtn.Position      = UDim2.new(1,-100,0.5,-10)
    bindBtn.Text          = "BIND"
    bindBtn.BackgroundColor3 = C.bgBtn
    bindBtn.TextColor3    = C.textDim
    bindBtn.Font          = Enum.Font.GothamSemibold
    bindBtn.TextSize      = 10
    bindBtn.ZIndex        = 4
    bindBtn.AutoButtonColor = false
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0,4)
    
    local boundKey = nil
    local listening = false
    
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.TextColor3 = C.accent
    end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            boundKey = input.KeyCode
            -- Show the name of the key without the "Enum.KeyCode." part
            bindBtn.Text = boundKey.Name
            bindBtn.TextColor3 = C.text
        elseif not gpe and boundKey and input.KeyCode == boundKey then
            toggleFunc()
        end
    end)

    return toggle, function() return state end, function(v)
        state = v
        toggle.Text             = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state and C.onGreen or C.bgBtn
    end
end

-- ===== SLIDER ROW =====
local function makeSliderRow(parent, label, default, lo, callback)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, 0, 0, 46)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = lo
    row.ZIndex           = 3

    makeLabel(row, label, UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, false, C.textDim)

    local box = Instance.new("TextBox", row)
    box.Size             = UDim2.new(1, 0, 0, 24)
    box.Position         = UDim2.new(0, 0, 0, 20)
    box.BackgroundColor3 = C.bgBtn
    box.TextColor3       = C.text
    box.Font             = Enum.Font.Gotham
    box.TextSize         = 13
    box.Text             = tostring(default)
    box.ZIndex           = 4
    box.BorderSizePixel  = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
    do
        local s = Instance.new("UIStroke", box)
        s.Color = C.border; s.Thickness = 1; s.Transparency = 0.5
    end
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then callback(num) end
    end)

    _G.ConfigSetters[label] = function(v) 
        box.Text = tostring(v)
        callback(v) 
    end

    return box
end

-- ===== COLOR SWATCH BUTTON =====
local function makeColorSwatch(parent, label, r, g, b, lo, callback)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1,0,0,32)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = lo
    row.ZIndex           = 3

    makeLabel(row, label, UDim2.new(1,-90,1,0), UDim2.new(0,0,0,0), 12, false, C.textDim)

    local swatch = Instance.new("Frame", row)
    swatch.Size          = UDim2.new(0, 28, 0, 22)
    swatch.Position      = UDim2.new(1,-88,0.5,-11)
    swatch.BackgroundColor3 = Color3.fromRGB(r,g,b)
    swatch.BorderSizePixel = 0
    swatch.ZIndex        = 4
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0,4)

    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.new(0, 56, 0, 24)
    btn.Position         = UDim2.new(1,-58,0.5,-12)
    btn.Text             = "PICK"
    btn.BackgroundColor3 = C.accentDim
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 12
    btn.ZIndex           = 4
    btn.AutoButtonColor  = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.accent end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.accentDim end)
    btn.MouseButton1Click:Connect(function() callback(swatch) end)
    return swatch
end

-- ===== COLOR PICKER POPUP

local ColorPickerFrame       = Instance.new("Frame", ScreenGui)
ColorPickerFrame.Size        = UDim2.new(0, 250, 0, 210)
ColorPickerFrame.Position    = UDim2.new(0.5, 20, 0.5, -105)
ColorPickerFrame.BackgroundColor3 = C.bgPanel
ColorPickerFrame.BorderSizePixel  = 0
ColorPickerFrame.Visible     = false
ColorPickerFrame.Draggable   = true
ColorPickerFrame.Active      = true
ColorPickerFrame.ZIndex      = 20
Instance.new("UICorner", ColorPickerFrame).CornerRadius = UDim.new(0,10)
do
    local s = Instance.new("UIStroke", ColorPickerFrame)
    s.Color = C.borderGlow; s.Thickness = 1.5; s.Transparency = 0.3
end

local PickerBar = Instance.new("Frame", ColorPickerFrame)
PickerBar.Size            = UDim2.new(1,0,0,30)
PickerBar.BackgroundColor3= C.accent
PickerBar.BorderSizePixel = 0
PickerBar.ZIndex          = 21
Instance.new("UICorner", PickerBar).CornerRadius = UDim.new(0,10)
do -- cover bottom corners of bar
    local cover = Instance.new("Frame", PickerBar)
    cover.Size = UDim2.new(1,0,0.5,0)
    cover.Position = UDim2.new(0,0,0.5,0)
    cover.BackgroundColor3 = C.accent
    cover.BorderSizePixel = 0; cover.ZIndex = 21
end

local PickerTitle = makeLabel(PickerBar, "  ❄ COLOR PICKER",
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), 13, true, Color3.new(1,1,1))
PickerTitle.ZIndex = 22

local PreviewBox = Instance.new("Frame", ColorPickerFrame)
PreviewBox.Size          = UDim2.new(0,55,0,55)
PreviewBox.Position      = UDim2.new(0,12,0,42)
PreviewBox.BackgroundColor3 = C.accent
PreviewBox.BorderSizePixel  = 0
PreviewBox.ZIndex        = 21
Instance.new("UICorner", PreviewBox).CornerRadius = UDim.new(0,6)
do
    local s = Instance.new("UIStroke", PreviewBox)
    s.Color = C.border; s.Thickness = 1
end

local function makePickerChannel(name, yPos)
    local lbl = makeLabel(ColorPickerFrame, name,
        UDim2.new(0,16,0,22), UDim2.new(0,80,0,yPos), 12, true, C.textDim)
    lbl.ZIndex = 21
    local box = Instance.new("TextBox", ColorPickerFrame)
    box.Size             = UDim2.new(0,100,0,22)
    box.Position         = UDim2.new(0,100,0,yPos)
    box.BackgroundColor3 = C.bgBtn
    box.TextColor3       = C.text
    box.Font             = Enum.Font.Gotham
    box.TextSize         = 12
    box.Text             = "255"
    box.ZIndex           = 21
    box.BorderSizePixel  = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,5)
    return box
end

local RBox = makePickerChannel("R", 42)
local GBox = makePickerChannel("G", 72)
local BBox = makePickerChannel("B", 102)

local pickerTarget    = nil
local pickerSwatchRef = nil

local function updatePreview()
    local r = math.clamp(tonumber(RBox.Text) or 0,0,255)
    local g = math.clamp(tonumber(GBox.Text) or 0,0,255)
    local b = math.clamp(tonumber(BBox.Text) or 0,0,255)
    PreviewBox.BackgroundColor3 = Color3.fromRGB(r,g,b)
end
RBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)
GBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)
BBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)

local function pickerApplyBtn(text, xOff, bgc, callback)
    local btn = Instance.new("TextButton", ColorPickerFrame)
    btn.Text         = text
    btn.Size         = UDim2.new(0, 96, 0, 30)
    btn.Position     = UDim2.new(0, xOff, 1, -40)
    btn.BackgroundColor3 = bgc
    btn.TextColor3   = Color3.new(1,1,1)
    btn.Font         = Enum.Font.GothamSemibold
    btn.TextSize         = 13
    btn.ZIndex       = 21
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

pickerApplyBtn("APPLY", 12, C.onGreen, function()
    local r = math.clamp(tonumber(RBox.Text) or 0,0,255)
    local g = math.clamp(tonumber(GBox.Text) or 0,0,255)
    local b = math.clamp(tonumber(BBox.Text) or 0,0,255)
    local newColor = Color3.fromRGB(r,g,b)
    if pickerTarget == "ENEMY" then
        enemyR,enemyG,enemyB = r,g,b
        enemyColor = newColor
    elseif pickerTarget == "TEAM" then
        teamR,teamG,teamB = r,g,b
        teamColor = newColor
    elseif pickerTarget == "FOV" then
        fovR,fovG,fovB = r,g,b
        aimbotFovColor = newColor
        FOVStroke.Color = newColor
    end
    if pickerSwatchRef then pickerSwatchRef.BackgroundColor3 = newColor end
    fullESPRefresh()
    ColorPickerFrame.Visible = false
end)
pickerApplyBtn("CANCEL", 116, C.bgBtn, function()
    ColorPickerFrame.Visible = false
end)

function openColorPicker(target, r, g, b, swatchRef)
    pickerTarget    = target
    pickerSwatchRef = swatchRef
    RBox.Text = tostring(r)
    GBox.Text = tostring(g)
    BBox.Text = tostring(b)
    updatePreview()
    ColorPickerFrame.Visible = true
end

-- ============================================================
--  AIMBOT TAB CONTENTS
-- ============================================================

-- Aimbot card
local aimbotCard = makeCard(AimbotFrame, 1)
makeLabel(aimbotCard, "🎯  AIMBOT", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local aimbotToggle = makeToggleRow(aimbotCard, "Enable Aimbot", false, 1, function(on)
    aimbotEnabled = on
    if on then enableAimbotBind(); updateFOVCircleAppearance(fov, true)
    else        disableAimbotBind(); updateFOVCircleAppearance(fov, false) end
end)

makeSliderRow(aimbotCard, "FOV Radius (px)", 200, 2, function(v)
    fov = v
    if aimbotEnabled then updateFOVCircleAppearance(fov, true) end
end)

makeToggleRow(aimbotCard, "Enable Wallbang (Shoot through walls)", false, 3, function(on)
    wallbangEnabled = on
end)

makeColorSwatch(aimbotCard, "FOV Circle Color", fovR, fovG, fovB, 4, function(swatch)
    openColorPicker("FOV", fovR, fovG, fovB, swatch)
end)

-- Spinbot card
local spinCard = makeCard(AimbotFrame, 2)
makeLabel(spinCard, "🌀  SPIN BOT", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0
makeToggleRow(spinCard, "Enable Spin Bot", false, 1, function(on) spinBotEnabled = on end)
makeSliderRow(spinCard, "Spin Speed (deg/s)", 360, 2, function(v) spinSpeedDeg = v end)

-- Flick card
local flickCard = makeCard(AimbotFrame, 3)
makeLabel(flickCard, "⚡  FLICK AIMBOT", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0
makeToggleRow(flickCard, "Enable Flick", false, 1, function(on) flickEnabled = on end)
makeSliderRow(flickCard, "Flick Interval (s)", 0.5, 2, function(v) flickInterval = v end)

-- MM2 Auto-Kill card
local killCard = makeCard(AimbotFrame, 4)
makeLabel(killCard, "🔪  MM2 AUTO-KILL (MURDERER)", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local function createKillAllBtn(parent, text, order, callback)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder      = order
    row.ZIndex           = 3

    local btn = Instance.new("TextButton", row)
    btn.Text        = text
    btn.Size        = UDim2.new(1,-46,1,0)
    btn.Position    = UDim2.new(0,0,0,0)
    btn.BackgroundColor3 = C.bgBtn
    btn.TextColor3  = C.text
    btn.Font        = Enum.Font.GothamSemibold
    btn.TextSize    = 13
    btn.ZIndex      = 4
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgBtn end)
    btn.MouseButton1Click:Connect(callback)

    -- Keybind Button
    local bindBtn = Instance.new("TextButton", row)
    bindBtn.Size          = UDim2.new(0, 42, 1, 0)
    bindBtn.Position      = UDim2.new(1,-42,0,0)
    bindBtn.Text          = "BIND"
    bindBtn.BackgroundColor3 = C.bgBtn
    bindBtn.TextColor3    = C.textDim
    bindBtn.Font          = Enum.Font.GothamSemibold
    bindBtn.TextSize      = 10
    bindBtn.ZIndex        = 4
    bindBtn.AutoButtonColor = false
    Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0,5)
    
    local boundKey = nil
    local listening = false
    
    bindBtn.MouseButton1Click:Connect(function()
        listening = true
        bindBtn.Text = "..."
        bindBtn.TextColor3 = C.accent
    end)
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            boundKey = input.KeyCode
            bindBtn.Text = boundKey.Name
            bindBtn.TextColor3 = C.text
        elseif not gpe and boundKey and input.KeyCode == boundKey then
            callback()
        end
    end)

    return btn
end

createKillAllBtn(killCard, "KILL ALL IN LOBBY", 1, function()
    _G.KillAllActive = true
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            -- Determine if the target is the murderer
            local isTargetM = false
            if _G.MM2_Roles and _G.MM2_Roles[p.Name] == "Murderer" then isTargetM = true end
            local bp = p:FindFirstChild("Backpack")
            if bp and bp:FindFirstChild("Knife") then isTargetM = true end
            local char = p.Character
            if char and char:FindFirstChild("Knife") then isTargetM = true end
            
            -- If target is NOT the murderer, expand their hitbox so we can kill them
            if not isTargetM then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size = Vector3.new(200, 200, 200)
                    root.Transparency = 0.8
                    root.BrickColor = BrickColor.new("Bright red")
                    root.Material = Enum.Material.ForceField
                    root.CanCollide = false
                end
            end
        end
    end
    pcall(function()
        if mouse1click then mouse1click() end
    end)
    task.delay(1, function()
        _G.KillAllActive = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root and root.Size.X > 5 then
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end
            end
        end
    end)
end)

-- Sheriff Wallbang Card
local hitboxCard = makeCard(AimbotFrame, 5)
makeLabel(hitboxCard, "💥  SHERIFF WALLBANG", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

makeToggleRow(hitboxCard, "Hitbox Expander Method (Legacy)", false, 1, function(on) _G.HitboxExpander = on end)
makeSliderRow(hitboxCard, "Hitbox Size (studs)", 50, 2, function(v) _G.HitboxSize = v end)

local trueMm2Wallbang = false
makeToggleRow(hitboxCard, "True Wallbang (Grip Offset Method)", false, 3, function(on)
    trueMm2Wallbang = on
end)

RunService.RenderStepped:Connect(function()
    if not trueMm2Wallbang then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun")
    if gun and gun:IsA("Tool") then
        local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        if not rightArm then return end
        
        -- Find the Murderer dynamically
        local mChar = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if (_G.MM2_Roles and _G.MM2_Roles[p.Name] == "Murderer") or p.Character:FindFirstChild("Knife") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife")) then
                    mChar = p.Character
                    break
                end
            end
        end
        
        if mChar and mChar:FindFirstChild("Head") and gun:FindFirstChild("Handle") then
            -- Teleport the barrel of the gun directly inside the Murderer's head
            -- We calculate the exact offset from the gun's physical handle to the Murderer's head
            local targetPos = mChar.Head.Position
            local handleCFrame = gun.Handle.CFrame
            -- GripPos operates in the local object space of the Handle, not the Arm
            local offset = handleCFrame:PointToObjectSpace(targetPos)
            gun.GripPos = offset
        else
            -- Default to normal if murderer isn't found
            gun.GripPos = Vector3.new(0, 0, 0)
        end
    end
end)

local blinkKillWallbang = false
makeToggleRow(hitboxCard, "Blink-Kill Method (Press Q with Gun)", false, 4, function(on)
    blinkKillWallbang = on
end)

makeToggleRow(hitboxCard, "Show Mobile Blink-Kill Button", false, 5, function(on)
    if on then
        createMobileButton("blinkBtn", "Q\nBLINK KILL", executeBlinkKill)
    else
        removeMobileButton("blinkBtn")
    end
end)

local function executeBlinkKill()
    local char = LocalPlayer.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun")
    if not gun or not gun:IsA("Tool") then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Find the Murderer
    local mChar = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if (_G.MM2_Roles and _G.MM2_Roles[p.Name] == "Murderer") or p.Character:FindFirstChild("Knife") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife")) then
                mChar = p.Character
                break
            end
        end
    end
    
    if mChar and mChar:FindFirstChild("HumanoidRootPart") then
        local oldPos = root.CFrame
        local mRoot = mChar.HumanoidRootPart
        
        -- Teleport directly above their head
        root.CFrame = CFrame.new(mRoot.Position + Vector3.new(0, 6, 0), mRoot.Position)
        
        -- Fire the gun instantly
        task.spawn(function()
            -- Ensure camera is looking straight down at them so the shot goes perfectly vertical
            local Camera = workspace.CurrentCamera
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, mRoot.Position)
            
            -- Wait a tiny fraction of a second for the server to register our new position
            task.wait(0.05)
            if mouse1click then mouse1click() end
            
            -- Wait for the bullet to spawn and leave the barrel
            task.wait(0.1)
            
            -- Teleport back to where we were sitting safely
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = oldPos
            end
        end)
    end
end

local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gpe)
    if gpe or not blinkKillWallbang then return end
    if input.KeyCode == Enum.KeyCode.Q then
        executeBlinkKill()
    end
end)

-- ============================================================
--  ESP TAB CONTENTS
-- ============================================================

local espMasterCard = makeCard(ESPFrame, 1)
makeLabel(espMasterCard, "👁  ESP MASTER", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local espToggle, _, setEspToggle = makeToggleRow(espMasterCard, "Enable ESP", false, 1, function(on)
    espEnabled = on
    fullESPRefresh()
end)

makeToggleRow(espMasterCard, "Team ESP", false, 2, function(on)
    teamEspEnabled = on
    fullESPRefresh()
end)

makeToggleRow(espMasterCard, "MM2 Roles ESP (Red=M, Blue=S, Green=I)", false, 3, function(on)
    mm2EspEnabled = on
    fullESPRefresh()
end)

local roleNotificationsEnabled = false
makeToggleRow(espMasterCard, "MM2 Role Notifications", false, 4, function(on)
    roleNotificationsEnabled = on
end)

-- Background loop to detect MM2 Roles and send notifications
task.spawn(function()
    local knownMurderer = nil
    local knownSheriff = nil
    
    while task.wait(0.5) do
        if not roleNotificationsEnabled then continue end
        
        local currentM = nil
        local currentS = nil
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                -- Check for Murderer
                if p.Character:FindFirstChild("Knife") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife")) then
                    currentM = p.Name
                end
                -- Check for Sheriff/Hero
                if p.Character:FindFirstChild("Gun") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Gun")) then
                    currentS = p.Name
                end
            end
        end
        
        if currentM and currentM ~= knownMurderer then
            knownMurderer = currentM
            pcall(function()
                game.StarterGui:SetCore("SendNotification", {
                    Title = "🔪 MURDERER FOUND",
                    Text = currentM .. " is the Murderer!",
                    Duration = 5
                })
            end)
        end
        
        if currentS and currentS ~= knownSheriff then
            knownSheriff = currentS
            pcall(function()
                game.StarterGui:SetCore("SendNotification", {
                    Title = "🔫 SHERIFF FOUND",
                    Text = currentS .. " has the Gun!",
                    Duration = 5
                })
            end)
        end
        
        -- Reset known roles if they leave or die (basic reset heuristic)
        if knownMurderer and not Players:FindFirstChild(knownMurderer) then knownMurderer = nil end
        if knownSheriff and not Players:FindFirstChild(knownSheriff) then knownSheriff = nil end
    end
end)



makeToggleRow(espMasterCard, "MM2 Dropped Gun ESP (Purple)", false, 4, function(on)
    mm2GunEspEnabled = on
end)

local enemySwatch = makeColorSwatch(espMasterCard, "Enemy Color", enemyR, enemyG, enemyB, 5, function(sw)
    openColorPicker("ENEMY", enemyR, enemyG, enemyB, sw)
end)

local teamSwatch = makeColorSwatch(espMasterCard, "Team Color", teamR, teamG, teamB, 6, function(sw)
    openColorPicker("TEAM", teamR, teamG, teamB, sw)
end)

-- ESP Features card
local espFeatCard = makeCard(ESPFrame, 2)
makeLabel(espFeatCard, "🔧  ESP FEATURES", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local espFeatures = {
    { name="Box ESP",      var="boxEnabled"      },
    { name="Skeleton ESP", var="skeletonEnabled"  },
    { name="Name Tag",     var="nameEnabled"      },
    { name="Health Bar",   var="healthEnabled"    },
    { name="Chams",        var="chamsEnabled"     },
}
for i, feat in ipairs(espFeatures) do
    makeToggleRow(espFeatCard, feat.name, false, i, function(on)
        if feat.var == "boxEnabled"      then boxEnabled      = on end
        if feat.var == "skeletonEnabled" then skeletonEnabled = on end
        if feat.var == "nameEnabled"     then nameEnabled     = on end
        if feat.var == "healthEnabled"   then healthEnabled   = on end
        if feat.var == "chamsEnabled"    then chamsEnabled    = on end
        fullESPRefresh()
    end)
end

-- ESP Thickness card
local espThickCard = makeCard(ESPFrame, 3)
makeLabel(espThickCard, "📐  THICKNESS & TRACERS", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

makeSliderRow(espThickCard, "Box Thickness (px)", 1.8, 1, function(v)
    boxThickness = math.max(v, 0.5)
end)

makeSliderRow(espThickCard, "Skeleton Thickness (px)", 1.4, 2, function(v)
    skeletonThickness = math.max(v, 0.5)
end)

makeToggleRow(espThickCard, "Tracers", false, 3, function(on)
    tracerEnabled = on
end)

makeSliderRow(espThickCard, "Tracer Thickness (px)", 1.2, 4, function(v)
    tracerThickness = math.max(v, 0.5)
end)
-- ============================================================
--  MISC TAB CONTENTS
-- ============================================================

local flightCard = makeCard(PlayerFrame, 1)
makeLabel(flightCard, "✈  FLIGHT", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0
makeToggleRow(flightCard, "Enable Flight", false, 1, function(on)
    if on then startFlight() else stopFlight() end
end)
makeSliderRow(flightCard, "Flight Speed", 50, 2, function(v) flightSpeed = v end)

local noclipCard = makeCard(PlayerFrame, 2)
makeLabel(noclipCard, "👻  NOCLIP", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0
makeToggleRow(noclipCard, "Enable Noclip", false, 1, function(on)
    if on then startNoclip() else stopNoclip() end
end)
makeSliderRow(noclipCard, "Noclip Speed", 50, 2, function(v)
    noclipSpeed = v
    if noclipEnabled then applyNoclipSpeed() end
end)

local speedCard = makeCard(PlayerFrame, 3)
makeLabel(speedCard, "🏃  SPEED", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0
makeToggleRow(speedCard, "Enable Speed", false, 1, function(on)
    speedEnabled = on; applyWalkSpeed()
end)
makeSliderRow(speedCard, "Walk Speed", 27, 2, function(v)
    walkSpeed = v
    if speedEnabled then applyWalkSpeed() end
end)

local jumpCard = makeCard(PlayerFrame, 4)
makeLabel(jumpCard, "🦘  JUMP POWER", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0
makeToggleRow(jumpCard, "Enable Jump Boost", false, 1, function(on)
    jumpEnabled = on; applyJumpPower()
end)
makeSliderRow(jumpCard, "Jump Power", 50, 2, function(v)
    jumpPower = v
    if jumpEnabled then applyJumpPower() end
end)

local ghostCard = makeCard(PlayerFrame, 5)
makeLabel(ghostCard, "👻  GHOST MODE (INVISIBILITY)", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local ghostModeEnabled = false
local ghostClone = nil
local ghostConnection = nil

local function stopGhostMode()
    local realChar = LocalPlayer.Character
    if ghostConnection then
        ghostConnection:Disconnect()
        ghostConnection = nil
    end
    if realChar then
        local root = realChar:FindFirstChild("HumanoidRootPart")
        if root then
            local bv = root:FindFirstChild("GhostAntiVoid")
            if bv then bv:Destroy() end
            
            if ghostClone and ghostClone:FindFirstChild("HumanoidRootPart") then
                root.Anchored = false
                -- Teleport real char to clone's location
                root.CFrame = ghostClone.HumanoidRootPart.CFrame
            else
                root.Anchored = false
            end
        end
        local realHum = realChar:FindFirstChildOfClass("Humanoid")
        if realHum then
            workspace.CurrentCamera.CameraSubject = realHum
        end
    end
    if ghostClone then
        ghostClone:Destroy()
        ghostClone = nil
    end
end

local function startGhostMode()
    local realChar = LocalPlayer.Character
    if not realChar then return end
    
    realChar.Archivable = true
    ghostClone = realChar:Clone()
    ghostClone.Name = "GhostOverlay"
    
    -- Make it translucent and non-collidable
    for _, p in pairs(ghostClone:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then
            p.Transparency = 0.5
            if p:IsA("BasePart") then
                p.CanCollide = false
                p.Massless = true
            end
        end
    end
    
    local cloneHum = ghostClone:FindFirstChildOfClass("Humanoid")
    if cloneHum then
        cloneHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    
    ghostClone.Parent = workspace
    
    -- Focus camera on clone
    if cloneHum then
        workspace.CurrentCamera.CameraSubject = cloneHum
    end
    
    local realHum = realChar:FindFirstChildOfClass("Humanoid")
    local root = realChar:FindFirstChild("HumanoidRootPart")
    
    if realHum and cloneHum and root then
        -- Setup Animations
        local walkAnimId = "rbxassetid://913376220" -- Default fallback R15 Walk
        local idleAnimId = "rbxassetid://507766288" -- Default fallback R15 Idle
        
        -- Attempt to scrape equipped animations
        local animate = realChar:FindFirstChild("Animate")
        if animate then
            local walk = animate:FindFirstChild("walk")
            if walk and walk:FindFirstChildOfClass("Animation") then
                walkAnimId = walk:FindFirstChildOfClass("Animation").AnimationId
            end
            local idle = animate:FindFirstChild("idle")
            if idle and idle:FindFirstChildOfClass("Animation") then
                idleAnimId = idle:FindFirstChildOfClass("Animation").AnimationId
            end
        end
        
        local animator = cloneHum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = cloneHum
        end
        
        local walkAnim = Instance.new("Animation")
        walkAnim.AnimationId = walkAnimId
        local walkTrack = animator:LoadAnimation(walkAnim)
        
        local idleAnim = Instance.new("Animation")
        idleAnim.AnimationId = idleAnimId
        local idleTrack = animator:LoadAnimation(idleAnim)
        
        idleTrack:Play()
        
        -- Initial teleport away to a "safe" off-map corner (avoiding killbox ceilings)
        root.Anchored = false
        root.CFrame = CFrame.new(9000, 9000, 9000)
        
        -- Add an anti-void velocity to hold the body up without anchoring (anchoring breaks server replication)
        local bv = root:FindFirstChild("GhostAntiVoid")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "GhostAntiVoid"
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = root
        end
        
        ghostConnection = RunService.RenderStepped:Connect(function()
            if not realChar or not realChar.Parent or not ghostClone or not ghostClone.Parent then
                stopGhostMode()
                if _G.ConfigSetters["Enable Ghost Mode"] then _G.ConfigSetters["Enable Ghost Mode"](false) end
                return
            end
            
            -- Make clone walk where real character intends to
            cloneHum:Move(realHum.MoveDirection, false)
            
            -- Animate the clone based on physical intent
            if realHum.MoveDirection.Magnitude > 0 then
                if not walkTrack.IsPlaying then walkTrack:Play() end
                if idleTrack.IsPlaying then idleTrack:Stop() end
            else
                if not idleTrack.IsPlaying then idleTrack:Play() end
                if walkTrack.IsPlaying then walkTrack:Stop() end
            end
            
            -- Sync jumps
            if realHum.Jump then
                cloneHum.Jump = true
            end
            
            -- Ensure real char stays locked at the safe off-map corner but UNANCHORED so it replicates
            root.Anchored = false
            local antiVoid = root:FindFirstChild("GhostAntiVoid")
            
            if ghostManifesting then
                -- Track the ghost's LIVE position frame-by-frame
                root.CFrame = ghostClone.HumanoidRootPart.CFrame
                -- Temporarily disable anti-void force to wake up the physics hitbox for Touch events
                if antiVoid then antiVoid.MaxForce = Vector3.new(0,0,0) end
            else
                -- Lock to the safe off-map corner
                root.CFrame = CFrame.new(9000, 9000, 9000)
                -- Re-enable anti-void to prevent falling into the void
                if antiVoid then antiVoid.MaxForce = Vector3.new(math.huge, math.huge, math.huge) end
            end
            
            -- Forcefully lock camera to clone to prevent game scripts from resetting it
            if workspace.CurrentCamera.CameraSubject ~= cloneHum then
                workspace.CurrentCamera.CameraSubject = cloneHum
            end
        end)
    end
end

local ghostManifesting = false
makeToggleRow(ghostCard, "Enable Ghost Mode", false, 1, function(on)
    ghostModeEnabled = on
    if on then
        startGhostMode()
    else
        stopGhostMode()
    end
end)

makeToggleRow(ghostCard, "Show Mobile Manifest Button", false, 2, function(on)
    if on then
        createMobileButton("ghostBtn", "V\nMANIFEST", executeGhostManifest)
    else
        removeMobileButton("ghostBtn")
    end
end)

local function executeGhostManifest()
    local realChar = LocalPlayer.Character
    if realChar then
        local root = realChar:FindFirstChild("HumanoidRootPart")
        if root and ghostClone and ghostClone:FindFirstChild("HumanoidRootPart") then
            -- Temporarily manifest real body at ghost position
            ghostManifesting = true
            root.CFrame = ghostClone.HumanoidRootPart.CFrame
            
            -- Wait half a second to allow server to register interaction (kill/pickup)
            task.delay(0.5, function()
                ghostManifesting = false
            end)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not ghostModeEnabled or not ghostClone then return end
    if input.KeyCode == Enum.KeyCode.V then
        executeGhostManifest()
    end
end)

-- Spectate Card
local spectateCard = makeCard(PlayerFrame, 6)
makeLabel(spectateCard, "🎥  SPECTATE", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local stopSpecBtn = Instance.new("TextButton", spectateCard)
stopSpecBtn.Text = "STOP SPECTATING"
stopSpecBtn.Size = UDim2.new(1,0,0,28)
stopSpecBtn.BackgroundColor3 = C.accentDim
stopSpecBtn.TextColor3 = Color3.new(1,1,1)
stopSpecBtn.Font = Enum.Font.GothamBold
stopSpecBtn.TextSize = 13
stopSpecBtn.AutoButtonColor = false
stopSpecBtn.LayoutOrder = 1
stopSpecBtn.ZIndex = 4
Instance.new("UICorner", stopSpecBtn).CornerRadius = UDim.new(0,6)
stopSpecBtn.MouseEnter:Connect(function() stopSpecBtn.BackgroundColor3 = C.accent end)
stopSpecBtn.MouseLeave:Connect(function() stopSpecBtn.BackgroundColor3 = C.accentDim end)
stopSpecBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end)

local specListFrame = Instance.new("ScrollingFrame", spectateCard)
specListFrame.Size             = UDim2.new(1,0,0,120)
specListFrame.BackgroundColor3 = C.bg
specListFrame.BorderSizePixel  = 0
specListFrame.ScrollBarThickness = 4
specListFrame.ScrollBarImageColor3 = C.accent
specListFrame.CanvasSize       = UDim2.new(0,0,0,0)
specListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
specListFrame.ZIndex           = 4
specListFrame.LayoutOrder      = 2
Instance.new("UICorner", specListFrame).CornerRadius = UDim.new(0,6)
local specListLayout = Instance.new("UIListLayout", specListFrame)
specListLayout.SortOrder = Enum.SortOrder.Name
specListLayout.Padding   = UDim.new(0,3)
local specPad = Instance.new("UIPadding", specListFrame)
specPad.PaddingLeft = UDim.new(0,4); specPad.PaddingRight = UDim.new(0,4)
specPad.PaddingTop  = UDim.new(0,4)

local function refreshSpectateList()
    for _, child in ipairs(specListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton", specListFrame)
            btn.Text             = player.Name
            btn.Size             = UDim2.new(1,0,0,26)
            btn.BackgroundColor3 = C.bgSection
            btn.TextColor3       = C.text
            btn.Font             = Enum.Font.Gotham
            btn.TextSize         = 13
            btn.AutoButtonColor  = false
            btn.ZIndex           = 5
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgSection end)
            btn.MouseButton1Click:Connect(function()
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    Camera.CameraSubject = player.Character.Humanoid
                end
            end)
        end
    end
end

-- Refresh spectate list when players join/leave
-- Fling Card
local flingCard = makeCard(PlayerFrame, 7)
makeLabel(flingCard, "🌪️  TARGET FLING", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local stopFlingBtn = Instance.new("TextButton", flingCard)
stopFlingBtn.Text = "STOP FLINGING"
stopFlingBtn.Size = UDim2.new(1,0,0,28)
stopFlingBtn.BackgroundColor3 = C.accentDim
stopFlingBtn.TextColor3 = Color3.new(1,1,1)
stopFlingBtn.Font = Enum.Font.GothamBold
stopFlingBtn.TextSize = 13
stopFlingBtn.AutoButtonColor = false
stopFlingBtn.LayoutOrder = 1
stopFlingBtn.ZIndex = 4
Instance.new("UICorner", stopFlingBtn).CornerRadius = UDim.new(0,6)
stopFlingBtn.MouseEnter:Connect(function() stopFlingBtn.BackgroundColor3 = C.accent end)
stopFlingBtn.MouseLeave:Connect(function() stopFlingBtn.BackgroundColor3 = C.accentDim end)

local flingListFrame = Instance.new("ScrollingFrame", flingCard)
flingListFrame.Size             = UDim2.new(1,0,0,120)
flingListFrame.BackgroundColor3 = C.bg
flingListFrame.BorderSizePixel  = 0
flingListFrame.ScrollBarThickness = 4
flingListFrame.ScrollBarImageColor3 = C.accent
flingListFrame.CanvasSize       = UDim2.new(0,0,0,0)
flingListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
flingListFrame.ZIndex           = 4
flingListFrame.LayoutOrder      = 2
Instance.new("UICorner", flingListFrame).CornerRadius = UDim.new(0,6)
local flingListLayout = Instance.new("UIListLayout", flingListFrame)
flingListLayout.SortOrder = Enum.SortOrder.Name
flingListLayout.Padding   = UDim.new(0,3)
local flingPad = Instance.new("UIPadding", flingListFrame)
flingPad.PaddingLeft = UDim.new(0,4); flingPad.PaddingRight = UDim.new(0,4)
flingPad.PaddingTop  = UDim.new(0,4)

local currentFlingTarget = nil
local flingConnection = nil

local function stopFling()
    currentFlingTarget = nil
    if flingConnection then
        flingConnection:Disconnect()
        flingConnection = nil
    end
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local bav = root:FindFirstChild("FlingSpin")
            if bav then bav:Destroy() end
            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            hum.PlatformStand = false
        end
    end
end

stopFlingBtn.MouseButton1Click:Connect(stopFling)

local function startFling(targetPlayer)
    if currentFlingTarget == targetPlayer then return end
    stopFling()
    currentFlingTarget = targetPlayer
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    
    -- Prepare physics for flinging
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum.PlatformStand = true
    
    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "FlingSpin"
    bav.AngularVelocity = Vector3.new(0, 99999, 0)
    bav.MaxTorque = Vector3.new(0, math.huge, 0)
    bav.P = math.huge
    bav.Parent = root
    
    flingConnection = RunService.Heartbeat:Connect(function()
        if not currentFlingTarget or not currentFlingTarget.Character then stopFling(); return end
        local tRoot = currentFlingTarget.Character:FindFirstChild("HumanoidRootPart")
        local tHum = currentFlingTarget.Character:FindFirstChildOfClass("Humanoid")
        
        if not tRoot or not tHum or tHum.Health <= 0 then
            stopFling()
            return
        end
        
        -- Orbit aggressively around their center mass to bypass basic anti-collisions
        local orbitOffset = CFrame.Angles(0, tick() * 20, 0) * CFrame.new(0, 0, -2)
        root.Velocity = Vector3.zero
        root.CFrame = tRoot.CFrame * orbitOffset
    end)
end

local function refreshFlingList()
    for _, child in ipairs(flingListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton", flingListFrame)
            btn.Text             = player.Name
            btn.Size             = UDim2.new(1,0,0,26)
            btn.BackgroundColor3 = C.bgSection
            btn.TextColor3       = C.text
            btn.Font             = Enum.Font.Gotham
            btn.TextSize         = 13
            btn.AutoButtonColor  = false
            btn.ZIndex           = 5
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgSection end)
            btn.MouseButton1Click:Connect(function()
                startFling(player)
            end)
        end
    end
end

-- Refresh both lists together
Players.PlayerAdded:Connect(function()
    refreshSpectateList()
    refreshFlingList()
end)
Players.PlayerRemoving:Connect(function(player)
    if currentFlingTarget == player then stopFling() end
    refreshSpectateList()
    refreshFlingList()
end)
refreshFlingList()

-- MM2 Grab Gun Helper
local cachedDroppedGun = nil
local lastGunScan = 0

local function findDroppedGun()
    -- Fast path: if we already have it and its parent is valid
    if cachedDroppedGun and cachedDroppedGun.Parent and cachedDroppedGun:IsDescendantOf(Workspace) then
        return cachedDroppedGun
    end
    
    -- Only do a full deep scan every 1 second max to avoid lagging the game
    local now = tick()
    if now - lastGunScan < 1 then return nil end
    lastGunScan = now
    
    cachedDroppedGun = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Gun" or obj.Name == "GunDrop" then
            if obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart") then
                local isHeld = false
                local parent = obj.Parent
                while parent and parent ~= Workspace do
                    if parent:FindFirstChildOfClass("Humanoid") or parent:IsA("Backpack") then
                        isHeld = true
                        break
                    end
                    parent = parent.Parent
                end
                if not isHeld then
                    cachedDroppedGun = obj
                    break
                end
            end
        end
    end
    return cachedDroppedGun
end
-- MM2 Grab Gun card
local mm2GunCard = makeCard(MiscFrame, 5)
makeLabel(mm2GunCard, "🔫  MM2 GRAB GUN", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local grabGunKey = Enum.KeyCode.E

local GrabGunBtn = Instance.new("TextButton", mm2GunCard)
GrabGunBtn.Text = "TELEPORT TO DROPPED GUN [E]"
GrabGunBtn.Size        = UDim2.new(1,0,0,28)
GrabGunBtn.BackgroundColor3 = C.accentDim
GrabGunBtn.TextColor3  = Color3.new(1,1,1)
GrabGunBtn.Font        = Enum.Font.GothamSemibold
GrabGunBtn.TextSize    = 13
GrabGunBtn.ZIndex      = 4
GrabGunBtn.LayoutOrder = 1
GrabGunBtn.AutoButtonColor = false
Instance.new("UICorner", GrabGunBtn).CornerRadius = UDim.new(0,7)

-- Add keybind change logic
local isBindingGun = false
GrabGunBtn.MouseButton2Click:Connect(function()
    isBindingGun = true
    GrabGunBtn.Text = "PRESS ANY KEY..."
    GrabGunBtn.BackgroundColor3 = C.accentGlow
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if isBindingGun and input.UserInputType == Enum.UserInputType.Keyboard then
        grabGunKey = input.KeyCode
        local keyName = UserInputService:GetStringByKeycode(grabGunKey)
        if keyName == "" then keyName = grabGunKey.Name end
        GrabGunBtn.Text = "TELEPORT TO DROPPED GUN [" .. keyName .. "]"
        GrabGunBtn.BackgroundColor3 = C.accentDim
        isBindingGun = false
        return
    end
    
    if not processed and input.KeyCode == grabGunKey then
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local gunDrop = findDroppedGun()

        if gunDrop then
            local targetPos
            if gunDrop:IsA("Model") then
                local cf = gunDrop:GetBoundingBox()
                targetPos = cf.Position
            elseif gunDrop:IsA("BasePart") then
                targetPos = gunDrop.Position
            elseif gunDrop:IsA("Tool") then
                local handle = gunDrop:FindFirstChild("Handle")
                if handle then targetPos = handle.Position end
            end
            if targetPos then
                -- Save original position
                local originalPos = root.CFrame
                
                -- Teleport to gun
                root.CFrame = CFrame.new(targetPos)
                
                -- Wait a tiny fraction of a second for the server to register the pickup, then rubberband back
                task.delay(0.2, function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = originalPos
                    end
                end)
            end
        end
    end
end)

GrabGunBtn.MouseEnter:Connect(function() if not isBindingGun then GrabGunBtn.BackgroundColor3 = C.accent end end)
GrabGunBtn.MouseLeave:Connect(function() if not isBindingGun then GrabGunBtn.BackgroundColor3 = C.accentDim end end)
GrabGunBtn.MouseButton1Click:Connect(function()
    if isBindingGun then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local gunDrop = findDroppedGun()

    if gunDrop then
        local targetPos
        if gunDrop:IsA("Model") then
            local cf = gunDrop:GetBoundingBox()
            targetPos = cf.Position
        elseif gunDrop:IsA("BasePart") then
            targetPos = gunDrop.Position
        elseif gunDrop:IsA("Tool") then
            local handle = gunDrop:FindFirstChild("Handle")
            if handle then targetPos = handle.Position end
        end
        if targetPos then
            local originalPos = root.CFrame
            root.CFrame = CFrame.new(targetPos)
            task.delay(0.2, function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = originalPos
                end
            end)
        end
    end
end)

-- Gun Drop Notification Listener
Workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "GunDrop" then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "🔫 GUN DROPPED!",
            Text = "The Sheriff has died! Press " .. grabGunKey.Name .. " to grab it!",
            Duration = 5,
        })
    end
end)

_G.SavedMapLocations = _G.SavedMapLocations or {}

local mm2MapNames = {
    "Lobby", "Bank", "Bank2", "BioLab", "Factory", "Hospital", "Hospital2", "Hospital3", 
    "Hotel", "Hotel2", "House", "House2", "Mansion", "Mansion2", "MilBase", "NStudio", 
    "Office", "Office2", "Office3", "PoliceStation", "ResearchFacility", "Workplace", 
    "Custom1", "Custom2"
}

pcall(function()
    if isfile and readfile then
        for _, name in ipairs(mm2MapNames) do
            local fileName = "DH_MM2_" .. name .. "Spot.txt"
            if isfile(fileName) then
                local data = readfile(fileName)
                local split = string.split(data, ",")
                if #split == 3 then
                    _G.SavedMapLocations[name] = Vector3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
                end
            end
        end
    end
end)

local TpToMapBtn = Instance.new("TextButton", mm2GunCard)
TpToMapBtn.Text        = "TELEPORT TO MAP"
TpToMapBtn.Size        = UDim2.new(1,0,0,28)
TpToMapBtn.BackgroundColor3 = C.bgBtn
TpToMapBtn.TextColor3  = C.text
TpToMapBtn.Font        = Enum.Font.GothamSemibold
TpToMapBtn.TextSize    = 13
TpToMapBtn.ZIndex      = 4
TpToMapBtn.LayoutOrder = 2
TpToMapBtn.AutoButtonColor = false
Instance.new("UICorner", TpToMapBtn).CornerRadius = UDim.new(0,7)
TpToMapBtn.MouseEnter:Connect(function() TpToMapBtn.BackgroundColor3 = C.bgBtnHover end)
TpToMapBtn.MouseLeave:Connect(function() TpToMapBtn.BackgroundColor3 = C.bgBtn end)

local TpToLobbyBtn = Instance.new("TextButton", mm2GunCard)
TpToLobbyBtn.Text        = "TELEPORT TO LOBBY"
TpToLobbyBtn.Size        = UDim2.new(1,0,0,28)
TpToLobbyBtn.BackgroundColor3 = C.bgBtn
TpToLobbyBtn.TextColor3  = C.text
TpToLobbyBtn.Font        = Enum.Font.GothamSemibold
TpToLobbyBtn.TextSize    = 13
TpToLobbyBtn.ZIndex      = 4
TpToLobbyBtn.LayoutOrder = 3
TpToLobbyBtn.AutoButtonColor = false
Instance.new("UICorner", TpToLobbyBtn).CornerRadius = UDim.new(0,7)
TpToLobbyBtn.MouseEnter:Connect(function() TpToLobbyBtn.BackgroundColor3 = C.bgBtnHover end)
TpToLobbyBtn.MouseLeave:Connect(function() TpToLobbyBtn.BackgroundColor3 = C.bgBtn end)

local SaveBank2Btn = Instance.new("TextButton", mm2GunCard)
SaveBank2Btn.Text        = "💾 SAVE BANK2 POS"
SaveBank2Btn.Size        = UDim2.new(1,0,0,28)
SaveBank2Btn.BackgroundColor3 = C.accentDim
SaveBank2Btn.TextColor3  = Color3.new(1,1,1)
SaveBank2Btn.Font        = Enum.Font.GothamSemibold
SaveBank2Btn.TextSize    = 13
SaveBank2Btn.ZIndex      = 4
SaveBank2Btn.LayoutOrder = 4
SaveBank2Btn.AutoButtonColor = false
Instance.new("UICorner", SaveBank2Btn).CornerRadius = UDim.new(0,7)
SaveBank2Btn.MouseEnter:Connect(function() SaveBank2Btn.BackgroundColor3 = C.accent end)
SaveBank2Btn.MouseLeave:Connect(function() SaveBank2Btn.BackgroundColor3 = C.accentDim end)

SaveBank2Btn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local pos = root.Position
    _G.SavedMapLocations["Bank2"] = pos
    
    if writefile then
        pcall(function()
            writefile("DH_MM2_Bank2Spot.txt", pos.X .. "," .. pos.Y .. "," .. pos.Z)
        end)
    end
    
    SaveBank2Btn.Text = "SAVED: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z)
    task.delay(2, function() SaveBank2Btn.Text = "💾 SAVE BANK2 POS" end)
end)

local function getCenterPos(folder)
    local totalPos = Vector3.new(0,0,0)
    local count = 0
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("BasePart") then
            totalPos = totalPos + obj.Position
            count = count + 1
            if count > 50 then break end
        end
    end
    if count > 0 then return totalPos / count end
    return nil
end

TpToMapBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local targetPos = nil
    local foundMapName = nil
    
    local mapFolder = Workspace:FindFirstChild("Normal")
    if mapFolder then
        for _, mapModel in ipairs(mapFolder:GetChildren()) do
            if mapModel:IsA("Model") or mapModel:IsA("Folder") then
                foundMapName = mapModel.Name
                break
            end
        end
    end
    
    if not foundMapName then
        for _, name in ipairs(mm2MapNames) do
            if name ~= "Lobby" and Workspace:FindFirstChild(name) then
                foundMapName = name
                break
            end
        end
    end

    if foundMapName and _G.SavedMapLocations[foundMapName] then
        targetPos = _G.SavedMapLocations[foundMapName]
    else
        if mapFolder then
            local spawns = mapFolder:FindFirstChild("Spawns")
            if spawns and #spawns:GetChildren() > 0 then
                targetPos = spawns:GetChildren()[1].Position + Vector3.new(0, 5, 0)
            else
                local center = getCenterPos(mapFolder)
                if center then targetPos = center + Vector3.new(0, 20, 0) end
            end
        end
        
        if not targetPos then
            local map = Workspace:FindFirstChild("Map")
            if map then targetPos = getCenterPos(map) end
            if targetPos then targetPos = targetPos + Vector3.new(0, 20, 0) end
        end
        
        if not targetPos then targetPos = Vector3.new(0, 10, 0) end
    end
    
    root.CFrame = CFrame.new(targetPos)
end)

TpToLobbyBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local lobbyPos = nil
    
    if _G.SavedMapLocations["Lobby"] then
        lobbyPos = _G.SavedMapLocations["Lobby"]
    end
    
    if not lobbyPos then
        lobbyPos = Vector3.new(-109, 145, 14)
    end
    
    root.CFrame = CFrame.new(lobbyPos)
end)

do
-- ===== CUSTOM ANIMATIONS CARD =====
local animCard = makeCard(PlayerFrame, 5)
makeLabel(animCard, "🕺 CUSTOM ANIMATIONS", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local animPacks = {
    ["Zombie"]    = { idle="616158929",  walk="616168032",  run="616163682",  jump="616161997",  fall="616157476" },
    ["Ninja"]     = { idle="656117400",  walk="656121766",  run="656118852",  jump="656117878",  fall="656115606" },
    ["Vampire"]   = { idle="1083195517", walk="1083195982", run="1083214717", jump="1083218792", fall="1083189019" },
    ["Superhero"] = { idle="782841498",  walk="782843345",  run="782842708",  jump="782847020",  fall="782846423" },
    ["Mage"]      = { idle="1083249320", walk="1083250144", run="1083249961", jump="1083251021", fall="1083248666" }
}

local function setAnimPack(packName)
    local char = LocalPlayer.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local pack = animPacks[packName]
    if not pack then return end
    
    local function setA(pName, cName, id)
        local p = animate:FindFirstChild(pName)
        if p then
            local c = p:FindFirstChild(cName)
            if c and c:IsA("Animation") then
                c.AnimationId = "rbxassetid://" .. id
            end
        end
    end
    
    setA("idle", "Animation1", pack.idle)
    setA("idle", "Animation2", pack.idle)
    setA("walk", "WalkAnim", pack.walk)
    setA("run", "RunAnim", pack.run)
    setA("jump", "JumpAnim", pack.jump)
    setA("fall", "FallAnim", pack.fall)
end

local packNames = {"Zombie", "Ninja", "Vampire", "Superhero", "Mage"}
for i, pName in ipairs(packNames) do
    local btn = Instance.new("TextButton", animCard)
    btn.Text             = pName
    btn.Size             = UDim2.new(1,0,0,24)
    btn.BackgroundColor3 = C.bgBtn
    btn.TextColor3       = C.text
    btn.Font             = Enum.Font.GothamSemibold
    btn.TextSize         = 12
    btn.AutoButtonColor  = false
    btn.ZIndex           = 4
    btn.LayoutOrder      = i
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgBtn end)
    btn.MouseButton1Click:Connect(function()
        setAnimPack(pName)
        btn.Text = "APPLIED: " .. string.upper(pName)
        task.delay(1.5, function() btn.Text = pName end)
    end)
end
end



-- Fling Logic for MM2 Targets
local function flingTarget(targetPlayer)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local oldWalkSpeed = hum.WalkSpeed
    hum.WalkSpeed = 0 -- Keep us from drifting during the fling

    -- Setup violent fling physics
    local spinForce = Instance.new("BodyAngularVelocity")
    spinForce.Name = "FlingForce"
    spinForce.MaxTorque = Vector3.new(1, 1, 1) * math.huge
    spinForce.AngularVelocity = Vector3.new(0, 99999, 0)
    spinForce.Parent = root

    -- Store original position to snap back to
    local originalPos = root.CFrame
    
    -- Bypass noclip checks temporarily
    local oldNoclip = noclipEnabled
    noclipEnabled = true

    local startTime = tick()
    local flingConn
    flingConn = RunService.Heartbeat:Connect(function()
        if tick() - startTime > 0.8 or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Cleanup
            if spinForce then spinForce:Destroy() end
            hum.WalkSpeed = oldWalkSpeed
            noclipEnabled = oldNoclip
            root.Velocity = Vector3.new(0,0,0)
            root.RotVelocity = Vector3.new(0,0,0)
            root.CFrame = originalPos -- Snap back to where we started
            if flingConn then flingConn:Disconnect() end
            return
        end
        
        -- Glitch the physics engine by teleporting directly inside their collision box
        local tr = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            pcall(function()
                -- Predict where they will be based on their current velocity so they can't walk out of it
                local predictedPos = tr.Position + (tr.Velocity * RunService.Heartbeat:Wait())
                root.CFrame = CFrame.new(predictedPos) * CFrame.Angles(math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)), math.rad(math.random(-180, 180)))
                -- Explicitly set our velocity to an absurd number to force collision resolution
                root.Velocity = Vector3.new(0, 99999, 0)
            end)
        end
    end)
end

local function getMM2PlayersByRole(roleFilter)
    local targets = {}
    local discoveredNewRole = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isM = false
            local isS = false
            
            -- Check role dictionary
            if _G.MM2_Roles then
                if _G.MM2_Roles[p.Name] == "Murderer" then isM = true end
                if _G.MM2_Roles[p.Name] == "Sheriff" then isS = true end
            end
            -- Fallback: check physical weapons
            local bp = p:FindFirstChild("Backpack")
            local c = p.Character
            if (bp and bp:FindFirstChild("Knife")) or (c and c:FindFirstChild("Knife")) then 
                isM = true 
                if _G.MM2_Roles[p.Name] ~= "Murderer" then
                    _G.MM2_Roles[p.Name] = "Murderer"
                    discoveredNewRole = true
                end
            end
            if (bp and bp:FindFirstChild("Gun")) or (c and c:FindFirstChild("Gun")) then 
                isS = true
                if _G.MM2_Roles[p.Name] ~= "Sheriff" then
                    _G.MM2_Roles[p.Name] = "Sheriff"
                    discoveredNewRole = true
                end
            end
            
            if roleFilter == "Murderer" and isM then
                table.insert(targets, p)
            elseif roleFilter == "Sheriff" and isS then
                table.insert(targets, p)
            elseif roleFilter == "All" then
                table.insert(targets, p)
            end
        end
    end
    if discoveredNewRole and mm2EspEnabled then
        fullESPRefresh()
    end
    return targets
end

do
-- MM2 Fling Targets Card
local flingCard = makeCard(MiscFrame, 6)
makeLabel(flingCard, "🌪  MM2 TROLL (FLING)", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local function createFlingBtn(parent, text, order, roleFilter)
    local btn = Instance.new("TextButton", parent)
    btn.Text        = text
    btn.Size        = UDim2.new(1,0,0,28)
    btn.BackgroundColor3 = C.bgBtn
    btn.TextColor3  = C.text
    btn.Font        = Enum.Font.GothamSemibold
    btn.TextSize    = 13
    btn.ZIndex      = 4
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgBtn end)
    btn.MouseButton1Click:Connect(function()
        local targets = getMM2PlayersByRole(roleFilter)
        if #targets > 0 then
            -- Just fling the first match if it's a specific role, otherwise try to hit the first person in list
            flingTarget(targets[1])
        end
    end)
    return btn
end

createFlingBtn(flingCard, "FLING MURDERER", 1, "Murderer")
createFlingBtn(flingCard, "FLING SHERIFF", 2, "Sheriff")
createFlingBtn(flingCard, "FLING ANYONE", 3, "All")
end

do
local autoDodgeKnifeEnabled = false
local autoDodgeConn = nil
local function toggleAutoDodgeKnife(on)
    autoDodgeKnifeEnabled = on
    if not on then
        if autoDodgeConn then autoDodgeConn:Disconnect(); autoDodgeConn = nil end
        return
    end
    
    local function getSafeDodgeCFrame(char, root, direction, distance)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local rayResult = Workspace:Raycast(root.Position, direction * distance, rayParams)
        if rayResult then
            local hitDist = (rayResult.Position - root.Position).Magnitude
            local safeDist = math.max(0, hitDist - 2.5) -- 2.5 studs padding from the wall
            return root.CFrame + (direction * safeDist), true, hitDist
        else
            return root.CFrame + (direction * distance), false, distance
        end
    end
    
    local lastDodgeTime = 0
    autoDodgeConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local root = char.HumanoidRootPart
        
        if tick() - lastDodgeTime < 0.5 then return end
        
        -- 1. Check for Murderer getting too close (Melee range)
        local mChar = nil
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if (_G.MM2_Roles and _G.MM2_Roles[p.Name] == "Murderer") or p.Character:FindFirstChild("Knife") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife")) then
                    mChar = p.Character
                    break
                end
            end
        end
        
        if mChar and mChar:FindFirstChild("HumanoidRootPart") then
            local mRoot = mChar.HumanoidRootPart
            local dist = (mRoot.Position - root.Position).Magnitude
            
            -- Preemptive check: Are we trapped?
            if dist < 25 then
                local awayVector = (root.Position - mRoot.Position).Unit
                local safeCFrame, wasBlocked, hitDist = getSafeDodgeCFrame(char, root, awayVector, 25)
                
                if wasBlocked and hitDist < 12 then
                    -- Cornered! Teleport behind the murderer early (ninja evade)
                    root.CFrame = mRoot.CFrame * CFrame.new(0, 3, 6)
                    lastDodgeTime = tick()
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "🥷 NINJA EVADE!",
                            Text = "Cornered! Blinked behind the Murderer!",
                            Duration = 2,
                        })
                    end)
                    return
                elseif dist < 15 then
                    -- Not cornered, but they got too close! Normal backward evade.
                    root.CFrame = safeCFrame + Vector3.new(0, 3, 0)
                    lastDodgeTime = tick()
                    pcall(function()
                        game:GetService("StarterGui"):SetCore("SendNotification", {
                            Title = "🏃 MELEE EVADED!",
                            Text = "Murderer got too close! You blinked away!",
                            Duration = 2,
                        })
                    end)
                    return
                end
            end
        end
        
        -- 2. Check for Thrown Knife
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Knife" and obj:IsA("BasePart") then
                if obj.Velocity.Magnitude > 15 then
                    local dist = (obj.Position - root.Position).Magnitude
                    if dist < 25 then
                        local dirToUs = (root.Position - obj.Position).Unit
                        local moveDir = obj.Velocity.Unit
                        local dot = moveDir:Dot(dirToUs)
                        
                        -- If dot > 0.75, it's heading directly towards us
                        if dot > 0.75 then
                            local rightVector = root.CFrame.RightVector
                            -- Teleport safely to the side without clipping out of map
                            root.CFrame = getSafeDodgeCFrame(char, root, rightVector, 15)
                            lastDodgeTime = tick()
                            
                            pcall(function()
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = "🏃 KNIFE DODGED!",
                                    Text = "Auto-Dodge just saved your life!",
                                    Duration = 2,
                                })
                            end)
                            return
                        end
                    end
                end
            end
        end
    end)
end

local dodgeCard = makeCard(MiscFrame, 7)
makeLabel(dodgeCard, "🏃 AUTO EVADE (GOD MODE)", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0
makeToggleRow(dodgeCard, "Enable God Mode Evade", false, 1, toggleAutoDodgeKnife)
end

do
-- Teleport list card
local tpCard = makeCard(MiscFrame, 8)
makeLabel(tpCard, "📍  PLAYER TELEPORT", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local PlayerListFrame = Instance.new("ScrollingFrame", tpCard)
PlayerListFrame.Size             = UDim2.new(1,0,0,120)
PlayerListFrame.BackgroundColor3 = C.bg
PlayerListFrame.BorderSizePixel  = 0
PlayerListFrame.ScrollBarThickness = 4
PlayerListFrame.ScrollBarImageColor3 = C.accent
PlayerListFrame.CanvasSize       = UDim2.new(0,0,0,0)
PlayerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerListFrame.ZIndex           = 4
PlayerListFrame.LayoutOrder      = 1
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0,6)
local PlayerListLayout = Instance.new("UIListLayout", PlayerListFrame)
PlayerListLayout.SortOrder = Enum.SortOrder.Name
PlayerListLayout.Padding   = UDim.new(0,3)
local plPad = Instance.new("UIPadding", PlayerListFrame)
plPad.PaddingLeft = UDim.new(0,4); plPad.PaddingRight = UDim.new(0,4)
plPad.PaddingTop  = UDim.new(0,4)

local RefreshPlayersBtn = Instance.new("TextButton", tpCard)
RefreshPlayersBtn.Text        = "⟳  REFRESH LIST"
RefreshPlayersBtn.Size        = UDim2.new(1,0,0,28)
RefreshPlayersBtn.BackgroundColor3 = C.accentDim
RefreshPlayersBtn.TextColor3  = Color3.new(1,1,1)
RefreshPlayersBtn.Font        = Enum.Font.GothamSemibold
RefreshPlayersBtn.TextSize    = 13
RefreshPlayersBtn.ZIndex      = 4
RefreshPlayersBtn.LayoutOrder = 2
RefreshPlayersBtn.AutoButtonColor = false
Instance.new("UICorner", RefreshPlayersBtn).CornerRadius = UDim.new(0,7)
RefreshPlayersBtn.MouseEnter:Connect(function() RefreshPlayersBtn.BackgroundColor3 = C.accent end)
RefreshPlayersBtn.MouseLeave:Connect(function() RefreshPlayersBtn.BackgroundColor3 = C.accentDim end)

function refreshPlayerList()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local btn = Instance.new("TextButton", PlayerListFrame)
                btn.Text             = player.Name
                btn.Size             = UDim2.new(1,0,0,26)
                btn.BackgroundColor3 = C.bgSection
                btn.TextColor3       = C.text
                btn.Font             = Enum.Font.Gotham
                btn.TextSize         = 13
                btn.AutoButtonColor  = false
                btn.ZIndex           = 5
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
                btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
                btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgSection end)
                btn.MouseButton1Click:Connect(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local tChar = player.Character
                    if tChar then
                        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                        if tRoot then
                            root.CFrame = CFrame.new(tRoot.Position + Vector3.new(0,3,0))
                        end
                    end
                end)
            end
        end
    end
    if _G.RefreshBgList then _G.RefreshBgList() end
end
RefreshPlayersBtn.MouseButton1Click:Connect(refreshPlayerList)
end

do
-- ============================================================
--  BODYGUARD ENGINE
-- ============================================================
local bodyguardTarget = nil
local bodyguardConn = nil

local function toggleBodyguard(playerNameChunk)
    if bodyguardConn then
        bodyguardConn:Disconnect()
        bodyguardConn = nil
        bodyguardTarget = nil
        return false, ""
    end
    
    if not playerNameChunk or playerNameChunk == "" then return false, "" end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(string.sub(p.Name, 1, #playerNameChunk)) == string.lower(playerNameChunk) or string.lower(string.sub(p.DisplayName, 1, #playerNameChunk)) == string.lower(playerNameChunk) then
            bodyguardTarget = p
            break
        end
    end
    
    if not bodyguardTarget then return false, "NOT FOUND!" end
    if bodyguardTarget == LocalPlayer then return false, "CAN'T PROTECT SELF!" end

    bodyguardConn = RunService.Heartbeat:Connect(function()
        if not bodyguardTarget or not bodyguardTarget.Character or not bodyguardTarget.Character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local root = char.HumanoidRootPart
        local tRoot = bodyguardTarget.Character.HumanoidRootPart
        
        -- Find Murderer
        local mChar = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p ~= bodyguardTarget and p.Character then
                if (_G.MM2_Roles and _G.MM2_Roles[p.Name] == "Murderer") or p.Character:FindFirstChild("Knife") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife")) then
                    mChar = p.Character
                    break
                end
            end
        end
        
        -- Meat shield for melee
        if mChar and mChar:FindFirstChild("HumanoidRootPart") then
            local mRoot = mChar.HumanoidRootPart
            local dist = (mRoot.Position - tRoot.Position).Magnitude
            if dist < 30 then
                -- Teleport directly between them, further away from the target
                local midPos = tRoot.Position + (mRoot.Position - tRoot.Position).Unit * 6
                root.CFrame = CFrame.new(midPos, mRoot.Position)
                return
            end
        end
        
        -- Meat shield for thrown knife
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Knife" and obj:IsA("BasePart") then
                if obj.Velocity.Magnitude > 10 then
                    local knifeDistToTarget = (obj.Position - tRoot.Position).Magnitude
                    if knifeDistToTarget < 30 then
                        -- Jump exactly in front of the knife
                        local interceptPos = obj.Position + (obj.Velocity.Unit * 2.5)
                        root.CFrame = CFrame.new(interceptPos)
                        return
                    end
                end
            end
        end
    end)
    
    return true, string.upper(bodyguardTarget.Name)
end

local protectCard = makeCard(MiscFrame, 9)
makeLabel(protectCard, "🛡️ BODYGUARD MODE", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local BgListFrame = Instance.new("ScrollingFrame", protectCard)
BgListFrame.Size             = UDim2.new(1,0,0,100)
BgListFrame.BackgroundColor3 = C.bg
BgListFrame.BorderSizePixel  = 0
BgListFrame.ScrollBarThickness = 4
BgListFrame.ScrollBarImageColor3 = C.accent
BgListFrame.CanvasSize       = UDim2.new(0,0,0,0)
BgListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
BgListFrame.ZIndex           = 4
BgListFrame.LayoutOrder      = 1
Instance.new("UICorner", BgListFrame).CornerRadius = UDim.new(0,6)
local BgListLayout = Instance.new("UIListLayout", BgListFrame)
BgListLayout.SortOrder = Enum.SortOrder.Name
BgListLayout.Padding   = UDim.new(0,3)
local bgPad = Instance.new("UIPadding", BgListFrame)
bgPad.PaddingLeft = UDim.new(0,4); bgPad.PaddingRight = UDim.new(0,4)
bgPad.PaddingTop  = UDim.new(0,4)

local toggleProtectBtn = Instance.new("TextButton", protectCard)
toggleProtectBtn.Text = "► SELECT A PLAYER ABOVE"
toggleProtectBtn.Size = UDim2.new(1,0,0,28)
toggleProtectBtn.BackgroundColor3 = C.accentDim
toggleProtectBtn.TextColor3 = Color3.new(1,1,1)
toggleProtectBtn.Font = Enum.Font.GothamBold
toggleProtectBtn.TextSize = 13
toggleProtectBtn.AutoButtonColor = false
toggleProtectBtn.LayoutOrder = 2
toggleProtectBtn.ZIndex = 4
Instance.new("UICorner", toggleProtectBtn).CornerRadius = UDim.new(0,6)
toggleProtectBtn.MouseEnter:Connect(function() 
    if not bodyguardConn then toggleProtectBtn.BackgroundColor3 = C.accent end
end)
toggleProtectBtn.MouseLeave:Connect(function() 
    if not bodyguardConn then toggleProtectBtn.BackgroundColor3 = C.accentDim end
end)

toggleProtectBtn.MouseButton1Click:Connect(function()
    if bodyguardConn then
        toggleBodyguard("") -- Pass empty string to disconnect
        toggleProtectBtn.Text = "► SELECT A PLAYER ABOVE"
        toggleProtectBtn.BackgroundColor3 = C.accentDim
    end
end)

_G.RefreshBgList = function()
    for _, child in ipairs(BgListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton", BgListFrame)
            btn.Text             = player.Name
            btn.Size             = UDim2.new(1,0,0,26)
            btn.BackgroundColor3 = C.bgSection
            btn.TextColor3       = C.text
            btn.Font             = Enum.Font.Gotham
            btn.TextSize         = 13
            btn.AutoButtonColor  = false
            btn.ZIndex           = 5
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgSection end)
            btn.MouseButton1Click:Connect(function()
                local success, ret = toggleBodyguard(player.Name)
                if success then
                    toggleProtectBtn.Text = "■ STOP PROTECTING: " .. ret
                    toggleProtectBtn.BackgroundColor3 = C.onGreen
                else
                    toggleProtectBtn.Text = "► SELECT A PLAYER ABOVE"
                    toggleProtectBtn.BackgroundColor3 = C.accentDim
                end
            end)
        end
    end
end
_G.RefreshBgList()
end

do
-- Utilities card (Respawn / Rejoin / Chat)
local utilCard = makeCard(MiscFrame, 10)
makeLabel(utilCard, "🛠  UTILITIES", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local function createUtilBtn(parent, text, order, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Text        = text
    btn.Size        = UDim2.new(1,0,0,28)
    btn.BackgroundColor3 = C.bgBtn
    btn.TextColor3  = C.text
    btn.Font        = Enum.Font.GothamSemibold
    btn.TextSize    = 13
    btn.ZIndex      = 4
    btn.LayoutOrder = order
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.bgBtnHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bgBtn end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

createUtilBtn(utilCard, "💀 RESPAWN CHARACTER", 1, function()
    local char = LocalPlayer.Character
    if char then
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root:Destroy() end
        if head then head:Destroy() end
    end
end)

createUtilBtn(utilCard, "🔄 REJOIN SERVER", 2, function()
    local ts = game:GetService("TeleportService")
    local p = game:GetService("Players").LocalPlayer
    ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, p)
end)

createUtilBtn(utilCard, "🎲 JOIN RANDOM SERVER", 3, function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    
    task.spawn(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success and result then
            local decoded = HttpService:JSONDecode(result)
            if decoded and decoded.data then
                -- Manually sort servers by highest player count to avoid API sort errors
                table.sort(decoded.data, function(a, b)
                    return (a.playing or 0) > (b.playing or 0)
                end)
                
                local validServers = {}
                for _, s in ipairs(decoded.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(validServers, s.id)
                    end
                end
                
                if #validServers > 0 then
                    -- Restrict random selection to only the top 10 most full servers
                    local maxIndex = math.min(#validServers, 10)
                    local randomId = validServers[math.random(1, maxIndex)]
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomId, LocalPlayer)
                end
            end
        end
    end)
end)

local bypassMap = {
    ["a"] = "а", ["A"] = "А", ["c"] = "с", ["C"] = "С", ["e"] = "е", ["E"] = "Е", 
    ["o"] = "о", ["O"] = "О", ["p"] = "р", ["P"] = "Р", ["x"] = "х", ["X"] = "Х", 
    ["y"] = "у", ["i"] = "і", ["I"] = "І", ["M"] = "Μ", ["N"] = "Ν", ["T"] = "Τ", 
    ["H"] = "Η", ["K"] = "Κ", ["Z"] = "Ζ", ["B"] = "Β"
}

local function applyBypass(str)
    local bypassed = ""
    for i = 1, #str do
        local char = str:sub(i, i)
        if bypassMap[char] then
            bypassed = bypassed .. bypassMap[char]
        else
            bypassed = bypassed .. char
        end
        if math.random() > 0.5 then
            bypassed = bypassed .. "\226\128\138"
        else
            bypassed = bypassed .. "\226\128\139"
        end
    end
    return bypassed
end

local BypassContainer = Instance.new("Frame", utilCard)
BypassContainer.Size = UDim2.new(1, 0, 0, 28)
BypassContainer.BackgroundTransparency = 1
BypassContainer.LayoutOrder = 3

local BypassBox = Instance.new("TextBox", BypassContainer)
BypassBox.Size = UDim2.new(0.75, -4, 1, 0)
BypassBox.Position = UDim2.new(0, 0, 0, 0)
BypassBox.BackgroundColor3 = C.bgSection
BypassBox.TextColor3 = C.text
BypassBox.PlaceholderText = "Type bypassed chat here..."
BypassBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
BypassBox.Font = Enum.Font.GothamSemibold
BypassBox.TextSize = 12
BypassBox.TextXAlignment = Enum.TextXAlignment.Left
BypassBox.ClearTextOnFocus = false
Instance.new("UICorner", BypassBox).CornerRadius = UDim.new(0, 5)

local UIPadding = Instance.new("UIPadding", BypassBox)
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingRight = UDim.new(0, 8)

local SendBtn = Instance.new("TextButton", BypassContainer)
SendBtn.Size = UDim2.new(0.25, 0, 1, 0)
SendBtn.Position = UDim2.new(0.75, 0, 0, 0)
SendBtn.BackgroundColor3 = C.accent
SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SendBtn.Text = "SEND"
SendBtn.Font = Enum.Font.GothamBold
SendBtn.TextSize = 12
Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(0, 5)

local function sendBypassedChat()
    local rawText = BypassBox.Text
    if rawText == "" then return end
    
    local safeText = applyBypass(rawText)
    
    local TextChatService = game:GetService("TextChatService")
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        -- Modern Chat
        local targetChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if targetChannel then
            targetChannel:SendAsync(safeText)
        end
    else
        -- Legacy Chat
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local DefaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if DefaultChatSystemChatEvents then
            local SayMessageRequest = DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
            if SayMessageRequest then
                SayMessageRequest:FireServer(safeText, "All")
            end
        end
    end
    
    BypassBox.Text = ""
end

SendBtn.MouseButton1Click:Connect(sendBypassedChat)
BypassBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendBypassedChat()
    end
end)

local SystemBypassContainer = Instance.new("Frame", utilCard)
SystemBypassContainer.Size = UDim2.new(1, 0, 0, 28)
SystemBypassContainer.BackgroundTransparency = 1
SystemBypassContainer.LayoutOrder = 4

local SysBox = Instance.new("TextBox", SystemBypassContainer)
SysBox.Size = UDim2.new(0.75, -4, 1, 0)
SysBox.Position = UDim2.new(0, 0, 0, 0)
SysBox.BackgroundColor3 = C.bgSection
SysBox.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red text to indicate system forgery
SysBox.PlaceholderText = "Fake [System] Message..."
SysBox.PlaceholderColor3 = Color3.fromRGB(150, 100, 100)
SysBox.Font = Enum.Font.GothamSemibold
SysBox.TextSize = 12
SysBox.TextXAlignment = Enum.TextXAlignment.Left
SysBox.ClearTextOnFocus = false
Instance.new("UICorner", SysBox).CornerRadius = UDim.new(0, 5)

local SysPadding = Instance.new("UIPadding", SysBox)
SysPadding.PaddingLeft = UDim.new(0, 8)
SysPadding.PaddingRight = UDim.new(0, 8)

local SysSendBtn = Instance.new("TextButton", SystemBypassContainer)
SysSendBtn.Size = UDim2.new(0.25, 0, 1, 0)
SysSendBtn.Position = UDim2.new(0.75, 0, 0, 0)
SysSendBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- Dark red button
SysSendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SysSendBtn.Text = "FORGE"
SysSendBtn.Font = Enum.Font.GothamBold
SysSendBtn.TextSize = 12
Instance.new("UICorner", SysSendBtn).CornerRadius = UDim.new(0, 5)

local function sendFakeSystemMessage()
    local rawText = SysBox.Text
    if rawText == "" then return end
    
    -- Format it exactly like an official server broadcast, but apply the bypass to evade filters
    -- The trailing spaces push the local player's actual name out of view in the chat box if possible
    local fakeFormat = "                                                                                             [System]: " .. rawText
    local safeText = applyBypass(fakeFormat)
    
    local TextChatService = game:GetService("TextChatService")
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local targetChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if targetChannel then
            targetChannel:SendAsync(safeText)
        end
    else
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local DefaultChatSystemChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if DefaultChatSystemChatEvents then
            local SayMessageRequest = DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
            if SayMessageRequest then
                SayMessageRequest:FireServer(safeText, "All")
            end
        end
    end
    
    SysBox.Text = ""
end

SysSendBtn.MouseButton1Click:Connect(sendFakeSystemMessage)
SysBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendFakeSystemMessage()
    end
end)

-- ============================================================
-- CONFIGURATION SAVE/LOAD
-- ============================================================
local configCard = makeCard(MiscFrame, 11)
makeLabel(configCard, "💾  CONFIGURATION", UDim2.new(1,0,0,18), UDim2.new(0,0,0,0), 12, true, C.accent).LayoutOrder = 0

local function getSettingsTable()
    return {
        ["Enable Aimbot"] = aimbotEnabled,
        ["FOV Radius (px)"] = fov,
        ["Enable Wallbang (Shoot through walls)"] = wallbangEnabled,
        ["Enable Spin Bot"] = spinBotEnabled,
        ["Spin Speed (deg/s)"] = spinSpeedDeg,
        ["Enable Flick"] = flickEnabled,
        ["Flick Interval (s)"] = flickInterval,
        ["Enable ESP"] = espEnabled,
        ["Team ESP"] = teamEspEnabled,
        ["MM2 Roles ESP (Red=M, Blue=S, Green=I)"] = mm2EspEnabled,
        ["MM2 Role Notifications"] = roleNotificationsEnabled,
        ["MM2 Dropped Gun ESP (Purple)"] = mm2GunEspEnabled,
        ["Box ESP"] = boxEnabled,
        ["Skeleton ESP"] = skeletonEnabled,
        ["Name Tag"] = nameEnabled,
        ["Health Bar"] = healthEnabled,
        ["Chams"] = chamsEnabled,
        ["Box Thickness (px)"] = boxThickness,
        ["Skeleton Thickness (px)"] = skeletonThickness,
        ["Tracers"] = tracerEnabled,
        ["Tracer Thickness (px)"] = tracerThickness,
        ["Enable Flight"] = flightEnabled,
        ["Flight Speed"] = flightSpeed,
        ["Enable Noclip"] = noclipEnabled,
        ["Noclip Speed"] = noclipSpeed,
        ["Enable Speed"] = speedEnabled,
        ["Walk Speed"] = walkSpeed,
        ["Enable Jump Boost"] = jumpEnabled,
        ["Jump Power"] = jumpPower,
        ["True Wallbang (Grip Offset Method)"] = trueMm2Wallbang,
        ["Blink-Kill Method (Press Q with Gun)"] = blinkKillWallbang,
        ["Enemy Color"] = {r = enemyR, g = enemyG, b = enemyB},
        ["Team Color"]  = {r = teamR,  g = teamG,  b = teamB},
        ["FOV Circle Color"] = {r = fovR, g = fovG, b = fovB}
    }
end

createUtilBtn(configCard, "💾 SAVE CONFIG", 1, function()
    local HttpService = game:GetService("HttpService")
    local settings = getSettingsTable()
    pcall(function()
        if writefile then
            writefile("DH_GlassHouse_Config.json", HttpService:JSONEncode(settings))
            game.StarterGui:SetCore("SendNotification", {Title = "CONFIG SAVED", Text = "Your settings have been saved to your executor workspace.", Duration = 3})
        end
    end)
end)

createUtilBtn(configCard, "📂 LOAD CONFIG", 2, function()
    local HttpService = game:GetService("HttpService")
    pcall(function()
        if readfile and isfile and isfile("DH_GlassHouse_Config.json") then
            local data = readfile("DH_GlassHouse_Config.json")
            local cfg = HttpService:JSONDecode(data)
            
            for labelName, savedVal in pairs(cfg) do
                if _G.ConfigSetters[labelName] then
                    if type(savedVal) == "table" and savedVal.r and savedVal.g and savedVal.b then
                        -- Handle color swatches
                        pcall(function() _G.ConfigSetters[labelName](savedVal.r, savedVal.g, savedVal.b) end)
                        if labelName == "Enemy Color" then enemyR, enemyG, enemyB = savedVal.r, savedVal.g, savedVal.b; enemyColor = Color3.fromRGB(enemyR, enemyG, enemyB) end
                        if labelName == "Team Color" then teamR, teamG, teamB = savedVal.r, savedVal.g, savedVal.b; teamColor = Color3.fromRGB(teamR, teamG, teamB) end
                        if labelName == "FOV Circle Color" then fovR, fovG, fovB = savedVal.r, savedVal.g, savedVal.b; aimbotFovColor = Color3.fromRGB(fovR, fovG, fovB) end
                    else
                        pcall(function() _G.ConfigSetters[labelName](savedVal) end)
                    end
                end
            end
            
            game.StarterGui:SetCore("SendNotification", {Title = "CONFIG LOADED", Text = "All saved settings have been successfully applied.", Duration = 3})
        else
            game.StarterGui:SetCore("SendNotification", {Title = "LOAD FAILED", Text = "No DH_GlassHouse_Config.json found in your executor workspace.", Duration = 3})
        end
    end)
end)

end

-- initial tab
switchTab("AIMBOT")

-- ============================================================
--  ESP DATA STORAGE & LOGIC
-- ============================================================

local espPlayerData = {}

local function clearAllESPData()
    for _, data in pairs(espPlayerData) do
        if data.highlight     then data.highlight:Destroy() end
        if data.nameBillboard then data.nameBillboard:Destroy() end
        if data.healthBillboard then data.healthBillboard:Destroy() end
        if data.healthConnection then data.healthConnection:Disconnect() end
        if data.boxLines      then for _,l in ipairs(data.boxLines)      do pcall(function() l:Remove() end) end end
        if data.skeletonLines then for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end end
        if data.tracerLine    then pcall(function() data.tracerLine:Remove() end) end
        for _, conn in ipairs(data.connections or {}) do pcall(function() conn:Disconnect() end) end
    end
    espPlayerData = {}
end

local function updateHealthBar(data, humanoid)
    if not data.healthBar or not humanoid then return end
    local hp = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth,1), 0, 1)
    data.healthBar.Size            = UDim2.new(1,0, hp, 0)
    data.healthBar.BackgroundColor3= Color3.new(1-hp, hp, 0)
end

local lastMM2RoundCheck = 0
local cachedMM2RoundActive = false

local function isMM2RoundActive()
    -- Instead of checking for physical weapons (which limits speed), 
    -- we just check if our bypass ping has successfully retrieved roles from the server.
    if _G.MM2_Roles then
        for _, role in pairs(_G.MM2_Roles) do
            if role == "Murderer" or role == "Sheriff" or role == "Hero" then
                return true
            end
        end
    end
    return false
end

local function getColorForTarget(obj)
    -- obj can be a Player or nil (for bots we pass nil)
    if obj == nil then return enemyColor end  -- bots always enemy color
    
    if mm2EspEnabled and isMM2RoundActive() then
        local isMurderer = false
        local isSheriff  = false
        
        -- Use the bypassed role table exclusively (instant roles before weapons drop)
        if _G.MM2_Roles and _G.MM2_Roles[obj.Name] then
            local role = _G.MM2_Roles[obj.Name]
            if role == "Murderer" then isMurderer = true end
            if role == "Sheriff" or role == "Hero" then isSheriff = true end
        end
        
        if isMurderer then return Color3.fromRGB(255, 0, 0) end
        if isSheriff  then return Color3.fromRGB(0, 100, 255) end
        return Color3.fromRGB(0, 255, 0) -- Innocent
    end

    if not teamEspEnabled then return enemyColor end
    local lTeam = LocalPlayer.Team
    local pTeam = obj.Team
    if lTeam and pTeam and lTeam == pTeam then return teamColor end
    return enemyColor
end

-- Returns (character, displayName, colorToUse) for any "target" (player or bot model)
-- Bots: we look for models in Workspace that have a Humanoid but are not a player's character
local function getPlayerDisplayName(player)
    return isBot(player) and "BOT" or player.Name
end

local function setupESPForCharacter(data, character, displayName, useColor)
    data.highlight     = nil
    data.nameBillboard = nil
    data.healthBillboard = nil
    data.healthBar     = nil
    data.boxLines      = {}
    data.skeletonLines = {}

    if espEnabled and chamsEnabled then
        local h = Instance.new("Highlight")
        h.FillColor          = useColor
        h.OutlineColor       = useColor
        h.FillTransparency   = 0.25
        h.OutlineTransparency= 0.35
        h.Parent             = character
        data.highlight       = h
    end

    if nameEnabled then
        local bb = Instance.new("BillboardGui")
        bb.Name         = "ESPName"
        bb.Size         = UDim2.new(5,0,1.2,0)
        bb.StudsOffset  = Vector3.new(0,2.8,0)
        bb.AlwaysOnTop  = true
        bb.Parent       = character
        local lbl       = Instance.new("TextLabel")
        lbl.Text        = displayName
        lbl.Size        = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3  = useColor
        lbl.Font        = Enum.Font.GothamBold
        lbl.TextSize    = 14
        lbl.TextStrokeTransparency = 0.4
        lbl.Parent      = bb
        data.nameBillboard = bb
    end

    if healthEnabled then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local bb = Instance.new("BillboardGui")
            bb.Name        = "ESPHealth"
            bb.Size        = UDim2.new(0.18,0,2.2,0)
            bb.StudsOffset = Vector3.new(-1.8,0,0)
            bb.AlwaysOnTop = true
            bb.Parent      = character
            local barBg    = Instance.new("Frame")
            barBg.Size     = UDim2.new(1,0,1,0)
            barBg.BackgroundColor3 = Color3.fromRGB(0,0,0)
            barBg.BackgroundTransparency = 0.4
            barBg.BorderSizePixel = 0
            barBg.Parent  = bb
            Instance.new("UICorner",barBg).CornerRadius = UDim.new(0,2)
            local bar      = Instance.new("Frame")
            bar.Name       = "HealthBar"
            bar.AnchorPoint= Vector2.new(0,1)
            bar.Position   = UDim2.new(0,0,1,0)
            bar.Size       = UDim2.new(1,0,1,0)
            bar.BackgroundColor3 = Color3.new(0,1,0)
            bar.BorderSizePixel  = 0
            bar.Parent     = barBg
            Instance.new("UICorner",bar).CornerRadius = UDim.new(0,2)
            data.healthBillboard = bb
            data.healthBar       = bar
            data.healthConnection = humanoid.HealthChanged:Connect(function()
                updateHealthBar(data, humanoid)
            end)
            updateHealthBar(data, humanoid)
        end
    end
end

local function createESPForPlayer(player)
    if espPlayerData[player] then return end
    local data = { connections = {} }

    local function setup()
        local character = player.Character
        if not character then return end
        local useColor  = getColorForTarget(player)
        local dispName  = getPlayerDisplayName(player)
        setupESPForCharacter(data, character, dispName, useColor)
    end

    table.insert(data.connections, player.CharacterAdded:Connect(function(char)
        -- clean up
        if data.highlight     then data.highlight:Destroy() end
        if data.nameBillboard then data.nameBillboard:Destroy() end
        if data.healthBillboard then data.healthBillboard:Destroy(); data.healthBillboard=nil; data.healthBar=nil end
        if data.healthConnection then data.healthConnection:Disconnect(); data.healthConnection=nil end
        if data.boxLines    then for _,l in ipairs(data.boxLines)    do pcall(function() l:Remove() end) end data.boxLines={} end
        if data.skeletonLines then for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end data.skeletonLines={} end
        
        char:WaitForChild("HumanoidRootPart", 5)
        char:WaitForChild("Humanoid", 5)
        task.wait(0.1)
        setup()
    end))

    table.insert(data.connections, player.CharacterRemoving:Connect(function()
        if data.highlight     then data.highlight:Destroy(); data.highlight=nil end
        if data.nameBillboard then data.nameBillboard:Destroy(); data.nameBillboard=nil end
        if data.healthBillboard then data.healthBillboard:Destroy(); data.healthBillboard=nil; data.healthBar=nil end
        if data.healthConnection then data.healthConnection:Disconnect(); data.healthConnection=nil end
        if data.boxLines    then for _,l in ipairs(data.boxLines)    do pcall(function() l:Remove() end) end data.boxLines=nil end
        if data.skeletonLines then for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end data.skeletonLines=nil end
    end))

    setup()
    espPlayerData[player] = data
end

-- ===== BOT ESP STORAGE =====
-- Bots are Workspace models (not in Players) with a Humanoid.
-- We store them separately keyed by model.
local botESPData = {}

local function createESPForBot(model)
    if botESPData[model] then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local data = { connections = {} }
    setupESPForCharacter(data, model, "BOT", enemyColor)
    data.boxLines      = data.boxLines or {}
    data.skeletonLines = data.skeletonLines or {}
    -- watch for removal
    table.insert(data.connections, model.AncestryChanged:Connect(function()
        if not model:IsDescendantOf(game) then
            if data.highlight     then data.highlight:Destroy() end
            if data.nameBillboard then data.nameBillboard:Destroy() end
            if data.healthBillboard then data.healthBillboard:Destroy() end
            if data.healthConnection then data.healthConnection:Disconnect() end
            if data.boxLines    then for _,l in ipairs(data.boxLines) do pcall(function() l:Remove() end) end end
            if data.skeletonLines then for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end end
            for _,c in ipairs(data.connections) do pcall(function() c:Disconnect() end) end
            botESPData[model] = nil
        end
    end))
    botESPData[model] = data
end

local function clearBotESP()
    for _, data in pairs(botESPData) do
        if data.highlight     then data.highlight:Destroy() end
        if data.nameBillboard then data.nameBillboard:Destroy() end
        if data.healthBillboard then data.healthBillboard:Destroy() end
        if data.healthConnection then data.healthConnection:Disconnect() end
        if data.boxLines      then for _,l in ipairs(data.boxLines)      do pcall(function() l:Remove() end) end end
        if data.skeletonLines then for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end end
        if data.tracerLine    then pcall(function() data.tracerLine:Remove() end) end
        for _,c in ipairs(data.connections or {}) do pcall(function() c:Disconnect() end) end
    end
    botESPData = {}
end

-- Detects bot-like models in workspace (Humanoid but not a player's character)
local function scanForBots()
    if not espEnabled then return end
    local playerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playerChars[p.Character] = true end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and not playerChars[obj] then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                createESPForBot(obj)
            end
        end
    end
end

function fullESPRefresh()
    clearAllESPData()
    clearBotESP()
    if not espEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESPForPlayer(player)
        end
    end
    scanForBots()
end

Players.PlayerAdded:Connect(function(p)
    if espEnabled then createESPForPlayer(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    local data = espPlayerData[p]
    if data then
        if data.highlight     then data.highlight:Destroy() end
        if data.nameBillboard then data.nameBillboard:Destroy() end
        if data.healthBillboard then data.healthBillboard:Destroy() end
        if data.healthConnection then data.healthConnection:Disconnect() end
        if data.boxLines    then for _,l in ipairs(data.boxLines) do pcall(function() l:Remove() end) end end
        if data.skeletonLines then for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end end
        for _,c in ipairs(data.connections) do pcall(function() c:Disconnect() end) end
        espPlayerData[p] = nil
    end
end)

-- ============================================================
--  RENDER LOOP: BOX & SKELETON (Fixed screen-space projection)
-- ============================================================

local function drawBox(character, lines, useColor, thickness)
    for _, l in ipairs(lines) do pcall(function() l:Remove() end) end
    local newLines = {}
    if not DrawingLib then return newLines end

    -- Project all 8 bounding box corners; only skip if Z <= 0 (behind camera)
    -- We deliberately do NOT bail on onScreen==false so far-away characters still render
    local ok, cframe, size = pcall(function() return character:GetBoundingBox() end)
    if not ok or not cframe or not size then return newLines end

    local hx, hy, hz = size.X/2, size.Y/2, size.Z/2
    local corners = {
        Vector3.new(-hx,-hy,-hz), Vector3.new( hx,-hy,-hz),
        Vector3.new(-hx, hy,-hz), Vector3.new( hx, hy,-hz),
        Vector3.new(-hx,-hy, hz), Vector3.new( hx,-hy, hz),
        Vector3.new(-hx, hy, hz), Vector3.new( hx, hy, hz),
    }
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyInFront = false
    for _, off in ipairs(corners) do
        local wp = cframe:PointToWorldSpace(off)
        local sp = Camera:WorldToViewportPoint(wp)
        -- sp.Z is depth; positive = in front of camera
        if sp.Z > 0 then
            anyInFront = true
            if sp.X < minX then minX = sp.X end
            if sp.Y < minY then minY = sp.Y end
            if sp.X > maxX then maxX = sp.X end
            if sp.Y > maxY then maxY = sp.Y end
        end
    end
    -- Must have at least one corner in front and a valid box
    if not anyInFront or maxX == -math.huge then return newLines end
    -- Clamp to screen bounds so lines don't fly off to infinity
    local vp = Camera.ViewportSize
    minX = math.clamp(minX, 0, vp.X)
    minY = math.clamp(minY, 0, vp.Y)
    maxX = math.clamp(maxX, 0, vp.X)
    maxY = math.clamp(maxY, 0, vp.Y)
    if (maxX - minX) < 2 or (maxY - minY) < 2 then return newLines end

    local function drawLine(a, b)
        local line = DrawingLib.new("Line")
        line.From        = a
        line.To          = b
        line.Color       = useColor
        line.Thickness   = thickness or 1.8
        line.Transparency= 0.1
        table.insert(newLines, line)
    end

    local tl = Vector2.new(minX, minY)
    local tr = Vector2.new(maxX, minY)
    local br = Vector2.new(maxX, maxY)
    local bl = Vector2.new(minX, maxY)

    -- Corner-bracket box style
    local cx = math.max((maxX - minX) * 0.28, 4)
    local cy = math.max((maxY - minY) * 0.28, 4)
    drawLine(tl, Vector2.new(tl.X + cx, tl.Y))
    drawLine(tl, Vector2.new(tl.X, tl.Y + cy))
    drawLine(tr, Vector2.new(tr.X - cx, tr.Y))
    drawLine(tr, Vector2.new(tr.X, tr.Y + cy))
    drawLine(br, Vector2.new(br.X - cx, br.Y))
    drawLine(br, Vector2.new(br.X, br.Y - cy))
    drawLine(bl, Vector2.new(bl.X + cx, bl.Y))
    drawLine(bl, Vector2.new(bl.X, bl.Y - cy))

    return newLines
end

local function drawSkeleton(character, lines, useColor, thickness)
    for _, l in ipairs(lines) do pcall(function() l:Remove() end) end
    local newLines = {}
    if not DrawingLib then return newLines end
    local vp = Camera.ViewportSize

    local function bone(nameA, nameB)
        local pA = character:FindFirstChild(nameA)
        local pB = character:FindFirstChild(nameB)
        if not pA or not pB then return end
        -- Use Position for BasePart, fallback to WorldPosition if Attachment
        local posA = (pA:IsA("BasePart") and pA.Position) or (pA:IsA("Attachment") and pA.WorldPosition)
        local posB = (pB:IsA("BasePart") and pB.Position) or (pB:IsA("Attachment") and pB.WorldPosition)
        if not posA or not posB then return end
        local spA = Camera:WorldToViewportPoint(posA)
        local spB = Camera:WorldToViewportPoint(posB)
        -- Only draw if both points are in front of camera
        if spA.Z > 0 and spB.Z > 0 then
            local ax = math.clamp(spA.X, 0, vp.X)
            local ay = math.clamp(spA.Y, 0, vp.Y)
            local bx = math.clamp(spB.X, 0, vp.X)
            local by = math.clamp(spB.Y, 0, vp.Y)
            local ln = DrawingLib.new("Line")
            ln.From       = Vector2.new(ax, ay)
            ln.To         = Vector2.new(bx, by)
            ln.Color      = useColor
            ln.Thickness  = thickness or 1.4
            ln.Transparency = 0.15
            table.insert(newLines, ln)
        end
    end

    -- R15 + R6 coverage
    bone("Head",        "UpperTorso")
    bone("Head",        "Torso")
    bone("UpperTorso",  "LowerTorso")
    bone("Torso",       "HumanoidRootPart")
    bone("UpperTorso",  "RightUpperArm")
    bone("UpperTorso",  "LeftUpperArm")
    bone("Torso",       "Right Arm")
    bone("Torso",       "Left Arm")
    bone("RightUpperArm","RightLowerArm")
    bone("LeftUpperArm", "LeftLowerArm")
    bone("RightLowerArm","RightHand")
    bone("LeftLowerArm", "LeftHand")
    bone("LowerTorso",  "RightUpperLeg")
    bone("LowerTorso",  "LeftUpperLeg")
    bone("Torso",       "Right Leg")
    bone("Torso",       "Left Leg")
    bone("RightUpperLeg","RightLowerLeg")
    bone("LeftUpperLeg", "LeftLowerLeg")
    bone("RightLowerLeg","RightFoot")
    bone("LeftLowerLeg", "LeftFoot")

    return newLines
end

-- Tracer origin: bottom-center of the screen
local function getTracerOrigin()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y)
end

local function drawTracer(rootPart, tracerLine, useColor)
    -- tracerLine is a single Drawing.Line object or nil; we reuse it to avoid GC thrash
    if not DrawingLib then return tracerLine end
    if not rootPart then
        if tracerLine then pcall(function() tracerLine:Remove() end) end
        return nil
    end
    local sp = Camera:WorldToViewportPoint(rootPart.Position)
    if sp.Z <= 0 then
        if tracerLine then tracerLine.Visible = false end
        return tracerLine
    end
    local vp = Camera.ViewportSize
    local destX = math.clamp(sp.X, 0, vp.X)
    local destY = math.clamp(sp.Y, 0, vp.Y)
    if not tracerLine then
        tracerLine = DrawingLib.new("Line")
    end
    tracerLine.From        = getTracerOrigin()
    tracerLine.To          = Vector2.new(destX, destY)
    tracerLine.Color       = useColor
    tracerLine.Thickness   = tracerThickness
    tracerLine.Transparency= 0.25
    tracerLine.Visible     = true
    return tracerLine
end

local function updateDrawingObjects()
    if not espEnabled then return end

    -- Player ESP drawing
    for player, data in pairs(espPlayerData) do
        local character = player.Character
        if not character then continue end
        local useColor = getColorForTarget(player)
        
        -- Sync dynamic colors to Highlight and NameTag
        if data.highlight then
            data.highlight.FillColor = useColor
            data.highlight.OutlineColor = useColor
        end
        if data.nameBillboard then
            local lbl = data.nameBillboard:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.TextColor3 = useColor end
        end

        if boxEnabled then
            data.boxLines = drawBox(character, data.boxLines or {}, useColor, boxThickness)
        else
            if data.boxLines then
                for _,l in ipairs(data.boxLines) do pcall(function() l:Remove() end) end
                data.boxLines = {}
            end
        end
        if skeletonEnabled then
            data.skeletonLines = drawSkeleton(character, data.skeletonLines or {}, useColor, skeletonThickness)
        else
            if data.skeletonLines then
                for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end
                data.skeletonLines = {}
            end
        end
        if tracerEnabled then
            local root = character:FindFirstChild("HumanoidRootPart")
            data.tracerLine = drawTracer(root, data.tracerLine, useColor)
        else
            if data.tracerLine then
                pcall(function() data.tracerLine:Remove() end)
                data.tracerLine = nil
            end
        end
    end

    -- Bot ESP drawing
    for model, data in pairs(botESPData) do
        if not model or not model:IsDescendantOf(Workspace) then continue end
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        if boxEnabled then
            data.boxLines = drawBox(model, data.boxLines or {}, enemyColor, boxThickness)
        else
            if data.boxLines then
                for _,l in ipairs(data.boxLines) do pcall(function() l:Remove() end) end
                data.boxLines = {}
            end
        end
        if skeletonEnabled then
            data.skeletonLines = drawSkeleton(model, data.skeletonLines or {}, enemyColor, skeletonThickness)
        else
            if data.skeletonLines then
                for _,l in ipairs(data.skeletonLines) do pcall(function() l:Remove() end) end
                data.skeletonLines = {}
            end
        end
        if tracerEnabled then
            local root = model:FindFirstChild("HumanoidRootPart")
            data.tracerLine = drawTracer(root, data.tracerLine, enemyColor)
        else
            if data.tracerLine then
                pcall(function() data.tracerLine:Remove() end)
                data.tracerLine = nil
            end
        end
    end
end

RunService:BindToRenderStep("DH_ESPDrawing", 1000, updateDrawingObjects)

-- ============================================================
--  MM2 DROPPED GUN ESP RENDER
-- ============================================================

local gunEspBoxLines = {}
local gunEspLabel    = nil
local GUN_COLOR      = Color3.fromRGB(170, 0, 255)

local function clearGunEsp()
    for _, l in ipairs(gunEspBoxLines) do pcall(function() l:Remove() end) end
    gunEspBoxLines = {}
    if gunEspLabel then pcall(function() gunEspLabel:Remove() end); gunEspLabel = nil end
end

-- (findDroppedGun moved up to be shared by ESP and TP)

RunService:BindToRenderStep("DH_GunESP", 1001, function()
    if not mm2GunEspEnabled then
        clearGunEsp()
        return
    end
    if not DrawingLib then return end

    local gun = findDroppedGun()
    if not gun then
        clearGunEsp()
        return
    end

    -- Resolve a position for the gun (Model or BasePart)
    local gunPos
    if gun:IsA("Model") then
        local ok, cf = pcall(function() return gun:GetBoundingBox() end)
        if ok then gunPos = cf.Position end
    elseif gun:IsA("BasePart") then
        gunPos = gun.Position
    elseif gun:IsA("Tool") then
        local handle = gun:FindFirstChild("Handle")
        if handle then gunPos = handle.Position end
    end
    if not gunPos then clearGunEsp(); return end

    local sp = Camera:WorldToViewportPoint(gunPos)
    if sp.Z <= 0 then clearGunEsp(); return end

    local vp = Camera.ViewportSize
    local dist = math.floor((Camera.CFrame.Position - gunPos).Magnitude)

    -- Draw bracket box (reuse drawBox helper uses bounding box; we draw manually for tool/basepart)
    -- Clean last frame's lines
    for _, l in ipairs(gunEspBoxLines) do pcall(function() l:Remove() end) end
    gunEspBoxLines = {}

    local function mkLine(a, b)
        local ln = DrawingLib.new("Line")
        ln.From        = a
        ln.To          = b
        ln.Color       = GUN_COLOR
        ln.Thickness   = 2
        ln.Transparency = 0.05
        ln.Visible     = true
        table.insert(gunEspBoxLines, ln)
    end

    local px, py = math.clamp(sp.X, 0, vp.X), math.clamp(sp.Y, 0, vp.Y)
    local bw, bh = 24, 36  -- fixed box size for the dropped gun
    local tl = Vector2.new(px - bw, py - bh)
    local tr = Vector2.new(px + bw, py - bh)
    local br = Vector2.new(px + bw, py + bh)
    local bl = Vector2.new(px - bw, py + bh)
    local cx, cy = bw * 0.35, bh * 0.35

    -- Corner bracket style
    mkLine(tl, Vector2.new(tl.X + cx, tl.Y))
    mkLine(tl, Vector2.new(tl.X, tl.Y + cy))
    mkLine(tr, Vector2.new(tr.X - cx, tr.Y))
    mkLine(tr, Vector2.new(tr.X, tr.Y + cy))
    mkLine(br, Vector2.new(br.X - cx, br.Y))
    mkLine(br, Vector2.new(br.X, br.Y - cy))
    mkLine(bl, Vector2.new(bl.X + cx, bl.Y))
    mkLine(bl, Vector2.new(bl.X, bl.Y - cy))

    -- Label above box
    if not gunEspLabel then
        gunEspLabel = DrawingLib.new("Text")
        gunEspLabel.Font     = Drawing and Drawing.Fonts and Drawing.Fonts.UI or 0
        gunEspLabel.Size     = 14
        gunEspLabel.Outline  = true
        gunEspLabel.Visible  = true
    end
    gunEspLabel.Text     = "🔫 Gun  [" .. dist .. "m]"
    gunEspLabel.Color    = GUN_COLOR
    gunEspLabel.Position = Vector2.new(px - 30, tl.Y - 18)
    gunEspLabel.Visible  = true
end)

-- Periodic bot scan (every 3 seconds)
task.spawn(function()
    while true do
        if espEnabled then scanForBots() end
        task.wait(3)
    end
end)

-- ============================================================
--  AIMBOT & TEAM LOGIC
-- ============================================================

local function isAlive(player)
    if not player.Character then return false end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    
    if mm2EspEnabled and isMM2RoundActive() then
        local myBp = LocalPlayer:FindFirstChild("Backpack")
        local myChar = LocalPlayer.Character
        local iHaveGun = (myBp and myBp:FindFirstChild("Gun")) or (myChar and myChar:FindFirstChild("Gun"))
        
        if iHaveGun then
            local theirBp = player:FindFirstChild("Backpack")
            local theirChar = player.Character
            local theyHaveKnife = (theirBp and theirBp:FindFirstChild("Knife")) or (theirChar and theirChar:FindFirstChild("Knife"))
            return theyHaveKnife ~= nil
        end
        return true
    end

    local myTeam    = LocalPlayer.Team
    local theirTeam = player.Team
    if not myTeam or not theirTeam then return true end
    return myTeam ~= theirTeam
end

local function isVisible(part)
    if wallbangEnabled then return true end
    local origin = Camera.CFrame.Position
    local dir    = (part.Position - origin)
    local rp     = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(origin, dir, rp)
    if result then
        -- Hit something — check if it's part of the target's model
        return result.Instance:IsDescendantOf(part.Parent)
    end
    return true  -- No obstruction
end

local function getClosestToCenter()
    local closest, shortestDist = nil, fov
    local center = Camera.ViewportSize / 2
    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) and isAlive(player) then
            local head = player.Character and player.Character:FindFirstChild("Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X,sp.Y) - center).Magnitude
                    if dist < shortestDist and isVisible(head) then
                        shortestDist = dist
                        closest      = head
                    end
                end
            end
        end
    end
    -- Also check bots — always wall-check regardless of wallbangEnabled
    -- (wallbang only affects the triggerbot fire path, not aimbot locking)
    for model, _ in pairs(botESPData) do
        if model and model:IsDescendantOf(Workspace) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = model:FindFirstChild("Head")
                if head then
                    local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(sp.X,sp.Y) - Camera.ViewportSize/2).Magnitude
                        if dist < shortestDist then
                            -- Raw raycast — never skipped by wallbang
                            local origin = Camera.CFrame.Position
                            local rp = RaycastParams.new()
                            rp.FilterType = Enum.RaycastFilterType.Blacklist
                            rp.FilterDescendantsInstances = {LocalPlayer.Character}
                            local result = Workspace:Raycast(origin, head.Position - origin, rp)
                            local botVisible = (not result) or result.Instance:IsDescendantOf(model)
                            if botVisible then
                                shortestDist = dist
                                closest      = head
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function aimbotStep()
    if not aimbotEnabled then return end
    local target = getClosestToCenter()
    if target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
    end
    updateFOVCircleAppearance(fov, true)
end

function enableAimbotBind()
    RunService:BindToRenderStep("DH_Aimbot", 200, aimbotStep)
end
function disableAimbotBind()
    pcall(function() RunService:UnbindFromRenderStep("DH_Aimbot") end)
end

-- ===== SPIN BOT =====
RunService.RenderStepped:Connect(function(dt)
    if not spinBotEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeedDeg * dt), 0)
end)

-- ===== FLICK AIMBOT =====
RunService:BindToRenderStep("DH_FlickAimbot", 199, function()
    if not flickEnabled then return end
    local now = tick()
    if now - lastFlickTime < flickInterval then return end
    lastFlickTime = now
    
    local function strictVisible(part)
        if wallbangEnabled then return true end
        local origin = Camera.CFrame.Position
        local dir    = (part.Position - origin)
        local rp     = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Blacklist
        rp.FilterDescendantsInstances = {LocalPlayer.Character}
        local result = Workspace:Raycast(origin, dir, rp)
        if result then return result.Instance:IsDescendantOf(part.Parent) end
        return true
    end

    local targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) and isAlive(player) and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head and strictVisible(head) then table.insert(targets, head) end
        end
    end
    for model, _ in pairs(botESPData) do
        if model and model:IsDescendantOf(Workspace) then
            local head = model:FindFirstChild("Head")
            if head and strictVisible(head) then table.insert(targets, head) end
        end
    end
    if #targets == 0 then flickIndex = 1; return end
    flickIndex = flickIndex % #targets + 1
    local t = targets[flickIndex]
    if t then Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position) end
end)

-- ============================================================
--  MOVEMENT LOGIC
-- ============================================================

function applyWalkSpeed()
    local char = LocalPlayer.Character
    if not char or noclipEnabled then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = speedEnabled and walkSpeed or defaultWalkSpeed end
end

function applyJumpPower()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = jumpEnabled and jumpPower or defaultJumpPower end
end

function applyNoclipSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = noclipEnabled and noclipSpeed or (speedEnabled and walkSpeed or defaultWalkSpeed) end
end

local function enforceNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end

function setNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if state then
                if not originalCollisions[p] then originalCollisions[p] = p.CanCollide end
                p.CanCollide = false
            else
                if originalCollisions[p] ~= nil then p.CanCollide = originalCollisions[p] end
            end
        end
    end
end

function startNoclip()
    noclipEnabled = true
    setNoclip(true)
    applyNoclipSpeed()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.RenderStepped:Connect(enforceNoclip)
end

function stopNoclip()
    noclipEnabled = false
    setNoclip(false)
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = speedEnabled and walkSpeed or defaultWalkSpeed end
    end
end

function attachFlight()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=0; h.JumpPower=0; h.AutoRotate=false end
end

function detachFlight()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed   = speedEnabled and walkSpeed or defaultWalkSpeed
        h.JumpPower   = jumpEnabled and jumpPower or defaultJumpPower
        h.AutoRotate  = true
    end
end

local function flightControl()
    if not flightEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir = dir + Camera.CFrame.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir = dir - Camera.CFrame.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir = dir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir = dir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
    if dir.Magnitude > 0 then dir = dir.Unit * flightSpeed end
    root.Velocity = dir
    root.CFrame   = CFrame.lookAt(root.Position, root.Position + Camera.CFrame.LookVector)
end

function startFlight()
    flightEnabled = true
    attachFlight()
    if flightConnection then flightConnection:Disconnect() end
    flightConnection = RunService.RenderStepped:Connect(flightControl)
end

function stopFlight()
    flightEnabled = false
    detachFlight()
    if flightConnection then flightConnection:Disconnect(); flightConnection = nil end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if flightEnabled  then task.wait(0.2); attachFlight() end
    if noclipEnabled  then task.wait(0.2); startNoclip()  end
    if speedEnabled or jumpEnabled then
        local h = char:WaitForChild("Humanoid", 5)
        if h then
            if speedEnabled then h.WalkSpeed = walkSpeed end
            if jumpEnabled  then h.JumpPower = jumpPower  end
        end
    end
end)

-- (Leaver message removed by request)

-- ===== MASTER KILL SWITCH (Right Ctrl + Delete) =====
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Delete and
       UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
        espEnabled        = false
        aimbotEnabled     = false
        spinBotEnabled    = false
        flickEnabled      = false
        flightEnabled     = false
        noclipEnabled     = false
        speedEnabled      = false
        jumpEnabled       = false
        _G.HitboxExpander = false
        fullESPRefresh()
        disableAimbotBind()
        updateFOVCircleAppearance(fov, false)
        if flightConnection  then flightConnection:Disconnect()  end
        if noclipConnection  then noclipConnection:Disconnect()  end
        print("[GH] Master kill switch activated.")
    end
    -- Toggle menu visibility with RightCtrl + Insert
    if input.KeyCode == Enum.KeyCode.Insert and
       UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ============================================================
--  VISIONHUB REVERSE-ENGINEERED EXPLOITS (MM2)
-- ============================================================

_G.MM2_Roles = {}
_G.HitboxExpander = false
_G.HitboxSize = 50

-- 1. Role Bypass: Ping ReplicatedStorage remote to get roles before weapons spawn
task.spawn(function()
    while true do
        if mm2EspEnabled then
            pcall(function()
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true)
                if remote and remote:IsA("RemoteFunction") then
                    local data = remote:InvokeServer()
                    if type(data) == "table" then
                        local changed = false
                        for name, info in pairs(data) do
                            if type(info) == "table" and info.Role then
                                if _G.MM2_Roles[name] ~= info.Role then
                                    _G.MM2_Roles[name] = info.Role
                                    changed = true
                                end
                            end
                        end
                        if changed then
                            fullESPRefresh()
                        end
                    end
                end
            end)
        end
        task.wait(1) -- Reduced from 2s to 1s for faster initial load
end
end)

-- 1.5 Real-Time Role Ping Override
-- Instead of waiting for physical weapons, we forcefully ping the server's own data table constantly.
-- If the ping loop is too slow, we just rely on the 1-second task loop above, but we remove the inventory scanner entirely.
-- We no longer check inventories for roles anywhere in the ESP updater.

-- 2. Hitbox Expander (Silent Aim / Wallbang)
RunService.RenderStepped:Connect(function()
    if _G.KillAllActive then return end -- Button handles it
    
    if not _G.HitboxExpander then
        -- Cleanup
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root and root.Size.X > 5 then
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end
            end
        end
        return
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- We only expand the Murderer if we are targeting them
            local isM = false
            if _G.MM2_Roles and _G.MM2_Roles[player.Name] == "Murderer" then isM = true end
            local bp = player:FindFirstChild("Backpack")
            if bp and bp:FindFirstChild("Knife") then isM = true end
            local char = player.Character
            if char and char:FindFirstChild("Knife") then isM = true end
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                if isM then
                    root.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                    root.Transparency = 0.8
                    root.BrickColor = BrickColor.new("Bright red")
                    root.Material = Enum.Material.ForceField
                    root.CanCollide = false
                elseif root.Size.X > 5 then
                    -- Shrink non-murderers
                    root.Size = Vector3.new(2, 2, 1)
                    root.Transparency = 1
                end
            end
        end
    end
end)

-- Hook removed.
-- ============================================================
--  MOBILE BUTTON FACTORY
-- ============================================================
local mobileButtons = {}

function createMobileButton(id, text, callback)
    if mobileButtons[id] then return end
    
    local btn = Instance.new("TextButton", ScreenGui)
    btn.Name = id
    btn.Size = UDim2.new(0, 80, 0, 80)
    
    -- Stack them neatly based on how many exist
    local count = 0
    for _, _ in pairs(mobileButtons) do count = count + 1 end
    btn.Position = UDim2.new(1, -100, 0, 200 + (count * 100))
    
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.BackgroundTransparency = 0.4
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Text = text
    btn.TextWrapped = true
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(1, 0) -- Perfect Circle
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.5
    stroke.Thickness = 1.5
    
    -- Draggable logic
    local dragging, dragInput, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Action execution
    btn.MouseButton1Click:Connect(function()
        -- Add a tiny bounce effect when tapped
        local ts = game:GetService("TweenService")
        local shrink = ts:Create(btn, TweenInfo.new(0.05), {Size = UDim2.new(0, 70, 0, 70)})
        local grow = ts:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0, 80, 0, 80)})
        shrink:Play()
        shrink.Completed:Wait()
        grow:Play()
        
        callback()
    end)
    
    mobileButtons[id] = btn
end

function removeMobileButton(id)
    if mobileButtons[id] then
        mobileButtons[id]:Destroy()
        mobileButtons[id] = nil
    end
end

-- ============================================================
print("[DH DADDY'S GLASS HOUSE v10.1] Loaded. ❄ Stay frosty.")
-- ============================================================
