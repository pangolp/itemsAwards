--[[
    ItemsAwards - Client Module (Build 41 + 42)

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

Awards         = Awards or {}
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
        showMessage(args.message, false)
        if AddAwardsLogMessage then
            AddAwardsLogMessage(args.uiMsg or args.message)
        end
        if AddAwardMessageToUI then
            AddAwardMessageToUI(args.item, args.uiMsg or args.message)
        end

    elseif command == "needKills" then
        showMessage(args.message, true)
        if AddLoserMessageToUI then
            AddLoserMessageToUI(args.message)
        end

    elseif command == "loser" then
        if Awards.Options.showNumberWhenLosing then
            showMessage(args.message, true)
        end
        if AddLoserMessageToUI then
            AddLoserMessageToUI(args.message)
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
