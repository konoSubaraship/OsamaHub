local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local SUPPORTED_GAMES = {
    [4931927012] = {
        Name = "Basketball Legends",
        Endpoint = 'd62049409df7eca297245cefb99a3283',
    },
    [8307114974] = {
        Name = "Operation One",
        Endpoint = '62c4e7d75bddac509e3fbba41d3e8e89',
    },
    [6858589072] = {
        Name = "Five Nights Hunted",
        Endpoint = '9d7b925e68c61f75ae73fdb083ba33d1',
    },
    [8250618750] = {
        Name = "KAT",
        Endpoint = 'ad7fb6616d4cbf64ffbd7846cf84dc41',
    },
    [1489026993] = {
        Name = "Survive The Killers",
        Endpoint = 'b73bd82040490dfe5522b492a0607776',
    },
    [3104101863] = {
        Name = "Michaels Zombies",
        Endpoint = '47ecdb3d25b261d98b756097cfa700bf',
    },
    [323675642] = {
        Name = "Flood Escape 2",
        Endpoint = 'bc06e81fb14df87f2cc279747f0e0de2',
    },
    [8795154789] = {
        Name = "Flick",
        Endpoint = '3629878c0cc219a3c477babd5ee50621',
    },
    [2953945619] = {
        Name = "Friday Night Bloxxin",
        Endpoint = '5cf45864a627afdcdc11b11da2380daf',
    },
    [427040621] = {
        Name = "Friday Night Partying",
        Endpoint = '5cf45864a627afdcdc11b11da2380daf',
    },
    [964540701] = {
        Name = "Sound Space",
        Endpoint = '6692f33b6cfdfa6c8b734f906e301ef4',
    },
    [2802559498] = {
        Name = "Monday Morning Misery",
        Endpoint = '5cf45864a627afdcdc11b11da2380daf',
    },
    [115797356] = {
        Name = "Counter Blox",
        Endpoint = 'cacfba3476afec3c75335f57dc018fbb',
    },
    [73754455] = {
        Name = "Survive The Killers In Area 51",
        Endpoint = 'ce3d34bd2c936d10717835ce906f6638',
    },
    [372226183] = {
        Name = "Flee The Facility",
        Endpoint = 'b9399313a701685b8dbf2da315bafd66',
    },
}

local KEY_LINK = 'https://ads.luarmor.net/get_key?for=Osama_Hub_Key-tEeXFzZtlmaQ'
local DISCORD_CODE = 'GTJj2Q8R'
local KEY_LENGTH = 32

local Theme = {
    Background = Color3.fromRGB(12, 12, 14),
    BackgroundSecondary = Color3.fromRGB(18, 18, 21),
    BackgroundTertiary = Color3.fromRGB(24, 24, 28),
    Accent = Color3.fromRGB(140, 120, 200),
    AccentDark = Color3.fromRGB(100, 80, 160),
    TextPrimary = Color3.fromRGB(230, 230, 235),
    TextSecondary = Color3.fromRGB(150, 150, 155),
    TextDim = Color3.fromRGB(100, 100, 105),
    Border = Color3.fromRGB(40, 40, 45),
    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(230, 180, 60),
    Error = Color3.fromRGB(220, 80, 80),
}

local Loader = {
    Connections = {},
    GUI = nil,
    Destroyed = false,
}

local function Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Tween(instance, properties, duration)
    duration = duration or 0.2
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Loader.Connections, connection)
    return connection
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos

    Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    Connect(handle.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function DestroyLoader()
    if Loader.Destroyed then return end
    Loader.Destroyed = true
    
    for _, conn in ipairs(Loader.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    Loader.Connections = {}
    
    if Loader.GUI then
        pcall(function() Loader.GUI:Destroy() end)
        Loader.GUI = nil
    end
    
    task.wait(0.1)
end

local function PrepareForGameScript()
    if getgenv then
        getgenv().Toggles = {}
        getgenv().Options = {}
    end
    
    DestroyLoader()
    
    pcall(function()
        collectgarbage("collect")
    end)
    
    task.wait(0.2)
end

local function SafeHttpGet(url, retries)
    retries = retries or 3
    
    for i = 1, retries do
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success and result and result ~= "" then
            return true, result
        end
        
        if i < retries then
            task.wait(0.5)
        end
    end
    
    return false, "Failed to fetch"
end

local function LoadGameScript(endpoint, key)
    local success, scriptSource = SafeHttpGet('https://api.luarmor.net/files/v4/loaders/' .. endpoint .. '.lua')
    
    if not success then
        return false, scriptSource
    end
    
    local compileSuccess, compiled = pcall(loadstring, scriptSource)
    
    if not compileSuccess or not compiled then
        return false, "Failed to compile script"
    end
    
    script_key = key
    _G.script_key = key
    if getgenv then
        getgenv().script_key = key
    end
    
    PrepareForGameScript()
    
    local execSuccess, execError = pcall(compiled)
    
    if not execSuccess then
        return false, tostring(execError)
    end
    
    return true, nil
end

local function JoinDiscord()
    if not request then return false end
    
    pcall(function()
        request({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Origin"] = "https://discord.com"
            },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                args = { code = DISCORD_CODE },
                nonce = HttpService:GenerateGUID(false)
            }),
        })
    end)
    
    return true
end

local function CreateNotification(parent, title, message, notifType, duration)
    duration = duration or 3
    
    local typeColors = {
        Success = Theme.Success,
        Warning = Theme.Warning,
        Error = Theme.Error,
        Info = Theme.Accent,
    }
    
    local accentColor = typeColors[notifType] or Theme.Accent
    
    local notif = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = Theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 10, 1, -80),
        Size = UDim2.new(0, 250, 0, 70),
        AnchorPoint = Vector2.new(1, 1),
    })
    
    Create("UICorner", { Parent = notif, CornerRadius = UDim.new(0, 6) })
    Create("UIStroke", { Parent = notif, Color = Theme.Border, Thickness = 1 })
    
    local accentLine = Create("Frame", {
        Parent = notif,
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
    })
    Create("UICorner", { Parent = accentLine, CornerRadius = UDim.new(0, 6) })
    
    Create("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 10),
        Size = UDim2.new(1, -24, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    Create("TextLabel", {
        Parent = notif,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 32),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Theme.TextSecondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    })
    
    notif.Position = UDim2.new(1, 270, 1, -80)
    Tween(notif, { Position = UDim2.new(1, -10, 1, -80) }, 0.3)
    
    task.delay(duration, function()
        if notif and notif.Parent then
            Tween(notif, { Position = UDim2.new(1, 270, 1, -80) }, 0.3)
            task.wait(0.3)
            if notif and notif.Parent then
                notif:Destroy()
            end
        end
    end)
    
    return notif
end

local function CreateButton(parent, text, position, size, callback)
    local btn = Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = Theme.BackgroundTertiary,
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        AutoButtonColor = false,
    })
    
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })
    Create("UIStroke", { Parent = btn, Color = Theme.Border, Thickness = 1 })
    
    Connect(btn.MouseEnter, function()
        Tween(btn, { BackgroundColor3 = Theme.Accent }, 0.15)
    end)
    
    Connect(btn.MouseLeave, function()
        Tween(btn, { BackgroundColor3 = Theme.BackgroundTertiary }, 0.15)
    end)
    
    Connect(btn.MouseButton1Click, function()
        Tween(btn, { BackgroundColor3 = Theme.AccentDark }, 0.1)
        task.wait(0.1)
        Tween(btn, { BackgroundColor3 = Theme.Accent }, 0.1)
        if callback then callback() end
    end)
    
    return btn
end

local function CreateAccentButton(parent, text, position, size, callback)
    local btn = Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        AutoButtonColor = false,
    })
    
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 4) })
    Create("UIStroke", { Parent = btn, Color = Theme.AccentDark, Thickness = 1 })
    
    Connect(btn.MouseButton1Click, function()
        Tween(btn, { BackgroundColor3 = Theme.AccentDark }, 0.1)
        task.wait(0.1)
        Tween(btn, { BackgroundColor3 = Theme.Accent }, 0.1)
        if callback then callback() end
    end)
    
    return btn
end

local function CreateTextbox(parent, placeholder, position, size)
    local container = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = position,
        Size = size,
    })
    
    Create("UICorner", { Parent = container, CornerRadius = UDim.new(0, 4) })
    Create("UIStroke", { Parent = container, Color = Theme.Border, Thickness = 1 })
    
    local textbox = Create("TextBox", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.TextDim,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    })
    
    local stroke = container:FindFirstChildOfClass("UIStroke")
    
    Connect(textbox.Focused, function()
        Tween(stroke, { Color = Theme.Accent }, 0.15)
    end)
    
    Connect(textbox.FocusLost, function()
        Tween(stroke, { Color = Theme.Border }, 0.15)
    end)
    
    return textbox
end

local function CreateLoaderUI()
    local currentGameId = game.GameId
    local gameData = SUPPORTED_GAMES[currentGameId]
    local isSupported = gameData ~= nil
    local gameName = gameData and gameData.Name or "Unknown"
    
    if isSupported and script_key and script_key ~= '' and #script_key == KEY_LENGTH then
        local endpoint = gameData.Endpoint
        if endpoint and endpoint ~= '' then
            task.wait(0.5)
            LoadGameScript(endpoint, script_key)
            return
        end
    end
    
    if not isSupported then
        task.delay(3, function()
            LocalPlayer:Kick("Unsupported game. Join our Discord for game requests!")
        end)
        return
    end
    
    local existing = CoreGui:FindFirstChild("OsamaHubLoader")
    if existing then existing:Destroy() end
    
    local screenGui = Create("ScreenGui", {
        Name = "OsamaHubLoader",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })
    Loader.GUI = screenGui
    
    local main = Create("Frame", {
        Parent = screenGui,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 420, 0, 320),
        ClipsDescendants = true,
    })
    
    Create("UICorner", { Parent = main, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = main, Color = Theme.Border, Thickness = 1 })
    
    local topAccent = Create("Frame", {
        Parent = main,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 2),
    })
    
    Create("UIGradient", {
        Parent = topAccent,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 195, 255)),
        }),
        Rotation = 0,
    })
    
    local titleBar = Create("Frame", {
        Parent = main,
        BackgroundColor3 = Theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 2),
        Size = UDim2.new(1, 0, 0, 40),
    })
    
    Create("TextLabel", {
        Parent = titleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Osama Hub",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    Create("TextLabel", {
        Parent = titleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, -15, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "Loader",
        TextColor3 = Theme.TextDim,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    
    MakeDraggable(main, titleBar)
    
    Create("Frame", {
        Parent = main,
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 42),
        Size = UDim2.new(1, 0, 0, 1),
    })
    
    local content = Create("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 43),
        Size = UDim2.new(1, 0, 1, -43),
    })
    
    local leftSection = Create("Frame", {
        Parent = content,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 15),
        Size = UDim2.new(0.55, -20, 1, -30),
    })
    
    Create("TextLabel", {
        Parent = leftSection,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "Key System",
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    Create("TextLabel", {
        Parent = leftSection,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 28),
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "Game: " .. gameName,
        TextColor3 = Theme.Success,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local keyInput = CreateTextbox(
        leftSection,
        "Paste your key here...",
        UDim2.new(0, 0, 0, 55),
        UDim2.new(1, 0, 0, 32)
    )
    
    CreateButton(
        leftSection,
        "Get Key",
        UDim2.new(0, 0, 0, 100),
        UDim2.new(0.48, 0, 0, 30),
        function()
            if setclipboard then
                setclipboard(KEY_LINK)
                CreateNotification(screenGui, "Copied!", "Key link copied to clipboard", "Success", 3)
            else
                CreateNotification(screenGui, "Error", "Clipboard not available", "Error", 3)
            end
        end
    )
    
    CreateButton(
        leftSection,
        "Discord",
        UDim2.new(0.52, 0, 0, 100),
        UDim2.new(0.48, 0, 0, 30),
        function()
            JoinDiscord()
            CreateNotification(screenGui, "Discord", "Opening Discord invite...", "Info", 3)
        end
    )
    
    CreateAccentButton(
        leftSection,
        "Confirm Key",
        UDim2.new(0, 0, 0, 145),
        UDim2.new(1, 0, 0, 36),
        function()
            local key = keyInput.Text
            
            if not key or key == "" then
                CreateNotification(screenGui, "Error", "Please enter a key", "Warning", 3)
                return
            end
            
            key = key:gsub("^%s+", ""):gsub("%s+$", "")
            
            if #key ~= KEY_LENGTH then
                CreateNotification(screenGui, "Error", "Invalid key length (need " .. KEY_LENGTH .. " chars)", "Warning", 3)
                return
            end
            
            local endpoint = gameData.Endpoint
            
            if not endpoint or endpoint == "" then
                CreateNotification(screenGui, "Error", "Script not available for this game yet", "Warning", 3)
                return
            end
            
            CreateNotification(screenGui, "Loading", "Fetching script...", "Info", 2)
            
            task.wait(0.5)
            
            LoadGameScript(endpoint, key)
        end
    )
    
    local rightSection = Create("Frame", {
        Parent = content,
        BackgroundColor3 = Theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0.55, 5, 0, 15),
        Size = UDim2.new(0.45, -20, 1, -30),
    })
    
    Create("UICorner", { Parent = rightSection, CornerRadius = UDim.new(0, 6) })
    Create("UIStroke", { Parent = rightSection, Color = Theme.Border, Thickness = 1 })
    
    Create("TextLabel", {
        Parent = rightSection,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(1, -24, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "Information",
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    local infoText = string.format(
        "User: %s\nGame: %s\n\n• Get key from Discord\n• Paste and confirm\n• One key per user\n• Keys reset daily",
        LocalPlayer.Name,
        gameName
    )
    
    Create("TextLabel", {
        Parent = rightSection,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 35),
        Size = UDim2.new(1, -24, 1, -47),
        Font = Enum.Font.Gotham,
        Text = infoText,
        TextColor3 = Theme.TextSecondary,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    })
    
    main.Size = UDim2.new(0, 420, 0, 0)
    main.BackgroundTransparency = 1
    
    Tween(main, { Size = UDim2.new(0, 420, 0, 320), BackgroundTransparency = 0 }, 0.4)
    
    task.delay(0.5, function()
        if not Loader.Destroyed then
            CreateNotification(screenGui, "Osama Hub", "Game: " .. gameName, "Success", 4)
        end
    end)
end

local existingLoader = CoreGui:FindFirstChild("OsamaHubLoader")
if existingLoader then
    existingLoader:Destroy()
end

CreateLoaderUI()
