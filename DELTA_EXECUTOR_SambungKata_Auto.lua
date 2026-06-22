-- ============================================
-- SAMBUNG KATA - AUTO MODE (DELTA EXECUTOR)
-- File Lengkap - Inject ke Delta Executor
-- ============================================

print("🚀 Loading Sambung Kata Auto Mode...")

-- ============================================
-- PART 1: WORD VALIDATOR MODULE
-- ============================================

local WordValidator = {}
WordValidator.__index = WordValidator

local kbbiWords = {}
local isLoaded = false

function WordValidator.new()
    local self = setmetatable({}, WordValidator)
    return self
end

function WordValidator:LoadKBBIDatabase()
    print("🌐 Loading KBBI database dari GitHub...")
    local HttpService = game:GetService("HttpService")
    
    local url = "https://raw.githubusercontent.com/aryakdaniswara/kbbi-v6-wordlist/main/all_entries_v6.1.0.txt"
    
    local success, response = pcall(function()
        return HttpService:GetAsync(url)
    end)
    
    if not success then
        error("❌ Gagal load database KBBI: " .. tostring(response))
    end
    
    local lineNum = 0
    for line in response:gmatch("[^\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            kbbiWords[string.upper(line)] = true
            lineNum = lineNum + 1
        end
    end
    
    isLoaded = true
    print("✅ Database KBBI dimuat! Total kata: " .. lineNum)
    return true
end

function WordValidator:IsWordValid(word)
    if not isLoaded then
        error("Database KBBI belum di-load!")
    end
    
    word = string.upper(word):gsub("^%s+", ""):gsub("%s+$", "")
    return kbbiWords[word] ~= nil
end

function WordValidator:GetFirstAndLastLetter(word)
    word = string.upper(word)
    if #word == 0 then
        return nil, nil
    end
    
    local firstLetter = string.sub(word, 1, 1)
    local lastLetter = string.sub(word, -1)
    return firstLetter, lastLetter
end

function WordValidator:ValidatePrefixSuffix(prefix, suffix)
    if not isLoaded then
        return false, "Database KBBI belum di-load!"
    end
    
    prefix = string.upper(prefix):gsub("^%s+", ""):gsub("%s+$", "")
    suffix = string.upper(suffix):gsub("^%s+", ""):gsub("%s+$", "")
    
    if suffix == "" then
        return false, "Suffix tidak boleh kosong!"
    end
    
    local fullWord = prefix .. suffix
    
    if not self:IsWordValid(fullWord) then
        return false, "❌ Kata '" .. fullWord .. "' tidak ada di KBBI!"
    end
    
    return true, fullWord
end

function WordValidator:GetSuggestedWords(prefix, limit)
    if not isLoaded then
        error("Database KBBI belum di-load!")
    end
    
    prefix = string.upper(prefix):gsub("^%s+", ""):gsub("%s+$", "")
    local suggestions = {}
    
    for word, _ in pairs(kbbiWords) do
        if string.sub(word, 1, #prefix) == prefix then
            table.insert(suggestions, word)
            if #suggestions >= (limit or 10) then
                break
            end
        end
    end
    
    return suggestions
end

function WordValidator:GenerateRandomPrefix(lastLetter)
    local prefixLengths = {1, 2, 3, 4, 5}
    local length = prefixLengths[math.random(1, #prefixLengths)]
    
    local prefix = ""
    
    if lastLetter then
        prefix = lastLetter
        length = length - 1
    end
    
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for i = 1, length do
        prefix = prefix .. string.sub(letters, math.random(1, #letters), math.random(1, #letters))
    end
    
    return prefix
end

-- ============================================
-- PART 2: GAME LOGIC MODULE
-- ============================================

local GameLogic = {}
GameLogic.__index = GameLogic

function GameLogic.new()
    local self = setmetatable({}, GameLogic)
    self.currentPrefix = ""
    self.lastWord = ""
    self.lastLetter = ""
    self.players = {}
    self.currentPlayerIndex = 1
    self.scores = {}
    self.totalRounds = 0
    self.gameActive = true
    return self
end

function GameLogic:Initialize(playerList)
    self.players = playerList
    self.currentPlayerIndex = 1
    self.totalRounds = 0
    self.gameActive = true
    
    for i, player in ipairs(playerList) do
        self.scores[player.UserId] = 0
    end
    
    print("🎮 Game initialized dengan " .. #playerList .. " pemain")
end

function GameLogic:ProcessPlayerInput(suffix, wordValidator)
    if not self.gameActive then
        return false, "Game sudah berakhir!"
    end
    
    local prefix = self.currentPrefix
    local isValid, resultOrError = wordValidator:ValidatePrefixSuffix(prefix, suffix)
    
    if not isValid then
        return false, resultOrError
    end
    
    local fullWord = resultOrError
    self.lastWord = fullWord
    
    local firstLetter, lastLetter = wordValidator:GetFirstAndLastLetter(fullWord)
    self.lastLetter = lastLetter
    
    local currentPlayer = self.players[self.currentPlayerIndex]
    self.scores[currentPlayer.UserId] = self.scores[currentPlayer.UserId] + #fullWord
    
    local newPrefix = wordValidator:GenerateRandomPrefix(lastLetter)
    self.currentPrefix = newPrefix
    
    self.currentPlayerIndex = self.currentPlayerIndex + 1
    if self.currentPlayerIndex > #self.players then
        self.currentPlayerIndex = 1
    end
    
    self.totalRounds = self.totalRounds + 1
    
    return true, {
        fullWord = fullWord,
        lastLetter = lastLetter,
        newPrefix = newPrefix,
        nextPlayer = self.players[self.currentPlayerIndex].Name,
        score = self.scores[currentPlayer.UserId]
    }
end

function GameLogic:GetGameState()
    return {
        prefix = self.currentPrefix,
        lastWord = self.lastWord,
        lastLetter = self.lastLetter,
        currentPlayer = self.players[self.currentPlayerIndex] and self.players[self.currentPlayerIndex].Name or "N/A",
        scores = self.scores,
        totalRounds = self.totalRounds,
        gameActive = self.gameActive
    }
end

function GameLogic:GetNextPlayer()
    return self.players[self.currentPlayerIndex]
end

function GameLogic:EndGame()
    self.gameActive = false
    
    local maxScore = 0
    local winner = nil
    
    for userId, score in pairs(self.scores) do
        if score > maxScore then
            maxScore = score
            winner = userId
        end
    end
    
    return {
        winner = winner,
        finalScores = self.scores,
        totalRounds = self.totalRounds
    }
end

-- ============================================
-- PART 3: MAIN GAME SERVER
-- ============================================

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "SambungKataEvent"
RemoteEvent.Parent = game.ReplicatedStorage

local RemoteFunction = Instance.new("RemoteFunction")
RemoteFunction.Name = "SambungKataFunction"
RemoteFunction.Parent = game.ReplicatedStorage

local wordValidator = WordValidator.new()
local gameLogic = GameLogic.new()

print("⏳ Initializing Sambung Kata game...")
wordValidator:LoadKBBIDatabase()

wait(2)

local players = game:GetService("Players"):GetPlayers()
if #players == 0 then
    print("⚠️ Tidak ada pemain!")
    return
end

gameLogic:Initialize(players)
local startPrefix = wordValidator:GenerateRandomPrefix()
gameLogic.currentPrefix = startPrefix

print("🎮 Game dimulai!")
print("Prefix pertama: " .. startPrefix)
print("Pemain pertama: " .. gameLogic:GetNextPlayer().Name)

RemoteEvent:FireAllClients("GameStarted", {
    prefix = startPrefix,
    firstPlayer = gameLogic:GetNextPlayer().Name
})

RemoteFunction.OnServerInvoke = function(player, action, data)
    if action == "SubmitWord" then
        local suffix = data.suffix
        
        local currentPlayer = gameLogic:GetNextPlayer()
        if currentPlayer.UserId ~= player.UserId then
            return false, "❌ Bukan giliran Anda!"
        end
        
        local isValid, result = gameLogic:ProcessPlayerInput(suffix, wordValidator)
        
        if not isValid then
            RemoteEvent:FireAllClients("WordInvalid", {
                player = player.Name,
                error = result
            })
            return false, result
        else
            RemoteEvent:FireAllClients("WordValid", {
                player = player.Name,
                fullWord = result.fullWord,
                score = result.score,
                newPrefix = result.newPrefix,
                nextPlayer = result.nextPlayer
            })
            return true, result
        end
    end
    
    if action == "GetGameState" then
        return gameLogic:GetGameState()
    end
    
    if action == "GetSuggestedWords" then
        local suggestions = wordValidator:GetSuggestedWords(data.prefix, 50)
        return suggestions
    end
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
    print(player.Name .. " meninggalkan game")
end)

print("✅ Game server siap!")

-- ============================================
-- PART 4: CLIENT UI & AUTO PLAYER
-- ============================================

local UserInputService = game:GetService("UserInputService")

local isMyTurn = false
local currentPrefix = ""
local gameActive = false
local autoModeEnabled = true
local typingSpeed = 0.05

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SambungKataUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.08, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 28
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "🎮 SAMBUNG KATA - AUTO MODE"
titleLabel.Parent = screenGui

-- Prefix display
local prefixLabel = Instance.new("TextLabel")
prefixLabel.Name = "PrefixLabel"
prefixLabel.Size = UDim2.new(0.35, 0, 0.12, 0)
prefixLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
prefixLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
prefixLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
prefixLabel.TextSize = 22
prefixLabel.Font = Enum.Font.GothamBold
prefixLabel.Text = "PREFIX: --"
prefixLabel.Parent = screenGui

-- Current player display
local playerLabel = Instance.new("TextLabel")
playerLabel.Name = "PlayerLabel"
playerLabel.Size = UDim2.new(0.35, 0, 0.12, 0)
playerLabel.Position = UDim2.new(0.6, 0, 0.12, 0)
playerLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
playerLabel.TextSize = 18
playerLabel.Font = Enum.Font.Gotham
playerLabel.Text = "GILIRAN: --"
playerLabel.Parent = screenGui

-- Last word display
local lastWordLabel = Instance.new("TextLabel")
lastWordLabel.Name = "LastWordLabel"
lastWordLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
lastWordLabel.Position = UDim2.new(0.05, 0, 0.28, 0)
lastWordLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
lastWordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
lastWordLabel.TextSize = 18
lastWordLabel.Font = Enum.Font.Gotham
lastWordLabel.Text = "KATA TERAKHIR: --"
lastWordLabel.Parent = screenGui

-- Typing display
local typingLabel = Instance.new("TextLabel")
typingLabel.Name = "TypingLabel"
typingLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
typingLabel.Position = UDim2.new(0.05, 0, 0.42, 0)
typingLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
typingLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
typingLabel.TextSize = 20
typingLabel.Font = Enum.Font.GothamMonospace
typingLabel.Text = "PREFIX: [sedang mengetik...]"
typingLabel.TextWrapped = true
typingLabel.Visible = false
typingLabel.Parent = screenGui

-- Score display
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
scoreLabel.Position = UDim2.new(0.05, 0, 0.58, 0)
scoreLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scoreLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
scoreLabel.TextSize = 16
scoreLabel.Font = Enum.Font.Gotham
scoreLabel.Text = "SCORE: 0"
scoreLabel.TextWrapped = true
scoreLabel.Parent = screenGui

-- Speed label
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
speedLabel.Position = UDim2.new(0.05, 0, 0.74, 0)
speedLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.Gotham
speedLabel.Text = "SPEED: 0.05s"
speedLabel.Parent = screenGui

-- Auto mode toggle
local autoToggle = Instance.new("TextButton")
autoToggle.Name = "AutoToggle"
autoToggle.Size = UDim2.new(0.2, 0, 0.08, 0)
autoToggle.Position = UDim2.new(0.75, 0, 0.74, 0)
autoToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
autoToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoToggle.TextSize = 14
autoToggle.Font = Enum.Font.GothamBold
autoToggle.Text = "AUTO: ON"
autoToggle.Parent = screenGui

-- Message display
local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
messageLabel.Position = UDim2.new(0.05, 0, 0.86, 0)
messageLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextSize = 16
messageLabel.Font = Enum.Font.Gotham
messageLabel.Text = "⏳ Menunggu game dimulai..."
messageLabel.TextWrapped = true
messageLabel.Parent = screenGui

-- Listen untuk events dari server
RemoteEvent.OnClientEvent:Connect(function(eventType, data)
    print("📨 Event: " .. eventType)
    
    if eventType == "GameStarted" then
        gameActive = true
        currentPrefix = data.prefix
        prefixLabel.Text = "PREFIX: " .. currentPrefix
        playerLabel.Text = "GILIRAN: " .. data.firstPlayer
        messageLabel.Text = "🎮 Game dimulai!"
        messageLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        wait(1)
        if autoModeEnabled and data.firstPlayer == game.Players.LocalPlayer.Name then
            autoPlay(currentPrefix)
        end
        
    elseif eventType == "WordValid" then
        lastWordLabel.Text = "KATA TERAKHIR: " .. data.fullWord .. " (+" .. data.score .. " poin)"
        prefixLabel.Text = "PREFIX: " .. data.newPrefix
        playerLabel.Text = "GILIRAN: " .. data.nextPlayer
        messageLabel.Text = "✅ BENAR! Kata: " .. data.fullWord
        messageLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        typingLabel.Visible = false
        
        updateScores()
        
        if autoModeEnabled and data.nextPlayer == game.Players.LocalPlayer.Name then
            wait(2)
            autoPlay(data.newPrefix)
        end
        
    elseif eventType == "WordInvalid" then
        messageLabel.Text = data.error
        messageLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        typingLabel.Visible = false
    end
end)

-- Auto play function
function autoPlay(prefix)
    messageLabel.Text = "⏳ Thinking... 🤔"
    messageLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
    
    wait(1)
    
    local suggestions = RemoteFunction:InvokeServer("GetSuggestedWords", {
        prefix = prefix
    })
    
    if not suggestions or #suggestions == 0 then
        messageLabel.Text = "❌ Tidak ada kata yang bisa disambung!"
        return
    end
    
    local fullWord = suggestions[math.random(1, #suggestions)]
    local suffix = string.sub(fullWord, #prefix + 1)
    
    typingLabel.Visible = true
    typingLabel.Text = "PREFIX: " .. prefix .. " + SUFFIX: [sedang mengetik...]"
    
    wait(math.random(50, 300) / 1000)
    
    local typedText = ""
    for i = 1, #suffix do
        typedText = typedText .. string.sub(suffix, i, i)
        typingLabel.Text = "PREFIX: " .. prefix .. " + SUFFIX: " .. typedText
        
        local variation = (math.random(-20, 20) / 100)
        local charDelay = typingSpeed * (1 + variation)
        wait(charDelay)
    end
    
    wait(0.5)
    
    messageLabel.Text = "📤 Submitting: " .. fullWord
    messageLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local success, result = RemoteFunction:InvokeServer("SubmitWord", {
        suffix = suffix,
        prefix = prefix
    })
    
    typingLabel.Visible = false
end

-- Update scores function
function updateScores()
    local gameState = RemoteFunction:InvokeServer("GetGameState")
    local scoreText = "SCORE: "
    
    for userId, score in pairs(gameState.scores) do
        scoreText = scoreText .. score .. " | "
    end
    
    scoreLabel.Text = scoreText
end

-- Toggle auto mode
autoToggle.MouseButton1Click:Connect(function()
    autoModeEnabled = not autoModeEnabled
    
    if autoModeEnabled then
        autoToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        autoToggle.Text = "AUTO: ON"
        messageLabel.Text = "✅ Auto mode: ENABLED"
    else
        autoToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        autoToggle.Text = "AUTO: OFF"
        messageLabel.Text = "❌ Auto mode: DISABLED"
    end
    
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

-- Keyboard input untuk speed control
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Up then
        typingSpeed = math.min(0.2, typingSpeed + 0.01)
        speedLabel.Text = "SPEED: " .. string.format("%.2f", typingSpeed) .. "s"
        messageLabel.Text = "⚙️ Typing speed: " .. string.format("%.2f", typingSpeed) .. "s/char"
        messageLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        
    elseif input.KeyCode == Enum.KeyCode.Down then
        typingSpeed = math.max(0.02, typingSpeed - 0.01)
        speedLabel.Text = "SPEED: " .. string.format("%.2f", typingSpeed) .. "s"
        messageLabel.Text = "⚙️ Typing speed: " .. string.format("%.2f", typingSpeed) .. "s/char"
        messageLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
        
    elseif input.KeyCode == Enum.KeyCode.A then
        autoToggle:Fire("MouseButton1Click")
    end
end)

print("✅ SAMBUNG KATA AUTO MODE SIAP!")
print("=" .. string.rep("=", 50))
print("KONTROL:")
print("  UP/DOWN Arrow    = Ubah typing speed")
print("  A                = Toggle Auto Mode")
print("  Click AUTO Btn   = Toggle Auto Mode")
print("=" .. string.rep("=", 50))
