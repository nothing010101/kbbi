-- SAMBUNG KATA UI v7
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local CONFIG = {
    wordListURL = "https://raw.githubusercontent.com/nothing010101/kbbi/main/kbbi_words.json",
    maxSuggestions = 10,
}

local usedWords = {}
local currentSuggestions = {}
local wordList = {}

local function createUI()
    local oldUI = localPlayer.PlayerGui:FindFirstChild("AutoKataUI")
    if oldUI then oldUI:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoKataUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 300, 0, 370)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    header.BorderSizePixel = 0
    header.Parent = frame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0.5, 0)
    headerFix.Position = UDim2.new(0, 0, 0.5, 0)
    headerFix.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.65, 0, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AUTO KATA"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local useBtn = Instance.new("TextButton")
    useBtn.Name = "UseBtn"
    useBtn.Size = UDim2.new(0, 90, 0, 26)
    useBtn.Position = UDim2.new(1, -96, 0.5, -13)
    useBtn.BackgroundColor3 = Color3.fromRGB(40, 190, 40)
    useBtn.BorderSizePixel = 0
    useBtn.Text = "Pakai #1"
    useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    useBtn.TextScaled = true
    useBtn.Font = Enum.Font.GothamBold
    useBtn.Parent = header
    Instance.new("UICorner", useBtn).CornerRadius = UDim.new(0, 6)

    -- Prompt
    local promptLabel = Instance.new("TextLabel")
    promptLabel.Name = "PromptLabel"
    promptLabel.Size = UDim2.new(1, -16, 0, 28)
    promptLabel.Position = UDim2.new(0, 8, 0, 44)
    promptLabel.BackgroundTransparency = 1
    promptLabel.Text = "Prompt: -"
    promptLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    promptLabel.TextScaled = true
    promptLabel.Font = Enum.Font.GothamBold
    promptLabel.TextXAlignment = Enum.TextXAlignment.Left
    promptLabel.Parent = frame

    -- Jawaban 1-10
    for i = 1, CONFIG.maxSuggestions do
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Jawaban" .. i
        lbl.Size = UDim2.new(1, -16, 0, 26)
        lbl.Position = UDim2.new(0, 8, 0, 76 + (i-1) * 27)
        lbl.BackgroundTransparency = 1
        lbl.Text = ""
        lbl.TextColor3 = i == 1
            and Color3.fromRGB(80, 255, 80)
            or Color3.fromRGB(180, 180, 180)
        lbl.TextScaled = true
        lbl.Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame
    end

    -- Status
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -16, 0, 20)
    status.Position = UDim2.new(0, 8, 1, -24)
    status.BackgroundTransparency = 1
    status.Text = "Memuat kata..."
    status.TextColor3 = Color3.fromRGB(130, 130, 130)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    return screenGui
end

local function loadWordList(ui)
    ui.MainFrame.Status.Text = "Memuat 29K kata..."
    local ok, result = pcall(function()
        return game:HttpGet(CONFIG.wordListURL)
    end)
    if ok and result then
        local ok2, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(result)
        end)
        if ok2 and data then
            wordList = data
            ui.MainFrame.Status.Text = #wordList .. " kata siap!"
        else
            ui.MainFrame.Status.Text = "Gagal parse JSON"
        end
    else
        ui.MainFrame.Status.Text = "Gagal load GitHub"
    end
end

local function findWords(prompt, maxResults)
    if not prompt or prompt == "" then return {} end
    local lp = string.lower(prompt)
    local len = #lp
    local results = {}
    local shuffled = {}
    for i, w in ipairs(wordList) do shuffled[i] = w end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    for _, word in ipairs(shuffled) do
        if #word > len and string.lower(string.sub(word, 1, len)) == lp then
            if not usedWords[string.upper(word)] then
                table.insert(results, string.upper(word))
                if #results >= maxResults then break end
            end
        end
    end
    return results
end

local function updateUI(ui, prompt, words)
    currentSuggestions = words
    ui.MainFrame.PromptLabel.Text = "Prompt: " .. (prompt or "-")
    for i = 1, CONFIG.maxSuggestions do
        local lbl = ui.MainFrame:FindFirstChild("Jawaban" .. i)
        if lbl then
            lbl.Text = words[i] and ((i == 1 and "> " or "  ") .. words[i]) or ""
        end
    end
end

local function getPrompt()
    local ok, result = pcall(function()
        return localPlayer.PlayerGui
            :FindFirstChild("MatchUI")
            :FindFirstChild("BottomUI")
            :FindFirstChild("TopUI")
            :FindFirstChild("WordServerFrame")
            :FindFirstChild("WordServer").Text
    end)
    if ok and result and result ~= "" then
        return string.upper(string.gsub(result, "%s+", ""))
    end
    return nil
end

local function isMyTurn()
    local ok, result = pcall(function()
        return localPlayer.PlayerGui
            :FindFirstChild("MatchUI")
            :FindFirstChild("BottomUI")
            :FindFirstChild("Keyboard").Visible
    end)
    return ok and result == true
end

-- MAIN
local ui = createUI()
loadWordList(ui)

-- Tombol Pakai
ui.MainFrame.Header.UseBtn.MouseButton1Click:Connect(function()
    if currentSuggestions[1] then
        local word = currentSuggestions[1]
        usedWords[word] = true
        local prompt = getPrompt()
        if prompt then
            local newWords = findWords(prompt, CONFIG.maxSuggestions)
            updateUI(ui, prompt, newWords)
            ui.MainFrame.Status.Text = word .. " ditandai terpakai"
        end
    end
end)

local lastPrompt = ""
while true do
    task.wait(0.3)
    if isMyTurn() then
        local prompt = getPrompt()
        if prompt and prompt ~= "" and prompt ~= lastPrompt then
            lastPrompt = prompt
            local words = findWords(prompt, CONFIG.maxSuggestions)
            updateUI(ui, prompt, words)
            ui.MainFrame.Status.Text = #words .. " kata ditemukan"
        end
    else
        if lastPrompt ~= "" then
            lastPrompt = ""
            updateUI(ui, "-", {})
            ui.MainFrame.Status.Text = "Menunggu giliran..."
        end
    end
end
