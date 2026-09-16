-- se tirar meus creditos (Bazuka) eu derrubo seu script.

--// Serviços
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = workspace
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ================================
-- LIMPEZA DE EXECUÇÃO ANTERIOR
-- ================================
if getgenv().KitK4t_Connections then
    for _, conn in ipairs(getgenv().KitK4t_Connections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().KitK4t_Connections = {}

if getgenv().KitK4t_Threads then
    for _, thread in ipairs(getgenv().KitK4t_Threads) do
        pcall(function() task.cancel(thread) end)
    end
end
getgenv().KitK4t_Threads = {}

pcall(function()
    local old = CoreGui:FindFirstChild("Imperium")
    if old then old:Destroy() end
end)

local function trackConnection(conn)
    table.insert(getgenv().KitK4t_Connections, conn)
    return conn
end

local function trackThread(thread)
    table.insert(getgenv().KitK4t_Threads, thread)
    return thread
end

repeat task.wait() until LocalPlayer.Character

--// Board Count (escrita)
local BoardCount =
    workspace:WaitForChild("WorkspaceCom")
    :WaitForChild("001_School")
    :WaitForChild("SchoolDryBoard")
    :WaitForChild("Words")
    :WaitForChild("Count")

--// Board Label (leitura automática)
local Words =
    workspace:WaitForChild("WorkspaceCom")
    :WaitForChild("001_School")
    :WaitForChild("SchoolDryBoard")
    :WaitForChild("Words")

--// Board Label (leitura automática e segura)
local BoardLabel = Words:FindFirstChildWhichIsA("TextLabel", true)

if not BoardLabel then
    warn("[Imperium] TextLabel do quadro não encontrado. Aguardando carregar...")
    repeat
        task.wait(0.25)
        BoardLabel = Words:FindFirstChildWhichIsA("TextLabel", true)
    until BoardLabel
end

--// Remote
local BoardRemote =
    ReplicatedStorage:WaitForChild("RE")
    :WaitForChild("1Schoo1lDr1yBoard1s")

--// Escrever no quadro
local function WriteBoard(text)
    text = tostring(text or "")

    BoardRemote:FireServer(
        "ReturningBoardName",
        BoardCount,
        text
    )
end

--// Ler o quadro
local function ReadBoard()
    return BoardLabel and BoardLabel.Text or ""
end

-- se tirar meus creditos (Bazuka) eu derrubo seu script.

-- ========================================
-- SISTEMA DE WHITELIST E TAGS
-- ========================================
getgenv().KitKatConfig = {
    AuthorizedPlayersURL = "https://raw.githubusercontent.com/dazzyxzx/allow-users/refs/heads/main/imperium.lua",
    SpecialTags = {
        ["Riftod37"] = "Dono Do Imperium"
    }
}

local ActiveTags = {}
local AuthorizedPlayersList = {}

pcall(function()
    local fn = loadstring(game:HttpGet(getgenv().KitKatConfig.AuthorizedPlayersURL))
    if fn then AuthorizedPlayersList = fn() end
end)

local function IsPlayerAuthorized(playerName)
    if getgenv().KitKatConfig.SpecialTags[playerName] then return true end
    if type(AuthorizedPlayersList) ~= "table" then return false end
    local lowerName = string.lower(tostring(playerName))
    for _, name in ipairs(AuthorizedPlayersList) do
        if string.lower(tostring(name)) == lowerName then
            return true
        end
    end
    return false
end

local function GetCargo(playerName)
    if getgenv().KitKatConfig.SpecialTags[playerName] then
        return getgenv().KitKatConfig.SpecialTags[playerName]
    elseif IsPlayerAuthorized(playerName) then
        return "Moderador Imperium"
    end
    return ""
end

local function RemovePlayerTag(playerName)
    if ActiveTags[playerName] then
        local tagData = ActiveTags[playerName]
        if tagData.Billboard then
            pcall(function() tagData.Billboard:Destroy() end)
        end
        ActiveTags[playerName] = nil
    end
end

local function CreatePlayerTag(playerName, tagText)
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    RemovePlayerTag(playerName)

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ImperiumTag"
    billboardGui.Adornee = head
    billboardGui.Size = UDim2.new(0, 150, 0, 30)
    billboardGui.AlwaysOnTop = true
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    billboardGui.MaxDistance = 120
    billboardGui.Parent = head

    local frame = Instance.new("Frame", billboardGui)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(1, -8, 1, -8)
    textLabel.Position = UDim2.new(0, 4, 0, 4)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = tagText
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)

    local glowEffect = Instance.new("UIStroke", frame)
    glowEffect.Color = Color3.fromRGB(255, 255, 255)
    glowEffect.Thickness = 1

    ActiveTags[playerName] = { Billboard = billboardGui, TagText = tagText }
end

local function createSpecialTag(player)
    if not player then return end

    local function apply()
        local tagText
        if getgenv().KitKatConfig.SpecialTags[player.Name] then
            tagText = getgenv().KitKatConfig.SpecialTags[player.Name]
        elseif IsPlayerAuthorized(player.Name) then
            tagText = "Moderador Imperium"
        end

        if tagText then
            if not ActiveTags[player.Name] or ActiveTags[player.Name].TagText ~= tagText then
                CreatePlayerTag(player.Name, tagText)
            end
        else
            RemovePlayerTag(player.Name)
        end
    end

    pcall(apply)

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        pcall(apply)
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    createSpecialTag(p)
end

trackConnection(Players.PlayerAdded:Connect(function(p)
    createSpecialTag(p)
end))

trackConnection(Players.PlayerRemoving:Connect(function(player)
    RemovePlayerTag(player.Name)
end))

trackThread(task.spawn(function()
    while true do
        task.wait(15)
        for _, p in ipairs(Players:GetPlayers()) do
            if ActiveTags[p.Name] then
                pcall(function()
                    local tagText
                    if getgenv().KitKatConfig.SpecialTags[p.Name] then
                        tagText = getgenv().KitKatConfig.SpecialTags[p.Name]
                    elseif IsPlayerAuthorized(p.Name) then
                        tagText = "Moderador Imperium"
                    end
                    if tagText then
                        CreatePlayerTag(p.Name, tagText)
                    end
                end)
            end
        end
    end
end))

-- Variáveis globais do sistema
local TEMP_MODS = {}
local KitK4t_USERS = {}
local playerOriginalSpeed = {}
local CASTIGO_PLAYERS = {}
local INVISIBLE_JAILED_PLAYERS = {}
local LOOP_KILL_PLAYERS = {}
local LOOP_BRING_PLAYERS = {}
local LOOP_SIT_PLAYERS = {}
local LOOP_FIRE_PLAYERS = {}
local jaulas = {}
local jailConnections = {}

-- ================================
-- SISTEMA DE ANÚNCIOS PREMIUM
-- ================================
local function CriarAnuncioBonito(remetente, texto)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ImperiumAnnouncement"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.DisplayOrder = 999
    screenGui.IgnoreGuiInset = true

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = game.Lighting

    local darkOverlay = Instance.new("Frame")
    darkOverlay.Size = UDim2.fromScale(1, 1)
    darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    darkOverlay.BackgroundTransparency = 1
    darkOverlay.BorderSizePixel = 0
    darkOverlay.Parent = screenGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 700, 0, 220)
    frame.Position = UDim2.new(0.5, 0, -0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = false
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 24)
    corner.Parent = frame

    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = Color3.fromRGB(255, 0, 0)
    outerStroke.Thickness = 4
    outerStroke.Transparency = 0
    outerStroke.Parent = frame

    local innerFrame = Instance.new("Frame")
    innerFrame.Size = UDim2.new(1, -8, 1, -8)
    innerFrame.Position = UDim2.fromScale(0.5, 0.5)
    innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    innerFrame.BackgroundTransparency = 1
    innerFrame.Parent = frame

    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.fromRGB(139, 0, 0)
    innerStroke.Thickness = 2
    innerStroke.Transparency = 0.3
    innerStroke.Parent = innerFrame

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 20)
    innerCorner.Parent = innerFrame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(60, 0, 0)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(100, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(139, 0, 0)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(100, 0, 0)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(60, 0, 0))
    }
    gradient.Rotation = 45
    gradient.Parent = frame

    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(0.4, 0, 2.5, 0)
    shine.Position = UDim2.new(-0.4, 0, -0.5, 0)
    shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shine.BackgroundTransparency = 0.85
    shine.BorderSizePixel = 0
    shine.Rotation = 30
    shine.Parent = frame

    local iconContainer = Instance.new("Frame")
    iconContainer.Size = UDim2.new(0, 100, 0, 100)
    iconContainer.Position = UDim2.new(0, 25, 0.5, 0)
    iconContainer.AnchorPoint = Vector2.new(0, 0.5)
    iconContainer.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    iconContainer.BackgroundTransparency = 0.1
    iconContainer.BorderSizePixel = 0
    iconContainer.Parent = frame

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = iconContainer

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Color = Color3.fromRGB(255, 50, 50)
    iconStroke.Thickness = 3
    iconStroke.Transparency = 0
    iconStroke.Parent = iconContainer

    local iconGradient = Instance.new("UIGradient")
    iconGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(200, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 50, 50)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(200, 0, 0))
    }
    iconGradient.Parent = iconContainer

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.fromScale(1, 1)
    icon.BackgroundTransparency = 1
    icon.Text = "📢"
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 50
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.Parent = iconContainer

    local textContainer = Instance.new("Frame")
    textContainer.Size = UDim2.new(1, -155, 1, -30)
    textContainer.Position = UDim2.new(0, 135, 0, 15)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = frame

    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, 0, 0, 2)
    topLine.Position = UDim2.new(0, 0, 0, 40)
    topLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    topLine.BackgroundTransparency = 0.3
    topLine.BorderSizePixel = 0
    topLine.Parent = textContainer

    local lineGradient = Instance.new("UIGradient")
    lineGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 100)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 0, 0))
    }
    lineGradient.Parent = topLine

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "⚡ AVISO DE " .. remetente:upper() .. " ⚡"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextStrokeTransparency = 0
    title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    title.Parent = textContainer

    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 100, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 100, 100))
    }
    titleGradient.Parent = title

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, 0, 1, -80)
    content.Position = UDim2.new(0, 0, 0, 65)
    content.BackgroundTransparency = 1
    content.Text = texto
    content.Font = Enum.Font.Gotham
    content.TextSize = 20
    content.TextColor3 = Color3.fromRGB(255, 255, 255)
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.TextStrokeTransparency = 0.7
    content.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    content.Parent = textContainer

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0, 0, 0, 4)
    progressBar.Position = UDim2.new(0, 0, 1, -10)
    progressBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = textContainer

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progressBar

    TweenService:Create(blur, TweenInfo.new(0.5), {Size = 18}):Play()
    TweenService:Create(darkOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()
    TweenService:Create(frame, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()

    TweenService:Create(shine, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {
        Position = UDim2.new(1.4, 0, -0.5, 0)
    }):Play()

    TweenService:Create(gradient, TweenInfo.new(7, Enum.EasingStyle.Linear), {
        Rotation = gradient.Rotation + 360
    }):Play()

    TweenService:Create(outerStroke, TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true), {
        Transparency = 0.6
    }):Play()
    TweenService:Create(iconStroke, TweenInfo.new(3.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true), {
        Transparency = 0.4
    }):Play()

    TweenService:Create(progressBar, TweenInfo.new(7, Enum.EasingStyle.Linear), {
        Size = UDim2.new(1, 0, 0, 4)
    }):Play()

    task.delay(7, function()
        TweenService:Create(frame, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, -0.5, 0),
            Size = UDim2.new(0, 700, 0, 0)
        }):Play()
        TweenService:Create(blur, TweenInfo.new(0.7), {Size = 0}):Play()
        TweenService:Create(darkOverlay, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()

        task.wait(0.8)
        screenGui:Destroy()
        blur:Destroy()
    end)
end

-- ================================
-- FUNÇÕES DE COMANDOS
-- ================================

local function GetPlayerRootPart(player)
    if player and player.Character then
        return player.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function KillPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0
        return true
    end
    return false
end

local function LoopKillPlayer(targetPlayer)
    if not targetPlayer then return false end
    LOOP_KILL_PLAYERS[targetPlayer.Name] = true
    task.spawn(function()
        while LOOP_KILL_PLAYERS[targetPlayer.Name] and targetPlayer and targetPlayer.Parent do
            if targetPlayer.Character then KillPlayer(targetPlayer) end
            task.wait(1)
        end
    end)
    return true
end

local function UnloopKillPlayer(targetPlayer)
    if not targetPlayer then return false end
    LOOP_KILL_PLAYERS[targetPlayer.Name] = nil
    return true
end

local function InvisibleJailPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end

    if INVISIBLE_JAILED_PLAYERS[targetPlayer.Name] then
        local jailData = INVISIBLE_JAILED_PLAYERS[targetPlayer.Name]
        if jailData.jailModel and jailData.jailModel.Parent then jailData.jailModel:Destroy() end
        if jailData.loop then task.cancel(jailData.loop) end
    end

    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local originalPosition = hrp.Position
    INVISIBLE_JAILED_PLAYERS[targetPlayer.Name] = { originalPosition = originalPosition, jailModel = nil, loop = nil }

    local jailPosition = hrp.Position
    local jailSize = 8

    local jailModel = Instance.new("Model", Workspace)
    jailModel.Name = "InvisibleJail_" .. targetPlayer.Name

    local parts = {
        Base  = Instance.new("Part", jailModel),
        Roof  = Instance.new("Part", jailModel),
        Wall1 = Instance.new("Part", jailModel),
        Wall2 = Instance.new("Part", jailModel),
        Wall3 = Instance.new("Part", jailModel),
        Wall4 = Instance.new("Part", jailModel)
    }

    parts.Base.Size = Vector3.new(jailSize, 0.5, jailSize)
    parts.Base.Position = jailPosition - Vector3.new(0, 3, 0)
    parts.Base.Anchored = true; parts.Base.CanCollide = true
    parts.Base.Transparency = 1; parts.Base.CastShadow = false

    parts.Roof.Size = Vector3.new(jailSize, 0.5, jailSize)
    parts.Roof.Position = parts.Base.Position + Vector3.new(0, jailSize, 0)
    parts.Roof.Anchored = true; parts.Roof.CanCollide = true
    parts.Roof.Transparency = 1; parts.Roof.CastShadow = false

    local wallConfigs = {
        { size = Vector3.new(0.5, jailSize, jailSize), position = parts.Base.Position + Vector3.new( jailSize/2, jailSize/2, 0) },
        { size = Vector3.new(0.5, jailSize, jailSize), position = parts.Base.Position + Vector3.new(-jailSize/2, jailSize/2, 0) },
        { size = Vector3.new(jailSize, jailSize, 0.5), position = parts.Base.Position + Vector3.new(0, jailSize/2,  jailSize/2) },
        { size = Vector3.new(jailSize, jailSize, 0.5), position = parts.Base.Position + Vector3.new(0, jailSize/2, -jailSize/2) }
    }

    for i, config in ipairs(wallConfigs) do
        local wall = parts["Wall" .. i]
        wall.Size = config.size; wall.Position = config.position
        wall.Anchored = true; wall.CanCollide = true
        wall.Transparency = 1; wall.CastShadow = false
    end

    local centerPosition = parts.Base.Position + Vector3.new(0, jailSize/2, 0)
    hrp.CFrame = CFrame.new(centerPosition)

    local monitorLoop = task.spawn(function()
        local center = parts.Base.Position + Vector3.new(0, jailSize/2, 0)
        while INVISIBLE_JAILED_PLAYERS[targetPlayer.Name] and targetPlayer.Parent and targetPlayer.Character and targetPlayer.Character.Parent do
            local currentHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if currentHrp and (currentHrp.Position - center).Magnitude > (jailSize/2) - 1 then
                currentHrp.CFrame = CFrame.new(center)
            end
            task.wait(0.2)
        end
    end)

    INVISIBLE_JAILED_PLAYERS[targetPlayer.Name].jailModel = jailModel
    INVISIBLE_JAILED_PLAYERS[targetPlayer.Name].loop = monitorLoop
    return true
end

local function InvisibleUnjailPlayer(targetPlayer)
    if not targetPlayer or not INVISIBLE_JAILED_PLAYERS[targetPlayer.Name] then return false end
    local jailData = INVISIBLE_JAILED_PLAYERS[targetPlayer.Name]
    if jailData.jailModel and jailData.jailModel.Parent then jailData.jailModel:Destroy() end
    if jailData.loop then task.cancel(jailData.loop) end
    if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        targetPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(jailData.originalPosition)
    end
    INVISIBLE_JAILED_PLAYERS[targetPlayer.Name] = nil
    return true
end

local function ExplodirPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local humanoidRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end

    local explosion = Instance.new("Explosion")
    explosion.Position = humanoidRootPart.Position
    explosion.BlastPressure = 500000
    explosion.BlastRadius = 10
    explosion.DestroyJointRadiusPercent = 0
    explosion.Parent = Workspace

    for i = 1, 8 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(2, 2, 2)
        part.Position = humanoidRootPart.Position + Vector3.new(math.random(-8,8), math.random(0,12), math.random(-8,8))
        part.Anchored = false; part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(100, 100, 255)
        part.Parent = Workspace
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(math.random(-80,80), math.random(30,100), math.random(-80,80))
        bv.MaxForce = Vector3.new(1e5,1e5,1e5)
        bv.Parent = part
        Debris:AddItem(part, 3)
    end

    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Health = 0 end
    return true
end

local function LocalBring(authorName)
    local author = Players:FindFirstChild(authorName)
    if not author then return end
    local authorRoot = GetPlayerRootPart(author)
    local playerRoot = GetPlayerRootPart(LocalPlayer)
    if authorRoot and playerRoot then
        playerRoot.CFrame = authorRoot.CFrame * CFrame.new(0, 2, 0)
    end
end

local function UnloopBringPlayer(targetPlayer)
    if not targetPlayer then return false end
    LOOP_BRING_PLAYERS[targetPlayer.Name] = nil
    return true
end

local function TPTrollPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local originalPosition = hrp.Position
    hrp.CFrame = CFrame.new(Vector3.new(799, -9, 482))
    task.delay(3, function()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(originalPosition)
        end
    end)
    return true
end

local function FloatPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not targetHrp or not targetHumanoid then return false end
    local targetPos = targetHrp.Position
    targetHumanoid.WalkSpeed = 0
    targetHumanoid.JumpHeight = 0

    local bodyVelocity = Instance.new("BodyVelocity", targetHrp)
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(0, 10, 0)
    bodyVelocity.Name = "FloatVelocity"

    local maxHeight = targetPos.Y + 50
    task.spawn(function()
        while targetPlayer.Character and targetPlayer.Character.Parent and targetHrp.Parent and targetHumanoid.Parent do
            if targetHrp.Position.Y >= maxHeight then
                if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
                targetHumanoid.Health = 0
                break
            end
            task.wait(0.2)
        end
        if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
    end)
    return true
end

local function LagPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    for i = 1, 50 do
        task.spawn(function()
            pcall(function()
                local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local explosion = Instance.new("Explosion")
                    explosion.Position = hrp.Position + Vector3.new(math.random(-10,10), math.random(0,5), math.random(-10,10))
                    explosion.BlastRadius = 20
                    explosion.BlastPressure = 1000000
                    explosion.Parent = Workspace
                end
            end)
        end)
    end
    for i = 1, 25 do
        task.spawn(function()
            local part = Instance.new("Part")
            part.Size = Vector3.new(5,5,5)
            part.Position = targetPlayer.Character.HumanoidRootPart.Position + Vector3.new(math.random(-20,20), math.random(0,10), math.random(-20,20))
            part.Anchored = false; part.CanCollide = true
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromRGB(255,0,0)
            part.Parent = Workspace
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(math.random(-100,100), math.random(50,200), math.random(-100,100))
            bv.MaxForce = Vector3.new(1e6,1e6,1e6)
            bv.Parent = part
            Debris:AddItem(part, 5)
        end)
    end
    return true
end

local function CastigoPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end

    if CASTIGO_PLAYERS[targetPlayer.Name] then
        local cd = CASTIGO_PLAYERS[targetPlayer.Name]
        if cd.jailModel and cd.jailModel.Parent then cd.jailModel:Destroy() end
        if cd.loop then task.cancel(cd.loop) end
    end

    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local originalPosition = hrp.Position
    CASTIGO_PLAYERS[targetPlayer.Name] = { originalPosition = originalPosition, jailModel = nil, loop = nil }

    local castigoPosition = Vector3.new(1159, 1727, 421)
    local jailSize = 12

    local jailModel = Instance.new("Model", Workspace)
    jailModel.Name = "Castigo_" .. targetPlayer.Name

    local parts = {
        Base  = Instance.new("Part", jailModel),
        Roof  = Instance.new("Part", jailModel),
        Wall1 = Instance.new("Part", jailModel),
        Wall2 = Instance.new("Part", jailModel),
        Wall3 = Instance.new("Part", jailModel),
        Wall4 = Instance.new("Part", jailModel)
    }

    parts.Base.Size = Vector3.new(jailSize, 0.5, jailSize)
    parts.Base.Position = castigoPosition - Vector3.new(0, 3, 0)
    parts.Base.Anchored = true; parts.Base.CanCollide = true

    parts.Roof.Size = Vector3.new(jailSize, 0.5, jailSize)
    parts.Roof.Position = parts.Base.Position + Vector3.new(0, jailSize, 0)
    parts.Roof.Anchored = true; parts.Roof.CanCollide = true

    local wallConfigs = {
        { size = Vector3.new(0.5, jailSize, jailSize), position = parts.Base.Position + Vector3.new( jailSize/2, jailSize/2, 0) },
        { size = Vector3.new(0.5, jailSize, jailSize), position = parts.Base.Position + Vector3.new(-jailSize/2, jailSize/2, 0) },
        { size = Vector3.new(jailSize, jailSize, 0.5), position = parts.Base.Position + Vector3.new(0, jailSize/2,  jailSize/2) },
        { size = Vector3.new(jailSize, jailSize, 0.5), position = parts.Base.Position + Vector3.new(0, jailSize/2, -jailSize/2) }
    }

    for i, config in ipairs(wallConfigs) do
        local wall = parts["Wall" .. i]
        wall.Size = config.size; wall.Position = config.position
        wall.Anchored = true; wall.CanCollide = true
    end

    local imageId = "rbxassetid://7409940017"
    for partName, part in pairs(parts) do
        for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom }) do
            local decal = Instance.new("Decal", part)
            decal.Face = face
            decal.Texture = imageId
            decal.Transparency = 0.1
        end
        part.Material = Enum.Material.Plastic
        part.Color = Color3.fromRGB(255, 255, 255)
    end

    local centerPosition = parts.Base.Position + Vector3.new(0, jailSize/2, 0)
    hrp.CFrame = CFrame.new(centerPosition)

    local monitorLoop = task.spawn(function()
        local center = parts.Base.Position + Vector3.new(0, jailSize/2, 0)
        while CASTIGO_PLAYERS[targetPlayer.Name] and targetPlayer.Parent and targetPlayer.Character and targetPlayer.Character.Parent do
            local currentHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if currentHrp and (currentHrp.Position - center).Magnitude > (jailSize/2) - 1 then
                currentHrp.CFrame = CFrame.new(center)
            end
            task.wait(0.2)
        end
    end)

    CASTIGO_PLAYERS[targetPlayer.Name].jailModel = jailModel
    CASTIGO_PLAYERS[targetPlayer.Name].loop = monitorLoop
    return true
end

local function DescastigoPlayer(targetPlayer)
    if not targetPlayer or not CASTIGO_PLAYERS[targetPlayer.Name] then return false end
    local cd = CASTIGO_PLAYERS[targetPlayer.Name]
    if cd.jailModel and cd.jailModel.Parent then cd.jailModel:Destroy() end
    if cd.loop then task.cancel(cd.loop) end
    if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        targetPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(cd.originalPosition)
    end
    CASTIGO_PLAYERS[targetPlayer.Name] = nil
    return true
end

local function CriarJumpscareLocal(imageId, audioId)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "JumpscareFullscreen"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 2147483647
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1,0,1,0)
    mainFrame.BackgroundColor3 = Color3.new(0,0,0)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2147483647
    mainFrame.Parent = screenGui

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1,0,1,0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = imageId
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.ZIndex = 2147483647
    imageLabel.Parent = mainFrame

    local sound = Instance.new("Sound")
    sound.SoundId = audioId
    sound.Volume = 2.0
    sound.Looped = false
    sound.Parent = mainFrame

    sound:Play()
    UserInputService.MouseIconEnabled = false

    task.spawn(function()
        for i = 1, 12 do
            if not screenGui.Parent then break end
            imageLabel.ImageTransparency = (i % 2 == 0) and 0.1 or 0
            task.wait(0.2)
        end
        imageLabel.ImageTransparency = 0
        task.wait(0.8)
        TweenService:Create(imageLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1 }):Play()
        TweenService:Create(mainFrame, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
        task.wait(2)
        UserInputService.MouseIconEnabled = true
        screenGui:Destroy()
    end)
    return true
end

local function TheRakeJumpscare()
    local SoundService = game:GetService("SoundService")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FullJumpscare"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    screenGui.Parent = CoreGui

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(1.2,0,1.2,0)
    imageLabel.Position = UDim2.new(-0.1,0,-0.1,0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = "rbxassetid://108753859505348"
    imageLabel.ZIndex = 999999
    imageLabel.Parent = screenGui

    local sound1 = Instance.new("Sound")
    sound1.SoundId = "rbxassetid://18967004856"
    sound1.Volume = 10
    sound1.Parent = SoundService

    local sound2 = Instance.new("Sound")
    sound2.SoundId = "rbxassetid://103396125105301"
    sound2.Volume = 10
    sound2.Parent = SoundService

    local isShaking = true
    task.spawn(function()
        while isShaking do
            imageLabel.Position = UDim2.new(-0.1, math.random(-10,10), -0.1, math.random(-10,10))
            task.wait(0.05)
        end
    end)

    imageLabel.Visible = true
    sound1:Play()
    task.delay(2, function()
        sound2:Play()
        sound2.Ended:Connect(function()
            isShaking = false
            screenGui:Destroy()
        end)
    end)
end

local function SitPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Sit = true; return true end
    return false
end

local function LoopSitPlayer(targetPlayer)
    if not targetPlayer then return false end
    LOOP_SIT_PLAYERS[targetPlayer.Name] = true
    task.spawn(function()
        while LOOP_SIT_PLAYERS[targetPlayer.Name] and targetPlayer and targetPlayer.Parent do
            if targetPlayer.Character then
                local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.Sit = true end
            end
            task.wait(0.5)
        end
    end)
    return true
end

local function UnloopSitPlayer(targetPlayer)
    if not targetPlayer then return false end
    LOOP_SIT_PLAYERS[targetPlayer.Name] = nil
    return true
end

local function FirePlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local fire = Instance.new("Fire")
        fire.Parent = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            or targetPlayer.Character:FindFirstChild("Torso")
            or targetPlayer.Character:FindFirstChildWhichIsA("BasePart")
        humanoid:TakeDamage(100)
        return true
    end
    return false
end

local function LoopFirePlayer(targetPlayer)
    if not targetPlayer then return false end
    LOOP_FIRE_PLAYERS[targetPlayer.Name] = true
    task.spawn(function()
        while LOOP_FIRE_PLAYERS[targetPlayer.Name] and targetPlayer and targetPlayer.Parent do
            if targetPlayer.Character then FirePlayer(targetPlayer) end
            task.wait(1)
        end
    end)
    return true
end

local function UnloopFirePlayer(targetPlayer)
    if not targetPlayer then return false end
    LOOP_FIRE_PLAYERS[targetPlayer.Name] = nil
    return true
end

local function TransformIntoGoner()
    local RS = game:GetService("ReplicatedStorage")
    RS:WaitForChild("Remotes"):WaitForChild("ChangeCharacterBody"):InvokeServer(unpack({{
        116253341067642, 110703630520331, 119263803737569,
        99234191703566, 99948897896884, 0
    }}))
    task.wait(3)
    local player = game.Players.LocalPlayer
    local humanoid = (player.Character or player.CharacterAdded:Wait()):WaitForChild("Humanoid")
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://4686925579"
    humanoid:LoadAnimation(animation):Play()
    humanoid.WalkSpeed = 0
    task.wait(2)

    local function ApplyGonerAppearance()
        local wearRemote = RS:WaitForChild("Remotes"):WaitForChild("Wear")
        for _, accessory in ipairs(humanoid:GetAppliedDescription():GetAccessories(true)) do
            if accessory.AssetId then wearRemote:InvokeServer(unpack({tonumber(accessory.AssetId)})) end
        end
        task.wait()
        RS.Remotes.Wear:InvokeServer(unpack({17771175724}))
        RS.Remotes.Wear:InvokeServer(unpack({17822722698}))
        RS.Remotes.Wear:InvokeServer(unpack({17822749561}))
        RS.Remotes.Wear:InvokeServer(unpack({17772174303}))
        RS.Remotes.Wear:InvokeServer(unpack({17770317484}))
        RS.Remotes.Wear:InvokeServer(unpack({4586060885}))
        RS.Remotes.Wear:InvokeServer(unpack({6913613757}))
        RS.Remotes.ChangeBodyColor:FireServer(unpack({"Really black"}))
        task.wait(0.2)
        RS.Remotes.ApplyEmmiter:InvokeServer(18635845425, "087SmokeBlack")
    end

    task.wait(0.2)
    local backpack = game.Players.LocalPlayer.Backpack
    local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

    local punchTool = Instance.new("Tool")
    punchTool.Name = "Soco"
    punchTool.RequiresHandle = true
    punchTool.CanBeDropped = false
    punchTool.Parent = backpack

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1,1,1)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.Anchored = false
    handle.Parent = punchTool

    punchTool.Equipped:Connect(function()
        punchTool.Activated:Connect(function()
            local characterHumanoid = character:FindFirstChildOfClass("Humanoid")
            if not characterHumanoid then return end
            local animator = characterHumanoid:FindFirstChild("Animator")
            if not animator then animator = Instance.new("Animator"); animator.Parent = characterHumanoid end
            local punchAnimation = Instance.new("Animation")
            punchAnimation.AnimationId = "rbxassetid://846744780"
            local animationTrack = animator:LoadAnimation(punchAnimation)
            animationTrack.Looped = false
            animationTrack:Play()
        end)
    end)

    local soundTools = {
        {name="Som 1", soundId=2291326370}, {name="Som 2", soundId=2316600989},
        {name="Som 3", soundId=2316601464}, {name="Som 4", soundId=2291325961},
        {name="Som 5", soundId=2290634374}, {name="Som 6", soundId=2737898305},
        {name="Som 7", soundId=2291326656}
    }

    for _, soundData in ipairs(soundTools) do
        local soundTool = Instance.new("Tool")
        soundTool.Name = soundData.name
        soundTool.RequiresHandle = false
        soundTool.Parent = backpack
        soundTool.Equipped:Connect(function()
            RS.RE:FindFirstChild("1Gu1nSound1s"):FireServer(unpack({workspace, soundData.soundId, 1}))
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://" .. soundData.soundId
            sound.Parent = workspace; sound.Volume = 0.3; sound.PlaybackSpeed = 1
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 3)
        end)
    end

    ApplyGonerAppearance()
    task.wait(1)

    local resetHumanoid = (player.Character or player.CharacterAdded:Wait()):WaitForChild("Humanoid")
    for _, track in pairs(resetHumanoid:GetPlayingAnimationTracks()) do track:Stop() end
    resetHumanoid.WalkSpeed = 16
    task.wait(0.2)

    game.Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        local newHumanoid = newCharacter:WaitForChild("Humanoid")
        RS:WaitForChild("Remotes"):WaitForChild("ResetCharacterAppearance"):FireServer()
        RS.Remotes.ApplyEmmiter:InvokeServer(unpack({18610639786, "0001Remove"}))
    end)

    task.wait()
    pcall(function()
        local r6fn = loadstring(game:HttpGet("https://github.com/contateste8/R6Convert/raw/refs/heads/main/R6Converter.txt"))
        if r6fn then r6fn() end
    end)
end

local FloppaRunning = false

local function FloppaRain()
    FloppaRunning = true

    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://123446364161879"
    sky.SkyboxDn = "rbxassetid://123446364161879"
    sky.SkyboxFt = "rbxassetid://123446364161879"
    sky.SkyboxLf = "rbxassetid://123446364161879"
    sky.SkyboxRt = "rbxassetid://123446364161879"
    sky.SkyboxUp = "rbxassetid://123446364161879"
    sky.Parent = game.Lighting

    task.spawn(function()
        while FloppaRunning do
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://8772968188"
            sound.Volume = 1
            sound.Parent = workspace
            sound:Play()
            task.wait(5)
        end
    end)

    task.wait(1)

    local floppaTemplate = Instance.new("Part")
    floppaTemplate.Size = Vector3.new(2,2,2)
    floppaTemplate.Anchored = false
    floppaTemplate.CanCollide = true

    local textureId = "rbxassetid://123446364161879"

    local function ApplyFloppaTexture(part)
        for _, faceName in pairs({"Front","Back","Left","Right","Top","Bottom"}) do
            local decal = Instance.new("Decal")
            decal.Texture = textureId
            decal.Face = Enum.NormalId[faceName]
            decal.Parent = part
        end
    end

    local function OnFloppaTouch(part)
        part.Touched:Connect(function(hit)
            local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:TakeDamage(10) end
        end)
    end

    local floppaCount = 0
    local MAX_FLOPPAS = 80
    while FloppaRunning do
        if floppaCount < MAX_FLOPPAS then
            for i = 1, 5 do
                local floppa = floppaTemplate:Clone()
                floppa.Position = Vector3.new(math.random(-250,250), 100, math.random(-250,250))
                ApplyFloppaTexture(floppa)
                OnFloppaTouch(floppa)
                floppa.Parent = workspace
                Debris:AddItem(floppa, 8)
                floppaCount = floppaCount + 1
            end
        end
        task.wait(0.5)
    end
end

local function StopFloppa()
    FloppaRunning = false
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Part") and obj.Size == Vector3.new(2,2,2) then
            local hasTexture = false
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Decal") then
                    hasTexture = true
                    break
                end
            end
            if hasTexture then
                pcall(function() obj:Destroy() end)
            end
        end
    end
    local flopSky = game.Lighting:FindFirstChildOfClass("Sky")
    if flopSky then flopSky:Destroy() end
end

-- ================================
-- FUNÇÃO: DOMAIN EXPANSION
-- ================================
local function DomainExpansion(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end

    local originalCFrame = targetHrp.CFrame
    local domainCenter = Vector3.new(5000, 100, 5000)
    local Lighting = game:GetService("Lighting")

    local savedLighting = {
        Brightness     = Lighting.Brightness,
        Ambient        = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd         = Lighting.FogEnd,
        FogStart       = Lighting.FogStart,
        FogColor       = Lighting.FogColor,
        ClockTime      = Lighting.ClockTime,
        ShadowSoftness = Lighting.ShadowSoftness,
    }

    local savedEffects = {}
    for _, eff in ipairs(Lighting:GetChildren()) do
        if eff:IsA("PostEffect") or eff:IsA("Sky") or eff:IsA("Atmosphere") then
            savedEffects[#savedEffects + 1] = eff:Clone()
            eff:Destroy()
        end
    end

    local sg = Instance.new("ScreenGui", CoreGui)
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 999999
    sg.IgnoreGuiInset = true

    local bg = Instance.new("Frame", sg)
    bg.Size = UDim2.new(2, 0, 2, 0)
    bg.Position = UDim2.new(-0.5, 0, -0.5, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.ZIndex = 999

    local titleLabel = Instance.new("TextLabel", sg)
    titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    titleLabel.Position = UDim2.new(0, 0, 0.4, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
    titleLabel.TextTransparency = 1
    titleLabel.Font = Enum.Font.Antique
    titleLabel.TextScaled = true
    titleLabel.Text = "Malevolent Shrine"
    titleLabel.ZIndex = 1000
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextStrokeTransparency = 0

    task.wait(0.8)
    targetHrp.CFrame = CFrame.new(domainCenter)

    Lighting.Brightness     = 0.3
    Lighting.ClockTime      = 0
    Lighting.ShadowSoftness = 1
    Lighting.Ambient        = Color3.fromRGB(60, 0, 0)
    Lighting.OutdoorAmbient = Color3.fromRGB(40, 0, 0)
    Lighting.FogStart       = 5
    Lighting.FogEnd         = 60
    Lighting.FogColor       = Color3.fromRGB(5, 0, 0)

    local domainSky = Instance.new("Sky", Lighting)
    domainSky.SkyboxBk = "rbxassetid://6444884337"
    domainSky.SkyboxDn = "rbxassetid://6444884337"
    domainSky.SkyboxFt = "rbxassetid://6444884337"
    domainSky.SkyboxLf = "rbxassetid://6444884337"
    domainSky.SkyboxRt = "rbxassetid://6444884337"
    domainSky.SkyboxUp = "rbxassetid://6444884337"

    local atm = Instance.new("Atmosphere", Lighting)
    atm.Density = 1; atm.Offset = 0
    atm.Color = Color3.fromRGB(30, 0, 0)
    atm.Decay = Color3.fromRGB(10, 0, 0)
    atm.Glare = 0; atm.Haze = 2.3

    local cc = Instance.new("ColorCorrectionEffect", Lighting)
    cc.Brightness = -0.04; cc.Contrast = 0.3
    cc.Saturation = -0.6
    cc.TintColor = Color3.fromRGB(255, 80, 80)

    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.6; bloom.Size = 24; bloom.Threshold = 0.8

    local floor = Instance.new("Part")
    floor.Size = Vector3.new(300, 1, 300)
    floor.Anchored = true; floor.CanCollide = true
    floor.Material = Enum.Material.SmoothPlastic
    floor.Color = Color3.fromRGB(10, 3, 3)
    floor.CFrame = CFrame.new(domainCenter - Vector3.new(0, 3, 0))
    floor.Parent = workspace

    local texture = Instance.new("Texture", floor)
    texture.Texture = "rbxassetid://74258839"
    texture.Color3 = Color3.fromRGB(80, 0, 0)
    texture.Transparency = 0.85
    texture.StudsPerTileU = 6; texture.StudsPerTileV = 6
    texture.Face = Enum.NormalId.Top

    local sphere = Instance.new("Part")
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(1, 1, 1)
    sphere.Anchored = true; sphere.CanCollide = false
    sphere.CastShadow = false
    sphere.Material = Enum.Material.SmoothPlastic
    sphere.Color = Color3.fromRGB(0, 0, 0)
    sphere.Transparency = 0
    sphere.Position = domainCenter
    sphere.Parent = workspace

    local sphereInner = Instance.new("Part")
    sphereInner.Shape = Enum.PartType.Ball
    sphereInner.Size = Vector3.new(1, 1, 1)
    sphereInner.Anchored = true; sphereInner.CanCollide = false
    sphereInner.CastShadow = false
    sphereInner.Material = Enum.Material.Neon
    sphereInner.Color = Color3.fromRGB(120, 0, 0)
    sphereInner.Transparency = 0.92
    sphereInner.Position = domainCenter
    sphereInner.Parent = workspace

    TweenService:Create(bg, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()

    task.delay(0.5, function()
        TweenService:Create(titleLabel, TweenInfo.new(1), {TextTransparency = 0}):Play()
        task.delay(2.5, function()
            TweenService:Create(titleLabel, TweenInfo.new(1.2), {TextTransparency = 1}):Play()
        end)
    end)

    task.spawn(function()
        for i = 1, 120, 2 do
            if sphere and sphere.Parent then
                sphere.Size = Vector3.new(i, i, i)
                sphereInner.Size = Vector3.new(i * 0.97, i * 0.97, i * 0.97)
            end
            task.wait(0.015)
        end
    end)

    task.wait(1.5)

    local playerLookVector = originalCFrame.LookVector
    local flatLook = Vector3.new(playerLookVector.X, 0, playerLookVector.Z).Unit
    local shrineOffset = flatLook * 20

    local shrineAssets = game:GetObjects("rbxassetid://16639433873")
    local shrine
    if shrineAssets and #shrineAssets > 0 then
        shrine = shrineAssets[1]
        shrine.Parent = workspace
        local p = shrine.PrimaryPart or shrine:FindFirstChildWhichIsA("BasePart")
        if p then
            shrine.PrimaryPart = p
            local shrinePos = domainCenter + shrineOffset + Vector3.new(0, -2, 0)
            shrine:SetPrimaryPartCFrame(CFrame.lookAt(shrinePos, domainCenter + Vector3.new(0, shrinePos.Y - domainCenter.Y, 0)))
        end

        local coresByName = {
            Skull = Color3.fromRGB(220, 200, 180), Horn = Color3.fromRGB(180, 160, 140),
            Shrine = Color3.fromRGB(60, 40, 40), Roof1 = Color3.fromRGB(40, 20, 20),
            Roof2 = Color3.fromRGB(40, 20, 20), Roof3 = Color3.fromRGB(40, 20, 20),
            Teethonroof = Color3.fromRGB(220, 200, 180),
            Mouth1 = Color3.fromRGB(200, 10, 10), Mouth2 = Color3.fromRGB(200, 10, 10),
            Thingy = Color3.fromRGB(180, 5, 5), ceiling = Color3.fromRGB(30, 15, 15),
        }

        for _, v in ipairs(shrine:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Anchored = true; v.CanCollide = false
                v.Material = Enum.Material.SmoothPlastic
                v.Color = coresByName[v.Name] or Color3.fromRGB(50, 25, 25)
            end
            if v:IsA("SurfaceAppearance") then v:Destroy() end
            if v:IsA("ParticleEmitter") then v.Enabled = true end
            if v:IsA("Sound") then v.Parent = workspace; v:Play() end
        end
    end

    local assets = game:GetObjects("rbxassetid://18618934824")
    local model, fxPart
    if assets and #assets > 0 then
        model = assets[1]
        model.Parent = workspace
        fxPart = model:FindFirstChild("DomainExpansionFX", true)
        if fxPart then
            fxPart.Anchored = true; fxPart.CanCollide = false
            fxPart.CFrame = CFrame.new(domainCenter)
            for _, v in ipairs(fxPart:GetDescendants()) do
                if v:IsA("ParticleEmitter") then v.Enabled = true end
            end
        end
        local starterPack = model:FindFirstChild("StarterPack", true)
        if starterPack then
            for _, v in ipairs(starterPack:GetDescendants()) do
                if v:IsA("Sound") then v.Parent = workspace; v:Play() end
            end
        end
    end

    local lightPart = Instance.new("Part")
    lightPart.Size = Vector3.new(1,1,1); lightPart.Anchored = true
    lightPart.CanCollide = false; lightPart.Transparency = 1
    lightPart.Position = domainCenter + Vector3.new(0, 8, 0)
    lightPart.Parent = workspace
    local redLight = Instance.new("PointLight", lightPart)
    redLight.Color = Color3.fromRGB(200, 0, 0)
    redLight.Brightness = 10; redLight.Range = 80

    local lightPart2 = Instance.new("Part")
    lightPart2.Size = Vector3.new(1,1,1); lightPart2.Anchored = true
    lightPart2.CanCollide = false; lightPart2.Transparency = 1
    lightPart2.Position = domainCenter + Vector3.new(0, -1, 0)
    lightPart2.Parent = workspace
    local darkLight = Instance.new("PointLight", lightPart2)
    darkLight.Color = Color3.fromRGB(100, 0, 0)
    darkLight.Brightness = 5; darkLight.Range = 60

    task.spawn(function()
        while lightPart and lightPart.Parent do
            TweenService:Create(redLight,  TweenInfo.new(0.4), {Brightness = 15}):Play()
            TweenService:Create(darkLight, TweenInfo.new(0.4), {Brightness = 8}):Play()
            task.wait(0.4)
            TweenService:Create(redLight,  TweenInfo.new(0.4), {Brightness = 6}):Play()
            TweenService:Create(darkLight, TweenInfo.new(0.4), {Brightness = 2}):Play()
            task.wait(0.4)
        end
    end)

    local slashRunning = true
    task.spawn(function()
        local hue = 0
        while slashRunning do
            for i = 1, 10 do
                task.spawn(function()
                    local slash = Instance.new("Part")
                    slash.Size = Vector3.new(0.12, math.random(5, 16), 0.12)
                    slash.Anchored = true; slash.CanCollide = false
                    slash.Material = Enum.Material.Neon
                    slash.Color = Color3.fromRGB(math.random(220, 255), math.random(0, 40), 0)
                    slash.Transparency = 0
                    local angle  = (i / 10) * math.pi * 2 + (hue * 0.1)
                    local radius = math.random(4, 25)
                    local height = math.random(-2, 10)
                    slash.CFrame = CFrame.new(
                        domainCenter.X + math.cos(angle) * radius,
                        domainCenter.Y + height,
                        domainCenter.Z + math.sin(angle) * radius
                    ) * CFrame.Angles(
                        math.random(-15, 15) * 0.1,
                        math.random(-15, 15) * 0.1,
                        math.random(-15, 15) * 0.1
                    )
                    slash.Parent = workspace
                    local trail = Instance.new("PointLight", slash)
                    trail.Color = Color3.fromRGB(255, 20, 0)
                    trail.Brightness = 3; trail.Range = 10
                    TweenService:Create(slash, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
                    task.delay(0.15, function() slash:Destroy() end)
                end)
            end
            hue = hue + 1
            task.wait(0.2)
        end
    end)

    local ashPart = Instance.new("Part")
    ashPart.Size = Vector3.new(1,1,1); ashPart.Anchored = true
    ashPart.CanCollide = false; ashPart.Transparency = 1
    ashPart.Position = domainCenter + Vector3.new(0, 2, 0)
    ashPart.Parent = workspace

    local ashEmitter = Instance.new("ParticleEmitter", ashPart)
    ashEmitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(80, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 0, 0)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 0, 0)),
    })
    ashEmitter.LightEmission  = 0.3; ashEmitter.LightInfluence = 0.8
    ashEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
    ashEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
    ashEmitter.Lifetime = NumberRange.new(3, 6)
    ashEmitter.Rate = 60; ashEmitter.Speed = NumberRange.new(2, 8)
    ashEmitter.SpreadAngle = Vector2.new(180, 180)
    ashEmitter.RotSpeed = NumberRange.new(-45, 45)
    ashEmitter.Rotation = NumberRange.new(0, 360)

    local damageRunning = true
    task.spawn(function()
        while damageRunning do
            local char = targetPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then hum:TakeDamage(5) end
            end
            task.wait(0.8)
        end
    end)

    task.delay(8, function()
        slashRunning  = false
        damageRunning = false
        ashEmitter.Enabled = false

        if fxPart then
            for _, v in ipairs(fxPart:GetDescendants()) do
                if v:IsA("ParticleEmitter") then v.Enabled = false end
            end
        end

        TweenService:Create(bg, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()
        task.wait(1)

        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
        end

        Lighting.Brightness     = savedLighting.Brightness
        Lighting.Ambient        = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.FogEnd         = savedLighting.FogEnd
        Lighting.FogStart       = savedLighting.FogStart
        Lighting.FogColor       = savedLighting.FogColor
        Lighting.ClockTime      = savedLighting.ClockTime
        Lighting.ShadowSoftness = savedLighting.ShadowSoftness

        if domainSky and domainSky.Parent then domainSky:Destroy() end
        if atm       and atm.Parent       then atm:Destroy()       end
        if cc        and cc.Parent        then cc:Destroy()        end
        if bloom     and bloom.Parent     then bloom:Destroy()     end

        for _, eff in ipairs(savedEffects) do eff.Parent = Lighting end

        task.spawn(function()
            for i = 120, 0, -2 do
                if sphere and sphere.Parent then
                    sphere.Size      = Vector3.new(i, i, i)
                    sphereInner.Size = Vector3.new(i * 0.97, i * 0.97, i * 0.97)
                end
                task.wait(0.015)
            end
            if sphere      and sphere.Parent      then sphere:Destroy()      end
            if sphereInner and sphereInner.Parent then sphereInner:Destroy() end
        end)

        task.wait(1.5)
        TweenService:Create(bg, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()

        task.delay(2, function()
            sg:Destroy()
            if model      and model.Parent      then model:Destroy()      end
            if shrine     and shrine.Parent     then shrine:Destroy()     end
            if floor      and floor.Parent      then floor:Destroy()      end
            if lightPart  and lightPart.Parent  then lightPart:Destroy()  end
            if lightPart2 and lightPart2.Parent then lightPart2:Destroy() end
            if ashPart    and ashPart.Parent    then ashPart:Destroy()    end
        end)
    end)

    return true
end

-- ================================
-- PROCESSADOR DE COMANDOS DO BOARD
-- ================================
local function ProcessarComando(texto)
    if not texto or texto == "" then return end

    local comando = texto:lower()
    local alvo = LocalPlayer.Name:lower()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    local remetente, mensagem = texto:match(";aviso%s+([^|]+)|(.+)$")
    if remetente and mensagem then
        mensagem = mensagem:gsub("||", "|")
        CriarAnuncioBonito(remetente, mensagem)
        return
    end

    local chAlvo, chMensagem = texto:match(";ch%s+(.-)%s+(.+)$")
    if chAlvo and chMensagem then
        if string.lower(chAlvo) == alvo then
            pcall(function()
                local TextChatService = game:GetService("TextChatService")
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    or TextChatService.TextChannels:GetChildren()[1]
                if channel then channel:SendAsync(chMensagem) end
            end)
        end
        return
    end

    if comando:match(";kick%s+" .. alvo) then
        LocalPlayer:Kick("Você foi expulso por um moderador.")
    end
    if comando:match(";kill%s+" .. alvo) then
        if char then char:BreakJoints() end
    end
    if comando:match(";loopkill%s+" .. alvo) then LoopKillPlayer(LocalPlayer) end
    if comando:match(";unloopkill%s+" .. alvo) then UnloopKillPlayer(LocalPlayer) end
    if comando:match(";fling%s+" .. alvo) then
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                TweenService:Create(root, TweenInfo.new(1), { CFrame = CFrame.new(0, 100000, 0) }):Play()
            end
        end
    end
    if comando:match(";backrooms%s+" .. alvo) then
        task.spawn(function()
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "BackroomsBlackout"
            screenGui.DisplayOrder = 9999
            screenGui.IgnoreGuiInset = true
            screenGui.ResetOnSpawn = false
            screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

            local blackFrame = Instance.new("Frame", screenGui)
            blackFrame.Size = UDim2.fromScale(1, 1)
            blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
            blackFrame.BackgroundTransparency = 1
            blackFrame.BorderSizePixel = 0

            TweenService:Create(blackFrame, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
            task.wait(2)

            local mapID = 10581711055
            local mapa = game:GetObjects("rbxassetid://" .. mapID)[1]
            if mapa then
                mapa.Parent = Workspace
                mapa.PrimaryPart = mapa.PrimaryPart or mapa:FindFirstChildWhichIsA("BasePart")
                if mapa.PrimaryPart then mapa:SetPrimaryPartCFrame(CFrame.new(0, 10000, 0)) end
            end
            if char and char:FindFirstChild("HumanoidRootPart") then
                char:MoveTo(Vector3.new(59, 9996, 19))
            end

            TweenService:Create(blackFrame, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
            task.wait(0.6)
            screenGui:Destroy()
        end)
    end
    if comando:match(";freeze%s+" .. alvo) then
        if humanoid then
            playerOriginalSpeed[alvo] = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
        end
    end
    if comando:match(";unfreeze%s+" .. alvo) then
        if humanoid then humanoid.WalkSpeed = playerOriginalSpeed[alvo] or 16 end
    end
    if comando:match(";jail%s+" .. alvo) then
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos = root.Position
                if jaulas[alvo] then
                    for _, parte in ipairs(jaulas[alvo]) do if parte then parte:Destroy() end end
                end
                jaulas[alvo] = {}

                local function criar(cf, s)
                    local p = Instance.new("Part")
                    p.Anchored = true; p.CanCollide = true
                    p.Material = Enum.Material.ForceField
                    p.Transparency = 0.3
                    p.Color = Color3.fromRGB(255, 0, 0)
                    p.Size = s; p.CFrame = cf
                    p.Parent = Workspace
                    local pointLight = Instance.new("PointLight")
                    pointLight.Color = Color3.fromRGB(255, 0, 0)
                    pointLight.Brightness = 2
                    pointLight.Range = 15
                    pointLight.Parent = p
                    table.insert(jaulas[alvo], p)
                end

                criar(CFrame.new(pos + Vector3.new(5,0,0)),   Vector3.new(1,10,10))
                criar(CFrame.new(pos + Vector3.new(-5,0,0)),  Vector3.new(1,10,10))
                criar(CFrame.new(pos + Vector3.new(0,0,5)),   Vector3.new(10,10,1))
                criar(CFrame.new(pos + Vector3.new(0,0,-5)),  Vector3.new(10,10,1))
                criar(CFrame.new(pos + Vector3.new(0,5,0)),   Vector3.new(10,1,10))
                criar(CFrame.new(pos + Vector3.new(0,-5,0)),  Vector3.new(10,1,10))

                if jailConnections[alvo] then jailConnections[alvo]:Disconnect() end
                local jailThread = task.spawn(function()
                    while jaulas[alvo] do
                        if root and (root.Position - pos).Magnitude > 5 then
                            root.CFrame = CFrame.new(pos)
                            root.Velocity = Vector3.new(0,0,0)
                        end
                        task.wait(0.2)
                    end
                end)
                jailConnections[alvo] = { Disconnect = function() task.cancel(jailThread) end }
            end
        end
    end
    if comando:match(";unjail%s+" .. alvo) then
        if jaulas[alvo] then
            for _, p in ipairs(jaulas[alvo]) do pcall(function() p:Destroy() end) end
            jaulas[alvo] = nil
        end
        if jailConnections[alvo] then
            jailConnections[alvo]:Disconnect()
            jailConnections[alvo] = nil
        end
    end
    if comando:match(";jail invisible%s+" .. alvo) then InvisibleJailPlayer(LocalPlayer) end
    if comando:match(";unjail invisible%s+" .. alvo) then InvisibleUnjailPlayer(LocalPlayer) end
    if comando:match(";explode%s+" .. alvo) then ExplodirPlayer(LocalPlayer) end
    if comando:match(";bring%s+" .. alvo) then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower() ~= alvo and IsPlayerAuthorized(player.Name) then
                LocalBring(player.Name)
                break
            end
        end
    end
    if comando:match(";loopbring%s+" .. alvo) then
        LOOP_BRING_PLAYERS[alvo] = true
        task.spawn(function()
            while LOOP_BRING_PLAYERS[alvo] do
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Name:lower() ~= alvo and IsPlayerAuthorized(player.Name) then
                        LocalBring(player.Name)
                        break
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    if comando:match(";unloopbring%s+" .. alvo) then LOOP_BRING_PLAYERS[alvo] = nil end
    if comando:match(";tptroll%s+" .. alvo) then TPTrollPlayer(LocalPlayer) end
    if comando:match(";float%s+" .. alvo) then FloatPlayer(LocalPlayer) end
    if comando:match(";lag%s+" .. alvo) then LagPlayer(LocalPlayer) end
    if comando:match(";castigo%s+" .. alvo) then CastigoPlayer(LocalPlayer) end
    if comando:match(";descastigo%s+" .. alvo) then DescastigoPlayer(LocalPlayer) end
    if comando:match(";jumps1%s+" .. alvo) then CriarJumpscareLocal("rbxassetid://126754882337711", "rbxassetid://138873214826309") end
    if comando:match(";jumps2%s+" .. alvo) then CriarJumpscareLocal("rbxassetid://86379969987314", "rbxassetid://143942090") end
    if comando:match(";jumps3%s+" .. alvo) then CriarJumpscareLocal("rbxassetid://127382022168206", "rbxassetid://143942090") end
    if comando:match(";jumps4%s+" .. alvo) then CriarJumpscareLocal("rbxassetid://95973611964555", "rbxassetid://138873214826309") end
    if comando:match(";therakejumpscare%s+" .. alvo) then TheRakeJumpscare() end
    if comando:match(";animejumpscare%s+" .. alvo) then
        task.spawn(function()
            pcall(function()
                local RunService = game:GetService("RunService")
                local Lighting = game:GetService("Lighting")

                local gui = Instance.new("ScreenGui")
                gui.Name = "AnimeJumpscare"
                gui.ResetOnSpawn = false
                gui.IgnoreGuiInset = true
                gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
                gui.DisplayOrder = 2147483647
                gui.Parent = CoreGui

                local whiteBackground = Instance.new("Frame")
                whiteBackground.Size = UDim2.fromScale(1, 1)
                whiteBackground.Position = UDim2.fromScale(0, 0)
                whiteBackground.BackgroundColor3 = Color3.new(1, 1, 1)
                whiteBackground.BorderSizePixel = 0
                whiteBackground.ZIndex = 999999
                whiteBackground.Parent = gui

                local blocker = Instance.new("TextButton")
                blocker.Size = UDim2.fromScale(1, 1)
                blocker.BackgroundTransparency = 1
                blocker.Text = ""
                blocker.AutoButtonColor = false
                blocker.Modal = true
                blocker.ZIndex = whiteBackground.ZIndex + 1
                blocker.Parent = whiteBackground

                local image = Instance.new("ImageLabel")
                image.AnchorPoint = Vector2.new(0.5, 0.5)
                image.Position = UDim2.fromScale(0.5, 0.5)
                image.Size = UDim2.fromScale(1, 1)
                image.BackgroundTransparency = 1
                image.Image = "rbxassetid://84838094344701"
                image.ZIndex = blocker.ZIndex + 1
                image.Parent = gui

                local sound1 = Instance.new("Sound")
                sound1.SoundId = "rbxassetid://82719020266339"
                sound1.Volume = 1
                sound1.Parent = gui

                local sound2 = Instance.new("Sound")
                sound2.SoundId = "rbxassetid://134884767490882"
                sound2.Volume = 0.8
                sound2.Looped = true
                sound2.Parent = workspace

                local distortion = Instance.new("DistortionSoundEffect")
                distortion.Level = 0.65
                distortion.Parent = sound2

                local eq = Instance.new("EqualizerSoundEffect")
                eq.LowGain = 12; eq.MidGain = -4; eq.HighGain = 3
                eq.Parent = sound2

                task.delay(2.8, function()
                    if image.Parent then image.Image = "rbxassetid://95558068230459" end
                end)

                local t = 0
                local conn
                conn = RunService.RenderStepped:Connect(function(dt)
                    if not image.Parent then conn:Disconnect() return end
                    t += dt * 5
                    image.Position = UDim2.fromScale(0.5 + math.sin(t * 7) * 0.02, 0.5 + math.cos(t * 8) * 0.02)
                    image.Size = UDim2.fromScale(1 + math.sin(t * 8) * 0.1, 1 + math.sin(t * 8) * 0.1)
                    image.Rotation = math.sin(t * 10) * 9
                end)

                sound1.Ended:Connect(function()
                    if gui and gui.Parent then gui:Destroy() end
                    sound2:Play()
                end)

                sound1:Play()

                local oldSky = Lighting:FindFirstChildOfClass("Sky")
                if oldSky then oldSky:Destroy() end

                local sky = Instance.new("Sky")
                sky.Name = "AnimeJumpscareSky"
                sky.Parent = Lighting

                local frames = {21076888,21076945,21077007,21077125,21077227,21077345,21077227,21077125,21077007,21076945}
                task.spawn(function()
                    while true do
                        for _, id in ipairs(frames) do
                            local asset = "rbxassetid://" .. id
                            sky.SkyboxBk = asset; sky.SkyboxDn = asset; sky.SkyboxFt = asset
                            sky.SkyboxLf = asset; sky.SkyboxRt = asset; sky.SkyboxUp = asset
                            task.wait(0.1)
                        end
                    end
                end)
            end)
        end)
    end
    if comando:match(";pararjumpscare%s+" .. alvo) then
        pcall(function()
            local gui = CoreGui:FindFirstChild("AnimeJumpscare")
            if gui then gui:Destroy() end
            for _, s in ipairs(workspace:GetChildren()) do
                if s:IsA("Sound") and s.SoundId == "rbxassetid://134884767490882" then
                    s:Stop(); s:Destroy()
                end
            end
            local sky = game:GetService("Lighting"):FindFirstChild("AnimeJumpscareSky")
            if sky then sky:Destroy() end
        end)
    end
    if comando:match(";sit%s+" .. alvo) then SitPlayer(LocalPlayer) end
    if comando:match(";loopsit%s+" .. alvo) then LoopSitPlayer(LocalPlayer) end
    if comando:match(";unloopsit%s+" .. alvo) then UnloopSitPlayer(LocalPlayer) end
    if comando:match(";fire%s+" .. alvo) then FirePlayer(LocalPlayer) end
    if comando:match(";loopfire%s+" .. alvo) then LoopFirePlayer(LocalPlayer) end
    if comando:match(";unloopfire%s+" .. alvo) then UnloopFirePlayer(LocalPlayer) end
    if comando:match(";goner%s+" .. alvo) then TransformIntoGoner() end
    if comando:match(";flopparain%s+" .. alvo) or comando == ";flopparain" then task.spawn(FloppaRain) end
    if comando:match(";unfloppa%s+" .. alvo) or comando == ";unfloppa" then StopFloppa() end

    if comando:match(";domainexpansion%s+" .. alvo) then
        task.spawn(function() DomainExpansion(LocalPlayer) end)
    end

    if comando == ";verifique" then
        ReplicatedStorage.RE["1Too1l"]:InvokeServer("PickingTools", "LaundryBasket")
        task.delay(0.5, function()
            for _, player in ipairs(Players:GetPlayers()) do
                local function possuiLaundry()
                    return (player.Backpack and player.Backpack:FindFirstChild("LaundryBasket"))
                        or (player.Character and player.Character:FindFirstChild("LaundryBasket"))
                end
                if possuiLaundry() and player.Character then
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local old = head:FindFirstChild("ImperiumTag")
                        if old then old:Destroy() end

                        local donos = { "Riftod37" }
                        local tagTexto = "Usuário Imperium"
                        for _, donoName in ipairs(donos) do
                            if player.Name == donoName then tagTexto = "Dono Imperium"; break end
                        end

                        local gui = Instance.new("BillboardGui")
                        gui.Name = "ImperiumTag"
                        gui.Size = UDim2.new(0, 240, 0, 50)
                        gui.StudsOffset = Vector3.new(0, 3.5, 0)
                        gui.AlwaysOnTop = true
                        gui.Adornee = head
                        gui.Parent = head

                        local text = Instance.new("TextLabel")
                        text.Size = UDim2.new(1, 0, 1, 0)
                        text.BackgroundTransparency = 1
                        text.Font = Enum.Font.GothamBold
                        text.TextScaled = true
                        text.TextStrokeTransparency = 0.2
                        text.TextStrokeColor3 = Color3.new(0, 0, 0)
                        text.TextColor3 = Color3.fromRGB(0, 180, 255)
                        text.Text = tagTexto
                        text.Parent = gui
                    end
                end
            end
        end)
    end
end

--// Escuta o board
if BoardLabel then
    trackConnection(BoardLabel:GetPropertyChangedSignal("Text"):Connect(function()
        local raw = BoardLabel.Text
        if not raw or raw == "" or raw == " " then return end
        ProcessarComando(raw)
    end))

    -- Processa caso já tenha texto no quadro quando o script carregar
    task.spawn(function()
        task.wait(0.5)
        local raw = ReadBoard()
        if raw and raw ~= "" and raw ~= " " then
            ProcessarComando(raw)
        end
    end)
else
    warn("[Imperium] BoardLabel não foi encontrado, comandos pelo quadro desativados.")
end

-- ================================
-- SERVIÇOS
-- ================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ================================
-- WINDUI - INTERFACE
-- ================================
KitK4t_USERS = KitK4t_USERS or {}
KitK4t_USERS[LocalPlayer.Name] = true

if not IsPlayerAuthorized(LocalPlayer.Name) then
    warn("⚠️ Você não está autorizado a usar o Imperium Admin")
    warn("⚠️ Seu username: " .. LocalPlayer.Name)
    return
end

print("✅ Usuário autorizado: " .. LocalPlayer.Name)
print("✅ Cargo: " .. GetCargo(LocalPlayer.Name))
print("✅ Carregando Imperium Admin...")

-- ================================
-- CARREGAR WINDUI
-- ================================
local WindUI
local Version = "1.4.0"

local success, result = pcall(function()
    local url = "https://github.com/Footagesus/WindUI/releases/download/" .. Version .. "/main.lua"
    local source = game:HttpGet(url, true)
    local loader = loadstring(source)
    if loader then return loader() else error("Falha no loadstring da WindUI") end
end)

if success and result then
    WindUI = result
else
    warn("[Imperium] Falha ao carregar WindUI.")
    warn(result)
    return
end

print("✅ WindUI carregado com sucesso!")
task.wait(0.5)

-- ================================
-- AVATAR
-- ================================
local Avatar = Players:GetUserThumbnailAsync(
    LocalPlayer.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

-- ================================
-- CRIAR JANELA
-- ================================
local Window = WindUI:CreateWindow({
    Title = "Imperium Admin",
    Icon = "shield",
    Author = "Bazuka",
    Folder = "Imperium",
    Size = UDim2.fromOffset(300, 300),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 120,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() end
    }
})

WindUI:SetTheme("Dark")
print("✅ Interface carregada com sucesso!")

local function getPlayersList()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(players, player.Name)
    end
    table.sort(players)
    return players
end

local registeredDropdowns = {}

local function registerDropdown(dropdown)
    table.insert(registeredDropdowns, dropdown)
end

local function updateAllDropdowns()
    local playerList = getPlayersList()
    for _, dd in ipairs(registeredDropdowns) do
        if dd then
            pcall(function()
                if dd.Refresh then dd:Refresh(playerList)
                elseif dd.SetValues then dd:SetValues(playerList)
                elseif dd.Set then dd:Set(playerList)
                elseif dd.UpdateValues then dd:UpdateValues(playerList)
                end
            end)
        end
    end
end

trackThread(task.spawn(function()
    while true do
        task.wait(20)
        updateAllDropdowns()
    end
end))
trackConnection(Players.PlayerAdded:Connect(function() task.wait(0.5); updateAllDropdowns() end))
trackConnection(Players.PlayerRemoving:Connect(function() task.wait(0.2); updateAllDropdowns() end))

-- ================================
-- DEBOUNCE + ENVIARBOARD
-- ================================
local _enviarBoardDebounce = false
local function EnviarBoard(cmd, target)
    if _enviarBoardDebounce then return end
    _enviarBoardDebounce = true
    task.delay(0.8, function() _enviarBoardDebounce = false end)

    cmd = tostring(cmd or "")
    target = tostring(target or "")

    local texto
    if target == "" then
        texto = ";" .. cmd
    else
        texto = ";" .. cmd .. " " .. target:lower()
    end

    WriteBoard(texto)

    task.delay(0.4, function()
        WriteBoard(" ")
    end)
end

task.spawn(function()
    task.wait(1)
    updateAllDropdowns()
end)

-- ================================
-- ABA: COMANDOS
-- ================================
local TabComandos = Window:Tab({ Title = "Comandos", Icon = "terminal" })
Window:SelectTab(1)

local TargetName = ""
local Dropdown = TabComandos:Dropdown({
    Title = "Selecionar Jogador",
    Values = getPlayersList(),
    Value = "",
    Multi = false,
    AllowNone = true,
    Callback = function(opt)
        if opt then TargetName = opt end
    end
})
registerDropdown(Dropdown)

TabComandos:Section({ Title = "Administração", TextXAlignment = "Left", TextSize = 17 })

TabComandos:Button({ Title = "/verifique", Desc = "Verifica quais jogadores são Imperium Users", Callback = function()
    EnviarBoard("verifique")
end })

local comandos = {
    { cmd = "kill",        desc = "Mata o jogador" },
    { cmd = "kick",        desc = "Expulsa o jogador" },
    { cmd = "fling",       desc = "Arremessa o jogador" },
    { cmd = "backrooms",   desc = "Teleporta para as Backrooms" },
    { cmd = "freeze",      desc = "Congela o jogador" },
    { cmd = "unfreeze",    desc = "Descongela o jogador" },
    { cmd = "jail",        desc = "Prende o jogador em jaula" },
    { cmd = "unjail",      desc = "Remove a jaula do jogador" },
    { cmd = "explode",     desc = "Explode o jogador" },
    { cmd = "bring",       desc = "Teleporta o jogador até você" },
    { cmd = "tptroll",     desc = "Trolleia com teleporte" },
    { cmd = "float",       desc = "Faz o jogador flutuar e morrer" },
    { cmd = "lag",         desc = "Causa lag no jogador" },
    { cmd = "castigo",     desc = "Manda o jogador para o castigo" },
    { cmd = "descastigo",  desc = "Remove o jogador do castigo" },
    { cmd = "loopkill",    desc = "Mata em loop" },
    { cmd = "unloopkill",  desc = "Para o loop kill" },
    { cmd = "loopbring",   desc = "Traz em loop" },
    { cmd = "unloopbring", desc = "Para o loop bring" },
    { cmd = "sit",         desc = "Força o jogador a sentar" },
    { cmd = "loopsit",     desc = "Senta em loop" },
    { cmd = "unloopsit",   desc = "Para o loop sit" },
    { cmd = "fire",        desc = "Coloca fogo no jogador" },
    { cmd = "loopfire",    desc = "Fogo em loop" },
    { cmd = "unloopfire",  desc = "Para o loop fire" },
}

for _, entry in ipairs(comandos) do
    TabComandos:Button({
        Title = "/" .. entry.cmd,
        Desc = entry.desc,
        Callback = function()
            if TargetName and TargetName ~= "" then
                EnviarBoard(entry.cmd, TargetName)
            end
        end
    })
end

TabComandos:Section({ Title = "Floppa", TextXAlignment = "Left", TextSize = 17 })
TabComandos:Button({ Title = "/flopparain", Desc = "Ativa chuva de Floppas", Callback = function()
    if TargetName and TargetName ~= "" then EnviarBoard("flopparain", TargetName) end
end })
TabComandos:Button({ Title = "/unfloppa", Desc = "Para a chuva de Floppas", Callback = function()
    if TargetName and TargetName ~= "" then EnviarBoard("unfloppa", TargetName) end
end })

-- ================================
-- ABA: COMMANDS 2
-- ================================
local TabComandos2 = Window:Tab({ Title = "Commands 2", Icon = "zap" })

TabComandos2:Section({ Title = "Domain Expansion", TextXAlignment = "Left", TextSize = 17 })

local Commands2TargetName = ""
local Commands2Dropdown = TabComandos2:Dropdown({
    Title = "Selecionar Jogador",
    Values = getPlayersList(),
    Value = "",
    Multi = false,
    AllowNone = true,
    Callback = function(opt)
        if opt then Commands2TargetName = opt end
    end
})
registerDropdown(Commands2Dropdown)

TabComandos2:Button({
    Title = "/domainexpansion",
    Desc = "Ativa o Domain Expansion (Malevolent Shrine) no jogador selecionado",
    Callback = function()
        if not Commands2TargetName or Commands2TargetName == "" then
            warn("Selecione um jogador primeiro!")
            return
        end
        local targetPlayer = Players:FindFirstChild(Commands2TargetName)
        if targetPlayer then
            task.spawn(function() DomainExpansion(targetPlayer) end)
        else
            warn("Jogador não encontrado: " .. Commands2TargetName)
        end
    end
})

-- ================================
-- ABA: AVISOS
-- ================================
local TabAvisos = Window:Tab({ Title = "Avisos", Icon = "megaphone" })

TabAvisos:Section({ Title = "Sistema de Anúncios", TextXAlignment = "Left", TextSize = 17 })

local textoAviso = ""
TabAvisos:Input({
    Title = "Mensagem do Aviso",
    Desc = "Digite a mensagem que deseja enviar a todos",
    Default = "",
    Placeholder = "Ex: Servidor será reiniciado em 5 minutos...",
    Callback = function(txt) textoAviso = txt end
})

TabAvisos:Button({
    Title = "Enviar Aviso",
    Desc = "Envia o aviso pelo board para todos com o script",
    Callback = function()
        if not textoAviso or textoAviso == "" then warn("Digite uma mensagem antes de enviar!") return end
        local mensagemCodificada = textoAviso:gsub("|", "||")
        WriteBoard(";aviso " .. LocalPlayer.Name .. "|" .. mensagemCodificada)
        task.delay(0.3, function()
            WriteBoard(" ")
        end)
        CriarAnuncioBonito(LocalPlayer.Name, textoAviso)
    end
})

TabAvisos:Section({ Title = "Forçar Chat (/ch)", TextXAlignment = "Left", TextSize = 17 })

local chTargetName = ""
local chDropdown = TabAvisos:Dropdown({
    Title = "Selecionar Jogador",
    Values = getPlayersList(),
    Value = "",
    Multi = false,
    AllowNone = true,
    Callback = function(opt)
        if opt then chTargetName = opt end
    end
})
registerDropdown(chDropdown)

local chMensagemTexto = ""
TabAvisos:Input({
    Title = "Mensagem",
    Desc = "Mensagem que será enviada no chat pelo jogador",
    Default = "",
    Placeholder = "Ex: oi gente tudo bem?",
    Callback = function(txt) chMensagemTexto = txt end
})

TabAvisos:Button({
    Title = "Enviar /ch",
    Desc = "Força o jogador selecionado a mandar a mensagem no chat",
    Callback = function()
        if not chTargetName or chTargetName == "" then warn("Selecione um jogador!") return end
        if not chMensagemTexto or chMensagemTexto == "" then warn("Digite uma mensagem!") return end
        WriteBoard(";ch " .. chTargetName .. " " .. chMensagemTexto)
        task.delay(0.4, function()
            WriteBoard(" ")
        end)
    end
})

-- ================================
-- ABA: JUMPSCARE
-- ================================
local TabJumpscare = Window:Tab({ Title = "Jumpscare", Icon = "skull" })

TabJumpscare:Section({ Title = "Jumpscares Terror", TextXAlignment = "Left", TextSize = 17 })

local JumpscareTargetName = ""
local JumpscareDropdown = TabJumpscare:Dropdown({
    Title = "Selecionar Jogador",
    Values = getPlayersList(),
    Value = "",
    Multi = false,
    AllowNone = true,
    Callback = function(opt)
        if opt then JumpscareTargetName = opt end
    end
})
registerDropdown(JumpscareDropdown)

local jumpscares = {
    { name = "jumps1",           desc = "Jumpscare 1 - Imagem assustadora" },
    { name = "jumps2",           desc = "Jumpscare 2 - Terror clássico" },
    { name = "jumps3",           desc = "Jumpscare 3 - Sustos intensos" },
    { name = "jumps4",           desc = "Jumpscare 4 - Horror máximo" },
    { name = "therakejumpscare", desc = "The Rake Jumpscare" },
    { name = "animejumpscare",   desc = "Anime Jumpscare - Vtuber com música" },
    { name = "pararjumpscare",   desc = "Para o Anime Jumpscare" },
}

for _, jumpscare in ipairs(jumpscares) do
    TabJumpscare:Button({
        Title = "/" .. jumpscare.name,
        Desc = jumpscare.desc,
        Callback = function()
            if JumpscareTargetName and JumpscareTargetName ~= "" then
                EnviarBoard(jumpscare.name, JumpscareTargetName)
            end
        end
    })
end

-- ================================
-- ABA: MORPHS
-- ================================
local TabMorphs = Window:Tab({ Title = "Morphs", Icon = "user" })

TabMorphs:Section({ Title = "Transformações", TextXAlignment = "Left", TextSize = 17 })

local MorphTargetName = ""
local MorphDropdown = TabMorphs:Dropdown({
    Title = "Selecionar Jogador",
    Values = getPlayersList(),
    Value = "",
    Multi = false,
    AllowNone = true,
    Callback = function(opt)
        if opt then MorphTargetName = opt end
    end
})
registerDropdown(MorphDropdown)

TabMorphs:Button({ Title = "/goner", Desc = "Transforma no Goner com skin e sons", Callback = function()
    if MorphTargetName ~= "" then EnviarBoard("goner", MorphTargetName) end
end })

print("✅ Imperium Admin carregado!")
print("📌 Minimize a janela para ver o botão flutuante 'Imperium'")

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://8486683243"
sound.Volume = 0.5
sound.PlayOnRemove = true
sound.Parent = Workspace
sound:Destroy()


-- se tirar meus creditos (Bazuka) eu derrubo seu script.
