--[[
    ItemsAwards - Admin Panel (Build 41)
    CRUD interface for the awards table.
    Only reachable by players with admin/moderator access (or in single-player).
--]]

if isServer() and not isClient() then return end

require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISLabel"

-- ============================================================
AwardsAdminUI          = ISPanel:derive("AwardsAdminUI")
AwardsAdminUI.instance = nil

local W           = 560
local H           = 440
local PAD         = 10
local ROW_H       = 22
local BTN_W       = 110
local BTN_H       = 24
local FIELD_H     = 22
local LIST_H      = 165

local function tx(key) return getText(key) end

-- ---- Helpers ----

local function sendToServer(command, args)
    sendClientCommand(getPlayer(), "ItemsAwards", command, args or {})
end

local function localPlayerIsAdmin()
    local p = getPlayer()
    if not p then return false end
    local level = p:getAccessLevel()
    if level == "admin" or level == "moderator" then return true end
    local online = getOnlinePlayers()
    return online and online:size() <= 1
end

-- ---- Public: called from awardsClient when server sends awardsList ----

function AwardsAdminUI.onAwardsList(awards)
    if AwardsAdminUI.instance then
        AwardsAdminUI.instance:refreshList(awards)
    end
end

-- ============================================================
--  Construction
-- ============================================================

function AwardsAdminUI:new(x, y)
    local o = ISPanel:new(x, y, W, H)
    setmetatable(o, self)
    self.__index      = self
    o.backgroundColor = {r = 0.08, g = 0.08, b = 0.08, a = 0.95}
    o.borderColor     = {r = 0.6,  g = 0.6,  b = 0.6,  a = 0.5}
    o.moveWithMouse   = true
    o._editIndex      = nil
    o._onZombieValue  = false
    return o
end

function AwardsAdminUI:initialise()
    ISPanel.initialise(self)
    self:createUI()
end

function AwardsAdminUI:createUI()
    local x      = PAD
    local labelW = 90
    local entryX = x + labelW + 5
    local entryW = W - entryX - PAD

    -- ---- List ----
    local listY = 38
    self.list = ISScrollingListBox:new(PAD, listY, W - PAD * 2, LIST_H)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight   = ROW_H
    self.list.selected     = 0
    self.list.font         = UIFont.NewSmall
    self.list.doDrawItem   = AwardsAdminUI.drawRow
    self.list:setOnMouseDoubleClick(self, AwardsAdminUI.onRowDoubleClick)
    self:addChild(self.list)

    -- ---- Form ----
    local fY = listY + LIST_H + 14

    -- Item
    self:addChild(ISLabel:new(x, fY + 3, FIELD_H, tx("UI_admin_item") .. ":", false, 1, 1, 1, 1, UIFont.Small, true))
    self.itemEntry = ISTextEntryBox:new("", entryX, fY, entryW, FIELD_H)
    self.itemEntry:initialise()
    self.itemEntry:instantiate()
    self.itemEntry:setMaxLines(1)
    self:addChild(self.itemEntry)
    fY = fY + FIELD_H + 8

    -- Number / Count / Kills (one row)
    local shortW = 50
    local col2 = x + labelW + 5 + shortW + 10
    local col3 = col2 + labelW + 5 + shortW + 10

    self:addChild(ISLabel:new(x, fY + 3, labelW, tx("UI_admin_number") .. ":", false, 1, 1, 1, 1, UIFont.Small, true))
    self.numberEntry = ISTextEntryBox:new("", x + labelW + 5, fY, shortW, FIELD_H)
    self.numberEntry:initialise()
    self.numberEntry:instantiate()
    self.numberEntry:setMaxLines(1)
    self:addChild(self.numberEntry)

    self:addChild(ISLabel:new(col2, fY + 3, labelW, tx("UI_admin_count") .. ":", false, 1, 1, 1, 1, UIFont.Small, true))
    self.countEntry = ISTextEntryBox:new("", col2 + labelW + 5, fY, shortW, FIELD_H)
    self.countEntry:initialise()
    self.countEntry:instantiate()
    self.countEntry:setMaxLines(1)
    self:addChild(self.countEntry)

    self:addChild(ISLabel:new(col3, fY + 3, labelW, tx("UI_admin_zkills") .. ":", false, 1, 1, 1, 1, UIFont.Small, true))
    self.zkillsEntry = ISTextEntryBox:new("", col3 + labelW + 5, fY, shortW, FIELD_H)
    self.zkillsEntry:initialise()
    self.zkillsEntry:instantiate()
    self.zkillsEntry:setMaxLines(1)
    self:addChild(self.zkillsEntry)
    fY = fY + FIELD_H + 8

    -- On zombie toggle
    self:addChild(ISLabel:new(x, fY + 3, labelW, tx("UI_admin_onZombie") .. ":", false, 1, 1, 1, 1, UIFont.Small, true))
    self.onZombieBtn = ISButton:new(x + labelW + 5, fY, 60, BTN_H, tx("UI_admin_no"), self, AwardsAdminUI.onToggleZombie)
    self.onZombieBtn:initialise()
    self.onZombieBtn:instantiate()
    self:addChild(self.onZombieBtn)
    fY = fY + BTN_H + 12

    -- ---- Action buttons ----
    self.addBtn = ISButton:new(PAD, fY, BTN_W, BTN_H, tx("UI_admin_add"), self, AwardsAdminUI.onAddClick)
    self.addBtn:initialise()
    self.addBtn:instantiate()
    self:addChild(self.addBtn)

    self.saveBtn = ISButton:new(PAD + BTN_W + 8, fY, BTN_W, BTN_H, tx("UI_admin_save"), self, AwardsAdminUI.onSaveClick)
    self.saveBtn:initialise()
    self.saveBtn:instantiate()
    self:addChild(self.saveBtn)

    self.deleteBtn = ISButton:new(PAD + (BTN_W + 8) * 2, fY, BTN_W, BTN_H, tx("UI_admin_delete"), self, AwardsAdminUI.onDeleteClick)
    self.deleteBtn:initialise()
    self.deleteBtn:instantiate()
    self:addChild(self.deleteBtn)
    fY = fY + BTN_H + 10

    -- Reload + Close
    self.reloadBtn = ISButton:new(PAD, fY, BTN_W, BTN_H, tx("UI_admin_reload"), self, AwardsAdminUI.onReloadClick)
    self.reloadBtn:initialise()
    self.reloadBtn:instantiate()
    self:addChild(self.reloadBtn)

    self.closeBtn = ISButton:new(W - PAD - BTN_W, fY, BTN_W, BTN_H, tx("UI_close"), self, AwardsAdminUI.onCloseClick)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self:addChild(self.closeBtn)
end

-- ============================================================
--  Drawing
-- ============================================================

function AwardsAdminUI:prerender()
    ISPanel.prerender(self)
    self:drawText(tx("UI_admin_panel_title"), PAD, 10, 1, 1, 1, 1, UIFont.Medium)
end

function AwardsAdminUI:drawRow(y, item, alt)
    local a = 0.9
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)
    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.2, 0.6, 0.8)
    end
    if item.item then
        self:drawText(item.text, 6, y + 3, 1, 1, 1, a, self.font)
    end
    return y + self.itemheight
end

-- ============================================================
--  List management
-- ============================================================

function AwardsAdminUI:refreshList(awards)
    self.list:clear()
    for i, e in ipairs(awards) do
        local label = string.format("[%d] %s  ×%d  kills>=%d  %s",
            e.Number, e.Item, e.Count, e.zkills,
            e.onZombie and "[Zombie]" or "[Inv]")
        self.list:insertItem(i, label, {index = i, data = e})
    end
end

function AwardsAdminUI:getSelectedEntry()
    local idx = self.list.selected
    if not idx or idx <= 0 then return nil, nil end
    local item = self.list:getItem(idx)
    if not item or not item.item then return nil, nil end
    return item.item.index, item.item.data
end

-- ============================================================
--  Form helpers
-- ============================================================

function AwardsAdminUI:fillForm(entry)
    self.itemEntry:setText(entry.Item or "")
    self.numberEntry:setText(tostring(entry.Number or ""))
    self.countEntry:setText(tostring(entry.Count or "1"))
    self.zkillsEntry:setText(tostring(entry.zkills or "1"))
    self._onZombieValue = entry.onZombie == true
    self.onZombieBtn:setTitle(self._onZombieValue and tx("UI_admin_yes") or tx("UI_admin_no"))
end

function AwardsAdminUI:clearForm()
    self.itemEntry:setText("")
    self.numberEntry:setText("")
    self.countEntry:setText("1")
    self.zkillsEntry:setText("1")
    self._onZombieValue = false
    self.onZombieBtn:setTitle(tx("UI_admin_no"))
    self._editIndex = nil
    self.list.selected = 0
end

function AwardsAdminUI:readForm()
    local item   = self.itemEntry:getText()
    local number = tonumber(self.numberEntry:getText())
    local count  = tonumber(self.countEntry:getText())
    local zkills = tonumber(self.zkillsEntry:getText())
    if not item or item == "" then return nil end
    if not number or number < 1 or number > 100 then return nil end
    if not count  or count  < 1 then return nil end
    if not zkills or zkills < 0 then return nil end
    return {
        Item     = item,
        Number   = math.floor(number),
        Count    = math.floor(count),
        zkills   = math.floor(zkills),
        onZombie = self._onZombieValue,
    }
end

-- ============================================================
--  Callbacks
-- ============================================================

function AwardsAdminUI:onToggleZombie()
    self._onZombieValue = not self._onZombieValue
    self.onZombieBtn:setTitle(self._onZombieValue and tx("UI_admin_yes") or tx("UI_admin_no"))
end

function AwardsAdminUI:onRowDoubleClick()
    local _, entry = self:getSelectedEntry()
    if entry then
        self._editIndex = entry.index
        self:fillForm(entry.data)
    end
end

function AwardsAdminUI:onAddClick()
    local entry = self:readForm()
    if not entry then return end
    sendToServer("addAward", entry)
    self:clearForm()
end

function AwardsAdminUI:onSaveClick()
    if not self._editIndex then return end
    local entry = self:readForm()
    if not entry then return end
    entry.index = self._editIndex
    sendToServer("updateAward", entry)
    self:clearForm()
end

function AwardsAdminUI:onDeleteClick()
    local idx = self._editIndex
    if not idx then
        local selIdx = self.list.selected
        if not selIdx or selIdx <= 0 then return end
        local item = self.list:getItem(selIdx)
        if item and item.item then idx = item.item.index end
    end
    if not idx then return end
    sendToServer("deleteAward", {index = idx})
    self:clearForm()
end

function AwardsAdminUI:onReloadClick()
    sendToServer("reloadAwards", {})
end

function AwardsAdminUI:onCloseClick()
    self:setVisible(false)
    self:removeFromUIManager()
    AwardsAdminUI.instance = nil
end

-- ============================================================
--  Public factory
-- ============================================================

function OpenAwardsAdminPanel()
    if not localPlayerIsAdmin() then return end
    if AwardsAdminUI.instance then
        AwardsAdminUI.instance:setVisible(true)
        AwardsAdminUI.instance:addToUIManager()
        sendToServer("getAwards", {})
        return
    end
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local panel = AwardsAdminUI:new((screenW - W) / 2, (screenH - H) / 2)
    panel:initialise()
    panel:addToUIManager()
    AwardsAdminUI.instance = panel
    sendToServer("getAwards", {})
end
