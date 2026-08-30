--[[
    ItemsAwards - User Panel hook (Build 42)

    Adds a "Premios" entry to the vanilla in-game User Panel (ISUserPanelUI),
    the client menu that also holds Faction / Safehouse. Replaces the old
    floating HUD gift icon.

    We wrap initialise() (the outer build entry) rather than create(), so it
    works regardless of which internal method a given build uses to lay out
    its buttons. The hook is applied both immediately and on OnGameBoot so it
    does not depend on Lua file load order.
--]]

-- Guard: skip on dedicated server (no client context)
if isServer() and not isClient() then return end

require "ISUI/ISButton"

local UI_BORDER_SPACING = 10

-- Add the "Premios" button below the bottom-most existing child (Close),
-- without relying on vanilla field names (layout varies between builds).
local function injectAwardsButton(self)
    if self.awardsBtn then return end   -- already added to this instance

    local lowest
    for _, child in pairs(self:getChildren() or {}) do
        if child.getY and (not lowest or child:getY() > lowest:getY()) then
            lowest = child
        end
    end
    if not lowest then
        print("[ItemsAwards] User Panel: no children found; button not added.")
        return
    end

    local BUTTON_HGT = getTextManager():getFontHeight(UIFont.Small) + 6
    local step       = BUTTON_HGT + UI_BORDER_SPACING
    local x          = lowest:getX()
    local w          = lowest:getWidth()
    local awardsY    = lowest:getY()

    self.awardsBtn = ISButton:new(x, awardsY, w, BUTTON_HGT,
        getText("UI_userpanel_awards"), self, ISUserPanelUI.onOptionMouseDown)
    self.awardsBtn.internal    = "ITEMSAWARDS"
    self.awardsBtn:initialise()
    self.awardsBtn:instantiate()
    self.awardsBtn.borderColor = self.buttonBorderColor
    self:addChild(self.awardsBtn)

    lowest:setY(awardsY + step)
    self:setHeight(lowest:getY() + BUTTON_HGT + UI_BORDER_SPACING + 1)
end

local function applyHook()
    if not ISUserPanelUI then return end
    if ISUserPanelUI._itemsAwardsHooked then return end
    ISUserPanelUI._itemsAwardsHooked = true

    local original_initialise = ISUserPanelUI.initialise
    function ISUserPanelUI:initialise()
        original_initialise(self)
        injectAwardsButton(self)
    end

    local original_onOptionMouseDown = ISUserPanelUI.onOptionMouseDown
    function ISUserPanelUI:onOptionMouseDown(button, x, y)
        if button.internal == "ITEMSAWARDS" then
            if OpenAwardsWelcomePanel then OpenAwardsWelcomePanel() end
            self:close()
            return
        end
        return original_onOptionMouseDown(self, button, x, y)
    end

    print("[ItemsAwards] User Panel hook applied.")
end

Events.OnGameBoot.Add(applyHook)
applyHook()  -- also try now, in case the class is already available
