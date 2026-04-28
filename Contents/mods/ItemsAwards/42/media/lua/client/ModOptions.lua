Awards = Awards or {}
Awards.Options = Awards.Options or {}

Awards.Options.showNumberWhenLosing = false
Awards.Options.showMessageInChat = false
Awards.Options.limitWinningNumbers = 1
Awards.Options.limitLosingNumbers = 1

local function applyAwardsOptions()
    local options = PZAPI.ModOptions:getOptions("ItemsAwards")
    if not options then return end

    Awards.Options.showNumberWhenLosing = options:getOption("showNumber"):getValue()
    Awards.Options.showMessageInChat    = options:getOption("showChat"):getValue()
    Awards.Options.limitWinningNumbers  = options:getOption("limitWin"):getValue()
    Awards.Options.limitLosingNumbers   = options:getOption("limitLose"):getValue()

    print("Awards: Opciones actualizadas correctamente.")
end

local function InitAwardsOptions()
    local options = PZAPI.ModOptions:create("ItemsAwards", "Items Awards")

    options:addTitle(getText("UI_Awards_Title"))

    options:addTickBox("showNumber", getText("UI_Awards_showNumberWhenLosing"), Awards.Options.showNumberWhenLosing, getText("Tooltip_Awards_showNumberWhenLosing"))
    options:addTickBox("showChat", getText("UI_Awards_showMessageInChat"), Awards.Options.showMessageInChat, getText("Tooltip_Awards_showMessageInChat"))

    options:addSeparator()

    local comboWin = options:addComboBox("limitWin", getText("UI_Awards_limitWinningNumbers"), getText("Tooltip_Awards_limitWinningNumbers"))
    comboWin:addItem("5", true)
    comboWin:addItem("10", false)
    comboWin:addItem("15", false)
    comboWin:addItem("20", false)

    local comboLose = options:addComboBox("limitLose", getText("UI_Awards_limitLosingNumbers"), getText("Tooltip_Awards_limitLosingNumbers"))
    comboLose:addItem("5", true)
    comboLose:addItem("10", false)
    comboLose:addItem("15", false)
    comboLose:addItem("20", false)

    options.apply = applyAwardsOptions
end

InitAwardsOptions()

Events.OnMainMenuEnter.Add(function()
    applyAwardsOptions()
end)

Events.OnPreMapLoad.Add(function()
    applyAwardsOptions()
end)
