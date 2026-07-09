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

local W       = 610
local H       = 440
local PAD     = 12
local BTN_H   = 24
local FIELD_H = 24
local COL_SEP = 295   -- x where the right column starts
local LIST_H  = 255

-- ---- Helpers ----

local function tx(key) return getText(key) end

local function localPlayerIsAdmin()
    local p = getPlayer()
    if not p then return false end
    local level = p:getAccessLevel()
    if level == "admin" or level == "moderator" then return true end
    local online = getOnlinePlayers()
    return online and online:size() <= 1
end

-- In single-player, isServer() is true in the same process as the client.
-- sendClientCommand() has no network to cross, so we call Awards.Data directly.
local function sendToServer(command, args)
    if isServer() and Awards and Awards.Data then
        local d = args or {}
        if command == "addAward" then
            if d.Item and d.Number then
                Awards.Data.add({
                    Item     = tostring(d.Item),
                    Number   = tonumber(d.Number) or 0,
                    Count    = tonumber(d.Count)  or 1,
                    zkills   = tonumber(d.zkills) or 1,
                    onZombie = d.onZombie == true,
                })
            end
        elseif command == "updateAward" then
            if d.index then
                Awards.Data.update(tonumber(d.index), {
                    Item     = tostring(d.Item),
                    Number   = tonumber(d.Number) or 0,
                    Count    = tonumber(d.Count)  or 1,
                    zkills   = tonumber(d.zkills) or 1,
                    onZombie = d.onZombie == true,
                })
            end
        elseif command == "deleteAward" then
            if d.index then Awards.Data.remove(tonumber(d.index)) end
        elseif command == "reloadAwards" then
            Awards.Data.load()
        end
        -- Refresh panel directly after any change
        if AwardsAdminUI.instance then
            local list = {}
            for i, v in ipairs(Awards.Data.getAll()) do
                list[i] = {Item=v.Item, Number=v.Number, Count=v.Count, zkills=v.zkills, onZombie=v.onZombie}
            end
            AwardsAdminUI.instance:refreshList(list)
        end
    else
        sendClientCommand(getPlayer(), "ItemsAwards", command, args or {})
    end
end

-- ---- Public: called from awardsClient when server sends awardsList (MP) ----

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
    o.backgroundColor = {r=0.08, g=0.08, b=0.10, a=0.96}
    o.borderColor     = {r=0.5,  g=0.5,  b=0.5,  a=0.8}
    o.moveWithMouse   = true
    o._editIndex      = nil
    o._onZombieValue  = false
    return o
end

function AwardsAdminUI:initialise()
    ISPanel.initialise(self)
    self:buildUI()
end

function AwardsAdminUI:buildUI()
    local leftW  = COL_SEP - PAD * 2          -- 271
    local rightX = COL_SEP + PAD              -- 307
    local rightW = W - rightX - PAD           -- 291
    local entryW = rightW                      -- full right column width for item entry
    local shortW = 60

    -- ===== LEFT COLUMN: list =====
    local lY = 42

    self.list = ISScrollingListBox:new(PAD, lY, leftW, LIST_H)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight   = 22
    self.list.selected     = 0
    self.list.font         = UIFont.NewSmall
    self.list.doDrawItem   = AwardsAdminUI.drawRow
    self.list:setOnMouseDoubleClick(self, AwardsAdminUI.onRowDoubleClick)
    self:addChild(self.list)

    local deleteY = lY + LIST_H + 8
    self.deleteBtn = ISButton:new(PAD, deleteY, leftW, BTN_H,
        tx("UI_admin_delete"), self, AwardsAdminUI.onDeleteClick)
    self.deleteBtn:initialise()
    self.deleteBtn:instantiate()
    self:addChild(self.deleteBtn)

    -- ===== RIGHT COLUMN: form =====
    local fY = 42

    -- Item type
    self:addChild(ISLabel:new(rightX, fY, FIELD_H, tx("UI_admin_item") .. ":", 0.8, 0.8, 0.8, 1, UIFont.Small, true))
    fY = fY + 20
    self.itemEntry = ISTextEntryBox:new("", rightX, fY, rightW, FIELD_H)
    self.itemEntry:initialise()
    self.itemEntry:instantiate()
    self.itemEntry:setMaxLines(1)
    self:addChild(self.itemEntry)
    fY = fY + FIELD_H + 10

    -- Number
    self:addChild(ISLabel:new(rightX, fY, FIELD_H, tx("UI_admin_number") .. ":", 0.8, 0.8, 0.8, 1, UIFont.Small, true))
    fY = fY + 20
    self.numberEntry = ISTextEntryBox:new("", rightX, fY, shortW, FIELD_H)
    self.numberEntry:initialise()
    self.numberEntry:instantiate()
    self.numberEntry:setMaxLines(1)
    self:addChild(self.numberEntry)
    fY = fY + FIELD_H + 10

    -- Count
    self:addChild(ISLabel:new(rightX, fY, FIELD_H, tx("UI_admin_count") .. ":", 0.8, 0.8, 0.8, 1, UIFont.Small, true))
    fY = fY + 20
    self.countEntry = ISTextEntryBox:new("", rightX, fY, shortW, FIELD_H)
    self.countEntry:initialise()
    self.countEntry:instantiate()
    self.countEntry:setMaxLines(1)
    self:addChild(self.countEntry)
    fY = fY + FIELD_H + 10

    -- Min kills
    self:addChild(ISLabel:new(rightX, fY, FIELD_H, tx("UI_admin_zkills") .. ":", 0.8, 0.8, 0.8, 1, UIFont.Small, true))
    fY = fY + 20
    self.zkillsEntry = ISTextEntryBox:new("", rightX, fY, shortW, FIELD_H)
    self.zkillsEntry:initialise()
    self.zkillsEntry:instantiate()
    self.zkillsEntry:setMaxLines(1)
    self:addChild(self.zkillsEntry)
    fY = fY + FIELD_H + 10

    -- On zombie toggle
    self:addChild(ISLabel:new(rightX, fY, FIELD_H, tx("UI_admin_onZombie") .. ":", 0.8, 0.8, 0.8, 1, UIFont.Small, true))
    fY = fY + 20
    self.onZombieBtn = ISButton:new(rightX, fY, 70, BTN_H,
        tx("UI_admin_no"), self, AwardsAdminUI.onToggleZombie)
    self.onZombieBtn:initialise()
    self.onZombieBtn:instantiate()
    self:addChild(self.onZombieBtn)
    fY = fY + BTN_H + 14

    -- Add / Save
    self.addBtn = ISButton:new(rightX, fY, (rightW - 8) / 2, BTN_H,
        tx("UI_admin_add"), self, AwardsAdminUI.onAddClick)
    self.addBtn:initialise()
    self.addBtn:instantiate()
    self:addChild(self.addBtn)

    self.saveBtn = ISButton:new(rightX + (rightW - 8) / 2 + 8, fY, (rightW - 8) / 2, BTN_H,
        tx("UI_admin_save"), self, AwardsAdminUI.onSaveClick)
    self.saveBtn:initialise()
    self.saveBtn:instantiate()
    self:addChild(self.saveBtn)

    -- ===== BOTTOM BAR =====
    local botY = H - BTN_H - PAD
    self.reloadBtn = ISButton:new(PAD, botY, 160, BTN_H,
        tx("UI_admin_reload"), self, AwardsAdminUI.onReloadClick)
    self.reloadBtn:initialise()
    self.reloadBtn:instantiate()
    self:addChild(self.reloadBtn)

    self.closeBtn = ISButton:new(W - PAD - 100, botY, 100, BTN_H,
        tx("UI_close"), self, AwardsAdminUI.onCloseClick)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self:addChild(self.closeBtn)

    self:clearForm()
end

-- ============================================================
--  Drawing
-- ============================================================

function AwardsAdminUI:prerender()
    ISPanel.prerender(self)

    -- Title
    self:drawText(tx("UI_admin_panel_title"), PAD, PAD, 1, 1, 1, 1, UIFont.Medium)

    -- Column headers
    self:drawText(tx("UI_admin_list_header"), PAD, 28, 0.6, 0.8, 1, 1, UIFont.Small)
    self:drawText(tx("UI_admin_form_header"), COL_SEP + PAD, 28, 0.6, 0.8, 1, 1, UIFont.Small)

    -- Vertical separator
    local sepTop  = 26
    local sepBot  = H - BTN_H - PAD - 6
    self:drawRect(COL_SEP, sepTop, 1, sepBot - sepTop, 0.6, 0.4, 0.4, 0.4)

    -- Horizontal separator above bottom bar
    self:drawRect(PAD, H - BTN_H - PAD - 6, W - PAD * 2, 1, 0.6, 0.4, 0.4, 0.4)

    -- Edit hint
    if self._editIndex then
        self:drawText("# " .. self._editIndex, COL_SEP + PAD, H - BTN_H - PAD + 3, 0.5, 1, 0.5, 0.9, UIFont.Small)
    end
end

function AwardsAdminUI:drawRow(y, item, alt)
    local a = 0.9
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a,
        self.borderColor.r, self.borderColor.g, self.borderColor.b)
    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.5, 0.1, 0.4, 0.7)
    end
    if item.item then
        self:drawText(item.text, 6, y + 3, 1, 1, 1, a, self.font)
    end
    return y + self.itemheight
end

-- ============================================================
--  List
-- ============================================================

function AwardsAdminUI:refreshList(awards)
    self.list:clear()
    for i, e in ipairs(awards) do
        local label = string.format("[%d] %s  x%d  kills>=%d  %s",
            e.Number, e.Item, e.Count, e.zkills,
            e.onZombie and "[Zombie]" or "[Inv]")
        self.list:insertItem(i, label, {index = i, data = e})
    end
end

-- ============================================================
--  Form
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
    if not item or item == ""               then return nil end
    if not number or number < 1 or number > 100 then return nil end
    if not count  or count  < 1             then return nil end
    if not zkills or zkills < 0             then return nil end
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
    local idx = self.list.selected
    if not idx or idx <= 0 then return end
    local listItem = self.list.items[idx]
    if not listItem or not listItem.item then return end
    self._editIndex = listItem.item.index
    self:fillForm(listItem.item.data)
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
        local listItem = self.list.items[selIdx]
        if listItem and listItem.item then idx = listItem.item.index end
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
        sendToServer("reloadAwards", {})
        return
    end
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local panel = AwardsAdminUI:new((sw - W) / 2, (sh - H) / 2)
    panel:initialise()
    panel:addToUIManager()
    AwardsAdminUI.instance = panel
    sendToServer("reloadAwards", {})
end
