--[[
    ItemsAwards - UI Module (Build 41 + 42 common)

    Provides:
      - AwardsWelcomeUI        floating panel with winners/losers lists
      - AwardsHUDButton        HUD gift icon that toggles the panel
      - AddAwardMessageToUI()  public helper called by awardsClient.lua
      - AddLoserMessageToUI()  public helper called by awardsClient.lua
      - AddAwardsLogMessage()  legacy compatibility stub
--]]

-- Guard: skip on dedicated server
if isServer() and not isClient() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

awardsWelcomeWindow = nil

AwardsWelcomeUI = ISPanel:derive("AwardsWelcomeUI")

function AwardsWelcomeUI:initialise()
    ISPanel.initialise(self)
    self:create()
end

function AwardsWelcomeUI:prerender()
    ISPanel.prerender(self)
    self:drawText(getText("UI_welcomeawards"), 10, 10, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(getText("UI_version") .. ": 1.0", 10, 40, 0.8, 0.8, 0.8, 1, UIFont.Small)
    self:drawText(getText("UI_instructions"), 10, 70, 0.8, 0.8, 0.8, 1, UIFont.Small)
end

function AwardsWelcomeUI:create()
    local btnWidth  = 100
    local btnHeight = 25

    self.awardsList = ISScrollingListBox:new(10, 100, self.width - 20, 110)
    self.awardsList:initialise()
    self.awardsList:instantiate()
    self.awardsList.itemheight   = 22
    self.awardsList.selected     = 0
    self.awardsList.joypadParent = self
    self.awardsList.font         = UIFont.NewSmall
    self.awardsList.doDrawItem   = self.drawAwardItem
    self.awardsList:setOnMouseDoubleClick(self, self.onAwardDoubleClick)
    self:addChild(self.awardsList)

    self.losersList = ISScrollingListBox:new(
        10, self.awardsList:getY() + self.awardsList:getHeight() + 10,
        self.width - 20, 110)
    self.losersList:initialise()
    self.losersList:instantiate()
    self.losersList.itemheight = 22
    self.losersList.selected   = 0
    self.losersList.font       = UIFont.NewSmall
    self.losersList.doDrawItem = self.drawLoserItem
    self:addChild(self.losersList)

    local btnsY = self.losersList:getY() + self.losersList:getHeight() + 10

    self.closeButton = ISButton:new(
        self.width - 490, btnsY, btnWidth, btnHeight,
        getText("UI_close"), self, AwardsWelcomeUI.onCloseClick)
    self:addChild(self.closeButton)

    self.cleanButton = ISButton:new(
        self.closeButton:getX() + btnWidth + 10, btnsY, btnWidth, btnHeight,
        getText("UI_clean"), self, AwardsWelcomeUI.onCleanClick)
    self:addChild(self.cleanButton)

    self.cleanLoserButton = ISButton:new(
        self.cleanButton:getX() + btnWidth + 10, btnsY, btnWidth, btnHeight,
        getText("UI_clean_loser"), self, AwardsWelcomeUI.onCleanLoserClick)
    self:addChild(self.cleanLoserButton)
end

-- ---- Draw items ----

function AwardsWelcomeUI:drawAwardItem(y, item, alt)
    local a = 0.9
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15)
    end

    local iconSize = self.itemheight - 4
    local x = 5

    if item.item and item.item.icon then
        self:drawTextureScaledAspect(item.item.icon,
            x, y + (self.itemheight - iconSize) / 2,
            iconSize, iconSize, a, 1, 1, 1)
    end

    if item.item and item.item.name then
        self:drawText(item.item.name, x + iconSize + 8, y + 3, 1, 1, 1, a, self.font)
    end

    return y + self.itemheight
end

function AwardsWelcomeUI:drawLoserItem(y, item, alt)
    local a = 0.9
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawText(item.text, 10, y + 2, 1, 1, 1, a, self.font)
    return y + self.itemheight
end

-- ---- Button callbacks ----

function AwardsWelcomeUI:onCloseClick()
    self:setVisible(false)
    self:removeFromUIManager()
end

function AwardsWelcomeUI:onCleanClick()
    self.awardsList:clear()
end

function AwardsWelcomeUI:onCleanLoserClick()
    self.losersList:clear()
end

function AwardsWelcomeUI:onAwardDoubleClick()
    local idx = self.awardsList.selected
    if idx and idx > 0 then
        self.awardsList:removeItemByIndex(idx)
    end
end

-- ---- Add messages (called from awardsClient.lua) ----

function AwardsWelcomeUI:addAwardMessage(_item, _message)
    local limit = (Awards.Options and Awards.Options.limitWinningNumbers or 1) * 5
    local icon  = nil

    -- B41 style: InventoryItemFactory.CreateItem
    if _item then
        local ok, obj = pcall(InventoryItemFactory.CreateItem, _item)
        if ok and obj then
            icon = obj:getTex()
        end
    end

    self.awardsList:insertItem(1, _message, {icon = icon, name = _message})
    self.awardsList.selected = 1

    while self.awardsList:size() > limit do
        self.awardsList:removeItemByIndex(self.awardsList:size())
    end
end

function AwardsWelcomeUI:addLoserMessage(message)
    local limit = (Awards.Options and Awards.Options.limitLosingNumbers or 1) * 5

    self.losersList:insertItem(1, message, {})
    self.losersList.selected = 1

    while self.losersList:size() > limit do
        self.losersList:removeItemByIndex(self.losersList:size())
    end
end

-- ---- Constructor ----

function AwardsWelcomeUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index      = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor     = {r=0.7, g=0.7, b=0.7, a=0.5}
    o.moveWithMouse   = true
    return o
end

-- ---- Window factory ----

function CreateWelcomeWindow()
    if awardsWelcomeWindow then return end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width   = 500
    local height  = 380

    awardsWelcomeWindow = AwardsWelcomeUI:new(
        (screenW - width) / 2 + 400,
        (screenH - height) / 2,
        width, height)
    awardsWelcomeWindow:initialise()
    awardsWelcomeWindow:addToUIManager()
    awardsWelcomeWindow:setVisible(false)
end

-- ============================================================
--  HUD Button
-- ============================================================

AwardsHUDButton          = ISButton:derive("AwardsHUDButton")
AwardsHUDButton.instance = nil

function AwardsHUDButton:new(x, y, width, height)
    local o = ISButton:new(x, y, width, height, "", nil, function()
        if awardsWelcomeWindow and awardsWelcomeWindow:isVisible() then
            awardsWelcomeWindow:setVisible(false)
            awardsWelcomeWindow:removeFromUIManager()
        else
            if not awardsWelcomeWindow then
                CreateWelcomeWindow()
            end
            awardsWelcomeWindow:setVisible(true)
            awardsWelcomeWindow:addToUIManager()
        end
    end)
    setmetatable(o, self)
    self.__index = self
    o:setImage(getTexture("media/ui/icons/gift_regular_icon.png"))
    o.backgroundColor          = {r=0, g=0, b=0, a=0}
    o.backgroundColorMouseOver = {r=1, g=1, b=1, a=0.1}
    o.borderColor              = {r=0, g=0, b=0, a=0}
    return o
end

local function createHUDButton()
    if AwardsHUDButton.instance then return end
    local btnSize = 32
    local btn = AwardsHUDButton:new(getCore():getScreenWidth() - 50, 600, btnSize, btnSize)
    btn:setAnchorLeft(false)
    btn:setAnchorRight(true)
    btn:setAnchorTop(true)
    btn:setAnchorBottom(false)
    btn.tooltip = getText("UI_awards_button_tooltip")
    btn:initialise()
    btn:addToUIManager()
    AwardsHUDButton.instance = btn
end

-- ============================================================
--  Game start
-- ============================================================

local function OnGameStart()
    local tick
    tick = function()
        if not awardsWelcomeWindow then
            CreateWelcomeWindow()
        end
        Events.OnTick.Remove(tick)
    end
    Events.OnTick.Add(tick)
    createHUDButton()
end

Events.OnGameStart.Add(OnGameStart)

-- ============================================================
--  Public API used by awardsClient.lua
-- ============================================================

function AddAwardMessageToUI(_item, _message)
    if awardsWelcomeWindow then
        awardsWelcomeWindow:addAwardMessage(_item, _message)
    end
end

function AddLoserMessageToUI(message)
    if awardsWelcomeWindow then
        awardsWelcomeWindow:addLoserMessage(message)
    end
end

function AddAwardsLogMessage(message)
    -- Legacy stub kept for compatibility
end
