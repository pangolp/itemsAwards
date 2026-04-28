Awards = Awards or {}
Awards.Options = Awards.Options or {}

local itemsAwards = {
    {Item = "Base.CopperCoin", Number = 50, Count = 1, zkills = 1, onZombie = false}, -- Copper Coin
}

local function awardsSendMessage(player, message, r, g, b, duration)
    if Awards.Options.showMessageInChat then
        player:Say(message)
    else
        player:setHaloNote(message, r, g, b, duration)
    end
end

local function isValidAttacker(zombie)
    local attacker = zombie:getAttackedBy()
    if attacker == nil then return nil end
    if not instanceof(attacker, "IsoPlayer") then return nil end
    if attacker:getVehicle() ~= nil then return nil end
    return attacker
end

local function tryGiveAward(attacker, zombie, number)
    local countZombieKill = attacker:getZombieKills() + 1

    for _, value in pairs(itemsAwards) do
        if number ~= value.Number then
            goto continue
        end

        local itemName = getItemNameFromFullType(value.Item)

        if countZombieKill < value.zkills then
            local message = string.format(getText("IGUI_YouNeedMoreKills"), number, value.zkills)
            awardsSendMessage(attacker, message, 255, 0, 0, 300)
            if AddLoserMessageToUI then AddLoserMessageToUI(message) end
            return true
        end

        if value.onZombie then
            zombie:getInventory():AddItems(value.Item, value.Count)
        else
            attacker:getInventory():AddItems(value.Item, value.Count)
        end

        local message = string.format(getText("IGUI_WonItem"), itemName, value.Count)
        awardsSendMessage(attacker, message, 255, 255, 255, 300)

        local awardMessage = string.format(getText("UI_awardMessage"), itemName, value.Count)
        if AddAwardsLogMessage then AddAwardsLogMessage(awardMessage) end
        if AddAwardMessageToUI then AddAwardMessageToUI(value.Item, awardMessage) end

        return true

        ::continue::
    end

    return false
end

local function handleNoWin(attacker, number)
    if not Awards.Options.showNumberWhenLosing then return end
    local message = string.format(getText("IGUI_LoseItem"), number)
    awardsSendMessage(attacker, message, 255, 0, 0, 300)
    if AddLoserMessageToUI then AddLoserMessageToUI(message) end
end

local function ZombKilled(zombie)
    local attacker = isValidAttacker(zombie)
    if not attacker then return end

    local number = ZombRandBetween(1, 101)
    local won = tryGiveAward(attacker, zombie, number)

    if not won then
        handleNoWin(attacker, number)
    end
end

Events.OnZombieDead.Add(ZombKilled)
