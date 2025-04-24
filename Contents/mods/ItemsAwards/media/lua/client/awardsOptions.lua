Awards = Awards or {}
Awards.Options = Awards.Options or {}

Awards.Options.showNumberWhenLosing = false
Awards.Options.showMessageInChat = false
Awards.Options.limitWinningNumbers = 1
Awards.Options.limitLosingNumbers = 1

if ModOptions and ModOptions.getInstance then

    local function onModOptionsApply(optionValues)
        Awards.Options.showNumberWhenLosing = optionValues.settings.options.showNumberWhenLosing
        Awards.Options.showMessageInChat = optionValues.settings.options.showMessageInChat
        Awards.Options.limitWinningNumbers = optionValues.settings.options.limitWinningNumbers
        Awards.Options.limitLosingNumbers = optionValues.settings.options.limitLosingNumbers
    end

    local SETTINGS = {
        options_data = {
            showNumberWhenLosing = {
                name = "UI_Awards_showNumberWhenLosing",
                tooltip = "Tooltip_Awards_showNumberWhenLosing",
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
            showMessageInChat = {
                name = "UI_Awards_showMessageInChat",
                tooltip = "Tooltip_Awards_showMessageInChat",
                default = false,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
            limitWinningNumbers = {
                "5", "10", "15", "20",
                name = "UI_Awards_limitWinningNumbers",
                tooltip = "Tooltip_Awards_limitWinningNumbers",
                default = 1,
                OnApplyMainMenu = onModOptionsApply,
                OnApplyInGame = onModOptionsApply
            },
            limitLosingNumbers = {
                "5", "10", "15", "20",
                name = "UI_Awards_limitLosingNumbers",
                tooltip = "Tooltip_Awards_limitLosingNumbers",
                default = 1,
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

    Events.OnPreMapLoad.Add(function() onModOptionsApply({ settings = SETTINGS }) end)
end
