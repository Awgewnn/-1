--[[
============================================================
SAMBUNG KATA – PREMIUM DUAL GUI LIBRARY v25.1
============================================================
Designed for integration with the user's existing Sambung Kata
main script.

IMPORTANT:
- GUI UTAMA and PANEL KBBI are two independent ScreenGui objects.
- Minimizing GUI UTAMA does NOT hide PANEL KBBI.
- PANEL KBBI can remain visible, draggable and compact.
- The library does not own or replace the KBBI database.
- Feed real data from the main script through:
    UI:SetSoal(soal)
    UI:SetPrefix(prefix)
    UI:SetSuggestions(words)
    UI:SetDetectionStatus(text, isDetected)
- Existing state/functions from the main script can be connected
  through the optional callbacks in CONFIG.Callbacks.

Changelog v25.1:
- Added SetSuggestionsWithColors method for custom-colored buttons.
- Minor stability improvements.

Compatible with:
    local createGUIModule = loadstring(...)()
    local UI = createGUIModule(state, CONFIG, EMOJI_TO_LETTER)
============================================================
]]

local function createGUIModule(state, CONFIG, EMOJI_TO_LETTER)
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")

    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    CONFIG = CONFIG or {}
    state = state or {}

    local Callbacks = CONFIG.Callbacks or {}

    local COLORS = {
        BASE = Color3.fromRGB(13, 11, 26),
        DARKER = Color3.fromRGB(5, 3, 9),
        PANEL = Color3.fromRGB(26, 24, 37),
        PANEL_2 = Color3.fromRGB(31, 27, 48),
        PURPLE = Color3.fromRGB(140, 100, 220),
        PURPLE_BRIGHT = Color3.fromRGB(168, 120, 255),
        TEXT = Color3.fromRGB(255, 255, 255),
        MUTED = Color3.fromRGB(176, 176, 176),
        SUCCESS = Color3.fromRGB(76, 175, 80),
        WARNING = Color3.fromRGB(255, 152, 0),
        OFF = Color3.fromRGB(66, 66, 66),
    }

    local function safeCallback(name, ...)
        local fn = Callbacks[name]
        if type(fn) == "function" then
            pcall(fn, ...)
        end
    end

    local function corner(obj, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 10)
        c.Parent = obj
        return c
    end

    local function stroke(obj, color, thickness)
        local s = Instance.new("UIStroke")
        s.Color = color or COLORS.PURPLE
        s.Thickness = thickness or 1
        s.Transparency = 0.1
        s.Parent = obj
        return s
    end

    local function tween(obj, info, props)
        local ok, result = pcall(function()
            return TweenService:Create(obj, info, props)
        end)
        if ok and result then
            result:Play()
            return result
        end
    end

    local function makeButton(parent, name, text, size, position)
        local b = Instance.new("TextButton")
        b.Name = name
        b.Text = text
        b.TextColor3 = COLORS.TEXT
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.BackgroundColor3 = COLORS.PANEL
        b.BorderSizePixel = 0
        b.Size = size
        b.Position = position
        b.Parent = parent
        corner(b, 7)
        stroke(b, COLORS.PURPLE, 1)
        b.MouseEnter:Connect(function()
            tween(b, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.PANEL_2})
        end)
        b.MouseLeave:Connect(function()
            tween(b, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.PANEL})
        end)
        return b
    end

    local function makeDraggable(frame, handle)
        handle = handle or frame
        local dragging = false
        local dragStart
        local startPos
        local dragInput

        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end

            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end)
    end

    -- ========================================================
    -- CLEANUP OLD INSTANCES CREATED BY THIS LIBRARY
    -- ========================================================

    for _, name in ipairs({
        "SambungKataPremiumMain_v25",
        "SambungKataPremiumKBBI_v25"
    }) do
        local old1 = CoreGui:FindFirstChild(name)
        if old1 then old1:Destroy() end

        local old2 = PlayerGui:FindFirstChild(name)
        if old2 then old2:Destroy() end
    end

    -- ========================================================
    -- GUI UTAMA
    -- ========================================================

    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "SambungKataPremiumMain_v25"
    mainGui.IgnoreGuiInset = true
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mainGui.Parent = CoreGui

    local mainPanel = Instance.new("Frame")
    mainPanel.Name = "MainPanel"
    mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainPanel.Size = UDim2.new(0, 720, 0, 420)
    mainPanel.BackgroundColor3 = COLORS.BASE
    mainPanel.BorderSizePixel = 0
    mainPanel.ClipsDescendants = true
    mainPanel.Parent = mainGui
    corner(mainPanel, 14)
    stroke(mainPanel, COLORS.PURPLE, 1.5)

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 42)
    topBar.BackgroundColor3 = COLORS.DARKER
    topBar.BorderSizePixel = 0
    topBar.Parent = mainPanel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 16, 0, 0)
    title.Size = UDim2.new(0.6, 0, 1, 0)
    title.Text = "⚡ SAMBUNG KATA  •  PREMIUM LIBRARY"
    title.TextColor3 = COLORS.PURPLE_BRIGHT
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    local minimizeBtn = makeButton(
        topBar,
        "Minimize",
        "−",
        UDim2.new(0, 34, 0, 28),
        UDim2.new(1, -76, 0, 7)
    )

    local closeBtn = makeButton(
        topBar,
        "Close",
        "×",
        UDim2.new(0, 34, 0, 28),
        UDim2.new(1, -38, 0, 7)
    )

    -- Main content columns
    local left = Instance.new("Frame")
    left.Name = "Navigation"
    left.Size = UDim2.new(0, 150, 1, -52)
    left.Position = UDim2.new(0, 10, 0, 48)
    left.BackgroundColor3 = COLORS.DARKER
    left.BorderSizePixel = 0
    left.Parent = mainPanel
    corner(left, 10)
    stroke(left, COLORS.PURPLE, 1)

    local navTitle = Instance.new("TextLabel")
    navTitle.BackgroundTransparency = 1
    navTitle.Size = UDim2.new(1, -20, 0, 30)
    navTitle.Position = UDim2.new(0, 10, 0, 5)
    navTitle.Text = "LIBRARY"
    navTitle.TextColor3 = COLORS.PURPLE_BRIGHT
    navTitle.TextSize = 11
    navTitle.Font = Enum.Font.GothamBold
    navTitle.TextXAlignment = Enum.TextXAlignment.Left
    navTitle.Parent = left

    local navList = Instance.new("UIListLayout")
    navList.Padding = UDim.new(0, 5)
    navList.SortOrder = Enum.SortOrder.LayoutOrder
    navList.Parent = left

    local navPad = Instance.new("UIPadding")
    navPad.PaddingTop = UDim.new(0, 40)
    navPad.PaddingLeft = UDim.new(0, 8)
    navPad.PaddingRight = UDim.new(0, 8)
    navPad.Parent = left

    local navButtons = {}
    for _, item in ipairs({"Library", "Suggestions", "History", "Settings"}) do
        local b = makeButton(
            left,
            item,
            item,
            UDim2.new(1, 0, 0, 32),
            UDim2.new()
        )
        table.insert(navButtons, b)
    end

    local center = Instance.new("Frame")
    center.Name = "DetectionArea"
    center.Size = UDim2.new(1, -390, 1, -52)
    center.Position = UDim2.new(0, 170, 0, 48)
    center.BackgroundColor3 = COLORS.PANEL
    center.BorderSizePixel = 0
    center.Parent = mainPanel
    corner(center, 10)
    stroke(center, COLORS.PURPLE, 1)

    local detectionTitle = Instance.new("TextLabel")
    detectionTitle.BackgroundTransparency = 1
    detectionTitle.Position = UDim2.new(0, 16, 0, 12)
    detectionTitle.Size = UDim2.new(1, -32, 0, 24)
    detectionTitle.Text = "DETEKSI SOAL"
    detectionTitle.TextColor3 = COLORS.PURPLE_BRIGHT
    detectionTitle.TextSize = 13
    detectionTitle.Font = Enum.Font.GothamBold
    detectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    detectionTitle.Parent = center

    local detectionSubtitle = Instance.new("TextLabel")
    detectionSubtitle.BackgroundTransparency = 1
    detectionSubtitle.Position = UDim2.new(0, 16, 0, 37)
    detectionSubtitle.Size = UDim2.new(1, -32, 0, 18)
    detectionSubtitle.Text = "Area Deteksi Awalan Kata / Soal"
    detectionSubtitle.TextColor3 = COLORS.MUTED
    detectionSubtitle.TextSize = 10
    detectionSubtitle.Font = Enum.Font.Gotham
    detectionSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    detectionSubtitle.Parent = center

    local soalDisplay = Instance.new("TextLabel")
    soalDisplay.Name = "SoalDisplay"
    soalDisplay.BackgroundTransparency = 1
    soalDisplay.Position = UDim2.new(0, 18, 0, 78)
    soalDisplay.Size = UDim2.new(1, -36, 0, 85)
    soalDisplay.Text = "Menunggu soal..."
    soalDisplay.TextColor3 = COLORS.TEXT
    soalDisplay.TextSize = 26
    soalDisplay.Font = Enum.Font.GothamBold
    soalDisplay.TextWrapped = true
    soalDisplay.Parent = center

    local prefixDisplay = Instance.new("TextLabel")
    prefixDisplay.Name = "PrefixDisplay"
    prefixDisplay.BackgroundColor3 = COLORS.DARKER
    prefixDisplay.Position = UDim2.new(0, 18, 0, 175)
    prefixDisplay.Size = UDim2.new(1, -36, 0, 42)
    prefixDisplay.Text = "AWALAN: —"
    prefixDisplay.TextColor3 = COLORS.PURPLE_BRIGHT
    prefixDisplay.TextSize = 16
    prefixDisplay.Font = Enum.Font.GothamBold
    prefixDisplay.Parent = center
    corner(prefixDisplay, 7)

    local statusDisplay = Instance.new("TextLabel")
    statusDisplay.Name = "DetectionStatus"
    statusDisplay.BackgroundTransparency = 1
    statusDisplay.Position = UDim2.new(0, 18, 0, 225)
    statusDisplay.Size = UDim2.new(1, -36, 0, 22)
    statusDisplay.Text = "● MENUNGGU DETEKSI"
    statusDisplay.TextColor3 = COLORS.MUTED
    statusDisplay.TextSize = 11
    statusDisplay.Font = Enum.Font.GothamBold
    statusDisplay.Parent = center

    local kbbiToggle = makeButton(
        center,
        "KBBIToggle",
        "📖 SARAN KBBI  •  OFF",
        UDim2.new(1, -36, 0, 38),
        UDim2.new(0, 18, 1, -52)
    )

    local right = Instance.new("Frame")
    right.Name = "Controls"
    right.Size = UDim2.new(0, 200, 1, -52)
    right.Position = UDim2.new(1, -210, 0, 48)
    right.BackgroundColor3 = COLORS.DARKER
    right.BorderSizePixel = 0
    right.Parent = mainPanel
    corner(right, 10)
    stroke(right, COLORS.PURPLE, 1)

    local controlsTitle = Instance.new("TextLabel")
    controlsTitle.BackgroundTransparency = 1
    controlsTitle.Position = UDim2.new(0, 12, 0, 10)
    controlsTitle.Size = UDim2.new(1, -24, 0, 24)
    controlsTitle.Text = "PANEL KONTROL"
    controlsTitle.TextColor3 = COLORS.PURPLE_BRIGHT
    controlsTitle.TextSize = 11
    controlsTitle.Font = Enum.Font.GothamBold
    controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
    controlsTitle.Parent = right

    local btnExecute = makeButton(right, "Execute", "▶ Execute", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 45))
    local btnClear = makeButton(right, "Clear", "🗑 Clear", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 84))
    local btnCopy = makeButton(right, "Copy", "📋 Copy", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 123))

    local autoDetectBtn = makeButton(right, "AutoDetect", "Auto Detect  •  OFF", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 175))
    local autoExecBtn = makeButton(right, "AutoExecute", "Auto Execute  •  OFF", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 214))
    local soundBtn = makeButton(right, "SoundAlert", "Sound Alert  •  OFF", UDim2.new(1, -24, 0, 32), UDim2.new(0, 12, 0, 253))

    -- ========================================================
    -- GUI KBBI TERPISAH
    -- ========================================================

    local kbbiGui = Instance.new("ScreenGui")
    kbbiGui.Name = "SambungKataPremiumKBBI_v25"
    kbbiGui.IgnoreGuiInset = true
    kbbiGui.ResetOnSpawn = false
    kbbiGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    kbbiGui.Parent = CoreGui

    local kbbiPanel = Instance.new("Frame")
    kbbiPanel.Name = "KBBIPanel"
    kbbiPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    kbbiPanel.Position = UDim2.new(0.78, 0, 0.70, 0)
    kbbiPanel.Size = UDim2.new(0, 300, 0, 220)
    kbbiPanel.BackgroundColor3 = COLORS.PANEL
    kbbiPanel.BorderSizePixel = 0
    kbbiPanel.Visible = false
    kbbiPanel.ClipsDescendants = true
    kbbiPanel.Parent = kbbiGui
    corner(kbbiPanel, 12)
    stroke(kbbiPanel, COLORS.PURPLE, 1.5)

    local kbbiHeader = Instance.new("Frame")
    kbbiHeader.Size = UDim2.new(1, 0, 0, 38)
    kbbiHeader.BackgroundColor3 = COLORS.DARKER
    kbbiHeader.BorderSizePixel = 0
    kbbiHeader.Parent = kbbiPanel

    local kbbiTitle = Instance.new("TextLabel")
    kbbiTitle.BackgroundTransparency = 1
    kbbiTitle.Position = UDim2.new(0, 12, 0, 0)
    kbbiTitle.Size = UDim2.new(1, -95, 1, 0)
    kbbiTitle.Text = "📖 SARAN KATA  •  KBBI"
    kbbiTitle.TextColor3 = COLORS.PURPLE_BRIGHT
    kbbiTitle.TextSize = 11
    kbbiTitle.Font = Enum.Font.GothamBold
    kbbiTitle.TextXAlignment = Enum.TextXAlignment.Left
    kbbiTitle.Parent = kbbiHeader

    local kbbiMinBtn = makeButton(kbbiHeader, "Collapse", "−", UDim2.new(0, 28, 0, 26), UDim2.new(1, -65, 0, 6))
    local kbbiCloseBtn = makeButton(kbbiHeader, "Close", "×", UDim2.new(0, 28, 0, 26), UDim2.new(1, -33, 0, 6))

    local kbbiPrefix = Instance.new("TextLabel")
    kbbiPrefix.BackgroundTransparency = 1
    kbbiPrefix.Position = UDim2.new(0, 12, 0, 45)
    kbbiPrefix.Size = UDim2.new(1, -24, 0, 24)
    kbbiPrefix.Text = "Awalan: —"
    kbbiPrefix.TextColor3 = COLORS.TEXT
    kbbiPrefix.TextSize = 12
    kbbiPrefix.Font = Enum.Font.GothamBold
    kbbiPrefix.TextXAlignment = Enum.TextXAlignment.Left
    kbbiPrefix.Parent = kbbiPanel

    local suggestionScroll = Instance.new("ScrollingFrame")
    suggestionScroll.Name = "Suggestions"
    suggestionScroll.Position = UDim2.new(0, 10, 0, 76)
    suggestionScroll.Size = UDim2.new(1, -20, 1, -86)
    suggestionScroll.BackgroundColor3 = COLORS.BASE
    suggestionScroll.BorderSizePixel = 0
    suggestionScroll.ScrollBarThickness = 3
    suggestionScroll.ScrollBarImageColor3 = COLORS.PURPLE
    suggestionScroll.CanvasSize = UDim2.new()
    suggestionScroll.Parent = kbbiPanel
    corner(suggestionScroll, 7)

    local suggestionContainer = Instance.new("Frame")
    suggestionContainer.BackgroundTransparency = 1
    suggestionContainer.Size = UDim2.new(1, 0, 0, 0)
    suggestionContainer.Parent = suggestionScroll

    local grid = Instance.new("UIGridLayout")
    grid.CellPadding = UDim2.new(0, 6, 0, 6)
    grid.CellSize = UDim2.new(0.5, -9, 0, 32)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = suggestionContainer

    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        suggestionContainer.Size = UDim2.new(1, 0, 0, grid.AbsoluteContentSize.Y + 8)
        suggestionScroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 12)
    end)

    makeDraggable(kbbiPanel, kbbiHeader)
    makeDraggable(mainPanel, topBar)

    -- ========================================================
    -- MINIMIZE / RESTORE
    -- ========================================================

    local mainMinimized = false
    local kbbiCollapsed = false
    local kbbiEnabled = false
    local savedMainPosition = mainPanel.Position

    local restoreButton = makeButton(
        mainGui,
        "RestoreMain",
        "⚡",
        UDim2.new(0, 48, 0, 42),
        UDim2.new(0, 18, 1, -60)
    )
    restoreButton.Visible = false

    local function minimizeMain()
        if mainMinimized then return end
        savedMainPosition = mainPanel.Position
        mainMinimized = true

        tween(mainPanel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })

        task.delay(0.23, function()
            if mainMinimized then
                mainPanel.Visible = false
                restoreButton.Visible = true
            end
        end)

        safeCallback("OnMainMinimized")
    end

    local function restoreMain()
        if not mainMinimized then return end
        mainMinimized = false
        restoreButton.Visible = false
        mainPanel.Visible = true
        mainPanel.Size = UDim2.new(0, 0, 0, 0)

        tween(mainPanel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 720, 0, 420)
        })

        safeCallback("OnMainRestored")
    end

    minimizeBtn.Activated:Connect(minimizeMain)
    restoreButton.Activated:Connect(restoreMain)

    closeBtn.Activated:Connect(function()
        mainPanel.Visible = false
        restoreButton.Visible = true
        mainMinimized = true
        safeCallback("OnMainClosed")
    end)

    -- ========================================================
    -- KBBI PANEL CONTROL
    -- ========================================================

    local function setKBBIVisible(visible)
        kbbiEnabled = visible
        kbbiPanel.Visible = visible

        if visible then
            kbbiToggle.Text = "📖 SARAN KBBI  •  ON"
            kbbiToggle.BackgroundColor3 = Color3.fromRGB(55, 42, 82)
        else
            kbbiToggle.Text = "📖 SARAN KBBI  •  OFF"
            kbbiToggle.BackgroundColor3 = COLORS.PANEL
        end

        safeCallback("OnKBBIToggleChanged", visible)
    end

    kbbiToggle.Activated:Connect(function()
        setKBBIVisible(not kbbiEnabled)
    end)

    kbbiCloseBtn.Activated:Connect(function()
        kbbiPanel.Visible = false
        safeCallback("OnKBBIClosed")
    end)

    kbbiMinBtn.Activated:Connect(function()
        kbbiCollapsed = not kbbiCollapsed

        if kbbiCollapsed then
            kbbiPanel.Size = UDim2.new(0, 300, 0, 38)
            kbbiMinBtn.Text = "+"
        else
            kbbiPanel.Size = UDim2.new(0, 300, 0, 220)
            kbbiMinBtn.Text = "−"
        end
    end)

    -- ========================================================
    -- DATA UPDATE API
    -- ========================================================

    local function clearSuggestions()
        for _, child in ipairs(suggestionContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end

    local function addSuggestion(word, index)
        if type(word) ~= "string" or word == "" then return end

        local button = Instance.new("TextButton")
        button.Name = "Suggestion_" .. tostring(index or word)
        button.Text = word
        button.TextColor3 = COLORS.TEXT
        button.TextSize = 10
        button.Font = Enum.Font.GothamBold
        button.BackgroundColor3 = COLORS.PANEL_2
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.LayoutOrder = index or 0
        button.Parent = suggestionContainer
        corner(button, 6)
        stroke(button, COLORS.PURPLE, 0.8)

        button.Activated:Connect(function()
            safeCallback("OnSuggestionClicked", word)
        end)

        return button  -- dikembalikan untuk modifikasi warna
    end

    local function setSuggestions(words)
        clearSuggestions()

        if type(words) ~= "table" then
            return
        end

        local count = 0
        for _, word in ipairs(words) do
            if type(word) == "string" and word ~= "" then
                count = count + 1
                addSuggestion(word, count)
            end
        end

        safeCallback("OnSuggestionsUpdated", words)
    end

    -- Metode baru: SetSuggestionsWithColors (tabel warna opsional)
    local function setSuggestionsWithColors(words, colorMap)
        clearSuggestions()
        if type(words) ~= "table" then return end
        local count = 0
        for _, word in ipairs(words) do
            if type(word) == "string" and word ~= "" then
                count = count + 1
                local btn = addSuggestion(word, count)
                if colorMap and colorMap[word] then
                    btn.BackgroundColor3 = colorMap[word]
                end
            end
        end
        safeCallback("OnSuggestionsUpdated", words)
    end

    local function setSoal(soal)
        soal = tostring(soal or "")
        if soal == "" then
            soalDisplay.Text = "Menunggu soal..."
        else
            soalDisplay.Text = soal
        end
        safeCallback("OnSoalChanged", soal)
    end

    local function setPrefix(prefix)
        prefix = tostring(prefix or "")
        if prefix == "" then
            prefixDisplay.Text = "AWALAN: —"
            kbbiPrefix.Text = "Awalan: —"
        else
            local upper = string.upper(prefix)
            prefixDisplay.Text = "AWALAN: " .. upper
            kbbiPrefix.Text = "Awalan: " .. upper
        end
        safeCallback("OnPrefixChanged", prefix)
    end

    local function setDetectionStatus(text, detected)
        text = tostring(text or "MENUNGGU DETEKSI")
        statusDisplay.Text = "● " .. text
        statusDisplay.TextColor3 = detected and COLORS.SUCCESS or COLORS.MUTED
    end

    -- ========================================================
    -- CONTROL BUTTON CALLBACKS
    -- ========================================================

    btnExecute.Activated:Connect(function()
        safeCallback("OnExecute")
    end)

    btnClear.Activated:Connect(function()
        safeCallback("OnClear")
    end)

    btnCopy.Activated:Connect(function()
        safeCallback("OnCopy")
    end)

    local toggles = {
        AutoDetect = false,
        AutoExecute = false,
        SoundAlert = false,
    }

    local function toggle(name, button, label)
        toggles[name] = not toggles[name]
        button.Text = label .. "  •  " .. (toggles[name] and "ON" or "OFF")
        button.BackgroundColor3 = toggles[name] and Color3.fromRGB(55, 42, 82) or COLORS.PANEL
        safeCallback("OnToggleChanged", name, toggles[name])
    end

    autoDetectBtn.Activated:Connect(function()
        toggle("AutoDetect", autoDetectBtn, "Auto Detect")
    end)

    autoExecBtn.Activated:Connect(function()
        toggle("AutoExecute", autoExecBtn, "Auto Execute")
    end)

    soundBtn.Activated:Connect(function()
        toggle("SoundAlert", soundBtn, "Sound Alert")
    end)

    -- ========================================================
    -- PUBLIC API
    -- ========================================================

    local API = {
        MainGui = mainGui,
        MainPanel = mainPanel,

        KBBIGui = kbbiGui,
        KBBIPanel = kbbiPanel,

        DetectionPanel = center,
        SoalDisplay = soalDisplay,
        PrefixDisplay = prefixDisplay,
        DetectionStatus = statusDisplay,

        SuggestionContainer = suggestionContainer,
        SuggestionScroll = suggestionScroll,

        BtnExecute = btnExecute,
        BtnClear = btnClear,
        BtnCopy = btnCopy,

        SetSoal = setSoal,
        SetPrefix = setPrefix,
        SetDetectionStatus = setDetectionStatus,
        SetSuggestions = setSuggestions,
        SetSuggestionsWithColors = setSuggestionsWithColors,
        AddSuggestion = addSuggestion,
        ClearSuggestions = clearSuggestions,

        ShowKBBI = function()
            setKBBIVisible(true)
        end,

        HideKBBI = function()
            setKBBIVisible(false)
        end,

        ToggleKBBI = function()
            setKBBIVisible(not kbbiEnabled)
        end,

        IsKBBIVisible = function()
            return kbbiPanel.Visible
        end,

        MinimizeMain = minimizeMain,
        RestoreMain = restoreMain,

        IsMainMinimized = function()
            return mainMinimized
        end,

        GetToggleState = function(name)
            return toggles[name] == true
        end,

        SetToggleState = function(name, value)
            value = value == true
            toggles[name] = value

            local button, label
            if name == "AutoDetect" then
                button, label = autoDetectBtn, "Auto Detect"
            elseif name == "AutoExecute" then
                button, label = autoExecBtn, "Auto Execute"
            elseif name == "SoundAlert" then
                button, label = soundBtn, "Sound Alert"
            end

            if button then
                button.Text = label .. "  •  " .. (value and "ON" or "OFF")
                button.BackgroundColor3 = value and Color3.fromRGB(55, 42, 82) or COLORS.PANEL
            end
        end,

        Destroy = function()
            if mainGui then mainGui:Destroy() end
            if kbbiGui then kbbiGui:Destroy() end
        end,
    }

    -- ========================================================
    -- INITIAL DATA
    -- ========================================================

    if state.lastSoal then
        setSoal(state.lastSoal)
    end

    if state.lastPrefix then
        setPrefix(state.lastPrefix)
    end

    if state.showSaran == true then
        setKBBIVisible(true)
    end

    return API
end

return createGUIModule