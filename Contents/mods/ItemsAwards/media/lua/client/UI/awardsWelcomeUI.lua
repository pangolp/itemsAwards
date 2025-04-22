require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISScrollingListBox"

-- Variable global para la ventana
awardsWelcomeWindow = nil

AwardsWelcomeUI = ISPanel:derive("AwardsWelcomeUI");

function AwardsWelcomeUI:initialise()
    ISPanel.initialise(self);
    self:create();
end

function AwardsWelcomeUI:prerender()
    ISPanel.prerender(self);
    -- Título principal
    self:drawText(getText("UI_welcomeawards"), 10, 10, 1, 1, 1, 1, UIFont.Medium);
    -- Versión del mod
    self:drawText(getText("UI_version") .. ": 1.0", 10, 40, 0.8, 0.8, 0.8, 1, UIFont.Small);
    -- Instrucciones básicas
    self:drawText(getText("UI_instructions"), 10, 70, 0.8, 0.8, 0.8, 1, UIFont.Small);
end

function AwardsWelcomeUI:create()
    local btnWidth = 100
    local btnHeight = 25

    -- Lista de premios
    self.awardsList = ISScrollingListBox:new(10, 100, self.width - 20, self.height - 140);
    self.awardsList:initialise();
    self.awardsList:instantiate();
    self.awardsList.itemheight = 22;
    self.awardsList.selected = 0;
    self.awardsList.joypadParent = self;
    self.awardsList.font = UIFont.NewSmall;
    self.awardsList.doDrawItem = self.drawAwardItem;
    self.awardsList:setOnMouseDownFunction(self, self.onAwardClick);
    self:addChild(self.awardsList);

    -- Botón de cerrar
    self.closeButton = ISButton:new(
        self:getWidth() - btnWidth - 10,
        self:getHeight() - btnHeight - 10,
        btnWidth,
        btnHeight,
        getText("UI_close"),
        self,
        AwardsWelcomeUI.onCloseClick
    );
    self.closeButton:initialise();
    self.closeButton:instantiate();
    self:addChild(self.closeButton);
end

-- Dibuja cada item de la lista
function AwardsWelcomeUI:drawAwardItem(y, item, alt)
    local a = 0.9;
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15);
    end

    self:drawText(item.text, 10, y + 2, 1, 1, 1, a, self.font);

    return y + self.itemheight;
end

function AwardsWelcomeUI:onAwardClick(item)
    -- Puedes agregar alguna acción al hacer clic en un premio si lo deseas
end

function AwardsWelcomeUI:onCloseClick()
    self:setVisible(false);
    self:removeFromUIManager();
end

-- Agrega un mensaje a la lista de premios
function AwardsWelcomeUI:addAwardMessage(message)
    self.awardsList:addItem(message, {});
    -- Hacer scroll hasta el último mensaje
    self.awardsList.selected = self.awardsList:size();
end

function AwardsWelcomeUI:new(x, y, width, height)
    local o = {};
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9};
    o.borderColor = {r=0.7, g=0.7, b=0.7, a=0.5};
    o.moveWithMouse = true;
    return o;
end

-- Función para crear la ventana
function CreateWelcomeWindow()
    if awardsWelcomeWindow then return end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = 400
    local height = 300
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2

    awardsWelcomeWindow = AwardsWelcomeUI:new(x, y, width, height)
    awardsWelcomeWindow:initialise();
    awardsWelcomeWindow:addToUIManager();
end

-- HUD Button para abrir/cerrar la ventana de premios
AwardsHUDButton = ISButton:derive("AwardsHUDButton")
AwardsHUDButton.instance = nil

function AwardsHUDButton:new(x, y, width, height)
    local o = ISButton:new(x, y, width, height, "★", nil, function()
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
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    o.backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=0.8}
    o.borderColor = {r=1, g=1, b=1, a=0.3}
    return o
end

local function createHUDButton()
    if AwardsHUDButton.instance then return end
    local btnSize = 32
    local x = getCore():getScreenWidth() - btnSize - 20
    local y = 20

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

-- Evento para mostrar la ventana al iniciar el juego
local function OnGameStart()
    -- Pequeño retraso para asegurar que todo esté cargado
    Events.OnTick.Add(function()
        if not awardsWelcomeWindow then
            CreateWelcomeWindow()
            Events.OnTick.Remove(this)
        end
    end)
    createHUDButton()
end

Events.OnGameStart.Add(OnGameStart)

-- Función global para agregar mensajes desde cualquier parte
function AddAwardMessageToUI(message)
    if awardsWelcomeWindow then
        awardsWelcomeWindow:addAwardMessage(message)
    end
end