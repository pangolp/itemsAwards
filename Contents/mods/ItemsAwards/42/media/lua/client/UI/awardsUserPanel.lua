--[[
    ItemsAwards - User Panel hook (Build 42)

    Adds a "Premios" entry to the vanilla in-game User Panel (ISUserPanelUI),
    the client menu that also holds Faction / Safehouse / Tickets. This
    replaces the old floating HUD gift icon.

    We monkey-patch create() and onOptionMouseDown() so the button is injected
    without touching the base game file, and the panel re-lays out to fit.
--]]

-- Guard: skip on dedicated server (no client context)
if isServer() and not isClient() then return end

require "ISUI/ISButton"

-- The base class must already exist (vanilla loads before mods).
if not ISUserPanelUI then return end

-- Guard against this file being applied twice.
if ISUserPanelUI._itemsAwardsHooked then return end
ISUserPanelUI._itemsAwardsHooked = true

local UI_BORDER_SPACING = 10

local original_create = ISUserPanelUI.create
function ISUserPanelUI:create()
    original_create(self)

    -- Cancel/Close is always the last button; we slot ours in above it.
    if not self.cancel then return end

    local BUTTON_HGT = getTextManager():getFontHeight(UIFont.Small) + 6
    local step       = BUTTON_HGT + UI_BORDER_SPACING

    local x       = self.cancel:getX()
    local w       = self.cancel:getWidth()
    local awardsY = self.cancel:getY()

    self.awardsBtn = ISButton:new(x, awardsY, w, BUTTON_HGT,
        getText("UI_userpanel_awards"), self, ISUserPanelUI.onOptionMouseDown)
    self.awardsBtn.internal    = "ITEMSAWARDS"
    self.awardsBtn:initialise()
    self.awardsBtn:instantiate()
    self.awardsBtn.borderColor = self.buttonBorderColor
    self:addChild(self.awardsBtn)

    -- Push Close down one row and grow the panel to fit.
    self.cancel:setY(awardsY + step)
    self:setHeight(self.cancel:getY() + BUTTON_HGT + UI_BORDER_SPACING + 1)
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
