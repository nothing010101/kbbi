-- ================================================
-- AUTO SAMBUNG KATA - Roblox KBBI Game
-- By: Script Auto Answer
-- Cara pakai: Jalankan saat giliran kamu muncul
-- ================================================

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- ================================================
-- KONFIGURASI
-- ================================================
local CONFIG = {
    autoMode = true,        -- true = auto jawab otomatis, false = manual (print saja)
    delay = 0.3,            -- jeda antar klik huruf (detik), turunkan jika mau lebih cepat
    submitDelay = 0.2,      -- jeda sebelum klik Masuk
    loopMode = true,        -- terus jalan sampai game selesai
    wordListURL = "https://raw.githubusercontent.com/nothing010101/kbbi/main/kbbi_words.json"
}

-- ================================================
-- PATH GUI (dari hasil scan log)
-- ================================================
local GUI_PATH = {
    matchUI    = "MatchUI",
    bottomUI   = "BottomUI",
    keyboard   = "Keyboard",
    topUI      = "TopUI",
    wordServer = "WordServerFrame",
    wordLabel  = "WordServer",   -- TextLabel berisi huruf prompt (K, MI, AHO, dll)
    enterBtn   = "Row4",
    enterName  = "Enter",
    rows       = {"Row1", "Row2", "Row3"},
}

-- ================================================
-- LOAD WORD LIST DARI GITHUB
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
            warn("[AutoKata] Gagal parse JSON: " .. tostring(data))
        end
    else
        warn("[AutoKata] Gagal load dari GitHub: " .. tostring(result))
        warn("[AutoKata] Menggunakan kata cadangan...")
        -- Kata cadangan minimal jika gagal load
        wordList = {
            "abad","abadi","air","ajar","alam","aman","anak","api","arah","asal",
            "baca","badan","baik","baru","batu","bawa","besar","bisa","buku","bumi",
            "cara","cerita","cinta","cukup","daftar","dalam","dasar","desa","diri","dunia",
            "edar","emosi","energi","era","esok","etika","fakta","fisik","fokus","fungsi",
            "gagal","gairah","gaya","gerak","giat","gigih","guna","guru","habis","hak",
            "halus","harap","harga","hasil","hidup","hormat","hukum","huruf","ideal","ilmu",
            "iman","impian","indah","ingin","inovasi","inti","izin","jabat","jaga","jalan",
            "janji","jelas","jiwa","jujur","kaki","kami","karya","kasih","kawan","kerja",
            "kira","kisah","kuat","lama","langkah","lanjut","layak","lebih","lemah","luar",
            "maju","malam","manfaat","merdeka","milik","mimpi","mudah","murah","murni",
            "nafas","naik","nama","nalar","negara","nilai","norma","nyata",
            "pada","paham","pandai","pasti","patuh","peduli","percaya","pikir","positif",
            "rasa","rakyat","rendah","resmi","rohani","rukun","sabar","sadar","sahabat",
            "sama","semangat","setia","sikap","solusi","sopan","syukur",
            "tabah","tahu","tangguh","tegas","tepat","tulus","tumbuh",
            "ubah","ulet","umum","usaha","utama","valid","visi","wajar","waktu","yakin","zakat",
            -- Kata dengan awalan khusus
            "ahok","ahwal","ekspor","ekspres","ekskul","ekspedisi","ekstra","eksis",
            "iffah","iftar","mimisan","mitos","migrasi","misi","mistis",
        }
        print("[AutoKata] Kata cadangan loaded: " .. #wordList)
    end
end

-- ================================================
-- FUNGSI UTAMA
-- ================================================

-- Ambil GUI MatchUI
local function getMatchUI()
    local pg = localPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    return pg:FindFirstChild(GUI_PATH.matchUI)
end

-- Ambil huruf/suku kata prompt saat ini
local function getPrompt()
    local matchUI = getMatchUI()
    if not matchUI then return nil end
    
    local path = matchUI
        :FindFirstChild(GUI_PATH.bottomUI)
    if not path then return nil end
    
    path = path:FindFirstChild(GUI_PATH.topUI)
    if not path then return nil end
    
    path = path:FindFirstChild(GUI_PATH.wordServer)
    if not path then return nil end
    
    local label = path:FindFirstChild(GUI_PATH.wordLabel)
    if not label then return nil end
    
    local text = label.Text
    if text and text ~= "" then
        return string.upper(string.gsub(text, "%s+", ""))
    end
    return nil
end

-- Cek apakah giliran kita (keyboard muncul)
local function isMyTurn()
    local matchUI = getMatchUI()
    if not matchUI then return false end
    
    local bottomUI = matchUI:FindFirstChild(GUI_PATH.bottomUI)
    if not bottomUI then return false end
    
    local keyboard = bottomUI:FindFirstChild(GUI_PATH.keyboard)
    if not keyboard then return false end
    
    return keyboard.Visible
end

-- Cari kata yang cocok dengan prompt
local function findWord(prompt)
    if not prompt or prompt == "" then return nil end
    local lowerPrompt = string.lower(prompt)
    local len = #lowerPrompt
    
    -- Shuffle untuk variasi jawaban
    local shuffled = {}
    for i, w in ipairs(wordList) do shuffled[i] = w end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    for _, word in ipairs(shuffled) do
        if #word >= len + 1 then -- minimal 1 huruf lebih dari prompt
            if string.lower(string.sub(word, 1, len)) == lowerPrompt then
                return string.upper(word)
            end
        end
    end
    return nil
end

-- Klik tombol huruf di keyboard
local function clickLetter(letter)
    local matchUI = getMatchUI()
    if not matchUI then return false end
    
    local keyboard = matchUI
        :FindFirstChild(GUI_PATH.bottomUI)
        :FindFirstChild(GUI_PATH.keyboard)
    
    if not keyboard then return false end
    
    -- Cari di semua row
    for _, rowName in ipairs(GUI_PATH.rows) do
        local row = keyboard:FindFirstChild(rowName)
        if row then
            local btn = row:FindFirstChild(letter)
            if btn and btn:IsA("TextButton") then
                btn.MouseButton1Click:Fire()
                return true
            end
        end
    end
    return false
end

-- Klik tombol Enter/Masuk
local function clickEnter()
    local matchUI = getMatchUI()
    if not matchUI then return false end
    
    local enterRow = matchUI
        :FindFirstChild(GUI_PATH.bottomUI)
        :FindFirstChild(GUI_PATH.keyboard)
        :FindFirstChild(GUI_PATH.enterBtn)
    
    if not enterRow then return false end
    
    local enterBtn = enterRow:FindFirstChild(GUI_PATH.enterName)
    if enterBtn and enterBtn:IsA("TextButton") then
        enterBtn.MouseButton1Click:Fire()
        return true
    end
    return false
end

-- Ketik kata huruf per huruf
local function typeWord(word)
    print("[AutoKata] Mengetik: " .. word)
    for i = 1, #word do
        local letter = string.sub(word, i, i)
        if letter ~= " " then
            local ok = clickLetter(letter)
            if not ok then
                warn("[AutoKata] Tombol " .. letter .. " tidak ditemukan!")
            end
            task.wait(CONFIG.delay)
        end
    end
    
    task.wait(CONFIG.submitDelay)
    local submitted = clickEnter()
    if submitted then
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
    print("[AutoKata] Mode: " .. (CONFIG.autoMode and "AUTO" or "MANUAL"))
    
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
                    print("[AutoKata] Jawaban ditemukan: " .. word .. " (prompt: " .. prompt .. ")")
                    
                    if CONFIG.autoMode then
                        task.wait(0.3) -- sedikit delay biar natural
                        typeWord(word)
                        answered = true
                    else
                        -- Mode manual: print saja ke console
                        print("[AutoKata] >> KETIK: " .. word)
                    end
                else
                    warn("[AutoKata] Tidak ada kata untuk prompt: " .. prompt)
                    -- Coba cari dengan huruf pertama saja
                    if #prompt > 1 then
                        local shortWord = findWord(string.sub(prompt, 1, 1))
                        if shortWord then
                            warn("[AutoKata] Fallback ke huruf pertama: " .. shortWord)
                        end
                    end
                end
            end
        else
            -- Reset saat bukan giliran kita
            if lastPrompt ~= "" then
                lastPrompt = ""
                answered = false
            end
        end
    end
end

-- Jalankan!
main()
