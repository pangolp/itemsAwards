--[[
    ItemsAwards - Server Module (Build 41)
    Runs ONLY on the server (dedicated, host, or single-player).

    Flow:
      1. OnZombieDead fires on server.
      2. Server rolls the number and decides if the player wins.
      3. Server adds the item to the player's inventory.
      4. Server sends a command to the client so it can update the UI.
--]]

-- Guard: only run in server context (includes single-player host)
if isClient() and not isServer() then return end

Awards = Awards or {}

-- Guard: this file can end up loaded as more than one physical copy
-- (e.g. root + common/ paths on B41). Only register everything once.
if Awards._serverLoaded then return end
Awards._serverLoaded = true

Awards.Server = Awards.Server or {}

-- ============================================================
--  Award table - edit freely
--  Item      : full item type string (e.g. "Base.Money")
--  Number    : the lucky number (1-100); must match exactly
--  Count     : how many copies to give
--  zkills    : minimum zombie kills required to claim the prize
--  onZombie  : true  -> item added to the zombie (player loots it)
--              false -> item goes directly to the killer's inventory
-- ============================================================
local itemsAwards = {
    {Item = "Base.Money", Number = 50, Count = 1, zkills = 1, onZombie = false},
}

-- ============================================================
--  Helper: add item to player inventory and sync to clients
-- ============================================================
local function giveItemToPlayer(player, itemType, count)
    local inv = player:getInventory()
    for i = 1, count do
        local item = inv:AddItem(itemType)
        if sendAddItemToContainer then
            sendAddItemToContainer(inv, item)
        end
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
        -- Multiplayer / coop: send over the network
        sendServerCommand(player, "ItemsAwards", cmd, args)
    else
        -- Single-player: call the client handler directly (no network)
        if Awards.Client and Awards.Client.onServerCommand then
            Awards.Client.onServerCommand(cmd, args)
        end
    end
end

-- ============================================================
--  Main logic: runs on every zombie death (server-side only)
-- ============================================================
local function ZombKilled(zombie)
    -- OnZombieDead can fire more than once for the same zombie
    -- (observed with debug-mode kills). Guard against double-processing.
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

    for _, value in pairs(itemsAwards) do

        if number == value.Number then

            if countZombieKill >= value.zkills then
                -- WIN: give the item
                if value.onZombie then
                    giveItemToZombie(zombie, value.Item, value.Count)
                else
                    giveItemToPlayer(attacker, value.Item, value.Count)
                end

                local itemName = ""
                if getItemNameFromFullType then
                    itemName = getItemNameFromFullType(value.Item)
                else
                    itemName = value.Item
                end

                local winMsg = string.format(getText("IGUI_WonItem"),    itemName, value.Count)
                local uiMsg  = string.format(getText("UI_awardMessage"), itemName, value.Count)

                notifyClient(attacker, "award", {
                    item     = value.Item,
                    message  = winMsg,
                    uiMsg    = uiMsg,
                    onZombie = value.onZombie,
                })

            else
                -- NOT ENOUGH KILLS
                local needMsg = string.format(getText("IGUI_YouNeedMoreKills"), number, value.zkills)
                notifyClient(attacker, "needKills", {
                    message = needMsg,
                })
            end

            won = true
            break
        end
    end

    if not won then
        -- LOSING ROLL
        local loseMsg = string.format(getText("IGUI_LoseItem"), number)
        notifyClient(attacker, "loser", {
            message = loseMsg,
        })
    end
end

Events.OnZombieDead.Add(ZombKilled)

-- Reserved for future client->server commands
local function OnClientCommand(module, command, player, args)
    if module ~= "ItemsAwards" then return end
end
Events.OnClientCommand.Add(OnClientCommand)

print("[ItemsAwards] Server module loaded.")
