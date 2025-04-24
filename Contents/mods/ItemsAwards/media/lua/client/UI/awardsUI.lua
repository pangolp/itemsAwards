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
    local btnWidth = 100
    local btnHeight = 25

    self.awardsList = ISScrollingListBox:new(10, 100, self.width - 20, 110)
    self.awardsList:initialise()
    self.awardsList:instantiate()
    self.awardsList.itemheight = 22
    self.awardsList.selected = 0
    self.awardsList.joypadParent = self
    self.awardsList.font = UIFont.NewSmall
    self.awardsList.doDrawItem = self.drawAwardItem
    self:addChild(self.awardsList)

    self.losersList = ISScrollingListBox:new(10, self.awardsList:getY() + self.awardsList:getHeight() + 10, self.width - 20, 110)
    self.losersList:initialise()
    self.losersList:instantiate()
    self.losersList.itemheight = 22
    self.awardsList.selected = 0
    self.losersList.font = UIFont.NewSmall
    self.losersList.doDrawItem = self.drawLoserItem
    self:addChild(self.losersList)

    self.closeButton = ISButton:new(
        self.width - 490,
        self.losersList:getY() + self.losersList:getHeight() + 10,
        btnWidth,
        btnHeight,
        getText("UI_Close"),
        self,
        AwardsWelcomeUI.onCloseClick
    )

    self:addChild(self.closeButton)

    self.cleanButton = ISButton:new(
        self.closeButton:getX() + btnWidth + 10,
        self.losersList:getY() + self.losersList:getHeight() + 10,
        btnWidth,
        btnHeight,
        getText("UI_clean"),
        self,
        AwardsWelcomeUI.onCleanClick
    )

    self:addChild(self.cleanButton)

    self.cleanLoserButton = ISButton:new(
        self.cleanButton:getX() + btnWidth + 10,
        self.losersList:getY() + self.losersList:getHeight() + 10,
        btnWidth,
        btnHeight,
        getText("UI_clean_loser"),
        self,
        AwardsWelcomeUI.onCleanLoserClick
    )

    self:addChild(self.cleanLoserButton)
end

function AwardsWelcomeUI:drawAwardItem(y, item, alt)
    local a = 0.9
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15)
    end

    local iconSize = (self.itemheight - 4)
    local x = 5

    if item.item and item.item.icon then
        self:drawTextureScaledAspect(item.item.icon, x, y + (self.itemheight - iconSize) / 2, iconSize, iconSize, a, 1, 1, 1)
    end

    local nameX = x + iconSize + 8
    if item.item and item.item.name then
        self:drawText(item.item.name, nameX, y + 3, 1, 1, 1, a, self.font)
    end

    if item.item and item.item.count and tostring(item.item.count) ~= "" then
        local countText = "x" .. tostring(item.item.count)
        local countX = self:getWidth() - 40 - getTextManager():MeasureStringX(self.font, countText)
        self:drawText(countText, countX, y + 6, 1, 1, 1, a, self.font)
    end

    return y + self.itemheight
end

function AwardsWelcomeUI:drawLoserItem(y, item, alt)
    local a = 0.9
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawText(item.text, 10, y + 2, 1, 1, 1, a, self.font)
    return y + self.itemheight
end

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

function AwardsWelcomeUI:addAwardMessage(_item, _message)
    local limit = Awards.Options.limitWinningNumbers * 5
    local icon, name, count = nil, _message, ""

    if _item then
        local item = InventoryItemFactory.CreateItem(_item)
        if item then
            icon = item:getTex()
            name = item:getDisplayName()
        end
    end

    local qty = string.match(_message, " x(%d+)")
    if qty then count = qty end

    self.awardsList:insertItem(1, name, {icon = icon, name = name, count = count})
    self.awardsList.selected = 1

    while self.awardsList:size() > limit do
        self.awardsList:removeItemByIndex(self.awardsList:size())
    end
end

function AwardsWelcomeUI:addLoserMessage(message)

    local limit = Awards.Options.limitLosingNumbers * 5

    self.losersList:insertItem(1, message, {})
    self.losersList.selected = 1

    while self.losersList:size() > limit do
        self.losersList:removeItemByIndex(self.losersList:size())
    end

end

function AwardsWelcomeUI:new(x, y, width, height)
    local o = {}
    o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
    o.moveWithMouse = true
    return o
end

function CreateWelcomeWindow()
    if awardsWelcomeWindow then return end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = 500
    local height = 380
    local x = (screenW - width) / 2 + 400
    local y = (screenH - height) / 2

    awardsWelcomeWindow = AwardsWelcomeUI:new(x, y, width, height)
    awardsWelcomeWindow:initialise()
    awardsWelcomeWindow:addToUIManager()
    awardsWelcomeWindow:setVisible(false)
end

AwardsHUDButton = ISButton:derive("AwardsHUDButton")
AwardsHUDButton.instance = nil

function AwardsHUDButton:new(x, y, width, height)

    local o = ISButton:new(x, y, width, height, "", nil, function()
        if awardsWelcomeWindow and awardsWelcomeWindow:isVisible() then
            awardsWelcomeWindow:setVisible(false)
            awardsWelcomeWindow:removeFromUIManager()
        else
            if not awardsWelcomeWindow then
                CreateWelcomeWindow()
            else
                awardsWelcomeWindow:setVisible(true)
                awardsWelcomeWindow:addToUIManager()
            end
        end
    end)

    setmetatable(o, self)
    self.__index = self

    o:setImage(getTexture("media/ui/icons/gift_regular_icon.png"))
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.backgroundColorMouseOver = {r=1, g=1, b=1, a=0.1}
    o.borderColor = {r=0, g=0, b=0, a=0}
    return o
end

local function createHUDButton()
    if AwardsHUDButton.instance then return end
    local btnSize = 32
    local x = getCore():getScreenWidth() - 50
    local y = 600

    local btn = AwardsHUDButton:new(x, y, btnSize, btnSize)
    btn:setAnchorLeft(false)
    btn:setAnchorRight(true)
    btn:setAnchorTop(true)
    btn:setAnchorBottom(false)
    btn.tooltip = getText("UI_awards_button_tooltip")
    btn:initialise()
    btn:addToUIManager()
    AwardsHUDButton.instance = btn
end

local function OnGameStart()

    Events.OnTick.Add(function()
        if not awardsWelcomeWindow then
            CreateWelcomeWindow()
            Events.OnTick.Remove(this)
        end
    end)

    createHUDButton()
end

Events.OnGameStart.Add(OnGameStart)

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
