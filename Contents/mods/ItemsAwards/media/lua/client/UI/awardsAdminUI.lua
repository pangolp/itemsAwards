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

local W        = 610
local H        = 520
local STATUS_H = 56
local PAD      = 12
local BTN_H    = 24
local FIELD_H  = 24
local COL_SEP  = 295
local LIST_H   = 285
local ROW_H    = 24

-- ---- Helpers ----

local function tx(key) return getText(key) end

local function localPlayerIsAdmin()
    local p = getPlayer()
    if not p then return false end
    local level = p:getAccessLevel()
    if level == "admin" or level == "moderator" then return true end
    return not isClient()
end

local function itemExists(itemType)
    local ok, found = pcall(function()
        local sm = getScriptManager()
        return sm ~= nil and sm:getItem(itemType) ~= nil
    end)
    return ok and found == true
end

local function getItemTex(itemType)
    local tex = nil
    pcall(function()
        local sm = getScriptManager()
        if sm then
            local s = sm:getItem(itemType)
            if s then tex = s:getNormalTexture() end
        end
    end)
    return tex
end

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

local function sendToServer(command, args)
    if isServer() and Awards and Awards.Data then
        local d = args or {}
        if command == "addAward" then
            if d.Item and d.Number then
                local n = tonumber(d.Number) or 0
                if n >= 1 and n <= Awards.Data.getMaxDice() then
                    Awards.Data.add({
                        Item     = tostring(d.Item),
                        Number   = n,
                        Count    = tonumber(d.Count)  or 1,
                        zkills   = tonumber(d.zkills) or 1,
                        onZombie = d.onZombie == true,
                    })
                end
            end
        elseif command == "updateAward" then
            if d.index then
                local n = tonumber(d.Number) or 0
                if n >= 1 and n <= Awards.Data.getMaxDice() then
                    Awards.Data.update(tonumber(d.index), {
                        Item     = tostring(d.Item),
                        Number   = n,
                        Count    = tonumber(d.Count)  or 1,
                        zkills   = tonumber(d.zkills) or 1,
                        onZombie = d.onZombie == true,
                    })
                end
            end
        elseif command == "deleteAward" then
            if d.index then Awards.Data.remove(tonumber(d.index)) end
        elseif command == "reloadAwards" then
            Awards.Data.load()
        elseif command == "setMaxDice" then
            Awards.Data.setMaxDice(tonumber(d.value))
        end
        if AwardsAdminUI.instance then
            local inst = AwardsAdminUI.instance
            local list = {}
            for i, v in ipairs(Awards.Data.getAll()) do
                list[i] = {Item=v.Item, Number=v.Number, Count=v.Count, zkills=v.zkills, onZombie=v.onZombie}
            end
            inst:refreshList(list)
            inst._maxDice = Awards.Data.getMaxDice()
            if inst.maxDiceEntry then
                inst.maxDiceEntry:setText(tostring(inst._maxDice))
            end
        end
    else
        sendClientCommand(getPlayer(), "ItemsAwards", command, args or {})
    end
end

function AwardsAdminUI.onAwardsList(awards, maxDice)
    if AwardsAdminUI.instance then
        local inst = AwardsAdminUI.instance
        inst._maxDice = maxDice or 100
        if inst.maxDiceEntry then
            inst.maxDiceEntry:setText(tostring(inst._maxDice))
        end
        inst:refreshList(awards)
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
    o._statusMsg      = nil
    o._statusIsErr    = false
    o._maxDice        = 100
    return o
end

function AwardsAdminUI:initialise()
    ISPanel.initialise(self)
    self:buildUI()
end

function AwardsAdminUI:buildUI()
    local leftW   = COL_SEP - PAD * 2
    local rightX  = COL_SEP + PAD
    local rightW  = W - rightX - PAD
    local shortW  = 60
    local LABEL_GAP = 4
    local FIELD_GAP = 10

    -- ===== LEFT COLUMN =====
    local lY = 55

    self.list = ISScrollingListBox:new(PAD, lY, leftW, LIST_H)
    self.list:initialise()
    self.list:instantiate()
    self.list.itemheight   = ROW_H
    self.list.selected     = 0
    self.list.font         = UIFont.NewSmall
    self.list.doDrawItem   = AwardsAdminUI.drawRow
    self.list:setOnMouseDoubleClick(self, AwardsAdminUI.onRowDoubleClick)
    self:addChild(self.list)

    self.deleteBtn = ISButton:new(PAD, lY + LIST_H + PAD, leftW, BTN_H,
        tx("UI_admin_delete"), self, AwardsAdminUI.onDeleteClick)
    self.deleteBtn:initialise()
    self.deleteBtn:instantiate()
    self:addChild(self.deleteBtn)

    -- ===== RIGHT COLUMN =====
    local fY = lY

    self:addChild(ISLabel:new(rightX, fY, FIELD_H,
        tx("UI_admin_item") .. ":", 0.75, 0.85, 1, 1, UIFont.Small, true))
    fY = fY + FIELD_H + LABEL_GAP
    self.itemEntry = ISTextEntryBox:new("", rightX, fY, rightW, FIELD_H)
    self.itemEntry:initialise()
    self.itemEntry:instantiate()
    self.itemEntry:setMaxLines(1)
    self:addChild(self.itemEntry)
    fY = fY + FIELD_H + FIELD_GAP

    self:addChild(ISLabel:new(rightX, fY, FIELD_H,
        tx("UI_admin_number") .. ":", 0.75, 0.85, 1, 1, UIFont.Small, true))
    fY = fY + FIELD_H + LABEL_GAP
    self.numberEntry = ISTextEntryBox:new("", rightX, fY, shortW, FIELD_H)
    self.numberEntry:initialise()
    self.numberEntry:instantiate()
    self.numberEntry:setMaxLines(1)
    self:addChild(self.numberEntry)
    fY = fY + FIELD_H + FIELD_GAP

    self:addChild(ISLabel:new(rightX, fY, FIELD_H,
        tx("UI_admin_count") .. ":", 0.75, 0.85, 1, 1, UIFont.Small, true))
    fY = fY + FIELD_H + LABEL_GAP
    self.countEntry = ISTextEntryBox:new("", rightX, fY, shortW, FIELD_H)
    self.countEntry:initialise()
    self.countEntry:instantiate()
    self.countEntry:setMaxLines(1)
    self:addChild(self.countEntry)
    fY = fY + FIELD_H + FIELD_GAP

    self:addChild(ISLabel:new(rightX, fY, FIELD_H,
        tx("UI_admin_zkills") .. ":", 0.75, 0.85, 1, 1, UIFont.Small, true))
    fY = fY + FIELD_H + LABEL_GAP
    self.zkillsEntry = ISTextEntryBox:new("", rightX, fY, shortW, FIELD_H)
    self.zkillsEntry:initialise()
    self.zkillsEntry:instantiate()
    self.zkillsEntry:setMaxLines(1)
    self:addChild(self.zkillsEntry)
    fY = fY + FIELD_H + FIELD_GAP

    self:addChild(ISLabel:new(rightX, fY, FIELD_H,
        tx("UI_admin_onZombie") .. ":", 0.75, 0.85, 1, 1, UIFont.Small, true))
    fY = fY + FIELD_H + LABEL_GAP
    self.onZombieBtn = ISButton:new(rightX, fY, 80, BTN_H,
        tx("UI_admin_no"), self, AwardsAdminUI.onToggleZombie)
    self.onZombieBtn:initialise()
    self.onZombieBtn:instantiate()
    self:addChild(self.onZombieBtn)
    fY = fY + BTN_H + FIELD_GAP * 2

    local halfW = math.floor((rightW - PAD) / 2)
    self.addBtn = ISButton:new(rightX, fY, halfW, BTN_H,
        tx("UI_admin_add"), self, AwardsAdminUI.onAddClick)
    self.addBtn:initialise()
    self.addBtn:instantiate()
    self:addChild(self.addBtn)

    self.saveBtn = ISButton:new(rightX + halfW + PAD, fY, halfW, BTN_H,
        tx("UI_admin_save"), self, AwardsAdminUI.onSaveClick)
    self.saveBtn:initialise()
    self.saveBtn:instantiate()
    self:addChild(self.saveBtn)

    self._formEndY = fY + BTN_H

    -- ===== BOTTOM BAR =====
    local botY = H - STATUS_H - BTN_H - PAD
    self.reloadBtn = ISButton:new(PAD, botY, 120, BTN_H,
        tx("UI_admin_reload"), self, AwardsAdminUI.onReloadClick)
    self.reloadBtn:initialise()
    self.reloadBtn:instantiate()
    self:addChild(self.reloadBtn)

    -- Max dice control
    local diceX = PAD + 130
    self:addChild(ISLabel:new(diceX, botY + 4, FIELD_H,
        tx("UI_admin_maxDice") .. ":", 0.75, 0.85, 1, 1, UIFont.Small, true))
    self.maxDiceEntry = ISTextEntryBox:new("", diceX + 88, botY, 55, BTN_H)
    self.maxDiceEntry:initialise()
    self.maxDiceEntry:instantiate()
    self.maxDiceEntry:setMaxLines(1)
    self.maxDiceEntry:setText(tostring(self._maxDice or 100))
    self:addChild(self.maxDiceEntry)
    self.maxDiceSetBtn = ISButton:new(diceX + 148, botY, 70, BTN_H,
        tx("UI_admin_set"), self, AwardsAdminUI.onSetMaxDice)
    self.maxDiceSetBtn:initialise()
    self.maxDiceSetBtn:instantiate()
    self:addChild(self.maxDiceSetBtn)

    self.closeBtn = ISButton:new(W - PAD - 100, botY, 100, BTN_H,
        tx("UI_close"), self, AwardsAdminUI.onCloseClick)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self:addChild(self.closeBtn)

    local texAdd    = getTexture("media/ui/icons/add.png")
    local texEdit   = getTexture("media/ui/icons/edit.png")
    local texTrash  = getTexture("media/ui/icons/trash-solid.png")
    local texReload = getTexture("media/ui/icons/reload.png")
    local texClose  = getTexture("media/ui/icons/close.png")

    applyIcon(self.addBtn,    texAdd)
    applyIcon(self.saveBtn,   texEdit)
    applyIcon(self.deleteBtn, texTrash)
    applyIcon(self.reloadBtn, texReload)
    applyIcon(self.closeBtn,  texClose)

    self:clearForm()
end

-- ============================================================
--  Drawing
-- ============================================================

function AwardsAdminUI:prerender()
    ISPanel.prerender(self)

    self:drawText(tx("UI_admin_panel_title"), PAD, PAD, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(tx("UI_admin_list_header"), PAD, 36, 0.6, 0.8, 1, 1, UIFont.Small)
    self:drawText(tx("UI_admin_form_header"), COL_SEP + PAD, 36, 0.6, 0.8, 1, 1, UIFont.Small)

    -- Vertical separator between columns
    self:drawRect(COL_SEP, 34, 1, H - STATUS_H - BTN_H - PAD - 6 - 34, 0.6, 0.4, 0.4, 0.4)

    -- Horizontal separator above bottom bar
    local sepY = H - STATUS_H - BTN_H - PAD - 8
    self:drawRect(PAD, sepY, W - PAD * 2, 1, 0.6, 0.4, 0.4, 0.4)

    -- Separator above status area
    self:drawRect(PAD, H - STATUS_H, W - PAD * 2, 1, 0.45, 0.35, 0.35, 0.5)

    -- Status / hint area: full-width at the very bottom
    local statusY = H - STATUS_H + 4
    local hintText
    if self._editIndex then
        hintText = tx("UI_admin_editing") .. "  #" .. self._editIndex
    else
        hintText = tx("UI_admin_hint_dblclick")
    end
    self:drawText(hintText, PAD, statusY, 0.55, 0.65, 0.75, 1, UIFont.Small)

    if self._statusMsg then
        local r = self._statusIsErr and 1   or 0.3
        local g = self._statusIsErr and 0.3 or 1
        self:drawText(self._statusMsg, PAD, statusY + 18, r, g, 0.3, 1, UIFont.Small)
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
        local invalid = item.item.invalid
        if invalid then
            self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.4, 0.6, 0.15, 0.05)
        end
        local tex    = item.item.tex
        local iconSz = self.itemheight - 6
        local textX  = 6
        if tex then
            self:drawTextureScaled(tex, 3, y + 3, iconSz, iconSz, 1, 1, 1, 1)
            textX = iconSz + 7
        end
        local r, g, b = 1, 1, 1
        if invalid then r, g, b = 1, 0.4, 0.2 end
        self:drawText(item.text, textX, y + 5, r, g, b, a, self.font)
    end
    return y + self.itemheight
end

-- ============================================================
--  List
-- ============================================================

function AwardsAdminUI:refreshList(awards)
    self.list:clear()
    local maxD = self._maxDice or 100
    for i, e in ipairs(awards) do
        local invalid = (tonumber(e.Number) or 0) > maxD
        local prefix  = invalid and "! " or ""
        local label = prefix .. string.format("[%d] %s  x%d  kills>=%d  %s",
            e.Number, e.Item, e.Count, e.zkills,
            e.onZombie and "[Zombie]" or "[Inv]")
        local tex = getItemTex(e.Item)
        self.list:insertItem(i, label, {index = i, data = e, tex = tex, invalid = invalid})
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
    local maxDice = self._maxDice or 100
    if not item or item == ""                         then return nil end
    if not number or number < 1 or number > maxDice   then return nil end
    if not count  or count  < 1                       then return nil end
    if not zkills or zkills < 0                       then return nil end
    return {
        Item     = item,
        Number   = math.floor(number),
        Count    = math.floor(count),
        zkills   = math.floor(zkills),
        onZombie = self._onZombieValue,
    }
end

function AwardsAdminUI:setStatus(msg, isErr)
    self._statusMsg   = msg
    self._statusIsErr = isErr
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
    local li = self.list.items[idx]
    if not li or not li.item then return end
    self._editIndex = li.item.index
    self:fillForm(li.item.data)
    self:setStatus(nil, false)
end

function AwardsAdminUI:onAddClick()
    local entry = self:readForm()
    if not entry then
        local n = tonumber(self.numberEntry:getText())
        local maxDice = self._maxDice or 100
        if n and (n < 1 or n > maxDice) then
            self:setStatus(string.format(tx("UI_admin_err_number_range"), maxDice), true)
        else
            self:setStatus(tx("UI_admin_err_form"), true)
        end
        return
    end
    if not itemExists(entry.Item) then
        self:setStatus(string.format(tx("UI_admin_err_item"), entry.Item), true)
        return
    end
    sendToServer("addAward", entry)
    self:setStatus(tx("UI_admin_added"), false)
    self:clearForm()
end

function AwardsAdminUI:onSaveClick()
    if not self._editIndex then
        self:setStatus(tx("UI_admin_err_nosel"), true)
        return
    end
    local entry = self:readForm()
    if not entry then
        local n = tonumber(self.numberEntry:getText())
        local maxDice = self._maxDice or 100
        if n and (n < 1 or n > maxDice) then
            self:setStatus(string.format(tx("UI_admin_err_number_range"), maxDice), true)
        else
            self:setStatus(tx("UI_admin_err_form"), true)
        end
        return
    end
    if not itemExists(entry.Item) then
        self:setStatus(string.format(tx("UI_admin_err_item"), entry.Item), true)
        return
    end
    entry.index = self._editIndex
    sendToServer("updateAward", entry)
    self:setStatus(tx("UI_admin_saved"), false)
    self:clearForm()
end

function AwardsAdminUI:onSetMaxDice()
    local n = tonumber(self.maxDiceEntry:getText())
    if not n or n < 2 then
        self:setStatus(tx("UI_admin_err_maxdice"), true)
        return
    end
    sendToServer("setMaxDice", {value = math.floor(n)})
    self:setStatus(tx("UI_admin_maxdice_set"), false)
end

function AwardsAdminUI:onDeleteClick()
    local idx = self._editIndex
    if not idx then
        local selIdx = self.list.selected
        if not selIdx or selIdx <= 0 then
            self:setStatus(tx("UI_admin_err_nosel"), true)
            return
        end
        local li = self.list.items[selIdx]
        if li and li.item then idx = li.item.index end
    end
    if not idx then
        self:setStatus(tx("UI_admin_err_nosel"), true)
        return
    end
    sendToServer("deleteAward", {index = idx})
    self:setStatus(tx("UI_admin_deleted"), false)
    self:clearForm()
end

function AwardsAdminUI:onReloadClick()
    sendToServer("reloadAwards", {})
    self:setStatus(tx("UI_admin_reloaded"), false)
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
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local panel = AwardsAdminUI:new((sw - W) / 2, (sh - H) / 2)
    panel:initialise()
    panel:addToUIManager()
    AwardsAdminUI.instance = panel
    sendToServer("getAwards", {})
end
