-- ================================================
-- AUTO SAMBUNG KATA - Roblox KBBI Game v3
-- ================================================

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local CONFIG = {
    autoMode = true,
    delay = 0.2,
    submitDelay = 0.3,
    loopMode = true,
    wordListURL = "https://raw.githubusercontent.com/nothing010101/kbbi/main/kbbi_words.json"
}

local GUI_PATH = {
    matchUI   = "MatchUI",
    bottomUI  = "BottomUI",
    keyboard  = "Keyboard",
    topUI     = "TopUI",
    wordServer = "WordServerFrame",
    wordLabel  = "WordServer",
    enterBtn  = "Row4",
    enterName = "Enter",
    rows      = {"Row1", "Row2", "Row3"},
}

-- ================================================
-- KLIK TOMBOL - pakai Activated event (paling reliable)
-- ================================================
local function clickButton(btn)
    -- Cara paling reliable: langsung fire Activated
    local ok = pcall(function()
        btn.Activated:Fire()
    end)
    if not ok then
        -- Fallback: MouseButton1Down + Up
        pcall(function() btn.MouseButton1Down:Fire() end)
        task.wait(0.05)
        pcall(function() btn.MouseButton1Up:Fire() end)
    end
end

-- ================================================
-- LOAD WORD LIST
-- ================================================
local wordList = {}

local function loadWordList()
    print("[AutoKata] Memuat daftar kata KBBI...")
    local success, result = pcall(function()
        return game:HttpGet(CONFIG.wordListURL)
    end)
    if success and result then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(result)
        end)
        if ok and data then
            wordList = data
            print("[AutoKata] Berhasil load " .. #wordList .. " kata!")
        else
            warn("[AutoKata] Gagal parse JSON!")
        end
    else
        warn("[AutoKata] Gagal load dari GitHub, pakai cadangan...")
    end
    
    -- Tambah kata-kata yang sering muncul sebagai fallback/tambahan
    local extraWords = {
        -- NG
        "nganga","ngeri","ngilu","ngobrol","ngomong","ngomel","ngantuk","ngarai","ngawur",
        "ngayuh","ngembat","ngemplang","ngendon","ngetik","ngerti","ngeluh","ngeles",
        -- LA
        "lapang","lama","langkah","lanjut","lapis","lapar","lari","larut","laut","layak",
        "layang","lazim","labuh","lacak","ladang","laga","lagak","lahan","lahir","laju",
        -- Umum lainnya
        "abad","abadi","air","ajar","alam","aman","anak","api","arah","asal",
        "baca","badan","baik","baru","batu","bawa","besar","bisa","buku","bumi",
        "cara","cerita","cinta","cukup","daftar","dalam","dasar","desa","diri","dunia",
        "edar","emosi","energi","era","esok","etika","ekspor","ekstra","eksis",
        "fakta","fisik","fokus","fungsi","gagal","gairah","gaya","gerak","giat","gigih",
        "habis","hak","halus","harap","harga","hasil","hidup","hormat","hukum","huruf",
        "ideal","ilmu","iman","impian","indah","ingin","inovasi","inti","izin","iffah",
        "jabat","jaga","jalan","janji","jelas","jiwa","jujur",
        "kaki","kami","karya","kasih","kawan","kerja","kira","kisah","kuat",
        "lama","langkah","lapang","layak","lebih","lemah","luar","lulus","lurus",
        "maju","malam","manfaat","merdeka","milik","mimpi","mimisan","minta","mudah","murah",
        "nafas","naik","nama","nalar","negara","nilai","norma","nyata",
        "pada","paham","pandai","pasti","patuh","peduli","percaya","pikir","positif",
        "rasa","rakyat","rendah","resmi","rohani","rukun",
        "sabar","sadar","sahabat","semangat","setia","sikap","solusi","sopan","syukur",
        "tabah","tahu","tangguh","tegas","tepat","tulus","tumbuh",
        "ubah","ulet","umum","usaha","utama","valid","visi","wajar","waktu","yakin","zakat",
        -- Kata 2-3 huruf awal
        "nganga","ngeri","ngilu","ngobrol","ngomong",
        "ahok","ahwal","ekspor","ekspres","ekskul",
        "iffah","iftar","mimisan","mitos","migrasi",
    }
    
    -- Merge extra words
    local existing = {}
    for _, w in ipairs(wordList) do existing[string.lower(w)] = true end
    for _, w in ipairs(extraWords) do
        if not existing[string.lower(w)] then
            table.insert(wordList, w)
            existing[string.lower(w)] = true
        end
    end
    
    print("[AutoKata] Total kata: " .. #wordList)
end

-- ================================================
-- FUNGSI GUI
-- ================================================
local function getMatchUI()
    local pg = localPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    return pg:FindFirstChild(GUI_PATH.matchUI)
end

local function getPrompt()
    local matchUI = getMatchUI()
    if not matchUI then return nil end
    local bottomUI = matchUI:FindFirstChild(GUI_PATH.bottomUI)
    if not bottomUI then return nil end
    local topUI = bottomUI:FindFirstChild(GUI_PATH.topUI)
    if not topUI then return nil end
    local wsFrame = topUI:FindFirstChild(GUI_PATH.wordServer)
    if not wsFrame then return nil end
    local label = wsFrame:FindFirstChild(GUI_PATH.wordLabel)
    if not label then return nil end
    local text = label.Text
    if text and text ~= "" then
        return string.upper(string.gsub(text, "%s+", ""))
    end
    return nil
end

local function isMyTurn()
    local matchUI = getMatchUI()
    if not matchUI then return false end
    local bottomUI = matchUI:FindFirstChild(GUI_PATH.bottomUI)
    if not bottomUI then return false end
    local keyboard = bottomUI:FindFirstChild(GUI_PATH.keyboard)
    if not keyboard then return false end
    return keyboard.Visible
end

local function findWord(prompt)
    if not prompt or prompt == "" then return nil end
    local lowerPrompt = string.lower(prompt)
    local len = #lowerPrompt
    local shuffled = {}
    for i, w in ipairs(wordList) do shuffled[i] = w end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    for _, word in ipairs(shuffled) do
        if #word > len then
            if string.lower(string.sub(word, 1, len)) == lowerPrompt then
                return string.upper(word)
            end
        end
    end
    return nil
end

local function getKeyboard()
    local matchUI = getMatchUI()
    if not matchUI then return nil end
    local bottomUI = matchUI:FindFirstChild(GUI_PATH.bottomUI)
    if not bottomUI then return nil end
    return bottomUI:FindFirstChild(GUI_PATH.keyboard)
end

local function clickLetter(letter)
    local keyboard = getKeyboard()
    if not keyboard then return false end
    for _, rowName in ipairs(GUI_PATH.rows) do
        local row = keyboard:FindFirstChild(rowName)
        if row then
            local btn = row:FindFirstChild(letter)
            if btn and btn:IsA("TextButton") then
                clickButton(btn)
                return true
            end
        end
    end
    -- Coba row4 juga (ada tombol A cadangan)
    local row4 = keyboard:FindFirstChild(GUI_PATH.enterBtn)
    if row4 then
        local btn = row4:FindFirstChild(letter)
        if btn and btn:IsA("TextButton") then
            clickButton(btn)
            return true
        end
    end
    warn("[AutoKata] Tombol tidak ditemukan: " .. letter)
    return false
end

local function clickEnter()
    local keyboard = getKeyboard()
    if not keyboard then return false end
    local enterRow = keyboard:FindFirstChild(GUI_PATH.enterBtn)
    if not enterRow then return false end
    local enterBtn = enterRow:FindFirstChild(GUI_PATH.enterName)
    if enterBtn and enterBtn:IsA("TextButton") then
        clickButton(enterBtn)
        return true
    end
    return false
end

local function typeWord(word)
    print("[AutoKata] Mengetik: " .. word)
    for i = 1, #word do
        local letter = string.sub(word, i, i)
        if letter ~= " " then
            clickLetter(letter)
            task.wait(CONFIG.delay)
        end
    end
    task.wait(CONFIG.submitDelay)
    local ok = clickEnter()
    if ok then
        print("[AutoKata] Submitted: " .. word)
    else
        warn("[AutoKata] Gagal klik Enter!")
    end
end

-- ================================================
-- MAIN LOOP
-- ================================================
local function main()
    loadWordList()
    print("[AutoKata] Script siap! Menunggu giliran...")
    local lastPrompt = ""
    local answered = false
    while CONFIG.loopMode do
        task.wait(0.5)
        if isMyTurn() then
            local prompt = getPrompt()
            if prompt and prompt ~= "" and prompt ~= lastPrompt then
                lastPrompt = prompt
                answered = false
                print("[AutoKata] Prompt baru: " .. prompt)
            end
            if prompt and not answered then
                local word = findWord(prompt)
                if word then
                    print("[AutoKata] Jawaban: " .. word)
                    if CONFIG.autoMode then
                        task.wait(0.2)
                        typeWord(word)
                        answered = true
                    end
                else
                    warn("[AutoKata] Tidak ada kata untuk: " .. prompt)
                end
            end
        else
            lastPrompt = ""
            answered = false
        end
    end
end

main()
