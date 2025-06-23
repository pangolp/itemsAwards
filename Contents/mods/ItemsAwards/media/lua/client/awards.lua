Awards = Awards or {}
Awards.Options = Awards.Options or {}

local itemsAwards = {
    {Item = "Base.CopperCoin", Number = 50, Count = 1, zkills = 1}, -- Copper Coin
}

local function ZombKilled(zombie)

    local attacker = zombie:getAttackedBy()

    if attacker == nil or not instanceof(attacker, "IsoPlayer") or attacker:getVehicle() ~= nil then
        return
    end

    local number = ZombRandBetween(1, 101)
    local countZombieKill = attacker:getZombieKills() + 1
    local won = false

    for key, value in pairs(itemsAwards) do

        if (number == value.Number) then

            if (countZombieKill >= value.zkills) then

                local itemName = getItemNameFromFullType(value.Item)
                zombie:getInventory():AddItems(value.Item, value.Count)
                local message = string.format(getText("IGUI_WonItem"), itemName, value.Count)

                if Awards.Options.showMessageInChat then
                    attacker:Say(message)
                else
                    attacker:setHaloNote(message)
                end

                local awardMessage = string.format(getText("UI_awardMessage"), itemName, value.Count)

                if AddAwardsLogMessage then
                    AddAwardsLogMessage(awardMessage)
                end

                if AddAwardMessageToUI then
                    AddAwardMessageToUI(value.Item, awardMessage)
                end

            else

                if Awards.Options.showMessageInChat then
                    attacker:Say(string.format(string.format(getText("IGUI_YouNeedMoreKills"), number, value.zkills)))
                else
                    attacker:setHaloNote(string.format(getText("IGUI_YouNeedMoreKills"), number, value.zkills), 255, 0, 0, 300)
                end

                if AddLoserMessageToUI then
                    AddLoserMessageToUI(string.format(string.format(getText("IGUI_YouNeedMoreKills"), number, value.zkills)))
                end

            end

            won = true
            break
        end
    end

    if (not won) then

        local message = string.format(getText("IGUI_LoseItem"), number)

        if (Awards.Options.showNumberWhenLosing) then

            if Awards.Options.showMessageInChat then
                attacker:Say(message)
            else
                attacker:setHaloNote(message, 255, 0, 0, 300)
            end

        end

        if AddLoserMessageToUI then
            AddLoserMessageToUI(message)
        end

    end
end

Events.OnZombieDead.Add(ZombKilled)
