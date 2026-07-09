--[[
    ItemsAwards - UI Module (Build 42)

    Provides:
      - AwardsWelcomeUI        floating panel with winners/losers lists
      - AwardsHUDButton        HUD gift icon that toggles the panel
      - AddAwardMessageToUI()  public helper called by awardsClient.lua
      - AddLoserMessageToUI()  public helper called by awardsClient.lua
      - AddAwardsLogMessage()  legacy compatibility stub
--]]

-- Guard: B42 only. B41 may scan common/ subdirectories and reach this file.
if not PZAPI then return end

-- Guard: skip on dedicated server
if isServer() and not isClient() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

awardsWelcomeWindow = nil

local function applyIcon(btn, tex)
    if not tex then return end
    local super = btn.render
    function btn:render()
        super(self)
        local s  = self:getHeight() - 8
        local iy = (self:getHeight() - s) * 0.5
        self:drawTextureScaled(tex, 4, iy, s, s, 0.85, 1, 1, 1)
    end
end

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
    local PAD     = 10
    local btnH    = 25
    local actionW = 120   -- Clean wins / Clean lost
    local closeW  = 110
    local manageW = 130

    self.awardsList = ISScrollingListBox:new(PAD, 100, self.width - PAD * 2, 110)
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
        PAD, self.awardsList:getY() + self.awardsList:getHeight() + PAD,
        self.width - PAD * 2, 110)
    self.losersList:initialise()
    self.losersList:instantiate()
    self.losersList.itemheight = 22
    self.losersList.selected   = 0
    self.losersList.font       = UIFont.NewSmall
    self.losersList.doDrawItem = self.drawLoserItem
    self:addChild(self.losersList)

    local btnsY = self.losersList:getY() + self.losersList:getHeight() + PAD

    -- Left group: action buttons (clear lists)
    self.cleanButton = ISButton:new(
        PAD, btnsY, actionW, btnH,
        getText("UI_clean"), self, AwardsWelcomeUI.onCleanClick)
    self:addChild(self.cleanButton)

    self.cleanLoserButton = ISButton:new(
        PAD + actionW + PAD, btnsY, actionW, btnH,
        getText("UI_clean_loser"), self, AwardsWelcomeUI.onCleanLoserClick)
    self:addChild(self.cleanLoserButton)

    -- Right group: Close (far right), Manage Awards (left of Close, admin only)
    self.closeButton = ISButton:new(
        self.width - PAD - closeW, btnsY, closeW, btnH,
        getText("UI_close"), self, AwardsWelcomeUI.onCloseClick)
    self:addChild(self.closeButton)

    local p = getPlayer()
    local level = p and p:getAccessLevel() or ""
    local ok, sz = pcall(function() return getOnlinePlayers():size() end)
    local isSP = ok and sz ~= nil and sz <= 1
    if level == "admin" or level == "moderator" or isSP then
        self.manageButton = ISButton:new(
            self.closeButton:getX() - PAD - manageW, btnsY, manageW, btnH,
            getText("UI_admin_manage"), self, AwardsWelcomeUI.onManageClick)
        self:addChild(self.manageButton)
    end

    local texClean = getTexture("media/ui/icons/clean.png")
    local texClose = getTexture("media/ui/icons/close.png")
    applyIcon(self.cleanButton,      texClean)
    applyIcon(self.cleanLoserButton, texClean)
    applyIcon(self.closeButton,      texClose)
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

function AwardsWelcomeUI:onManageClick()
    if OpenAwardsAdminPanel then OpenAwardsAdminPanel() end
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
    local width   = 540
    local height  = 400

    awardsWelcomeWindow = AwardsWelcomeUI:new(
        (screenW - width) / 2 + 400,
        (screenH - height) / 2,
        width, height)
    awardsWelcomeWindow:initialise()
    awardsWelcomeWindow:addToUIManager()
    awardsWelcomeWindow:setVisible(false)
end

-- ============================================================
--  HUD Button (draggable, position persisted across sessions)
-- ============================================================

AwardsHUDButton          = ISButton:derive("AwardsHUDButton")
AwardsHUDButton.instance = nil

local HUD_BUTTON_POS_FILE = "ItemsAwards_hudButtonPos.txt"
local HUD_BUTTON_DRAG_THRESHOLD = 3

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function saveHUDButtonPosition(x, y)
    local writer = getFileWriter(HUD_BUTTON_POS_FILE, true, false)
    if not writer then return end
    writer:write(tostring(math.floor(x)) .. "\n")
    writer:write(tostring(math.floor(y)) .. "\n")
    writer:close()
end

local function loadHUDButtonPosition()
    local reader = getFileReader(HUD_BUTTON_POS_FILE, true)
    if not reader then return nil, nil end
    local lineX = reader:readLine()
    local lineY = reader:readLine()
    reader:close()
    return lineX and tonumber(lineX), lineY and tonumber(lineY)
end

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
    o.dragging                 = false
    o.dragMoved                = false
    return o
end

-- ---- Drag handling: hold the icon and move it; a plain click still
--      toggles the panel as before.
--
--      The button's own onMouseMove only fires while the cursor stays
--      over it, so a fast mouse movement outruns a small 32x32 icon
--      and the drag freezes. Instead, track the absolute mouse
--      position every tick (independent of hover) while dragging. ----

function AwardsHUDButton:onMouseDown(x, y)
    self.dragging        = true
    self.dragMoved        = false
    self.dragStartMouseX = getMouseX()
    self.dragStartMouseY = getMouseY()
    self.dragStartBtnX   = self:getX()
    self.dragStartBtnY   = self:getY()
    ISButton.onMouseDown(self, x, y)
end

function AwardsHUDButton:onMouseUp(x, y)
    self.dragging = false
    if self.dragMoved then
        self.dragMoved = false
        saveHUDButtonPosition(self:getX(), self:getY())
        return
    end
    ISButton.onMouseUp(self, x, y)
end

function AwardsHUDButton:onMouseUpOutside(x, y)
    self.dragging = false
    if self.dragMoved then
        self.dragMoved = false
        saveHUDButtonPosition(self:getX(), self:getY())
    end
    if ISButton.onMouseUpOutside then
        ISButton.onMouseUpOutside(self, x, y)
    end
end

local function updateHUDButtonDrag()
    local btn = AwardsHUDButton.instance
    if not btn or not btn.dragging then return end

    local totalDX = getMouseX() - btn.dragStartMouseX
    local totalDY = getMouseY() - btn.dragStartMouseY

    if math.abs(totalDX) > HUD_BUTTON_DRAG_THRESHOLD or math.abs(totalDY) > HUD_BUTTON_DRAG_THRESHOLD then
        btn.dragMoved = true
    end

    local maxX = getCore():getScreenWidth()  - btn:getWidth()
    local maxY = getCore():getScreenHeight() - btn:getHeight()
    btn:setX(clamp(btn.dragStartBtnX + totalDX, 0, maxX))
    btn:setY(clamp(btn.dragStartBtnY + totalDY, 0, maxY))
end

Events.OnTick.Add(updateHUDButtonDrag)

local function createHUDButton()
    if AwardsHUDButton.instance then return end
    local btnSize = 32

    -- Default to the top-left corner: always on screen regardless of
    -- resolution. Once the player drags the icon, the saved spot is
    -- used instead (also clamped, in case the resolution changed since).
    local maxX = getCore():getScreenWidth()  - btnSize
    local maxY = getCore():getScreenHeight() - btnSize
    local savedX, savedY = loadHUDButtonPosition()
    local x = clamp(savedX or 10, 0, maxX)
    local y = clamp(savedY or 10, 0, maxY)

    -- No anchors: the button is positioned/persisted manually via drag,
    -- and anchoring it to an edge fights setX()/setY() while dragging.
    local btn = AwardsHUDButton:new(x, y, btnSize, btnSize)
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
