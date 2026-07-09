--[[
    ItemsAwards - Data Module (Build 42)
    Loads and saves the awards table from/to a CSV file on the server.
    Exposes Awards.Data for other server modules to read and mutate prizes.
--]]

if not PZAPI then return end

if isClient() and not isServer() then return end

Awards = Awards or {}

if Awards._dataLoaded then return end
Awards._dataLoaded = true

Awards.Data = Awards.Data or {}

local AWARDS_FILE = "ItemsAwards_awards.txt"

local _awards = {}

local DEFAULT_AWARDS = {
    {Item = "Base.Money", Number = 50, Count = 1, zkills = 1, onZombie = false},
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
    local reader = getFileReader(AWARDS_FILE, true)
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

Awards.Data.load()

print("[ItemsAwards] Data module loaded (B42).")
