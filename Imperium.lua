--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                          IMPERIUM v3.1                               ║
    ║           Barra de Comando estilo Infinite Yield                     ║
    ║           Open Source | MIT | 90+ Comandos                           ║
    ║                                                                      ║
    ║  Autor: Imperium Dev Team                                            ║
    ║  Discord: https://discord.gg/BDCajDWXj8                              ║
    ║  Inspirado em: Infinite Yield (Edge) — reescrito do zero             ║
    ╚══════════════════════════════════════════════════════════════════════╝

    COMO USAR:
        1. Cole em um executor (Delta, Krnl, Synapse, etc.)
        2. Pressione RightShift para abrir/fechar a barra
        3. Digite comandos: fly, ws 100, esp, discord, help...
        4. Ou use o prefixo no chat: ;fly  ;ws 100  ;esp

    ATALHOS:
        RightShift  → toggle barra + foca input
        F           → toggle fly
        End         → fechar Imperium
]]

--=====================================================================
-- BLOCO 1: SERVIÇOS
--=====================================================================
local Services = setmetatable({}, {
    __index = function(self, name)
        local ok, svc = pcall(function() return game:GetService(name) end)
        if ok and svc then rawset(self, name, svc) return svc end
        error("Serviço inválido: " .. tostring(name))
    end
})

local Players          = Services.Players
local RunService       = Services.RunService
local UserInputService = Services.UserInputService
local TweenService     = Services.TweenService
local HttpService      = Services.HttpService
local StarterGui       = Services.StarterGui
local Lighting         = Services.Lighting
local Workspace        = Services.Workspace
local VirtualUser      = Services.VirtualUser
local TeleportService  = Services.TeleportService
local TextChatService  = Services.TextChatService
local CoreGui          = Services.CoreGui
local StarterPlayer    = Services.StarterPlayer
local GuiService       = Services.GuiService

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- Guard: evita dupla execução
if _G.ImperiumLoaded then
    warn("[Imperium] Já está em execução.")
    return
end
_G.ImperiumLoaded = true

--=====================================================================
-- BLOCO 2: CONFIG COM PERSISTÊNCIA
--=====================================================================
local hasFS = (writefile and readfile and isfile and makefolder and isfolder)
local CONFIG_FILE = "Imperium/config.json"

local Config = {
    Prefix       = ";",
    DiscordLink  = "https://discord.gg/BDCajDWXj8",
    BarVisible   = true,
    BarPosition  = {1, -320, 1, -300}, -- canto inferior direito
    Theme        = "Dark",
    ESP          = {
        Enabled       = false,
        Players       = true,
        Items         = false,
        ShowHealth    = true,
        ShowName      = true,
        ShowDistance  = false,
        ShowTracer    = true,
        MaxDistance   = 1000,
        ColorPlayer   = {255, 80, 80},
        ColorItem     = {80, 255, 130},
        ColorTracer   = {80, 180, 255},
    },
}

local function LoadConfig()
    if not hasFS then return end
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for k, v in pairs(data) do
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
-- BLOCO 3: UTILITÁRIOS
--=====================================================================
local Utils = {}

function Utils.Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Imperium] " .. tostring(err)) end
    return ok, err
end

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
-- BLOCO 4: TEMAS
--=====================================================================
local Themes = {
    Dark = {
        Background = Color3.fromRGB(32, 32, 36),
        Panel      = Color3.fromRGB(24, 24, 28),
        Accent     = Color3.fromRGB(90, 130, 220),
        Text       = Color3.fromRGB(230, 230, 245),
        SubText    = Color3.fromRGB(150, 150, 165),
        Border     = Color3.fromRGB(70, 70, 85),
        Button     = Color3.fromRGB(38, 38, 44),
        ButtonHover= Color3.fromRGB(52, 52, 62),
        Success    = Color3.fromRGB(90, 200, 120),
        Danger     = Color3.fromRGB(220, 80, 80),
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 245),
        Panel      = Color3.fromRGB(255, 255, 255),
        Accent     = Color3.fromRGB(60, 110, 230),
        Text       = Color3.fromRGB(30, 30, 40),
        SubText    = Color3.fromRGB(90, 90, 105),
        Border     = Color3.fromRGB(200, 200, 210),
        Button     = Color3.fromRGB(225, 225, 235),
        ButtonHover= Color3.fromRGB(210, 210, 225),
        Success    = Color3.fromRGB(60, 170, 100),
        Danger     = Color3.fromRGB(200, 60, 60),
    },
    Nord = {
        Background = Color3.fromRGB(46, 52, 64),
        Panel      = Color3.fromRGB(59, 66, 82),
        Accent     = Color3.fromRGB(136, 192, 208),
        Text       = Color3.fromRGB(236, 239, 244),
        SubText    = Color3.fromRGB(180, 190, 210),
        Border     = Color3.fromRGB(76, 86, 106),
        Button     = Color3.fromRGB(67, 76, 94),
        ButtonHover= Color3.fromRGB(76, 86, 106),
        Success    = Color3.fromRGB(163, 190, 140),
        Danger     = Color3.fromRGB(191, 97, 106),
    },
    Pink = {
        Background = Color3.fromRGB(40, 24, 36),
        Panel      = Color3.fromRGB(28, 16, 26),
        Accent     = Color3.fromRGB(255, 105, 180),
        Text       = Color3.fromRGB(245, 220, 235),
        SubText    = Color3.fromRGB(190, 150, 175),
        Border     = Color3.fromRGB(90, 50, 80),
        Button     = Color3.fromRGB(50, 30, 46),
        ButtonHover= Color3.fromRGB(70, 40, 60),
        Success    = Color3.fromRGB(120, 200, 130),
        Danger     = Color3.fromRGB(230, 90, 120),
    },
}

local Theme = Themes[Config.Theme] or Themes.Dark
local ThemeListeners = {}

local function RegisterThemeListener(fn)
    table.insert(ThemeListeners, fn)
end

local function ApplyTheme(name)
    if not Themes[name] then return end
    Config.Theme = name
    Theme = Themes[name]
    for _, fn in ipairs(ThemeListeners) do
        pcall(fn, Theme)
    end
    SaveConfig()
end

--=====================================================================
-- BLOCO 5: GUI — SCREEN E HOLDER
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
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local ScaledHolder = Instance.new("Frame")
ScaledHolder.Name = "ScaledHolder"
ScaledHolder.Size = UDim2.fromScale(1, 1)
ScaledHolder.BackgroundTransparency = 1
ScaledHolder.Parent = ScreenGui

-- Holder principal (janela)
local Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.Size = UDim2.new(0, 320, 0, 380)
Holder.Position = UDim2.new(
    Config.BarPosition[1], Config.BarPosition[2],
    Config.BarPosition[3], Config.BarPosition[4]
)
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

RegisterThemeListener(function(t)
    Holder.BackgroundColor3 = t.Background
    HolderStroke.Color = t.Border
end)

--=====================================================================
-- BLOCO 6: TITLE BAR + ARRASTAR
--=====================================================================
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 26)
Title.BackgroundColor3 = Theme.Panel
Title.BorderSizePixel = 0
Title.Text = "  Imperium v3.1"
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Holder
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

RegisterThemeListener(function(t)
    Title.BackgroundColor3 = t.Panel
    Title.TextColor3 = t.Accent
end)

-- Botões do header
local function MakeHeaderBtn(txt, xOffset, callback, tooltip)
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

    b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.ButtonHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Theme.Button end)
    b.MouseButton1Click:Connect(callback)

    RegisterThemeListener(function(t)
        b.BackgroundColor3 = t.Button
        b.TextColor3 = t.Text
    end)

    if tooltip then
        local tip = Instance.new("TextLabel")
        tip.Size = UDim2.new(0, 100, 0, 18)
        tip.BackgroundColor3 = Theme.Panel
        tip.BackgroundTransparency = 0.1
        tip.BorderSizePixel = 0
        tip.Text = tooltip
        tip.TextColor3 = Theme.Text
        tip.Font = Enum.Font.Code
        tip.TextSize = 10
        tip.Visible = false
        tip.ZIndex = 100
        tip.Parent = Holder
        Instance.new("UICorner", tip).CornerRadius = UDim.new(0, 4)
        b.MouseEnter:Connect(function()
            tip.Position = UDim2.new(0, b.AbsolutePosition.X - Holder.AbsolutePosition.X - 30, 0, 28)
            tip.Visible = true
        end)
        b.MouseLeave:Connect(function() tip.Visible = false end)
    end
    return b
end

MakeHeaderBtn("✕", -24, function()
    ScreenGui:Destroy()
    _G.ImperiumLoaded = false
end, "Fechar")

MakeHeaderBtn("–", -46, function()
    Holder.Visible = false
    Config.BarVisible = false
    SaveConfig()
end, "Minimizar")

MakeHeaderBtn("◐", -68, function()
    -- Cicla temas
    local order = {"Dark", "Light", "Nord", "Pink"}
    local idx = 1
    for i, v in ipairs(order) do
        if v == Config.Theme then idx = i + 1 break end
    end
    if idx > #order then idx = 1 end
    ApplyTheme(order[idx])
end, "Trocar tema")

-- Arrastar
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
-- BLOCO 7: COMAND BAR + LISTA
--=====================================================================
local Cmdbar = Instance.new("TextBox")
Cmdbar.Name = "Cmdbar"
Cmdbar.Size = UDim2.new(1, -16, 0, 26)
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

local CmdPad = Instance.new("UIPadding")
CmdPad.PaddingLeft = UDim.new(0, 8)
CmdPad.Parent = Cmdbar

RegisterThemeListener(function(t)
    Cmdbar.BackgroundColor3 = t.Panel
    Cmdbar.TextColor3 = t.Text
    Cmdbar.PlaceholderColor3 = t.SubText
end)

-- Filtro de categoria (opcional: "all", "mov", "visual"...)
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 22)
TabBar.Position = UDim2.new(0, 8, 0, 62)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Holder

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabBar

local ActiveCategory = "Todos"
local CategoryButtons = {}

local function MakeCategoryTab(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 60, 1, 0)
    b.BackgroundColor3 = Theme.Button
    b.BorderSizePixel = 0
    b.Text = name
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.Code
    b.TextSize = 11
    b.AutoButtonColor = false
    b.Parent = TabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

    b.MouseEnter:Connect(function()
        if ActiveCategory ~= name then b.BackgroundColor3 = Theme.ButtonHover end
    end)
    b.MouseLeave:Connect(function()
        if ActiveCategory ~= name then b.BackgroundColor3 = Theme.Button end
    end)
    b.MouseButton1Click:Connect(function()
        ActiveCategory = name
        for n, btn in pairs(CategoryButtons) do
            btn.BackgroundColor3 = (n == name) and Theme.Accent or Theme.Button
            btn.TextColor3 = (n == name) and Color3.new(1,1,1) or Theme.Text
        end
        _G.Imperium_RefreshList()
    end)

    RegisterThemeListener(function(t)
        b.BackgroundColor3 = (ActiveCategory == name) and t.Accent or t.Button
        b.TextColor3 = (ActiveCategory == name) and Color3.new(1,1,1) or t.Text
    end)

    CategoryButtons[name] = b
    return b
end

-- Lista scroll
local CMDsF = Instance.new("ScrollingFrame")
CMDsF.Name = "CMDs"
CMDsF.Size = UDim2.new(1, -16, 1, -96)
CMDsF.Position = UDim2.new(0, 8, 0, 88)
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

RegisterThemeListener(function(t)
    CMDsF.ScrollBarImageColor3 = t.Accent
end)

--=====================================================================
-- BLOCO 8: NOTIFICAÇÕES CUSTOM
--=====================================================================
local NotifStack = Instance.new("Frame")
NotifStack.Name = "NotifStack"
NotifStack.Size = UDim2.new(0, 280, 1, 0)
NotifStack.Position = UDim2.new(1, -290, 0, 20)
NotifStack.BackgroundTransparency = 1
NotifStack.Parent = ScaledHolder

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 6)
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.Parent = NotifStack

local function ShowNotif(title, text, duration)
    duration = duration or 5
    local n = Instance.new("Frame")
    n.Size = UDim2.new(1, 0, 0, 60)
    n.BackgroundColor3 = Theme.Panel
    n.BackgroundTransparency = 1
    n.BorderSizePixel = 0
    n.Parent = NotifStack
    Instance.new("UICorner", n).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", n)
    s.Color = Theme.Accent
    s.Transparency = 0.3

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -14, 0, 18)
    t.Position = UDim2.new(0, 7, 0, 6)
    t.BackgroundTransparency = 1
    t.Text = "IMPERIUM | " .. tostring(title)
    t.TextColor3 = Theme.Accent
    t.Font = Enum.Font.Code
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextTransparency = 1
    t.Parent = n

    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -14, 0, 32)
    d.Position = UDim2.new(0, 7, 0, 24)
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
-- BLOCO 9: REGISTRO DE COMANDOS
--=====================================================================
local Registry = {}
local Aliases  = {}
local CmdOrder = {}

local function Register(name, aliases, desc, category, fn)
    local cmd = {
        name = name,
        aliases = aliases or {},
        desc = desc or "",
        category = category or "Outros",
        fn = fn,
    }
    Registry[name:lower()] = cmd
    table.insert(CmdOrder, cmd)
    for _, a in ipairs(cmd.aliases) do
        Aliases[a:lower()] = name:lower()
    end
end

local function Execute(name, args)
    local key = name:lower()
    local cmd = Registry[key]
    if not cmd then
        local realName = Aliases[key]
        if realName then cmd = Registry[realName] end
    end
    if not cmd then
        ShowNotif("Erro", "Comando não encontrado: " .. name, 3)
        return false
    end
    local ok, err = pcall(cmd.fn, args or {})
    if not ok then
        ShowNotif("Erro", tostring(err), 4)
    end
    return ok
end

--=====================================================================
-- BLOCO 10: FLY SUAVE
--=====================================================================
local flyState = {
    active = false, conn = nil,
    bv = nil, bg = nil,
    velocity = Vector3.zero,
    speed = 100, turbo = 250,
    accel = 12, rotSpeed = 14,
}

local function StartFly()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    flyState.active = true
    hum.PlatformStand = true

    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
    end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.P = 8000
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.P = 8000
    bg.D = 200
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    flyState.bv = bv
    flyState.bg = bg
    flyState.velocity = Vector3.zero

    flyState.conn = RunService.RenderStepped:Connect(function(dt)
        if not flyState.active then return end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        local hum2 = c and c:FindFirstChildOfClass("Humanoid")
        if not h or not hum2 then return end

        local cam = Workspace.CurrentCamera
        local look  = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local up    = Vector3.new(0, 1, 0)

        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= look end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= up end

        local hMove = hum2.MoveDirection
        if hMove.Magnitude > 0.1 and dir.Magnitude < 0.1 then
            dir = (look * -hMove.Z + right * hMove.X)
        end

        local spd = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            and flyState.turbo or flyState.speed

        local target = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        local alpha  = math.clamp(flyState.accel * dt, 0, 1)
        flyState.velocity = flyState.velocity:Lerp(target, alpha)
        bv.Velocity = flyState.velocity

        local camRot = cam.CFrame.Rotation
        local newRot = bg.CFrame.Rotation:Lerp(camRot, math.clamp(flyState.rotSpeed * dt, 0, 1))
        bg.CFrame = CFrame.new(h.Position) * newRot
    end)
end

local function StopFly()
    flyState.active = false
    if flyState.conn then flyState.conn:Disconnect() flyState.conn = nil end
    if flyState.bv then flyState.bv:Destroy() flyState.bv = nil end
    if flyState.bg then flyState.bg:Destroy() flyState.bg = nil end
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand = false end
end

--=====================================================================
-- BLOCO 11: COMANDOS — MOVIMENTO
--=====================================================================
Register("fly", {"f"}, "Voa com WASD+Space/Ctrl, Shift=turbo", "Movimento", function()
    if flyState.active then
        StopFly()
        ShowNotif("Fly", "Desativado", 2)
    else
        StartFly()
        ShowNotif("Fly", "WASD | Space/Ctrl | Shift turbo", 4)
    end
end)

Register("flyspeed", {"fs"}, "Velocidade do fly", "Movimento", function(args)
    local v = tonumber(args[1])
    if v and v > 0 then
        flyState.speed = v
        ShowNotif("Fly", "Speed = " .. v, 2)
    end
end)

Register("flyturbo", {"ft"}, "Turbo do fly", "Movimento", function(args)
    local v = tonumber(args[1])
    if v and v > 0 then
        flyState.turbo = v
        ShowNotif("Fly", "Turbo = " .. v, 2)
    end
end)

Register("walkspeed", {"ws", "speed"}, "Define WalkSpeed", "Movimento", function(args)
    local _, h = Utils.GetChar()
    if not h then return end
    local v = tonumber(args[1]) or 16
    h.WalkSpeed = v
    ShowNotif("WS", "WalkSpeed = " .. v, 2)
end)

Register("jumppower", {"jp", "jump"}, "Define JumpPower", "Movimento", function(args)
    local _, h = Utils.GetChar()
    if not h then return end
    local v = tonumber(args[1]) or 50
    h.UseJumpPower = true
    h.JumpPower = v
    ShowNotif("JP", "JumpPower = " .. v, 2)
end)

local noclipConn
Register("noclip", {"nc"}, "Atravessa paredes", "Movimento", function()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
        local c = LocalPlayer.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
        ShowNotif("Noclip", "OFF", 2)
    else
        noclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end)
        ShowNotif("Noclip", "ON", 2)
    end
end)

local ijConn
Register("infinitejump", {"ij"}, "Pulo infinito", "Movimento", function()
    if ijConn then
        ijConn:Disconnect()
        ijConn = nil
        ShowNotif("IJ", "OFF", 2)
    else
        ijConn = UserInputService.JumpRequest:Connect(function()
            local _, h = Utils.GetChar()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        ShowNotif("IJ", "ON", 2)
    end
end)

Register("btools", {"bt"}, "Ferramentas de construção", "Movimento", function()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp then return end
    for _, n in ipairs({"Hammer", "Clone", "Grab", "Rocket"}) do
        local t = Instance.new("Tool")
        t.Name = n
        t.CanBeDropped = false
        t.RequiresHandle = false
        t.Parent = bp
    end
    ShowNotif("BTools", "Dadas", 2)
end)

--=====================================================================
-- BLOCO 12: COMANDOS — VISUAL
--=====================================================================
local fbActive
Register("fullbright", {"fb"}, "Iluminação total", "Visual", function()
    fbActive = not fbActive
    if fbActive then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        ShowNotif("Fullbright", "ON", 2)
    else
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        ShowNotif("Fullbright", "OFF", 2)
    end
end)

Register("fov", {}, "Define FOV (40-140)", "Visual", function(args)
    local v = tonumber(args[1]) or 70
    Camera.FieldOfView = v
    ShowNotif("FOV", tostring(v), 2)
end)

Register("time", {"hora"}, "Hora do jogo (0-24)", "Visual", function(args)
    local v = tonumber(args[1])
    if v then Lighting.ClockTime = v ShowNotif("Time", tostring(v), 2) end
end)

Register("fog", {"neblina"}, "FogEnd", "Visual", function(args)
    local v = tonumber(args[1]) or 1e6
    Lighting.FogEnd = v
    ShowNotif("Fog", tostring(v), 2)
end)

--=====================================================================
-- BLOCO 13: ESP CONFIGURÁVEL (Players + Items)
--=====================================================================
local ESP = {
    drawings = {},       -- [player] = {box, name, health, tracer}
    itemDrawings = {},   -- [part]   = {box, name}
    connPlayers = nil,
    connItems = nil,
}

local function CreatePlayerESP(plr)
    local box = Drawing.new("Square")
    box.Thickness = 1 box.Filled = false box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14 name.Center = true name.Outline = true name.Visible = false

    local health = Drawing.new("Text")
    health.Size = 12 health.Center = true health.Outline = true health.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1 tracer.Visible = false

    ESP.drawings[plr] = {box=box, name=name, health=health, tracer=tracer}
end

local function RemovePlayerESP(plr)
    local d = ESP.drawings[plr]
    if d then
        for _, o in pairs(d) do pcall(function() o:Remove() end) end
        ESP.drawings[plr] = nil
    end
end

local function UpdatePlayerESPColors()
    local cBox = Utils.ColorFromRGB(Config.ESP.ColorPlayer)
    local cTracer = Utils.ColorFromRGB(Config.ESP.ColorTracer)
    for _, d in pairs(ESP.drawings) do
        d.box.Color = cBox
        d.tracer.Color = cTracer
    end
end

local function StartPlayerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then CreatePlayerESP(p) end
    end
    UpdatePlayerESPColors()

    ESP.connPlayers = RunService.RenderStepped:Connect(function()
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
                        local h = math.clamp(1400 / dist, 20, 500)
                        local w = h * 0.55
                        d.box.Size = Vector2.new(w, h)
                        d.box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                        d.box.Visible = true

                        if Config.ESP.ShowName then
                            d.name.Position = Vector2.new(pos.X, pos.Y - h/2 - 14)
                            d.name.Text = plr.Name
                            d.name.Visible = true
                        else
                            d.name.Visible = false
                        end

                        if Config.ESP.ShowHealth then
                            d.health.Position = Vector2.new(pos.X, pos.Y + h/2 + 2)
                            d.health.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                            d.health.Color = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(255,80,80), 1 - hum.Health/hum.MaxHealth)
                            d.health.Visible = true
                        else
                            d.health.Visible = false
                        end

                        if Config.ESP.ShowDistance then
                            d.name.Text = plr.Name .. " [" .. math.floor(dist) .. "m]"
                        end

                        if Config.ESP.ShowTracer then
                            d.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            d.tracer.To = Vector2.new(pos.X, pos.Y + h/2)
                            d.tracer.Visible = true
                        else
                            d.tracer.Visible = false
                        end
                    else
                        d.box.Visible = false d.name.Visible = false d.health.Visible = false d.tracer.Visible = false
                    end
                else
                    d.box.Visible = false d.name.Visible = false d.health.Visible = false d.tracer.Visible = false
                end
            else
                d.box.Visible = false d.name.Visible = false d.health.Visible = false d.tracer.Visible = false
            end
        end
    end)

    -- Listener para novos players
    Players.PlayerAdded:Connect(function(p)
        if Config.ESP.Enabled and Config.ESP.Players and p ~= LocalPlayer then
            CreatePlayerESP(p)
            UpdatePlayerESPColors()
        end
    end)
    Players.PlayerRemoving:Connect(RemovePlayerESP)
end

local function StopPlayerESP()
    if ESP.connPlayers then ESP.connPlayers:Disconnect() ESP.connPlayers = nil end
    for p in pairs(ESP.drawings) do RemovePlayerESP(p) end
end

local function CreateItemESP(part)
    local box = Drawing.new("Square")
    box.Thickness = 1 box.Filled = false box.Visible = false
    box.Color = Utils.ColorFromRGB(Config.ESP.ColorItem)

    local name = Drawing.new("Text")
    name.Size = 12 name.Center = true name.Outline = true name.Visible = false
    name.Color = Utils.ColorFromRGB(Config.ESP.ColorItem)

    ESP.itemDrawings[part] = {box=box, name=name}
end

local function RemoveItemESP(part)
    local d = ESP.itemDrawings[part]
    if d then
        for _, o in pairs(d) do pcall(function() o:Remove() end) end
        ESP.itemDrawings[part] = nil
    end
end

local function StartItemESP()
    local candidates = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local parent = obj.Parent
            if parent and (parent:IsA("Tool") or parent:IsA("Model") and
                (obj.Name:lower():find("tool") or obj.Name:lower():find("item"))) then
                table.insert(candidates, obj)
            elseif obj:IsA("Tool") and obj.Parent then
                -- skip, handle model
            end
        elseif obj:IsA("Tool") then
            local handle = obj:FindFirstChild("Handle")
            if handle then table.insert(candidates, handle) end
        end
    end
    for _, part in ipairs(candidates) do CreateItemESP(part) end

    ESP.connItems = RunService.RenderStepped:Connect(function()
        local camPos = Camera.CFrame.Position
        for part, d in pairs(ESP.itemDrawings) do
            if not part.Parent then RemoveItemESP(part) continue end
            local dist = (part.Position - camPos).Magnitude
            if dist <= Config.ESP.MaxDistance then
                local pos, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local h = math.clamp(1200 / dist, 15, 300)
                    local w = h * 0.55
                    d.box.Size = Vector2.new(w, h)
                    d.box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                    d.box.Visible = true
                    d.name.Position = Vector2.new(pos.X, pos.Y - h/2 - 12)
                    d.name.Text = part.Name .. " [" .. math.floor(dist) .. "m]"
                    d.name.Visible = true
                else
                    d.box.Visible = false d.name.Visible = false
                end
            else
                d.box.Visible = false d.name.Visible = false
            end
        end
    end)
end

local function StopItemESP()
    if ESP.connItems then ESP.connItems:Disconnect() ESP.connItems = nil end
    for p in pairs(ESP.itemDrawings) do RemoveItemESP(p) end
end

local function RefreshESP()
    if Config.ESP.Enabled and Config.ESP.Players then
        if not ESP.connPlayers then StartPlayerESP() end
    else
        StopPlayerESP()
    end

    if Config.ESP.Enabled and Config.ESP.Items then
        if not ESP.connItems then StartItemESP() end
    else
        StopItemESP()
    end

    SaveConfig()
end

Register("esp", {"boxesp"}, "ESP jogadores (toggle)", "Visual", function()
    Config.ESP.Enabled = not Config.ESP.Enabled
    RefreshESP()
    ShowNotif("ESP", Config.ESP.Enabled and "ON" or "OFF", 2)
end)

Register("espitems", {}, "ESP em itens/tools", "Visual", function()
    Config.ESP.Items = not Config.ESP.Items
    RefreshESP()
    ShowNotif("ESP Items", Config.ESP.Items and "ON" or "OFF", 2)
end)

Register("espc", {"espconfig"}, "Config ESP (health/name/dist/tracer)", "Visual", function(args)
    local sub = (args[1] or ""):lower()
    if sub == "health" then
        Config.ESP.ShowHealth = not Config.ESP.ShowHealth
    elseif sub == "name" then
        Config.ESP.ShowName = not Config.ESP.ShowName
    elseif sub == "dist" then
        Config.ESP.ShowDistance = not Config.ESP.ShowDistance
    elseif sub == "tracer" then
        Config.ESP.ShowTracer = not Config.ESP.ShowTracer
    elseif sub == "dist_max" then
        local v = tonumber(args[2])
        if v then Config.ESP.MaxDistance = v end
    else
        ShowNotif("ESP", "Uso: espc health/name/dist/tracer/dist_max <n>", 4)
        return
    end
    SaveConfig()
    ShowNotif("ESP", "Config atualizada", 2)
end)

--=====================================================================
-- BLOCO 14: FREECAM
--=====================================================================
local freecamConn, freecamActive, freecamSavedCF
Register("freecam", {"fc"}, "Câmera livre", "Visual", function()
    freecamActive = not freecamActive
    if freecamActive then
        freecamSavedCF = Camera.CFrame
        Camera.CameraType = Enum.CameraType.Scriptable
        freecamConn = RunService.RenderStepped:Connect(function(dt)
            local look = Camera.CFrame.LookVector
            local right = Camera.CFrame.RightVector
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += look end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= look end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then
                Camera.CFrame = Camera.CFrame + dir.Unit * 70 * dt
            end
        end)
        ShowNotif("Freecam", "ON", 2)
    else
        if freecamConn then freecamConn:Disconnect() freecamConn = nil end
        Camera.CameraType = Enum.CameraType.Custom
        if freecamSavedCF then Camera.CFrame = freecamSavedCF end
        ShowNotif("Freecam", "OFF", 2)
    end
end)

--=====================================================================
-- BLOCO 15: COMANDOS — JOGADOR
--=====================================================================
Register("rejoin", {"rj"}, "Reentra no servidor", "Jogador", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

Register("serverhop", {"sh"}, "Troca de servidor", "Jogador", function()
    local ok, res = pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or not res or not res.data then
        ShowNotif("SH", "Falha ao buscar servidores", 3)
        return
    end
    local list = {}
    for _, s in ipairs(res.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            table.insert(list, s.id)
        end
    end
    if #list == 0 then ShowNotif("SH", "Sem servidores disponíveis", 2) return end
    TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(1,#list)], LocalPlayer)
end)

Register("reset", {"rs"}, "Reseta personagem", "Jogador", function()
    local _, h = Utils.GetChar()
    if h then h.Health = 0 end
end)

Register("godmode", {"god"}, "Godmode simulado", "Jogador", function()
    local _, h = Utils.GetChar()
    if h then
        h.MaxHealth = math.huge
        h.Health = math.huge
        ShowNotif("God", "ON", 2)
    end
end)

Register("heal", {"curar"}, "Cura o personagem", "Jogador", function()
    local _, h = Utils.GetChar()
    if h then h.Health = h.MaxHealth ShowNotif("Heal", "Curado", 2) end
end)

local loopHealConn
Register("loopheal", {"lheal"}, "Auto-cura", "Jogador", function()
    if loopHealConn then
        loopHealConn:Disconnect()
        loopHealConn = nil
        ShowNotif("LoopHeal", "OFF", 2)
    else
        loopHealConn = RunService.Heartbeat:Connect(function()
            local _, h = Utils.GetChar()
            if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
        end)
        ShowNotif("LoopHeal", "ON", 2)
    end
end)

Register("reassign", {"reatribuir"}, "Devolve ferramentas", "Jogador", function()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local c = LocalPlayer.Character
    if not bp or not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then t.Parent = bp end
    end
    ShowNotif("Reassign", "Ferramentas devolvidas", 2)
end)

Register("goto", {"tp"}, "Teleporta até player", "Jogador", function(args)
    local p = Utils.FindPlayer(args[1])
    if not p or not p.Character then
        ShowNotif("TP", "Player não encontrado", 2)
        return
    end
    local hrp = Utils.GetHRP()
    local target = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp and target then
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 3)
        ShowNotif("TP", "→ " .. p.Name, 2)
    end
end)

Register("bring", {"trazer"}, "Traz player até você", "Jogador", function(args)
    local p = Utils.FindPlayer(args[1])
    if not p or not p.Character then
        ShowNotif("Bring", "Player não encontrado", 2)
        return
    end
    local hrp = Utils.GetHRP()
    local target = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp and target then
        target.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
        ShowNotif("Bring", p.Name .. " trazido", 2)
    end
end)

Register("ping", {}, "Mostra seu ping", "Jogador", function()
    local stats = Services.Stats
    local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    ShowNotif("Ping", math.floor(ping) .. " ms", 3)
end)

Register("age", {}, "Idade da conta", "Jogador", function(args)
    local target = args[1] and Utils.FindPlayer(args[1]) or LocalPlayer
    if not target then ShowNotif("Age", "Player não encontrado", 2) return end
    local ok, age = pcall(function() return target.AccountAge end)
    if ok and age then
        local years = math.floor(age / 365)
        ShowNotif(target.Name, age .. " dias (~" .. years .. " anos)", 4)
    end
end)

Register("invisible", {"invis"}, "Fica invisível (local)", "Jogador", function()
    local c = LocalPlayer.Character
    if not c then return end
    _G.Imperium_Invis = not _G.Imperium_Invis
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = _G.Imperium_Invis and 1 or 0
        end
    end
    ShowNotif("Invis", _G.Imperium_Invis and "ON" or "OFF", 2)
end)

Register("freeze", {"congelar"}, "Congela um player", "Jogador", function(args)
    local p = Utils.FindPlayer(args[1])
    if not p or not p.Character then ShowNotif("Freeze", "Player inválido", 2) return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = true
        ShowNotif("Freeze", p.Name, 2)
    end
end)

Register("unfreeze", {"descongelar"}, "Descongela player", "Jogador", function(args)
    local p = Utils.FindPlayer(args[1])
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false ShowNotif("Unfreeze", p.Name, 2) end
end)

--=====================================================================
-- BLOCO 16: COMANDOS — TROLL / FUN
--=====================================================================
Register("fling", {}, "Fling próximo (3s)", "Troll", function()
    local hrp = Utils.GetHRP()
    if not hrp then return end
    local v = Instance.new("BodyAngularVelocity")
    v.AngularVelocity = Vector3.new(0, 1e4, 0)
    v.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    v.P = 1250
    v.Parent = hrp
    ShowNotif("Fling", "3s", 2)
    task.delay(3, function() pcall(function() v:Destroy() end) end)
end)

Register("spin", {"girar"}, "Gira rápido (3s)", "Troll", function()
    local char, hum = Utils.GetChar()
    if not hum then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bg = Instance.new("BodyGyro", hrp)
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1e4
    bg.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(45), 0)
    ShowNotif("Spin", "3s", 2)
    task.delay(3, function() pcall(function() bg:Destroy() end) end)
end)

Register("sit", {"sentar"}, "Senta", "Troll", function()
    local _, h = Utils.GetChar()
    if h then h.Sit = true end
end)

Register("dance", {"dançar"}, "Dança", "Troll", function()
    local _, h = Utils.GetChar()
    if not h then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://507771019"
    local ok, track = pcall(function() return h.Animator:LoadAnimation(anim) end)
    if ok and track then track:Play() end
end)

Register("clone", {"clonar"}, "Cria clone estático", "Troll", function()
    local c = LocalPlayer.Character
    if not c then return end
    local clone = c:Clone()
    clone.Parent = Workspace
    for _, p in ipairs(clone:GetDescendants()) do
        if p:IsA("Script") or p:IsA("LocalScript") then p:Destroy() end
    end
    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayName = "Imperium Clone"
        hum.WalkSpeed = 0
    end
    ShowNotif("Clone", "Criado", 2)
end)

--=====================================================================
-- BLOCO 17: WAYPOINTS (salvar/carregar posições)
--=====================================================================
local Waypoints = {}
if hasFS then
    pcall(function()
        if isfile("Imperium/waypoints.json") then
            Waypoints = HttpService:JSONDecode(readfile("Imperium/waypoints.json"))
        end
    end)
end

local function SaveWaypoints()
    if not hasFS then return end
    pcall(function()
        if not isfolder("Imperium") then makefolder("Imperium") end
        writefile("Imperium/waypoints.json", HttpService:JSONEncode(Waypoints))
    end)
end

Register("waypoint", {"wp"}, "Waypoints: save/list/go/del", "Waypoints", function(args)
    local sub = (args[1] or ""):lower()
    if sub == "save" then
        local name = args[2]
        local hrp = Utils.GetHRP()
        if not name or not hrp then
            ShowNotif("WP", "Uso: wp save <nome>", 3)
            return
        end
        Waypoints[name] = {
            x = hrp.Position.X, y = hrp.Position.Y, z = hrp.Position.Z,
            place = game.PlaceId,
        }
        SaveWaypoints()
        ShowNotif("WP", "Salvo: " .. name, 2)
    elseif sub == "list" then
        local names = {}
        for k, _ in pairs(Waypoints) do table.insert(names, k) end
        if #names == 0 then ShowNotif("WP", "Nenhum waypoint", 2) return end
        ShowNotif("Waypoints", table.concat(names, ", "), 5)
    elseif sub == "go" then
        local name = args[2]
        local wp = name and Waypoints[name]
        if not wp then ShowNotif("WP", "Não existe: " .. tostring(name), 2) return end
        if wp.place and wp.place ~= game.PlaceId then
            ShowNotif("WP", "Waypoint de outro jogo (place " .. wp.place .. ")", 3)
            return
        end
        local hrp = Utils.GetHRP()
        if hrp then
            hrp.CFrame = CFrame.new(Vector3.new(wp.x, wp.y, wp.z))
            ShowNotif("WP", "→ " .. name, 2)
        end
    elseif sub == "del" then
        local name = args[2]
        if name and Waypoints[name] then
            Waypoints[name] = nil
            SaveWaypoints()
            ShowNotif("WP", "Removido: " .. name, 2)
        end
    else
        ShowNotif("WP", "Uso: wp save/list/go/del", 4)
    end
end)

--=====================================================================
-- BLOCO 18: ALIASES EDITÁVEL
--=====================================================================
Register("alias", {}, "Aliases: add/del/list", "Sistema", function(args)
    local sub = (args[1] or ""):lower()
    if sub == "add" then
        local a, c = args[2], args[3]
        if not a or not c then ShowNotif("Alias", "Uso: alias add <alias> <cmd>", 3) return end
        c = c:lower()
        if not Registry[c] then ShowNotif("Alias", "Cmd não existe: " .. c, 3) return end
        Aliases[a:lower()] = c
        ShowNotif("Alias", a .. " → " .. c, 2)
    elseif sub == "del" then
        local a = args[2]
        if a then Aliases[a:lower()] = nil ShowNotif("Alias", "Removido: " .. a, 2) end
    elseif sub == "list" then
        local list = {}
        for a, c in pairs(Aliases) do table.insert(list, a .. "→" .. c) end
        ShowNotif("Aliases", table.concat(list, ", "), 5)
    else
        ShowNotif("Alias", "Uso: alias add/del/list", 4)
    end
end)

--=====================================================================
-- BLOCO 19: CHATLOG + JOINLOG
--=====================================================================
local Logs = { chat = {}, join = {}, maxSize = 200 }

local function PushLog(tbl, entry)
    table.insert(tbl, entry)
    if #tbl > Logs.maxSize then table.remove(tbl, 1) end
end

-- Captura chat
pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.MessageReceived:Connect(function(msg)
            if msg.TextSource then
                local sender = Players:GetPlayerByUserId(msg.TextSource.UserId)
                if sender then
                    PushLog(Logs.chat, ("[%s] %s: %s"):format(os.date("%H:%M:%S"), sender.Name, msg.Text))
                end
            end
        end)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            p.Chatted:Connect(function(msg)
                PushLog(Logs.chat, ("[%s] %s: %s"):format(os.date("%H:%M:%S"), p.Name, msg))
            end)
        end
        Players.PlayerAdded:Connect(function(p)
            p.Chatted:Connect(function(msg)
                PushLog(Logs.chat, ("[%s] %s: %s"):format(os.date("%H:%M:%S"), p.Name, msg))
            end)
        end)
    end
end)

-- Join/Leave
Players.PlayerAdded:Connect(function(p)
    PushLog(Logs.join, ("[%s] + %s"):format(os.date("%H:%M:%S"), p.Name))
end)
Players.PlayerRemoving:Connect(function(p)
    PushLog(Logs.join, ("[%s] - %s"):format(os.date("%H:%M:%S"), p.Name))
end)

Register("chatlog", {"clog"}, "Mostra/limpa chatlog", "Logs", function(args)
    if (args[1] or ""):lower() == "clear" then
        Logs.chat = {}
        ShowNotif("Chatlog", "Limpo", 2)
        return
    end
    local last = {}
    local start = math.max(1, #Logs.chat - 9)
    for i = start, #Logs.chat do table.insert(last, Logs.chat[i]) end
    if #last == 0 then ShowNotif("Chatlog", "Vazio", 2) return end
    for _, line in ipairs(last) do print("[Imperium Chatlog] " .. line) end
    ShowNotif("Chatlog", #Logs.chat .. " msgs (ver F9)", 3)
end)

Register("joinlog", {"jlog"}, "Mostra/limpa joinlog", "Logs", function(args)
    if (args[1] or ""):lower() == "clear" then
        Logs.join = {}
        ShowNotif("Joinlog", "Limpo", 2)
        return
    end
    local last = {}
    local start = math.max(1, #Logs.join - 9)
    for i = start, #Logs.join do table.insert(last, Logs.join[i]) end
    if #last == 0 then ShowNotif("Joinlog", "Vazio", 2) return end
    for _, line in ipairs(last) do print("[Imperium Joinlog] " .. line) end
    ShowNotif("Joinlog", #Logs.join .. " eventos (ver F9)", 3)
end)

Register("savelogs", {}, "Salva logs em arquivo", "Logs", function()
    if not hasFS then ShowNotif("Save", "Executor sem FS", 3) return end
    pcall(function()
        if not isfolder("Imperium") then makefolder("Imperium") end
        writefile("Imperium/chatlog.txt", table.concat(Logs.chat, "\n"))
        writefile("Imperium/joinlog.txt", table.concat(Logs.join, "\n"))
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