--[[
    ItemsAwards - UI patch for Build 42

    Overrides AwardsWelcomeUI:addAwardMessage() to resolve item
    textures using the B42 getScriptManager() API instead of
    InventoryItemFactory (which still works in B42 but getScriptManager
    is the preferred method for script-level item data).
--]]

if isServer() and not isClient() then return end

local function patchB42UI()
    if not AwardsWelcomeUI then return end

    function AwardsWelcomeUI:addAwardMessage(_item, _message)
        local limit = (Awards.Options and Awards.Options.limitWinningNumbers or 1) * 5
        local icon  = nil

        if _item then
            local ok, script = pcall(function()
                return getScriptManager():getItem(_item)
            end)
            if ok and script then
                icon = script:getNormalTexture()
            end
        end

        self.awardsList:insertItem(1, _message, {icon = icon, name = _message})
        self.awardsList.selected = 1

        while self.awardsList:size() > limit do
            self.awardsList:removeItemByIndex(self.awardsList:size())
        end
    end

    print("[ItemsAwards] B42 UI patch applied.")
end

Events.OnGameBoot.Add(patchB42UI)
