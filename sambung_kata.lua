-- ================================================
-- SAMBUNG KATA - UI Helper v6
-- Dengan history kata terpakai
-- ================================================

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local CONFIG = {
    wordListURL = "https://raw.githubusercontent.com/nothing010101/kbbi/main/kbbi_words.json",
    maxSuggestions = 10,
}

-- History kata yang udah dipakai (reset tiap execute)
local usedWords = {}

-- ================================================
-- BUAT UI
-- ================================================
local function createUI()
    local oldUI = localPlayer.PlayerGui:FindFirstChild("AutoKataUI")
    if oldUI then oldUI:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoKataUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = localPlayer.PlayerGui

    -- Frame utama
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 320, 0, 320)
    frame.Position = UDim2.new(0.5, -160, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    header.BorderSizePixel = 0
    header.Parent = frame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0.5, 0)
    headerFix.Position = UDim2.new(0, 0, 0.5, 0)
    headerFix.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "ðŸŽ¯ AUTO KATA"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = header

    -- Tombol pakai kata (tandai terpakai)
    local useBtn = Instance.new("TextButton")
    useBtn.Name = "UseBtn"
    useBtn.Size = UDim2.new(0, 90, 0, 24)
    useBtn.Position = UDim2.new(1, -95, 0.5, -12)
    useBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    useBtn.BorderSizePixel = 0
    useBtn.Text = "âœ“ Pakai"
    useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    useBtn.TextScaled = true
    useBtn.Font = Enum.Font.GothamBold
    useBtn.Parent = header

    local useBtnCorner = Instance.new("UICorner")
    useBtnCorner.CornerRadius = UDim.new(0, 6)
    useBtnCorner.Parent = useBtn

    -- Prompt label
    local promptLabel = Instance.new("TextLabel")
    promptLabel.Name = "PromptLabel"
    promptLabel.Size = UDim2.new(1, -20, 0, 30)
    promptLabel.Position = UDim2.new(0, 10, 0, 42)
    promptLabel.BackgroundTransparency = 1
    promptLabel.Text = "Prompt: -"
    promptLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    promptLabel.TextScaled = true
    promptLabel.Font = Enum.Font.Gotham
    promptLabel.TextXAlignment = Enum.TextXAlignment.Left
    promptLabel.Parent = frame

    -- Jawaban labels
    for i = 1, CONFIG.maxSuggestions do
        local jawaban = Instance.new("TextLabel")
        jawaban.Name = "Jawaban" .. i
        jawaban.Size = UDim2.new(1, -20, 0, 22)
        jawaban.Position = UDim2.new(0, 10, 0, 42 + 30 + (i-1) * 24)
        jawaban.BackgroundTransparency = 1
        jawaban.Text = ""
        jawaban.TextColor3 = i == 1
            and Color3.fromRGB(100, 255, 100)
            or Color3.fromRGB(180, 180, 180)
        jawaban.TextScaled = true
        jawaban.Font = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham
        jawaban.TextXAlignment = Enum.TextXAlignment.Left
        jawaban.Parent = frame
    end

    -- Status label
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -20, 0, 18)
    status.Position = UDim2.new(0, 10, 1, -22)
    status.BackgroundTransparency = 1
    status.Text = "â³ Memuat kata..."
    status.TextColor3 = Color3.fromRGB(150, 150, 150)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame

    return screenGui
end

-- ================================================
-- LOAD WORD LIST
-- ================================================
local wordList = {}

local function loadWordList(ui)
    local status = ui.MainFrame.Status
    status.Text = "â³ Memuat 29K kata KBBI..."
    local success, result = pcall(function()
        return game:HttpGet(CONFIG.wordListURL)
    end)
    if success and result then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(result)
        end)
        if ok and data then
            wordList = data
            status.Text = "âœ… " .. #wordList .. " kata siap!"
        else
            status.Text = "âŒ Gagal parse JSON"
        end
    else
        status.Text = "âŒ Gagal load dari GitHub"
    end
end

-- ================================================
-- CARI KATA (skip yang udah dipakai)
-- ================================================
local currentSuggestions = {}

local function findWords(prompt, maxResults)
    if not prompt or prompt == "" then return {} end
    local lowerPrompt = string.lower(prompt)
    local len = #lowerPrompt
    local results = {}

    local shuffled = {}
    for i, w in ipairs(wordList) do shuffled[i] = w end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    for _, word in ipairs(shuffled) do
        if #word > len then
            if string.lower(string.sub(word, 1, len)) == lowerPrompt then
                -- Skip kata yang udah dipakai
                if not usedWords[string.upper(word)] then
                    table.insert(results, string.upper(word))
                    if #results >= maxResults then break end
                end
            end
        end
    end
    return results
end

-- ================================================
-- UPDATE UI
-- ================================================
local function updateUI(ui, prompt, words)
    local frame = ui.MainFrame
    frame.PromptLabel.Text = "Prompt: " .. (prompt or "-")
    currentSuggestions = words
    for i = 1, CONFIG.maxSuggestions do
        local label = frame:FindFirstChild("Jawaban" .. i)
        if label then
            if words[i] then
                label.Text = (i == 1 and "âž¡ï¸ " or "   ") .. words[i]
            else
                label.Text = ""
            end
        end
    end
end

-- ================================================
-- FUNGSI GUI GAME
-- ================================================
local function getMatchUI()
    local pg = localPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    return pg:FindFirstChild("MatchUI")
end

local function getPrompt()
    local matchUI = getMatchUI()
    if not matchUI then return nil end
    local ok, result = pcall(function()
        return matchUI
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
    local matchUI = getMatchUI()
    if not matchUI then return false end
    local ok, result = pcall(function()
        return matchUI:FindFirstChild("BottomUI"):FindFirstChild("Keyboard").Visible
    end)
    return ok and result == true
end

-- ================================================
-- MAIN
-- ================================================
local ui = createUI()
loadWordList(ui)

-- Tombol "Pakai" â€” tandai kata pertama sebagai terpakai
ui.MainFrame.Header.UseBtn.MouseButton1Click:Connect(function()
    if currentSuggestions[1] then
        local word = currentSuggestions[1]
        usedWords[word] = true
        print("[AutoKata] Ditandai terpakai: " .. word)

        -- Refresh saran dengan kata baru
        local prompt = getPrompt()
        if prompt then
            local newWords = findWords(prompt, CONFIG.maxSuggestions)
            updateUI(ui, prompt, newWords)
            ui.MainFrame.Status.Text = "âœ… " .. word .. " ditandai terpakai"
        end
    end
end)

print("[AutoKata] UI aktif! Tinggal tunggu giliran.")

local lastPrompt = ""

while true do
    task.wait(0.3)
    if isMyTurn() then
        local prompt = getPrompt()
        if prompt and prompt ~= "" and prompt ~= lastPrompt then
            lastPrompt = prompt
            local words = findWords(prompt, CONFIG.maxSuggestions)
            updateUI(ui, prompt, words)
            if #words > 0 then
                ui.MainFrame.Status.Text = "âœ… " .. #words .. " kata ditemukan!"
                print("[AutoKata] Prompt: " .. prompt .. " â†’ " .. words[1])
            else
                ui.MainFrame.Status.Text = "âŒ Tidak ada kata untuk: " .. prompt
            end
        end
    else
        if lastPrompt ~= "" then
            lastPrompt = ""
            updateUI(ui, "-", {})
            ui.MainFrame.Status.Text = "â³ Menunggu giliran..."
        end
    end
end
