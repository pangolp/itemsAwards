--[[
    ItemsAwards - Data Module (Build 42)
    Loads and saves the awards table from/to a CSV file on the server.
    Exposes Awards.Data for other server modules to read and mutate prizes.
--]]

-- Server-only guard: skip on a pure client (dedicated server, coop host and
-- single-player all pass). Never add a PZAPI guard here: PZAPI is client-only.
if isClient() and not isServer() then return end

Awards = Awards or {}

if Awards._dataLoaded then return end
Awards._dataLoaded = true

Awards.Data = Awards.Data or {}

local AWARDS_FILE = "ItemsAwards_awards.txt"
local CONFIG_FILE = "ItemsAwards_config.txt"

local _awards  = {}
local _maxDice = 100

-- ---- Config ----

function Awards.Data.getMaxDice()
    return _maxDice
end

function Awards.Data.setMaxDice(n)
    n = math.max(2, math.floor(tonumber(n) or 100))
    _maxDice = n
    local writer = getFileWriter(CONFIG_FILE, true, false)
    if writer then
        writer:write("maxDice=" .. n .. "\n")
        writer:close()
    end
end

local function loadConfig()
    local reader = getFileReader(CONFIG_FILE, false)
    if not reader then return end
    local line = reader:readLine()
    while line do
        local v = line:match("^maxDice=(%d+)")
        if v then _maxDice = math.max(2, tonumber(v) or 100) end
        line = reader:readLine()
    end
    reader:close()
end

-- Seed prizes so the mod ships with something to win out of the box.
-- Admins can edit/remove these from the in-game panel; they are only written
-- the first time, when no awards file exists yet. Numbers are unique slots in
-- [1, maxDice] (default 100); zkills gates each prize behind a kill count so
-- better loot arrives later. Weapons drop on the zombie body (onZombie = true).
local DEFAULT_AWARDS = {
    {Item = "Base.Bandage",     Number = 10,  Count = 2,  zkills = 1,   onZombie = false},
    {Item = "Base.Money",       Number = 25,  Count = 5,  zkills = 3,   onZombie = false},
    {Item = "Base.TinnedBeans", Number = 40,  Count = 1,  zkills = 10,  onZombie = false},
    {Item = "Base.Nails",       Number = 50,  Count = 10, zkills = 15,  onZombie = false},
    {Item = "Base.Screwdriver", Number = 60,  Count = 1,  zkills = 25,  onZombie = false},
    {Item = "Base.Hammer",      Number = 65,  Count = 1,  zkills = 30,  onZombie = false},
    {Item = "Base.HuntingKnife",Number = 75,  Count = 1,  zkills = 50,  onZombie = true},
    {Item = "Base.BaseballBat", Number = 85,  Count = 1,  zkills = 75,  onZombie = true},
    {Item = "Base.Axe",         Number = 95,  Count = 1,  zkills = 100, onZombie = true},
    {Item = "Base.Pistol",      Number = 99,  Count = 1,  zkills = 150, onZombie = true},
    {Item = "Base.Bullets9mm",  Number = 100, Count = 15, zkills = 150, onZombie = true},
}

-- ---- Serialization ----

local function parseLine(line)
    local parts = {}
    for part in (line .. ","):gmatch("([^,]*),") do
        parts[#parts + 1] = part
    end
    if #parts < 5 then return nil end
    local num  = tonumber(parts[2])
    local cnt  = tonumber(parts[3])
    local zkil = tonumber(parts[4])
    if not num or not cnt or not zkil then return nil end
    return {
        Item     = parts[1],
        Number   = num,
        Count    = cnt,
        zkills   = zkil,
        onZombie = parts[5] == "true",
    }
end

local function serializeLine(e)
    return e.Item .. "," .. e.Number .. "," .. e.Count .. "," .. e.zkills .. "," .. tostring(e.onZombie)
end

-- ---- File I/O ----

function Awards.Data.save()
    local writer = getFileWriter(AWARDS_FILE, true, false)
    if not writer then
        print("[ItemsAwards] ERROR: cannot write " .. AWARDS_FILE)
        return
    end
    writer:write("Item,Number,Count,zkills,onZombie\n")
    for _, e in ipairs(_awards) do
        writer:write(serializeLine(e) .. "\n")
    end
    writer:close()
end

function Awards.Data.load()
    -- Pass false so a missing file returns nil (createIfNull=true would create
    -- an empty file and hide the "no file yet" case, skipping the seed below).
    local reader = getFileReader(AWARDS_FILE, false)
    if not reader then
        _awards = {}
        for _, v in ipairs(DEFAULT_AWARDS) do
            _awards[#_awards + 1] = {Item = v.Item, Number = v.Number, Count = v.Count, zkills = v.zkills, onZombie = v.onZombie}
        end
        Awards.Data.save()
        print("[ItemsAwards] No awards file found – defaults written.")
        return
    end

    local loaded = {}
    local skipHeader = true
    local line = reader:readLine()
    while line do
        if skipHeader and line:find("^Item") then
            skipHeader = false
        elseif line ~= "" then
            local e = parseLine(line)
            if e then loaded[#loaded + 1] = e end
        end
        line = reader:readLine()
    end
    reader:close()

    _awards = loaded
    print("[ItemsAwards] Loaded " .. #_awards .. " award(s) from file.")
end

-- ---- CRUD ----

function Awards.Data.getAll()
    return _awards
end

function Awards.Data.add(entry)
    _awards[#_awards + 1] = entry
    Awards.Data.save()
end

function Awards.Data.update(index, entry)
    if _awards[index] then
        _awards[index] = entry
        Awards.Data.save()
    end
end

function Awards.Data.remove(index)
    if _awards[index] then
        table.remove(_awards, index)
        Awards.Data.save()
    end
end

-- ---- Boot ----

loadConfig()
Awards.Data.load()

print("[ItemsAwards] Data module loaded (B42).")
