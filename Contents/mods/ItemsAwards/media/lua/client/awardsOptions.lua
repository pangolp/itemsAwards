Awards = Awards or {}
Awards.Options = Awards.Options or {}

Awards.Options.showNumberWhenLosing = false
Awards.Options.showMessageInChat = false

if ModOptions and ModOptions.getInstance then
    local function onModOptionsApply(optionValues)
        Awards.Options.showNumberWhenLosing = optionValues.settings.options.showNumberWhenLosing
        Awards.Options.showMessageInChat = optionValues.settings.options.showMessageInChat
    end

    local SETTINGS = {
        options_data = {
            showNumberWhenLosing = {
                name = "UI_Awards_showNumberWhenLosing",
                tooltip = "UI_Awards_showNumberWhenLosing_Tooltip",
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
            showMessageInChat = {
                name = "UI_Awards_showMessageInChat",
                tooltip = "UI_Awards_showMessageInChat_Tooltip",
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
        },

        mod_id = 'ItemsAwards',
        mod_shortname = 'Items Awards',
        mod_fullname = 'Items Awards',
    }

    local optionsInstance = ModOptions:getInstance(SETTINGS)
    ModOptions:loadFile()

    Events.OnPreMapLoad.Add(
        function() onModOptionsApply(
            { settings = SETTINGS }
        )
    end)
end
