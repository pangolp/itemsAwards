--[[
    ItemsAwards - Player Prize Viewer (Build 42)

    Read-only modal that lists every configured prize and how to obtain it:
      - which dice number wins it (out of the current max dice)
      - the minimum zombie kills required
      - whether it drops on the zombie body or into the player inventory

    Available to ANY player (not just admins). Data is requested from the
    server via the public "getAwardsView" command; in single-player / host
    it is read directly from Awards.Data.
--]]

-- Guard: skip on dedicated server (no client context)
if isServer() and not isClient() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

AwardsViewUI          = ISPanel:derive("AwardsViewUI")
AwardsViewUI.instance = nil

local W     = 470
local H     = 450
local PAD   = 12
local BTN_H = 26
local ROW_H = 42

local function tx(k) return getText(k) end

-- Resolve an item type into its display name + inventory texture.
local function getItemInfo(itemType)
    local name, tex = itemType, nil
    pcall(function()
        local sm = getScriptManager()
        if sm then
            local s = sm:getItem(itemType)
            if s then
                tex  = s:getNormalTexture()
                name = s:getDisplayName() or itemType
            end
        end
    end)
    return name, tex
end

-- ============================================================
--  Construction
-- ============================================================

function AwardsViewUI:new(x, y)
    local o = ISPanel:new(x, y, W, H)
    setmetatable(o, self)
    self.__index      = self
    o.backgroundColor = {r=0.08, g=0.08, b=0.10, a=0.96}
    o.borderColor     = {r=0.5,  g=0.5,  b=0.5,  a=0.8}
    o.moveWithMouse   = true
    o._maxDice        = 100
    return o
end

function AwardsViewUI:initialise()
    ISPanel.initialise(self)
    self:buildUI()
end

function AwardsViewUI:buildUI()
    local listY = 78
    local listH = H - listY - PAD - BTN_H - PAD

    self.list = ISScrollingListBox:new(PAD, listY, W - PAD * 2, listH)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight = ROW_H
    self.list.selected   = 0
    self.list.font       = UIFont.NewSmall
    self.list.drawBorder = true
    self.list.doDrawItem = AwardsViewUI.drawRow
    self:addChild(self.list)

    self.closeBtn = ISButton:new(W - PAD - 110, H - PAD - BTN_H, 110, BTN_H,
        tx("UI_close"), self, AwardsViewUI.onCloseClick)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self:addChild(self.closeBtn)

    local texClose = getTexture("media/ui/icons/close.png")
    if texClose then
        local super = self.closeBtn.render
        function self.closeBtn:render()
            super(self)
            local s = self:getHeight() - 8
            self:drawTextureScaled(texClose, 4, (self:getHeight() - s) * 0.5, s, s, 0.85, 1, 1, 1)
        end
    end
end

-- ============================================================
--  Drawing
-- ============================================================

function AwardsViewUI:prerender()
    ISPanel.prerender(self)
    self:drawText(tx("UI_view_title"), PAD, PAD, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(tx("UI_view_subtitle"),  PAD, PAD + 26, 0.6, 0.75, 0.9, 1, UIFont.Small)
    self:drawText(tx("UI_view_subtitle2"), PAD, PAD + 42, 0.6, 0.75, 0.9, 1, UIFont.Small)
    if self.list and self.list:size() == 0 then
        self:drawText(tx("UI_view_empty"), PAD + 4, 86, 0.85, 0.6, 0.4, 1, UIFont.Small)
    end
end

function AwardsViewUI:drawRow(y, item, alt)
    local d = item.item
    local h = self.itemheight
    self:drawRectBorder(0, y, self:getWidth(), h - 1, 0.5,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)

    local pad    = 8
    local iconSz = h - 10
    local textX  = pad
    if d.tex then
        -- Aspect-preserving so non-square item icons (axes, bats…) are not
        -- stretched. Centered vertically and boxed into iconSz x iconSz.
        local iy = y + (h - iconSz) * 0.5
        self:drawTextureScaledAspect(d.tex, pad, iy, iconSz, iconSz, 1, 1, 1, 1)
        textX = pad + iconSz + pad
    end
    -- Line 1: item name + count
    self:drawText(d.title, textX, y + 7, 1, 1, 1, 1, self.font)
    -- Line 2: dice / kills / placement (gray)
    self:drawText(d.detail, textX, y + 22, 0.62, 0.74, 0.92, 1, self.font)
    return y + h
end

-- ============================================================
--  Data
-- ============================================================

function AwardsViewUI.onAwardsList(awards, maxDice)
    local inst = AwardsViewUI.instance
    if not inst then return end
    inst._maxDice = maxDice or 100
    inst:refreshList(awards or {})
end

function AwardsViewUI:refreshList(awards)
    self.list:clear()
    local maxD = self._maxDice or 100

    -- Sort by dice number so prizes read in roll order (low -> high).
    local sorted = {}
    for _, e in ipairs(awards) do sorted[#sorted + 1] = e end
    table.sort(sorted, function(a, b) return (a.Number or 0) < (b.Number or 0) end)

    for i, e in ipairs(sorted) do
        local name, tex = getItemInfo(e.Item)
        local placement = e.onZombie and tx("UI_view_drop_zombie") or tx("UI_view_drop_player")
        local detail = string.format("%s   %s   %s",
            getText("UI_view_dice",  e.Number, maxD),
            getText("UI_view_kills", e.zkills),
            placement)
        self.list:addItem(name, {
            title  = name .. "   x" .. tostring(e.Count),
            detail = detail,
            tex    = tex,
        })
    end
end

-- ============================================================
--  Callbacks
-- ============================================================

function AwardsViewUI:onCloseClick()
    self:setVisible(false)
    self:removeFromUIManager()
    AwardsViewUI.instance = nil
end

-- ============================================================
--  Public factory
-- ============================================================

-- Ask the server (or read locally in SP/host) for the current prize table.
local function requestAwards()
    if (not isClient() or isServer()) and Awards and Awards.Data then
        local list = {}
        for i, v in ipairs(Awards.Data.getAll()) do
            list[i] = {Item = v.Item, Number = v.Number, Count = v.Count, zkills = v.zkills, onZombie = v.onZombie}
        end
        AwardsViewUI.onAwardsList(list, Awards.Data.getMaxDice())
    else
        sendClientCommand(getPlayer(), "ItemsAwards", "getAwardsView", {})
    end
end

function OpenAwardsViewPanel()
    if AwardsViewUI.instance then
        AwardsViewUI.instance:setVisible(true)
        AwardsViewUI.instance:addToUIManager()
        requestAwards()
        return
    end
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local panel = AwardsViewUI:new((sw - W) / 2, (sh - H) / 2)
    panel:initialise()
    panel:addToUIManager()
    AwardsViewUI.instance = panel
    requestAwards()
end
