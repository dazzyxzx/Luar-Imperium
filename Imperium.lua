--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     IMPERIUM v3.2                            ║
    ║       Barra de Comando estilo Infinite Yield                 ║
    ║       Mobile + PC | Tooltip Universal | ~50 comandos         ║
    ║                                                              ║
    ║  Discord: https://discord.gg/BDCajDWXj8                      ║
    ╚══════════════════════════════════════════════════════════════╝

    ATALHOS:
        PC   → RightShift abre/fecha | End fecha
        Mobile → botão flutuante "IM" no canto
        Ambos → digite comandos na barra ou use ;cmd no chat
]]

--=====================================================================
-- 1. SERVIÇOS
--=====================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local TeleportService  = game:GetService("TeleportService")
local TextChatService  = game:GetService("TextChatService")
local CoreGui          = game:GetService("CoreGui")
local Stats            = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- Detecção de plataforma
local IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if _G.ImperiumLoaded then return end
_G.ImperiumLoaded = true

--=====================================================================
-- 2. CONFIG + PERSISTÊNCIA
--=====================================================================
local hasFS = (writefile and readfile and isfile and makefolder and isfolder)
local CONFIG_FILE = "Imperium/config.json"

local Config = {
    Prefix      = ";",
    DiscordLink = "https://discord.gg/BDCajDWXj8",
    BarVisible  = true,
    BarPosition = {1, -330, 1, -400},
    Theme       = "Dark",
    ESP = {
        Enabled = false, Items = false,
        ShowHealth = true, ShowName = true, ShowDistance = false, ShowTracer = true,
        MaxDistance = 1000,
        ColorPlayer = {255, 80, 80}, ColorItem = {80, 255, 130}, ColorTracer = {80, 180, 255},
    },
}

local function LoadConfig()
    if not hasFS then return end
    pcall(function()
        if isfile(CONFIG_FILE) then
            local d = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for k, v in pairs(d) do
                if type(v) == "table" and type(Config[k]) == "table" then
                    for k2, v2 in pairs(v) do Config[k][k2] = v2 end
                else
                    Config[k] = v
                end
            end
        end
    end)
end

local function SaveConfig()
    if not hasFS then return end
    pcall(function()
        if not isfolder("Imperium") then makefolder("Imperium") end
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)
end
LoadConfig()

--=====================================================================
-- 3. UTILS
--=====================================================================
local Utils = {}

function Utils.GetChar()
    local c = LocalPlayer.Character
    if not c or not c.Parent then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    return c, h
end

function Utils.GetHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

function Utils.FindPlayer(name)
    if not name or name == "" then return nil end
    name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name
        or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
    return nil
end

function Utils.ColorFromRGB(t)
    return Color3.fromRGB(t[1] or 255, t[2] or 255, t[3] or 255)
end

--=====================================================================
-- 4. TEMAS
--=====================================================================
local Themes = {
    Dark  = { Background=Color3.fromRGB(32,32,36), Panel=Color3.fromRGB(24,24,28), Accent=Color3.fromRGB(90,130,220), Text=Color3.fromRGB(230,230,245), SubText=Color3.fromRGB(150,150,165), Border=Color3.fromRGB(70,70,85), Button=Color3.fromRGB(38,38,44), ButtonHover=Color3.fromRGB(52,52,62) },
    Light = { Background=Color3.fromRGB(240,240,245), Panel=Color3.fromRGB(255,255,255), Accent=Color3.fromRGB(60,110,230), Text=Color3.fromRGB(30,30,40), SubText=Color3.fromRGB(90,90,105), Border=Color3.fromRGB(200,200,210), Button=Color3.fromRGB(225,225,235), ButtonHover=Color3.fromRGB(210,210,225) },
    Nord  = { Background=Color3.fromRGB(46,52,64), Panel=Color3.fromRGB(59,66,82), Accent=Color3.fromRGB(136,192,208), Text=Color3.fromRGB(236,239,244), SubText=Color3.fromRGB(180,190,210), Border=Color3.fromRGB(76,86,106), Button=Color3.fromRGB(67,76,94), ButtonHover=Color3.fromRGB(76,86,106) },
    Pink  = { Background=Color3.fromRGB(40,24,36), Panel=Color3.fromRGB(28,16,26), Accent=Color3.fromRGB(255,105,180), Text=Color3.fromRGB(245,220,235), SubText=Color3.fromRGB(190,150,175), Border=Color3.fromRGB(90,50,80), Button=Color3.fromRGB(50,30,46), ButtonHover=Color3.fromRGB(70,40,60) },
}

local Theme = Themes[Config.Theme] or Themes.Dark
local ThemeListeners = {}
local function OnTheme(fn) table.insert(ThemeListeners, fn) end

local function ApplyTheme(name)
    if not Themes[name] then return end
    Config.Theme = name
    Theme = Themes[name]
    for _, fn in ipairs(ThemeListeners) do pcall(fn, Theme) end
    SaveConfig()
end

--=====================================================================
-- 5. GUI — ROOT
--=====================================================================
pcall(function()
    local old = CoreGui:FindFirstChild("ImperiumGui")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ImperiumGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local ScaledHolder = Instance.new("Frame")
ScaledHolder.Size = UDim2.fromScale(1, 1)
ScaledHolder.BackgroundTransparency = 1
ScaledHolder.Parent = ScreenGui

--=====================================================================
-- 6. JANELA PRINCIPAL
--=====================================================================
local Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Size = UDim2.new(0, 320, 0, 360)
Holder.Position = UDim2.new(Config.BarPosition[1], Config.BarPosition[2], Config.BarPosition[3], Config.BarPosition[4])
Holder.BackgroundColor3 = Theme.Background
Holder.BorderSizePixel = 0
Holder.Active = true
Holder.Visible = Config.BarVisible
Holder.Parent = ScaledHolder
Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 8)
local HolderStroke = Instance.new("UIStroke")
HolderStroke.Color = Theme.Border
HolderStroke.Thickness = 1
HolderStroke.Transparency = 0.4
HolderStroke.Parent = Holder

OnTheme(function(t)
    Holder.BackgroundColor3 = t.Background
    HolderStroke.Color = t.Border
end)

--=====================================================================
-- 7. TITLE BAR
--=====================================================================
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 26)
Title.BackgroundColor3 = Theme.Panel
Title.BorderSizePixel = 0
Title.Text = "  Imperium v3.2"
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Holder
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

OnTheme(function(t)
    Title.BackgroundColor3 = t.Panel
    Title.TextColor3 = t.Accent
end)

-- Botões do header
local function MakeHeaderBtn(txt, xOffset, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 20, 0, 20)
    b.Position = UDim2.new(1, xOffset, 0, 3)
    b.BackgroundColor3 = Theme.Button
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.Code
    b.TextSize = 12
    b.AutoButtonColor = false
    b.Parent = Title
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(callback)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.ButtonHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Theme.Button end)
    OnTheme(function(t)
        b.BackgroundColor3 = t.Button
        b.TextColor3 = t.Text
    end)
    return b
end

MakeHeaderBtn("✕", -24, function()
    ScreenGui:Destroy()
    _G.ImperiumLoaded = false
end)

MakeHeaderBtn("–", -46, function()
    Holder.Visible = false
    Config.BarVisible = false
    SaveConfig()
end)

MakeHeaderBtn("◐", -68, function()
    local order = {"Dark", "Light", "Nord", "Pink"}
    local idx = 1
    for i, v in ipairs(order) do
        if v == Config.Theme then idx = i + 1 break end
    end
    if idx > #order then idx = 1 end
    ApplyTheme(order[idx])
end)

-- Drag
local dragging, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Holder.Position
    end
end)
Title.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Holder.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)
Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        Config.BarPosition = {
            Holder.Position.X.Scale, Holder.Position.X.Offset,
            Holder.Position.Y.Scale, Holder.Position.Y.Offset,
        }
        SaveConfig()
    end
end)

--=====================================================================
-- 8. COMMAND BAR + LISTA
--=====================================================================
local Cmdbar = Instance.new("TextBox")
Cmdbar.Size = UDim2.new(1, -16, 0, 28)
Cmdbar.Position = UDim2.new(0, 8, 0, 32)
Cmdbar.BackgroundColor3 = Theme.Panel
Cmdbar.BorderSizePixel = 0
Cmdbar.Text = ""
Cmdbar.PlaceholderText = "Digite um comando..."
Cmdbar.PlaceholderColor3 = Theme.SubText
Cmdbar.TextColor3 = Theme.Text
Cmdbar.Font = Enum.Font.Code
Cmdbar.TextSize = 13
Cmdbar.TextXAlignment = Enum.TextXAlignment.Left
Cmdbar.ClearTextOnFocus = false
Cmdbar.Parent = Holder
Instance.new("UICorner", Cmdbar).CornerRadius = UDim.new(0, 5)
Instance.new("UIPadding", Cmdbar).PaddingLeft = UDim.new(0, 8)

OnTheme(function(t)
    Cmdbar.BackgroundColor3 = t.Panel
    Cmdbar.TextColor3 = t.Text
    Cmdbar.PlaceholderColor3 = t.SubText
end)

local CMDsF = Instance.new("ScrollingFrame")
CMDsF.Size = UDim2.new(1, -16, 1, -70)
CMDsF.Position = UDim2.new(0, 8, 0, 64)
CMDsF.BackgroundTransparency = 1
CMDsF.BorderSizePixel = 0
CMDsF.CanvasSize = UDim2.new(0, 0, 0, 0)
CMDsF.ScrollBarThickness = 5
CMDsF.ScrollBarImageColor3 = Theme.Accent
CMDsF.Parent = Holder

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 3)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = CMDsF

OnTheme(function(t)
    CMDsF.ScrollBarImageColor3 = t.Accent
end)

--=====================================================================
-- 9. TOOLTIP UNIVERSAL (hover PC / long-press mobile)
--=====================================================================
local Tooltip = Instance.new("Frame")
Tooltip.Size = UDim2.new(0, 240, 0, 58)
Tooltip.BackgroundColor3 = Theme.Panel
Tooltip.BorderSizePixel = 0
Tooltip.Visible = false
Tooltip.ZIndex = 999
Tooltip.Parent = ScaledHolder
Instance.new("UICorner", Tooltip).CornerRadius = UDim.new(0, 6)
local TStroke = Instance.new("UIStroke", Tooltip)
TStroke.Color = Theme.Accent
TStroke.Transparency = 0.3

local TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1, -14, 0, 18)
TTitle.Position = UDim2.new(0, 7, 0, 6)
TTitle.BackgroundTransparency = 1
TTitle.Text = ""
TTitle.TextColor3 = Theme.Accent
TTitle.Font = Enum.Font.Code
TTitle.TextSize = 12
TTitle.TextXAlignment = Enum.TextXAlignment.Left
TTitle.Parent = Tooltip

local TDesc = Instance.new("TextLabel")
TDesc.Size = UDim2.new(1, -14, 0, 32)
TDesc.Position = UDim2.new(0, 7, 0, 24)
TDesc.BackgroundTransparency = 1
TDesc.Text = ""
TDesc.TextColor3 = Theme.Text
TDesc.Font = Enum.Font.Code
TDesc.TextSize = 11
TDesc.TextWrapped = true
TDesc.TextXAlignment = Enum.TextXAlignment.Left
TDesc.TextYAlignment = Enum.TextYAlignment.Top
TDesc.Parent = Tooltip

OnTheme(function(t)
    Tooltip.BackgroundColor3 = t.Panel
    TStroke.Color = t.Accent
    TTitle.TextColor3 = t.Accent
    TDesc.TextColor3 = t.Text
end)

local function ShowTooltip(cmd, btn)
    TTitle.Text = ">" .. cmd.name
    TDesc.Text = cmd.desc
    local abs = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    local screenW = ScaledHolder.AbsoluteSize.X
    local x
    if abs.X + size.X + 250 < screenW then
        x = abs.X + size.X + 6
    else
        x = abs.X - 246
    end
    -- Clamp vertical
    local y = math.clamp(abs.Y, 0, ScaledHolder.AbsoluteSize.Y - 70)
    Tooltip.Position = UDim2.new(0, x, 0, y)
    Tooltip.Visible = true
end

local function HideTooltip()
    Tooltip.Visible = false
end

--=====================================================================
-- 10. NOTIFICAÇÕES
--=====================================================================
local NotifStack = Instance.new("Frame")
NotifStack.Size = UDim2.new(0, 260, 1, 0)
NotifStack.Position = UDim2.new(1, -270, 0, 20)
NotifStack.BackgroundTransparency = 1
NotifStack.Parent = ScaledHolder
local NL = Instance.new("UIListLayout", NotifStack)
NL.Padding = UDim.new(0, 6)
NL.VerticalAlignment = Enum.VerticalAlignment.Top
NL.SortOrder = Enum.SortOrder.LayoutOrder

local function Notify(title, text, duration)
    duration = duration or 4
    local n = Instance.new("Frame")
    n.Size = UDim2.new(1, 0, 0, 58)
    n.BackgroundColor3 = Theme.Panel
    n.BackgroundTransparency = 1
    n.BorderSizePixel = 0
    n.Parent = NotifStack
    Instance.new("UICorner", n).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", n)
    s.Color = Theme.Accent
    s.Transparency = 0.3

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -14, 0, 16)
    t.Position = UDim2.new(0, 7, 0, 5)
    t.BackgroundTransparency = 1
    t.Text = "IMPERIUM | " .. title
    t.TextColor3 = Theme.Accent
    t.Font = Enum.Font.Code
    t.TextSize = 11
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextTransparency = 1
    t.Parent = n

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -14, 0, 30)
    d.Position = UDim2.new(0, 7, 0, 22)
    d.BackgroundTransparency = 1
    d.Text = tostring(text)
    d.TextColor3 = Theme.Text
    d.Font = Enum.Font.Code
    d.TextSize = 11
    d.TextWrapped = true
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextYAlignment = Enum.TextYAlignment.Top
    d.TextTransparency = 1
    d.Parent = n

    TweenService:Create(n, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    TweenService:Create(t, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    TweenService:Create(d, TweenInfo.new(0.2), {TextTransparency = 0}):Play()

    task.delay(duration, function()
        if not n.Parent then return end
        TweenService:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(t, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(d, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        task.wait(0.35)
        pcall(function() n:Destroy() end)
    end)
end

--=====================================================================
-- 11. REGISTRO DE COMANDOS
--=====================================================================
local Registry = {}
local Aliases  = {}
local CmdList  = {}

local function Register(name, aliases, desc, fn)
    local cmd = { name = name, aliases = aliases or {}, desc = desc or "", fn = fn }
    Registry[name:lower()] = cmd
    table.insert(CmdList, cmd)
    for _, a in ipairs(cmd.aliases) do Aliases[a:lower()] = name:lower() end
end

local function Execute(name, args)
    local key = name:lower()
    local cmd = Registry[key]
    if not cmd then
        local real = Aliases[key]
        if real then cmd = Registry[real] end
    end
    if not cmd then
        Notify("Erro", "Comando não encontrado: " .. name, 3)
        return
    end
    local ok, err = pcall(cmd.fn, args or {})
    if not ok then Notify("Erro", tostring(err), 4) end
end

--=====================================================================
-- 12. FLY
--=====================================================================
local fly = { active=false, conn=nil, bv=nil, bg=nil, vel=Vector3.zero, speed=100, turbo=250 }

local function StartFly()
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    fly.active = true
    hum.PlatformStand = true
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
    end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6,1e6,1e6) bv.P = 8000 bv.Velocity = Vector3.zero
    bv.Parent = hrp
    local bg = Instance.new("BodyGyro")
    bg.P = 8000 bg.D = 200 bg.MaxTorque = Vector3.new(1e6,1e6,1e6) bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    fly.bv, fly.bg, fly.vel = bv, bg, Vector3.zero

    fly.conn = RunService.RenderStepped:Connect(function(dt)
        if not fly.active then return end
        local cc = LocalPlayer.Character
        local h = cc and cc:FindFirstChild("HumanoidRootPart")
        local hu = cc and cc:FindFirstChildOfClass("Humanoid")
        if not h or not hu then return end
        local cam = Workspace.CurrentCamera
        local look, right, up = cam.CFrame.LookVector, cam.CFrame.RightVector, Vector3.new(0,1,0)
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= look end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= up end
        local hm = hu.MoveDirection
        if hm.Magnitude > 0.1 and dir.Magnitude < 0.1 then
            dir = (look * -hm.Z + right * hm.X)
        end
        local spd = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and fly.turbo or fly.speed
        local target = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        fly.vel = fly.vel:Lerp(target, math.clamp(12*dt, 0, 1))
        bv.Velocity = fly.vel
        local newRot = bg.CFrame.Rotation:Lerp(cam.CFrame.Rotation, math.clamp(14*dt, 0, 1))
        bg.CFrame = CFrame.new(h.Position) * newRot
    end)
end

local function StopFly()
    fly.active = false
    if fly.conn then fly.conn:Disconnect() fly.conn = nil end
    if fly.bv then fly.bv:Destroy() fly.bv = nil end
    if fly.bg then fly.bg:Destroy() fly.bg = nil end
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand = false end
end

--=====================================================================
-- 13. COMANDOS
--=====================================================================

-- MOVIMENTO
Register("fly", {"f"}, "Voa com WASD + Space/Ctrl. Shift = turbo.", function()
    if fly.active then StopFly() Notify("Fly", "Desativado", 2)
    else StartFly() Notify("Fly", "WASD | Space/Ctrl | Shift turbo", 3) end
end)
Register("flyspeed", {}, "Velocidade do fly.", function(a)
    local v = tonumber(a[1]) if v then fly.speed = v Notify("Fly", "Speed = " .. v, 2) end
end)
Register("flyturbo", {}, "Velocidade turbo do fly.", function(a)
    local v = tonumber(a[1]) if v then fly.turbo = v Notify("Fly", "Turbo = " .. v, 2) end
end)
Register("walkspeed", {"ws", "speed"}, "Define WalkSpeed.", function(a)
    local _, h = Utils.GetChar() if not h then return end
    local v = tonumber(a[1]) or 16 h.WalkSpeed = v Notify("WS", "= " .. v, 2)
end)
Register("jumppower", {"jp", "jump"}, "Define JumpPower.", function(a)
    local _, h = Utils.GetChar() if not h then return end
    local v = tonumber(a[1]) or 50 h.UseJumpPower = true h.JumpPower = v Notify("JP", "= " .. v, 2)
end)
local noclipConn
Register("noclip", {"nc"}, "Atravessa paredes (toggle).", function()
    if noclipConn then
        noclipConn:Disconnect() noclipConn = nil
        local c = LocalPlayer.Character
        if c then for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end end
        Notify("Noclip", "OFF", 2)
    else
        noclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end)
        Notify("Noclip", "ON", 2)
    end
end)
local ijConn
Register("infinitejump", {"ij"}, "Pulo infinito (toggle).", function()
    if ijConn then ijConn:Disconnect() ijConn = nil Notify("IJ", "OFF", 2)
    else
        ijConn = UserInputService.JumpRequest:Connect(function()
            local _, h = Utils.GetChar()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        Notify("IJ", "ON", 2)
    end
end)
Register("btools", {"bt"}, "Dá ferramentas de construção.", function()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack") if not bp then return end
    for _, n in ipairs({"Hammer","Clone","Grab","Rocket"}) do
        local t = Instance.new("Tool")
        t.Name = n t.CanBeDropped = false t.RequiresHandle = false t.Parent = bp
    end
    Notify("BTools", "Dadas", 2)
end)

-- VISUAL
local fb
Register("fullbright", {"fb"}, "Iluminação total (toggle).", function()
    fb = not fb
    if fb then
        Lighting.Brightness=3 Lighting.ClockTime=14
        Lighting.Ambient=Color3.fromRGB(180,180,180)
        Lighting.OutdoorAmbient=Color3.fromRGB(180,180,180)
        Lighting.FogEnd=1e6 Lighting.GlobalShadows=false Notify("FB", "ON", 2)
    else
        Lighting.Brightness=2 Lighting.ClockTime=14
        Lighting.Ambient=Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
        Lighting.FogEnd=100000 Lighting.GlobalShadows=true Notify("FB", "OFF", 2)
    end
end)
Register("fov", {}, "Define FOV (40-140).", function(a)
    local v = tonumber(a[1]) or 70 Camera.FieldOfView = v Notify("FOV", v, 2)
end)
Register("time", {"hora"}, "Hora do jogo (0-24).", function(a)
    local v = tonumber(a[1]) if v then Lighting.ClockTime = v Notify("Time", v, 2) end
end)
Register("fog", {}, "FogEnd (neblina).", function(a)
    local v = tonumber(a[1]) or 1e6 Lighting.FogEnd = v Notify("Fog", v, 2)
end)

-- ESP
local ESP = { drawings={}, items={}, connP=nil, connI=nil }
local function espPlayer(plr)
    local box = Drawing.new("Square")
    box.Thickness=1 box.Filled=false box.Visible=false
    local nm = Drawing.new("Text")
    nm.Size=14 nm.Center=true nm.Outline=true nm.Visible=false
    local hp = Drawing.new("Text")
    hp.Size=12 hp.Center=true hp.Outline=true hp.Visible=false
    local tr = Drawing.new("Line")
    tr.Thickness=1 tr.Visible=false
    ESP.drawings[plr] = {box=box, name=nm, health=hp, tracer=tr}
end
local function espPlayerRm(plr)
    local d = ESP.drawings[plr]
    if d then for _, o in pairs(d) do pcall(function() o:Remove() end) end ESP.drawings[plr] = nil end
end
local function espColors()
    local cb, ct = Utils.ColorFromRGB(Config.ESP.ColorPlayer), Utils.ColorFromRGB(Config.ESP.ColorTracer)
    for _, d in pairs(ESP.drawings) do d.box.Color = cb d.tracer.Color = ct end
end
local function espStartPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then espPlayer(p) end
    end
    espColors()
    ESP.connP = RunService.RenderStepped:Connect(function()
        local camPos = Camera.CFrame.Position
        for plr, d in pairs(ESP.drawings) do
            local c = plr.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - camPos).Magnitude
                if dist <= Config.ESP.MaxDistance then
                    local pos, on = Camera:WorldToViewportPoint(hrp.Position)
                    if on then
                        local h = math.clamp(1400/dist, 20, 500)
                        local w = h * 0.55
                        d.box.Size = Vector2.new(w, h)
                        d.box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                        d.box.Visible = true
                        if Config.ESP.ShowName then
                            d.name.Position = Vector2.new(pos.X, pos.Y - h/2 - 14)
                            d.name.Text = plr.Name .. (Config.ESP.ShowDistance and (" ["..math.floor(dist).."m]") or "")
                            d.name.Visible = true
                        else d.name.Visible = false end
                        if Config.ESP.ShowHealth then
                            d.health.Position = Vector2.new(pos.X, pos.Y + h/2 + 2)
                            d.health.Text = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
                            d.health.Visible = true
                        else d.health.Visible = false end
                        if Config.ESP.ShowTracer then
                            d.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            d.tracer.To = Vector2.new(pos.X, pos.Y + h/2)
                            d.tracer.Visible = true
                        else d.tracer.Visible = false end
                    else
                        d.box.Visible=false d.name.Visible=false d.health.Visible=false d.tracer.Visible=false
                    end
                else
                    d.box.Visible=false d.name.Visible=false d.health.Visible=false d.tracer.Visible=false
                end
            else
                d.box.Visible=false d.name.Visible=false d.health.Visible=false d.tracer.Visible=false
            end
        end
    end)
    Players.PlayerAdded:Connect(function(p)
        if Config.ESP.Enabled and Config.ESP.Players and p ~= LocalPlayer then espPlayer(p) espColors() end
    end)
    Players.PlayerRemoving:Connect(espPlayerRm)
end
local function espStopPlayers()
    if ESP.connP then ESP.connP:Disconnect() ESP.connP = nil end
    for p in pairs(ESP.drawings) do espPlayerRm(p) end
end
local function espItem(part)
    local box = Drawing.new("Square")
    box.Thickness=1 box.Filled=false box.Visible=false box.Color=Utils.ColorFromRGB(Config.ESP.ColorItem)
    local nm = Drawing.new("Text")
    nm.Size=12 nm.Center=true nm.Outline=true nm.Visible=false nm.Color=Utils.ColorFromRGB(Config.ESP.ColorItem)
    ESP.items[part] = {box=box, name=nm}
end
local function espItemRm(part)
    local d = ESP.items[part]
    if d then for _, o in pairs(d) do pcall(function() o:Remove() end) end ESP.items[part] = nil end
end
local function espStartItems()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            local handle = obj:FindFirstChild("Handle")
            if handle then espItem(handle) end
        elseif obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("tool") or n:find("item") or n:find("drop") then espItem(obj) end
        end
    end
    ESP.connI = RunService.RenderStepped:Connect(function()
        local camPos = Camera.CFrame.Position
        for part, d in pairs(ESP.items) do
            if not part.Parent then espItemRm(part) continue end
            local dist = (part.Position - camPos).Magnitude
            if dist <= Config.ESP.MaxDistance then
                local pos, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local h = math.clamp(1200/dist, 15, 300)
                    local w = h * 0.55
                    d.box.Size = Vector2.new(w, h)
                    d.box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                    d.box.Visible = true
                    d.name.Position = Vector2.new(pos.X, pos.Y - h/2 - 12)
                    d.name.Text = part.Name.." ["..math.floor(dist).."m]"
                    d.name.Visible = true
                else
                    d.box.Visible=false d.name.Visible=false
                end
            else
                d.box.Visible=false d.name.Visible=false
            end
        end
    end)
end
local function espStopItems()
    if ESP.connI then ESP.connI:Disconnect() ESP.connI = nil end
    for p in pairs(ESP.items) do espItemRm(p) end
end
local function espRefresh()
    if Config.ESP.Enabled and Config.ESP.Players then
        if not ESP.connP then espStartPlayers() end
    else espStopPlayers() end
    if Config.ESP.Enabled and Config.ESP.Items then
        if not ESP.connI then espStartItems() end
    else espStopItems() end
    SaveConfig()
end
Register("esp", {"boxesp"}, "ESP em jogadores (toggle).", function()
    Config.ESP.Enabled = not Config.ESP.Enabled espRefresh()
    Notify("ESP", Config.ESP.Enabled and "ON" or "OFF", 2)
end)
Register("espitems", {}, "ESP em itens/tools (toggle).", function()
    Config.ESP.Items = not Config.ESP.Items espRefresh()
    Notify("ESP Items", Config.ESP.Items and "ON" or "OFF", 2)
end)
Register("espconfig", {"espc"}, "Config ESP: health/name/dist/tracer/dist_max <n>", function(a)
    local s = (a[1] or ""):lower()
    if s == "health" then Config.ESP.ShowHealth = not Config.ESP.ShowHealth
    elseif s == "name" then Config.ESP.ShowName = not Config.ESP.ShowName
    elseif s == "dist" then Config.ESP.ShowDistance = not Config.ESP.ShowDistance
    elseif s == "tracer" then Config.ESP.ShowTracer = not Config.ESP.ShowTracer
    elseif s == "dist_max" then
        local v = tonumber(a[2]) if v then Config.ESP.MaxDistance = v end
    else
        Notify("ESP", "Uso: espconfig health/name/dist/tracer/dist_max <n>", 4) return
    end
    SaveConfig() Notify("ESP", "Atualizado", 2)
end)

-- Freecam
local fcConn, fcActive, fcSaved
Register("freecam", {"fc"}, "Câmera livre (toggle).", function()
    fcActive = not fcActive
    if fcActive then
        fcSaved = Camera.CFrame
        Camera.CameraType = Enum.CameraType.Scriptable
        fcConn = RunService.RenderStepped:Connect(function(dt)
            local look, right = Camera.CFrame.LookVector, Camera.CFrame.RightVector
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += look end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= look end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then Camera.CFrame = Camera.CFrame + dir.Unit * 70 * dt end
        end)
        Notify("Freecam", "ON", 2)
    else
        if fcConn then fcConn:Disconnect() fcConn = nil end
        Camera.CameraType = Enum.CameraType.Custom
        if fcSaved then Camera.CFrame = fcSaved end
        Notify("Freecam", "OFF", 2)
    end
end)

-- JOGADOR
Register("rejoin", {"rj"}, "Reentra no servidor.", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
Register("serverhop", {"sh"}, "Troca de servidor.", function()
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)))
    end)
    if not ok or not res or not res.data then Notify("SH", "Falha", 3) return end
    local l = {}
    for _, s in ipairs(res.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(l, s.id) end
    end
    if #l == 0 then Notify("SH", "Sem servidores", 2) return end
    TeleportService:TeleportToPlaceInstance(game.PlaceId, l[math.random(1,#l)], LocalPlayer)
end)
Register("reset", {"rs"}, "Reseta personagem.", function()
    local _, h = Utils.GetChar() if h then h.Health = 0 end
end)
Register("godmode", {"god"}, "Godmode simulado.", function()
    local _, h = Utils.GetChar()
    if h then h.MaxHealth = math.huge h.Health = math.huge Notify("God", "ON", 2) end
end)
Register("heal", {"curar"}, "Cura o personagem.", function()
    local _, h = Utils.GetChar() if h then h.Health = h.MaxHealth Notify("Heal", "OK", 2) end
end)
local loopHealConn
Register("loopheal", {}, "Auto-cura (toggle).", function()
    if loopHealConn then loopHealConn:Disconnect() loopHealConn = nil Notify("LoopHeal","OFF",2)
    else
        loopHealConn = RunService.Heartbeat:Connect(function()
            local _, h = Utils.GetChar()
            if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
        end)
        Notify("LoopHeal", "ON", 2)
    end
end)
Register("reassign", {}, "Devolve ferramentas ao backpack.", function()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local c = LocalPlayer.Character
    if not bp or not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then t.Parent = bp end
    end
    Notify("Reassign", "OK", 2)
end)
Register("goto", {"tp"}, "Teleporta até um player.", function(a)
    local p = Utils.FindPlayer(a[1])
    if not p or not p.Character then Notify("TP", "Player não achado", 2) return end
    local hrp = Utils.GetHRP()
    local t = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp and t then hrp.CFrame = t.CFrame * CFrame.new(0,0,3) Notify("TP", "→ "..p.Name, 2) end
end)
Register("bring", {}, "Traz um player até você.", function(a)
    local p = Utils.FindPlayer(a[1])
    if not p or not p.Character then Notify("Bring", "Player não achado", 2) return end
    local hrp = Utils.GetHRP()
    local t = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp and t then t.CFrame = hrp.CFrame * CFrame.new(0,0,3) Notify("Bring", p.Name, 2) end
end)
Register("ping", {}, "Mostra seu ping atual.", function()
    local p = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    Notify("Ping", math.floor(p).." ms", 3)
end)
Register("age", {}, "Idade da conta (age / age nome).", function(a)
    local t = a[1] and Utils.FindPlayer(a[1]) or LocalPlayer
    if not t then Notify("Age", "Não achado", 2) return end
    local ok, age = pcall(function() return t.AccountAge end)
    if ok and age then Notify(t.Name, age.." dias (~"..math.floor(age/365).." anos)", 4) end
end)
Register("invisible", {"invis"}, "Fica invisível (local).", function()
    local c = LocalPlayer.Character if not c then return end
    _G.ImpInvis = not _G.ImpInvis
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.LocalTransparencyModifier = _G.ImpInvis and 1 or 0 end
    end
    Notify("Invis", _G.ImpInvis and "ON" or "OFF", 2)
end)
Register("freeze", {"congelar"}, "Congela um player.", function(a)
    local p = Utils.FindPlayer(a[1])
    if not p or not p.Character then Notify("Freeze", "Inválido", 2) return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = true Notify("Freeze", p.Name, 2) end
end)
Register("unfreeze", {}, "Descongela um player.", function(a)
    local p = Utils.FindPlayer(a[1])
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false Notify("Unfreeze", p.Name, 2) end
end)

-- TROLL
Register("fling", {}, "Fling em quem estiver perto (3s).", function()
    local hrp = Utils.GetHRP() if not hrp then return end
    local v = Instance.new("BodyAngularVelocity", hrp)
    v.AngularVelocity = Vector3.new(0,1e4,0)
    v.MaxTorque = Vector3.new(1e5,1e5,1e5)
    v.P = 1250
    Notify("Fling", "3s", 2)
    task.delay(3, function() pcall(function() v:Destroy() end) end)
end)
Register("spin", {"girar"}, "Gira rápido (3s).", function()
    local c, h = Utils.GetChar() if not h then return end
    local hrp = c:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local bg = Instance.new("BodyGyro", hrp)
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4
    bg.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(45), 0)
    Notify("Spin", "3s", 2)
    task.delay(3, function() pcall(function() bg:Destroy() end) end)
end)
Register("sit", {"sentar"}, "Faz o personagem sentar.", function()
    local _, h = Utils.GetChar() if h then h.Sit = true end
end)
Register("dance", {"dançar"}, "Executa animação de dança.", function()
    local _, h = Utils.GetChar() if not h then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://507771019"
    local ok, t = pcall(function() return h.Animator:LoadAnimation(anim) end)
    if ok and t then t:Play() end
end)
Register("clone", {"clonar"}, "Cria clone estático.", function()
    local c = LocalPlayer.Character if not c then return end
    local cl = c:Clone()
    cl.Parent = Workspace
    for _, p in ipairs(cl:GetDescendants()) do
        if p:IsA("Script") or p:IsA("LocalScript") then p:Destroy() end
    end
    local h = cl:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 0 h.DisplayName = "Imperium Clone" end
    Notify("Clone", "OK", 2)
end)

-- WAYPOINTS
local WPs = {}
if hasFS then pcall(function()
    if isfile("Imperium/waypoints.json") then
        WPs = HttpService:JSONDecode(readfile("Imperium/waypoints.json"))
    end
end) end
local function SaveWPs()
    if not hasFS then return end
    pcall(function()
        if not isfolder("Imperium") then makefolder("Imperium") end
        writefile("Imperium/waypoints.json", HttpService:JSONEncode(WPs))
    end)
end
Register("waypoint", {"wp"}, "Waypoints: save/list/go/del <nome>.", function(a)
    local s = (a[1] or ""):lower()
    if s == "save" then
        local n = a[2] local hrp = Utils.GetHRP()
        if not n or not hrp then Notify("WP", "Uso: wp save <nome>", 3) return end
        WPs[n] = {x=hrp.Position.X, y=hrp.Position.Y, z=hrp.Position.Z, place=game.PlaceId}
        SaveWPs() Notify("WP", "Salvo: "..n, 2)
    elseif s == "list" then
        local l = {} for k in pairs(WPs) do table.insert(l, k) end
        if #l == 0 then Notify("WP", "Vazio", 2) return end
        Notify("WPs", table.concat(l, ", "), 5)
    elseif s == "go" then
        local wp = a[2] and WPs[a[2]]
        if not wp then Notify("WP", "Não existe", 2) return end
        local hrp = Utils.GetHRP()
        if hrp then hrp.CFrame = CFrame.new(Vector3.new(wp.x, wp.y, wp.z)) Notify("WP", "→ "..a[2], 2) end
    elseif s == "del" then
        if a[2] and WPs[a[2]] then WPs[a[2]] = nil SaveWPs() Notify("WP", "Removido", 2) end
    else
        Notify("WP", "Uso: wp save/list/go/del", 4)
    end
end)

-- ALIASES
Register("alias", {}, "Aliases: add/del/list.", function(a)
    local s = (a[1] or ""):lower()
    if s == "add" then
        local al, cm = a[2], a[3]
        if not al or not cm then Notify("Alias", "Uso: alias add <a> <cmd>", 3) return end
        cm = cm:lower()
        if not Registry[cm] then Notify("Alias", "Cmd não existe", 3) return end
        Aliases[al:lower()] = cm Notify("Alias", al.." → "..cm, 2)
    elseif s == "del" then
        if a[2] then Aliases[a[2]:lower()] = nil Notify("Alias", "Removido", 2) end
    elseif s == "list" then
        local l = {} for k, v in pairs(Aliases) do table.insert(l, k.."→"..v) end
        Notify("Aliases", table.concat(l, ", "), 5)
    else Notify("Alias", "Uso: alias add/del/list", 4) end
end)

-- LOGS
local Logs = { chat = {}, join = {} }
local function PushLog(t, e)
    table.insert(t, e)
    if #t > 200 then table.remove(t, 1) end
end

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.MessageReceived:Connect(function(msg)
            if msg.TextSource then
                local s = Players:GetPlayerByUserId(msg.TextSource.UserId)
                if s then PushLog(Logs.chat, ("[%s] %s: %s"):format(os.date("%H:%M:%S"), s.Name, msg.Text)) end
            end
        end)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            p.Chatted:Connect(function(m) PushLog(Logs.chat, ("[%s] %s: %s"):format(os.date("%H:%M:%S"), p.Name, m)) end)
        end
        Players.PlayerAdded:Connect(function(p)
            p.Chatted:Connect(function(m) PushLog(Logs.chat, ("[%s] %s: %s"):format(os.date("%H:%M:%S"), p.Name, m)) end)
        end)
    end
end)
Players.PlayerAdded:Connect(function(p) PushLog(Logs.join, ("[%s] + %s"):format(os.date("%H:%M:%S"), p.Name)) end)
Players.PlayerRemoving:Connect(function(p) PushLog(Logs.join, ("[%s] - %s"):format(os.date("%H:%M:%S"), p.Name)) end)

Register("chatlog", {"clog"}, "Ver/limpar chatlog (chatlog clear).", function(a)
    if (a[1] or ""):lower() == "clear" then Logs.chat = {} Notify("Chatlog", "Limpo", 2) return end
    if #Logs.chat == 0 then Notify("Chatlog", "Vazio", 2) return end
    local last = Logs.chat[#Logs.chat]
    Notify("Chatlog", #Logs.chat.." msgs. Última: "..last, 5)
end)
Register("joinlog", {"jlog"}, "Ver/limpar joinlog (joinlog clear).", function(a)
    if (a[1] or ""):lower() == "clear" then Logs.join = {} Notify("Joinlog", "Limpo", 2) return end
    if #Logs.join == 0 then Notify("Joinlog", "Vazio", 2) return end
    local last = Logs.join[#Logs.join]
    Notify("Joinlog", #Logs.join.." eventos. Último: "..last, 5)
end)
Register("savelogs", {}, "Salva logs em arquivos.", function()
    if not hasFS then Notify("Save", "Sem FS", 3) return end
    pcall(function()
        if not isfolder("Imperium") then makefolder("Imperium") end
        writefile("Imperium/chatlog.txt", table.concat(Logs.chat, "\n"))
        writefile("Imperium/joinlog.txt", table.concat(Logs.join, "\n"))
        Notify("Save", "OK em Imperium/", 3)
    end)
end)

-- SISTEMA
Register("discord", {"dc"}, "Copia o link do Discord.", function()
    local link = Config.DiscordLink
    if setclipboard then pcall(function() setclipboard(link) end)
    elseif toclipboard then pcall(function() toclipboard(link) end) end
    Notify("Discord", link, 5)
end)
Register("help", {"h", "?"}, "Lista todos os comandos.", function()
    Notify("Help", #CmdList.." comandos. Use a barra ou ;cmd", 4)
end)
Register("prefix", {}, "Muda o prefixo do chat.", function(a)
    if a[1] and #a[1] >= 1 then Config.Prefix = a[1] SaveConfig() Notify("Prefix", a[1], 2) end
end)
Register("theme", {}, "Troca tema: Dark/Light/Nord/Pink.", function(a)
    if a[1] and Themes[a[1]] then ApplyTheme(a[1]) Notify("Tema", a[1], 2)
    else Notify("Tema", "Opções: Dark, Light, Nord, Pink", 4) end
end)
Register("notify", {}, "Notificação de teste.", function(a)
    Notify("Teste", #a > 0 and table.concat(a, " ") or "Hello!", 4)
end)
Register("version", {"v"}, "Versão do Imperium.", function()
    Notify("Imperium", "v3.2 | Open Source", 3)
end)
Register("credits", {}, "Créditos.", function()
    Notify("Credits", "Imperium Dev | inspirado em Infinite Yield", 5)
end)
Register("clear", {"limpar"}, "Remove clones locais.", function()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and o.Name:find(LocalPlayer.Name) then pcall(function() o:Destroy() end) end
    end
    Notify("Clear", "OK", 2)
end)

--=====================================================================
-- 14. LISTA ALFABÉTICA + BIND (tooltip universal)
--=====================================================================
table.sort(CmdList, function(a, b) return a.name:lower() < b.name:lower() end)

local function BindButton(btn, cmd)
    if IsOnMobile then
        -- Long-press mostra tooltip; tap rápido executa
        local holding, holdTask, showedTip = false, nil, false
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                holding = true
                showedTip = false
                holdTask = task.delay(0.5, function()
                    if holding then ShowTooltip(cmd, btn) showedTip = true end
                end)
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                holding = false
                if holdTask then task.cancel(holdTask) holdTask = nil end
                if showedTip then HideTooltip()
                else Execute(cmd.name, {}) end
                showedTip = false
            end
        end)
    else
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Theme.ButtonHover
            ShowTooltip(cmd, btn)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Theme.Button
            HideTooltip()
        end)
        btn.MouseButton1Click:Connect(function()
            Execute(cmd.name, {})
        end)
    end
end

local function BuildList()
    for _, c in ipairs(CMDsF:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for i, cmd in ipairs(CmdList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 22)
        btn.BackgroundColor3 = Theme.Button
        btn.BorderSizePixel = 0
        btn.Text = "  " .. cmd.name
        btn.TextColor3 = Theme.Text
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Font = Enum.Font.Code
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.Parent = CMDsF
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        BindButton(btn, cmd)
        OnTheme(function(t)
            btn.BackgroundColor3 = t.Button
            btn.TextColor3 = t.Text
        end)
    end
    CMDsF.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    CMDsF.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end)

--=====================================================================
-- 15. INPUT DA BARRA + CHAT
--=====================================================================
Cmdbar.FocusLost:Connect(function(enter)
    if not enter then return end
    local text = Cmdbar.Text
    Cmdbar.Text = ""
    if text == "" then return end
    if text:sub(1, #Config.Prefix) == Config.Prefix then
        text = text:sub(#Config.Prefix + 1)
    end
    local parts = {}
    for w in text:gmatch("%S+") do table.insert(parts, w) end
    if #parts == 0 then return end
    local name = table.remove(parts, 1)
    Execute(name, parts)
end)

local function ProcessChat(text)
    if #text < 2 then return end
    if text:sub(1, #Config.Prefix) ~= Config.Prefix then return end
    local body = text:sub(#Config.Prefix + 1)
    local parts = {}
    for w in body:gmatch("%S+") do table.insert(parts, w) end
    if #parts == 0 then return end
    local name = table.remove(parts, 1)
    Execute(name, parts)
end

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.MessageReceived:Connect(function(msg)
            if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then
                ProcessChat(msg.Text)
            end
        end)
    end
end)
LocalPlayer.Chatted:Connect(ProcessChat)

--=====================================================================
-- 16. BOTÃO FLUTUANTE MOBILE
--=====================================================================
if IsOnMobile then
    local fab = Instance.new("TextButton")
    fab.Size = UDim2.new(0, 46, 0, 46)
    fab.Position = UDim2.new(0, 12, 0, 80)
    fab.BackgroundColor3 = Theme.Background
    fab.BackgroundTransparency = 0.1
    fab.BorderSizePixel = 0
    fab.Text = "IM"
    fab.TextColor3 = Theme.Accent
    fab.Font = Enum.Font.Code
    fab.TextSize = 16
    fab.ZIndex = 100
    fab.Parent = ScaledHolder
    Instance.new("UICorner", fab).CornerRadius = UDim.new(0, 23)
    local st = Instance.new("UIStroke", fab)
    st.Color = Theme.Border st.Thickness = 1

    OnTheme(function(t)
        fab.BackgroundColor3 = t.Background
        fab.TextColor3 = t.Accent
        st.Color = t.Border
    end)

    -- Arrastável
    local fdrag, fstart, fpos
    fab.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            fdrag = true fstart = input.Position fpos = fab.Position
        end
    end)
    fab.InputChanged:Connect(function(input)
        if fdrag and input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - fstart
            fab.Position = UDim2.new(fpos.X.Scale, fpos.X.Offset + d.X, fpos.Y.Scale, fpos.Y.Offset + d.Y)
        end
    end)
    fab.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            fdrag = false
            -- Se moveu pouco, considera tap
            if (input.Position - fstart).Magnitude < 8 then
                Holder.Visible = not Holder.Visible
                Config.BarVisible = Holder.Visible
                SaveConfig()
                if Holder.Visible then
                    Holder.Position = UDim2.new(0.5, -160, 0.5, -180)
                end
            end
        end
    end)
end

--=====================================================================
-- 17. KEYBINDS (só PC)
--=====================================================================
if not IsOnMobile then
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if Cmdbar:IsFocused() then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Holder.Visible = not Holder.Visible
            Config.BarVisible = Holder.Visible
            SaveConfig()
            if Holder.Visible then Cmdbar:CaptureFocus() end
        elseif input.KeyCode == Enum.KeyCode.End then
            ScreenGui:Destroy()
            _G.ImperiumLoaded = false
        end
    end)
end

--=====================================================================
-- 18. BOOT
--=====================================================================
BuildList()

Notify("Imperium", "v3.2 carregado! " .. #CmdList .. " comandos", 5)
Notify("Ajuda", IsOnMobile and "Botão IM no canto | Toque longo = ver descrição"
    or "RightShift = abrir | Hover = ver descrição | ;discord", 6)

_G.Imperium = {
    Config = Config,
    Registry = Registry,
    Aliases = Aliases,
    Register = Register,
    Execute = Execute,
    Notify = Notify,
    Logs = Logs,
    Waypoints = WPs,
    ESP = ESP,
    GUI = ScreenGui,
    Holder = Holder,
    DiscordLink = Config.DiscordLink,
    Version = "3.2",
    IsOnMobile = IsOnMobile,
}"Imperium/joinlog.txt", table.concat(Logs.join, "\n"))
        ShowNotif("Save", "Salvo em Imperium/", 3)
    end)
end)

--=====================================================================
-- BLOCO 20: COMANDOS DE SISTEMA
--=====================================================================
Register("discord", {"dc"}, "Copia link do Discord", "Sistema", function()
    local link = Config.DiscordLink
    if setclipboard then pcall(function() setclipboard(link) end)
    elseif toclipboard then pcall(function() toclipboard(link) end) end
    ShowNotif("Discord", "Copiado: " .. link, 5)
    print("[Imperium] Discord: " .. link)
end)

Register("help", {"h", "?"}, "Lista comandos", "Sistema", function()
    local names = {}
    for k, v in pairs(Registry) do table.insert(names, v.name) end
    table.sort(names)
    print("[Imperium] Comandos: " .. table.concat(names, ", "))
    ShowNotif("Help", #names .. " comandos (ver F9)", 4)
end)

Register("cmds", {}, "Alias de help", "Sistema", function() Execute("help", {}) end)

Register("prefix", {}, "Muda prefixo do chat", "Sistema", function(args)
    local p = args[1]
    if p and #p >= 1 then
        Config.Prefix = p
        SaveConfig()
        ShowNotif("Prefix", "Novo: " .. p, 3)
    end
end)

Register("theme", {}, "Troca tema (Dark/Light/Nord/Pink)", "Sistema", function(args)
    local t = args[1]
    if t and Themes[t] then
        ApplyTheme(t)
        ShowNotif("Tema", t, 2)
    else
        ShowNotif("Tema", "Opções: Dark, Light, Nord, Pink", 4)
    end
end)

Register("notify", {}, "Notificação de teste", "Sistema", function(args)
    local msg = table.concat(args, " ")
    if msg == "" then msg = "Teste de notificação!" end
    ShowNotif("Teste", msg, 4)
end)

Register("version", {"v"}, "Versão", "Sistema", function()
    ShowNotif("Imperium", "v3.1 | Open Source", 3)
end)

Register("credits", {}, "Créditos", "Sistema", function()
    ShowNotif("Credits", "Imperium Dev | Baseado em conceitos do Infinite Yield", 5)
end)

Register("clear", {"limpar"}, "Limpa clones locais", "Sistema", function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(LocalPlayer.Name) then
            pcall(function() obj:Destroy() end)
        end
    end
    ShowNotif("Clear", "Limpo", 2)
end)

--=====================================================================
-- BLOCO 21: FILTRO DE CATEGORIAS
--=====================================================================
local allCategories = {}
for _, cmd in ipairs(CmdOrder) do
    allCategories[cmd.category] = true
end
-- Adiciona "Todos"
MakeCategoryTab("Todos")
ActiveCategory = "Todos"
CategoryButtons["Todos"].BackgroundColor3 = Theme.Accent
CategoryButtons["Todos"].TextColor3 = Color3.new(1,1,1)

for cat, _ in pairs(allCategories) do
    MakeCategoryTab(cat)
end

--=====================================================================
-- BLOCO 22: LISTA DE COMANDOS NA GUI
--=====================================================================
local function RefreshCmdList()
    for _, c in ipairs(CMDsF:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    local sorted = {}
    for _, cmd in ipairs(CmdOrder) do
        if ActiveCategory == "Todos" or cmd.category == ActiveCategory then
            table.insert(sorted, cmd)
        end
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)

    local filter = Cmdbar.Text:lower()
    local i = 0
    for _, cmd in ipairs(sorted) do
        local txt = cmd.name .. (cmd.desc ~= "" and ("  —  " .. cmd.desc) or "")
        if filter == "" or txt:lower():find(filter, 1, true) then
            i += 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 22)
            btn.BackgroundColor3 = Theme.Button
            btn.BorderSizePixel = 0
            btn.Text = "  " .. txt
            btn.TextColor3 = Theme.Text
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.Code
            btn.TextSize = 11
            btn.AutoButtonColor = false
            btn.LayoutOrder = i
            btn.Parent = CMDsF
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.ButtonHover end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.Button end)
            btn.MouseButton1Click:Connect(function() Execute(cmd.name, {}) end)

            RegisterThemeListener(function(t)
                btn.BackgroundColor3 = t.Button
                btn.TextColor3 = t.Text
            end)
        end
    end

    CMDsF.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end
_G.Imperium_RefreshList = RefreshCmdList

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    CMDsF.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end)

--=====================================================================
-- BLOCO 23: INPUT DA BARRA
--=====================================================================
Cmdbar.FocusLost:Connect(function(enter)
    if not enter then return end
    local text = Cmdbar.Text
    Cmdbar.Text = ""
    if text == "" then return end

    if text:sub(1, #Config.Prefix) == Config.Prefix then
        text = text:sub(#Config.Prefix + 1)
    end

    local parts = {}
    for w in text:gmatch("%S+") do table.insert(parts, w) end
    if #parts == 0 then return end
    local name = table.remove(parts, 1)
    Execute(name, parts)
end)

-- Filtro em tempo real enquanto digita
Cmdbar:GetPropertyChangedSignal("Text"):Connect(function()
    RefreshCmdList()
end)

--=====================================================================
-- BLOCO 24: CHAT LISTENER (prefixo)
--=====================================================================
local function ProcessChat(text)
    if #text < 2 then return end
    if text:sub(1, #Config.Prefix) ~= Config.Prefix then return end
    local body = text:sub(#Config.Prefix + 1)
    local parts = {}
    for w in body:gmatch("%S+") do table.insert(parts, w) end
    if #parts == 0 then return end
    local name = table.remove(parts, 1)
    Execute(name, parts)
end

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.MessageReceived:Connect(function(msg)
            if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then
                ProcessChat(msg.Text)
            end
        end)
    end
end)

LocalPlayer.Chatted:Connect(ProcessChat)

--=====================================================================
-- BLOCO 25: KEYBINDS GLOBAIS
--=====================================================================
local GlobalKeybinds = {
    [Enum.KeyCode.RightShift] = function()
        Holder.Visible = not Holder.Visible
        Config.BarVisible = Holder.Visible
        SaveConfig()
        if Holder.Visible then
            Cmdbar:CaptureFocus()
        end
    end,
    [Enum.KeyCode.End] = function()
        ScreenGui:Destroy()
        _G.ImperiumLoaded = false
    end,
    [Enum.KeyCode.F] = function()
        if not Cmdbar:IsFocused() then
            Execute("fly", {})
        end
    end,
}

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    -- Não dispara se estiver digitando na barra
    if Cmdbar:IsFocused() then return end
    local fn = GlobalKeybinds[input.KeyCode]
    if fn then pcall(fn) end
end)

--=====================================================================
-- BLOCO 26: BOOT FINAL
--=====================================================================
RefreshCmdList()

ShowNotif("Imperium", "v3.1 | Digite help ou use a GUI", 5)
print("======================================================")
print("  Imperium v3.1 — Open Source")
print("  Prefixo: '" .. Config.Prefix .. "'")
print("  Atalhos: RightShift (barra) | F (fly) | End (sair)")
print("  Discord: " .. Config.DiscordLink)
print("  " .. #CmdOrder .. " comandos registrados")
print("======================================================")

-- API Global
_G.Imperium = {
    Config       = Config,
    Registry     = Registry,
    Aliases      = Aliases,
    Register     = Register,
    Execute      = Execute,
    Notify       = ShowNotif,
    Logs         = Logs,
    Waypoints    = Waypoints,
    ESP          = ESP,
    GUI          = ScreenGui,
    Holder       = Holder,
    RefreshList  = RefreshCmdList,
    ApplyTheme   = ApplyTheme,
    DiscordLink  = Config.DiscordLink,
    Version      = "3.1",
}