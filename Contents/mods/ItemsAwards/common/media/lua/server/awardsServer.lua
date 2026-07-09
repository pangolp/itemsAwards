--[[
    ItemsAwards - Server Module (Build 42)
    Runs ONLY on the server (dedicated, host, or single-player).

    Flow:
      1. OnZombieDead fires on server.
      2. Server rolls the number and decides if the player wins.
      3. Server adds the item to the player's inventory.
      4. Server sends a command to the client so it can update the UI.

    Awards table is managed by awardsData.lua (loaded before this file).
--]]

-- Guard: B42 only. B41 may scan common/ subdirectories and reach this file.
if not PZAPI then return end

-- Guard: only run in server context (includes single-player host)
if isClient() and not isServer() then return end

Awards = Awards or {}

if Awards._serverLoaded then return end
Awards._serverLoaded = true

Awards.Server = Awards.Server or {}

-- ============================================================
--  Helper: add item to player inventory
-- ============================================================
local function giveItemToPlayer(player, itemType, count)
    local inv = player:getInventory()
    for i = 1, count do
        inv:AddItem(itemType)
    end
end

local function giveItemToZombie(zombie, itemType, count)
    zombie:getInventory():AddItems(itemType, count)
end

-- ============================================================
--  Notify the client with the outcome
-- ============================================================
local function notifyClient(player, cmd, args)
    if isServer() then
        sendServerCommand(player, "ItemsAwards", cmd, args)
    else
        if Awards.Client and Awards.Client.onServerCommand then
            Awards.Client.onServerCommand(cmd, args)
        end
    end
end

-- ============================================================
--  Admin helpers
-- ============================================================
local function playerIsAdmin(player)
    local level = player:getAccessLevel()
    if level == "admin" or level == "moderator" then return true end
    local online = getOnlinePlayers()
    return online and online:size() == 1
end

local function sendAwardsList(player)
    local list = {}
    for i, v in ipairs(Awards.Data.getAll()) do
        list[i] = {Item = v.Item, Number = v.Number, Count = v.Count, zkills = v.zkills, onZombie = v.onZombie}
    end
    notifyClient(player, "awardsList", {awards = list})
end

-- ============================================================
--  Main logic: runs on every zombie death (server-side only)
-- ============================================================
local function ZombKilled(zombie)
    local modData = zombie:getModData()
    if modData.ItemsAwardsProcessed then return end
    modData.ItemsAwardsProcessed = true

    local attacker = zombie:getAttackedBy()

    if attacker == nil
    or not instanceof(attacker, "IsoPlayer")
    or attacker:getVehicle() ~= nil then
        return
    end

    local number          = ZombRandBetween(1, 101)
    local countZombieKill = attacker:getZombieKills() + 1
    local won             = false

    for _, value in pairs(Awards.Data.getAll()) do

        if number == value.Number then

            if countZombieKill >= value.zkills then
                if value.onZombie then
                    giveItemToZombie(zombie, value.Item, value.Count)
                else
                    giveItemToPlayer(attacker, value.Item, value.Count)
                end

                local itemName = getItemNameFromFullType and getItemNameFromFullType(value.Item) or value.Item

                notifyClient(attacker, "award", {
                    item     = value.Item,
                    message  = getText("IGUI_WonItem",    itemName, value.Count),
                    uiMsg    = getText("UI_awardMessage", itemName, value.Count),
                    onZombie = value.onZombie,
                })
            else
                notifyClient(attacker, "needKills", {
                    message = getText("IGUI_YouNeedMoreKills", number, value.zkills),
                })
            end

            won = true
            break
        end
    end

    if not won then
        notifyClient(attacker, "loser", {
            message = getText("IGUI_LoseItem", number),
        })
    end
end

Events.OnZombieDead.Add(ZombKilled)

-- ============================================================
--  Client → Server commands
-- ============================================================
local function OnClientCommand(module, command, player, args)
    if module ~= "ItemsAwards" then return end

    if not playerIsAdmin(player) then return end

    if command == "getAwards" then
        sendAwardsList(player)

    elseif command == "addAward" then
        if not args or not args.Item or not args.Number then return end
        Awards.Data.add({
            Item     = tostring(args.Item),
            Number   = tonumber(args.Number) or 0,
            Count    = tonumber(args.Count)  or 1,
            zkills   = tonumber(args.zkills) or 1,
            onZombie = args.onZombie == true,
        })
        sendAwardsList(player)

    elseif command == "updateAward" then
        if not args or not args.index then return end
        Awards.Data.update(tonumber(args.index), {
            Item     = tostring(args.Item),
            Number   = tonumber(args.Number) or 0,
            Count    = tonumber(args.Count)  or 1,
            zkills   = tonumber(args.zkills) or 1,
            onZombie = args.onZombie == true,
        })
        sendAwardsList(player)

    elseif command == "deleteAward" then
        if not args or not args.index then return end
        Awards.Data.remove(tonumber(args.index))
        sendAwardsList(player)

    elseif command == "reloadAwards" then
        Awards.Data.load()
        sendAwardsList(player)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

print("[ItemsAwards] Server module loaded (B42).")
