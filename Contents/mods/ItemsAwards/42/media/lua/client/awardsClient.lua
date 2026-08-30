--[[
    ItemsAwards - Client Module (Build 42)

    Responsibilities:
      - Listen for commands sent by the server via OnServerCommand.
      - In single-player, the server module calls Awards.Client.onServerCommand()
        directly (no network hop needed).
      - Display halo notes or chat messages depending on player options.
      - Feed data into the UI (awardsUI.lua).

    This file contains NO award logic whatsoever.
--]]

-- Guard: skip on dedicated server (no client context)
if isServer() and not isClient() then return end

Awards = Awards or {}

-- Guard: only register everything once.
if Awards._clientLoaded then return end
Awards._clientLoaded = true

Awards.Client  = Awards.Client or {}
Awards.Options = Awards.Options or {
    showNumberWhenLosing = false,
    showMessageInChat    = false,
    limitWinningNumbers  = 1,
    limitLosingNumbers   = 1,
}

-- ============================================================
--  Display helpers
-- ============================================================
local function playerSay(message)
    local p = getPlayer()
    if p then p:Say(message) end
end

local function playerHalo(message, r, g, b, duration)
    local p = getPlayer()
    if p then p:setHaloNote(message, r or 255, g or 255, b or 255, duration or 200) end
end

local function showMessage(message, isError)
    if Awards.Options.showMessageInChat then
        playerSay(message)
    else
        if isError then
            playerHalo(message, 255, 0, 0, 300)
        else
            playerHalo(message)
        end
    end
end

-- ============================================================
--  Command dispatcher
--  Called from OnServerCommand (multiplayer) or directly from
--  awardsServer.lua (single-player).
-- ============================================================
function Awards.Client.onServerCommand(command, args)
    if not args then return end

    if command == "award" then
        local itemName  = (getItemNameFromFullType and getItemNameFromFullType(args.item)) or args.item
        local placement = getText(args.onZombie and "IGUI_PlacementZombie" or "IGUI_PlacementInventory")
        local msg   = getText("IGUI_WonItem",    itemName, args.count) .. " " .. placement
        local uiMsg = getText("UI_awardMessage", itemName, args.count) .. " " .. placement
        showMessage(msg, false)
        if AddAwardsLogMessage then
            AddAwardsLogMessage(uiMsg)
        end
        if AddAwardMessageToUI then
            AddAwardMessageToUI(args.item, uiMsg)
        end

    elseif command == "needKills" then
        local msg = getText("IGUI_YouNeedMoreKills", args.number, args.zkills)
        showMessage(msg, true)
        if AddLoserMessageToUI then
            AddLoserMessageToUI(msg)
        end

    elseif command == "loser" then
        local msg = getText("IGUI_LoseItem", args.number)
        if Awards.Options.showNumberWhenLosing then
            showMessage(msg, true)
        end
        if AddLoserMessageToUI then
            AddLoserMessageToUI(msg)
        end

    elseif command == "awardsList" then
        if AwardsAdminUI and AwardsAdminUI.onAwardsList then
            AwardsAdminUI.onAwardsList(args.awards or {}, args.maxDice or 100)
        end

    elseif command == "awardsView" then
        if AwardsViewUI and AwardsViewUI.onAwardsList then
            AwardsViewUI.onAwardsList(args.awards or {}, args.maxDice or 100)
        end
    end
end

-- ============================================================
--  Network listener: server -> client (multiplayer / coop)
-- ============================================================
local function OnServerCommand(module, command, args)
    if module ~= "ItemsAwards" then return end
    Awards.Client.onServerCommand(command, args)
end

Events.OnServerCommand.Add(OnServerCommand)

print("[ItemsAwards] Client module loaded.")
