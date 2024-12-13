-- This addon allows for adding and stopping multiple timers and stopwatches.
-- Commands:
-- Timer start: /time start [TimerName] [duration] [x_position] [y_position]
-- Timer stop: /time stop - Stops all timers.
-- Timer kill: /time kill - Stops all timers and stopwatches.
-- Stopwatch start: /sw start [StopwatchName] [x_position] [y_position] - Starts a stopwatch even if it doesn’t exist in XML.
-- Stopwatch stop: /sw stop - Stops all stopwatches.
-- Color Test: /time colortest - Displays timer and stopwatch colors for testing.

-- List of Functions:
-- 1. chatcolortest - Tests colors by displaying color codes in the chat log.
-- 2. stop_colortest - Stops any ongoing color test and removes associated fonts.
-- 3. colortest - Runs a color test showing colors on the screen with different backgrounds.
-- 4. cleanup_timers_and_stopwatches - Removes all active timers and stopwatches from the screen.
-- 5. safe_call - Safely calls functions with error handling.
-- 6. find_timer - Finds a timer by name in the active timers list with case-insensitive matching.
-- 7. find_stopwatch - Finds a stopwatch by name in the active stopwatches list with case-insensitive matching.
-- 8. print_help - Displays available commands and syntax.
-- 9. play_alert_sound - Plays a sound when a timer completes.
-- 10. get_color - Fetches color from colors.lua or defaults to white.
-- 11. load_settings_from_xml - Loads settings from an XML file.
-- 12. load_individual_timer_settings - Loads settings for individual timers from XML with case-insensitive name matching and preserves the XML casing for display.
-- 13. load_individual_stopwatch_settings - Loads settings for individual stopwatches from XML with case-insensitive name matching and preserves the XML casing for display.
-- 14. apply_background_settings - Helper function to apply the background opacity settings consistently for both timers and stopwatches.
-- 15. apply_timer_settings - Applies visual settings to a timer based on the color key and background type.
-- 16. apply_stopwatch_settings - Sets up font color and background based on color_key and background type for stopwatches.
-- 17. render - Updates active timers and stopwatches every frame.
-- 18. stop_all_timers - Stops and removes all active timers from the screen.
-- 19. stop_all_stopwatches - Stops and removes all active stopwatches from the screen.
-- 20. command - Handles incoming commands for timers and stopwatches.
-- 21. unload - Triggered when the addon is unloaded or reloaded to prevent lingering font objects on the screen.

_addon.author   = 'Astos from Eden';
_addon.name     = 'customtimers';
_addon.version  = '2.3';

require 'common'
local date = require('resources/date')
local colors = require('resources/colors')

local timer_config = {
    font = {
        family = 'Tahoma',
        size = 12
    },
    timers = {},
    stopwatches = {},
    defaults = {}
};

local settings_file = _addon.path .. 'Config/settings.xml'
local color_test_active = false  -- Flag to track if a color test is currently active

----------------------------------------------------------------------------------------------------
-- chatcolortest
-- Function to test colors by displaying color codes in the chat.
-- These colors only work in the chat log, not for timer objects.
----------------------------------------------------------------------------------------------------
local function chatcolortest()
    local selected_colors = {
        1, 2, 3, 4, 5, 6, 7, 8, 17, 19, 20, 21, 22, 28, 29, 36, 38, 39, 44, 45, 46, 47, 48, 49, 50, 53, 54, 56, 57, 59, 60, 61, 63, 73, 74,
        75, 76, 77, 78, 79, 95, 96, 97, 98, 99, 115, 116, 117, 118, 119, 120, 121, 123, 124, 125, 126, 141, 142, 143, 154, 155, 156, 157,
        158, 159, 160, 161, 166, 167, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 206, 207, 209, 210, 211, 212,
        213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238,
        239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 254, 255, 256, 257, 258, 259, 260, 261, 262
    }

    local counter = 0
    local line = ''
    for _, n in ipairs(selected_colors) do
        local loc_col
        if n <= 255 then
            loc_col = string.char(0x1F, n)
        else
            loc_col = string.char(0x1E, n - 254)
        end
        line = line .. loc_col .. string.format('%03d ', n)
        counter = counter + 1

        if counter == 16 then
            print(line)
            counter = 0
            line = ''
        end
    end
    
    if line ~= '' then
        print(line)
    end
    
    print('Colors Tested!')
end

----------------------------------------------------------------------------------------------------
-- stop_colortest
-- Helper function to stop the active color test and remove associated fonts.
----------------------------------------------------------------------------------------------------
local function stop_colortest()
    for col = 1, 3 do
        AshitaCore:GetFontManager():Delete('__colortest_header_' .. col)
        for key = 1, 100 do  -- Assuming a limit of 100 color keys; adjust if needed
            AshitaCore:GetFontManager():Delete(string.format('__colortest_key%d_%d', key, col))
        end
    end
    color_test_active = false  -- Reset the flag to indicate no color test is active
end

----------------------------------------------------------------------------------------------------
-- colortest
-- Creates temporary font objects with three background options (light, regular, and dark).
-- Stops an existing test if one is already running.
-- Ensures cleanup of all font objects when the test completes.
----------------------------------------------------------------------------------------------------
local function colortest()
    -- Stop any ongoing color test to prevent overlap
    if color_test_active then
        print("Stopping current color test before starting a new one.")
        stop_colortest()
    end

    color_test_active = true

    local color_keys = {}
    for key in pairs(colors) do
        table.insert(color_keys, key)
    end
    table.sort(color_keys)

    local background_options = {
        { "Light Background", math.d3dcolor(64, 255, 255, 255) },
        { "Regular Background", math.d3dcolor(128, 0, 0, 0) },
        { "Dark Background", math.d3dcolor(224, 0, 0, 0) }
    }

    local column_offsets = { 200, 500, 800 }
    local batch_size = 50
    local batch_index = 1

    local function display_batch()
        local start_index = (batch_index - 1) * batch_size + 1
        local end_index = math.min(batch_index * batch_size, #color_keys)

        -- Create headers for each column
        for col, bg_option in ipairs(background_options) do
            local bg_name = bg_option[1]
            local header_font = AshitaCore:GetFontManager():Create('__colortest_header_' .. col)
            header_font:SetFontFamily(timer_config.font.family)
            header_font:SetFontHeight(math.floor(timer_config.font.size * 1.5))
            header_font:SetBold(true)
            header_font:SetColor(math.d3dcolor(255, 255, 255, 255))
            header_font:SetPositionX(column_offsets[col])
            header_font:SetPositionY(70)
            header_font:SetText(bg_name)
            header_font:SetVisibility(true)
        end

        -- Display colors for the current batch in each column
        for col, bg_option in ipairs(background_options) do
            local _, bg_color = unpack(bg_option)
            for i = start_index, end_index do
                local key = color_keys[i]
                local color_data = colors[key]
                local r, g, b = unpack(color_data)

                local font = AshitaCore:GetFontManager():Create(string.format('__colortest_key%d_%d', key, col))
                font:SetFontFamily(timer_config.font.family)
                font:SetFontHeight(timer_config.font.size)
                font:SetBold(true)
                font:SetColor(math.d3dcolor(255, r, g, b))
                font:SetPositionX(column_offsets[col])
                font:SetPositionY(100 + ((i - start_index) * 20))
                font:SetText(string.format("Color %d - RGB(%d, %d, %d)", key, r, g, b))
                
                font:GetBackground():SetVisibility(true)
                font:GetBackground():SetColor(bg_color)
                font:SetVisibility(true)
            end
        end

        -- Schedule removal of the current batch and load the next after 10 seconds
        ashita.timer.once(10, function()
            for col = 1, #background_options do
                AshitaCore:GetFontManager():Delete('__colortest_header_' .. col)
                for i = start_index, end_index do
                    local key = color_keys[i]
                    AshitaCore:GetFontManager():Delete(string.format('__colortest_key%d_%d', key, col))
                end
            end

            -- Move to the next batch or end if complete
            if end_index < #color_keys then
                batch_index = batch_index + 1
                display_batch()
            else
                -- Ensure all fonts are deleted when the last batch is done
                stop_colortest()
                print("Color test completed.")
            end
        end)
    end

    -- Start displaying the first batch
    display_batch()
end

----------------------------------------------------------------------------------------------------
-- cleanup_timers_and_stopwatches
-- Cleans up and removes all active timers and stopwatches from the screen. 
-- If 'silent' is set to true, a message is not printed to the console.
----------------------------------------------------------------------------------------------------
local function cleanup_timers_and_stopwatches(silent)
    for _, timer in ipairs(timer_config.timers) do
        if timer.font then
            AshitaCore:GetFontManager():Delete(timer.font:GetAlias())
        end
    end
    for _, stopwatch in ipairs(timer_config.stopwatches) do
        if stopwatch.font then
            AshitaCore:GetFontManager():Delete(stopwatch.font:GetAlias())
        end
    end
    timer_config.timers = {}
    timer_config.stopwatches = {}
    
    if not silent then
        print('\31\200[\31\05' .. _addon.name .. '\31\200] All timers and stopwatches destroyed.')
    end
end

----------------------------------------------------------------------------------------------------
-- safe_call
-- Wrapper function for safely calling other functions with error handling.
-- If an error occurs, it cleans up all timers and stopwatches.
----------------------------------------------------------------------------------------------------
local function safe_call(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        print('\31\200[\31\05' .. _addon.name .. '\31\200] Error: ' .. result)
        cleanup_timers_and_stopwatches()
        return false
    end
    return result
end

----------------------------------------------------------------------------------------------------
-- find_timer
-- Helper function to find a timer by name in the active timers list.
-- This function performs a case-insensitive match, returning the index of the timer if found.
----------------------------------------------------------------------------------------------------
local function find_timer(name)
    local lower_name = name:lower()
    for i, timer in ipairs(timer_config.timers) do
        if timer.name:lower() == lower_name then
            return i
        end
    end
    return nil
end

----------------------------------------------------------------------------------------------------
-- find_stopwatch
-- Helper function to find a stopwatch by name in the active stopwatches list.
-- This function performs a case-insensitive match, returning the index of the stopwatch if found.
----------------------------------------------------------------------------------------------------
local function find_stopwatch(name)
    local lower_name = name:lower()
    for i, stopwatch in ipairs(timer_config.stopwatches) do
        if stopwatch.name:lower() == lower_name then
            return i
        end
    end
    return nil
end

----------------------------------------------------------------------------------------------------
-- print_help
-- Function to print help message displaying the available commands and their syntax.
----------------------------------------------------------------------------------------------------
local function print_help()
    print('\31\200[\31\05' .. _addon.name .. '\31\200] Available Commands:')
    print('\31\200[\31\05' .. _addon.name .. '\31\200] /time start [TimerName] [duration] [x_position] [y_position] - Start a timer with specified duration and position.')
    print('\31\200[\31\05' .. _addon.name .. '\31\200] /time stop - Stop all timers.')
    print('\31\200[\31\05' .. _addon.name .. '\31\200] /time kill - Stop all timers and stopwatches.')
    print('\31\200[\31\05' .. _addon.name .. '\31\200] /sw start [StopwatchName] [x_position] [y_position] - Start a stopwatch with optional position.')
    print('\31\200[\31\05' .. _addon.name .. '\31\200] /sw stop - Stop all stopwatches.')
    print('\31\200[\31\05' .. _addon.name .. '\31\200] /time colortest - Displays color codes in the chat for testing.')
    print('\31\200[\31\05' .. _addon.name .. '\31\200] /time soundtest - Test sound playback.')
end

----------------------------------------------------------------------------------------------------
-- play_alert_sound
-- Plays an alert sound from the 'resources' folder when a timer completes.
----------------------------------------------------------------------------------------------------
local function play_alert_sound()
    local fullpath = string.format('%s\\resources\\A timer has ended.wav', _addon.path)
    ashita.misc.play_sound(fullpath)
end

----------------------------------------------------------------------------------------------------
-- get_color
-- Fetches the color from colors.lua based on a numeric key. Defaults to white if not found.
----------------------------------------------------------------------------------------------------
local function get_color(key)
    return colors[key] or {255, 255, 255} -- White as fallback
end

----------------------------------------------------------------------------------------------------
-- load_settings_from_xml
-- Reads and parses the settings from the 'settings.xml' file, setting default values for timers and stopwatches.
----------------------------------------------------------------------------------------------------
local function load_settings_from_xml(file)
    local f = io.open(file, "r")
    if not f then
        error("Error: settings.xml not found in the Config folder.")
    end
    
    local content = f:read("*all")
    f:close()
    
    -- Update root tag for customtimers
    timer_config.root_tag = content:match("<customtimers>.-</customtimers>")

    -- Extract default values for timers
    timer_config.font.size = tonumber(content:match("<timer_defaults>.-<fontsize>(%d+)</fontsize>")) or timer_config.font.size
    timer_config.defaults.timer_length = tonumber(content:match("<timer_defaults>.-<timer_length>(%d+)</timer_length>")) or 60
    timer_config.defaults.audible_notification = content:match("<timer_defaults>.-<audible_notification>(True)</audible_notification>") == "True"
    timer_config.defaults.overwrite_timer = content:match("<timer_defaults>.-<overwrite_timer>(True)</overwrite_timer>") == "True"
    timer_config.defaults.color = tonumber(content:match("<timer_defaults>.-<color>(%d+)</color>")) or 7
    timer_config.defaults.background = content:match("<timer_defaults>.-<background>(%w+)</background>") or "regular"

    -- Default position for timers
    timer_config.defaults.position = {
        tonumber(content:match("<timer_defaults>.-<x_position>(%d+)</x_position>")) or 200,
        tonumber(content:match("<y_position>(%d+)</y_position>")) or 200
    }

    -- Default position and color for stopwatches
    timer_config.defaults.stopwatch_color = tonumber(content:match("<stopwatch_defaults>.-<color>(%d+)</color>")) or 7
    timer_config.defaults.stopwatch_background = content:match("<stopwatch_defaults>.-<background>(%w+)</background>") or "regular"
    timer_config.defaults.stopwatch_position = {
        tonumber(content:match("<stopwatch_defaults>.-<x_position>(%d+)</x_position>")) or 200,
        tonumber(content:match("<y_position>(%d+)</y_position>")) or 200
    }
end

----------------------------------------------------------------------------------------------------
-- load_individual_timer_settings
-- Loads settings for an individual timer from the XML content.
-- This function performs case-insensitive matching for the timer name, and if the timer is found,
-- it uses the original XML casing for display.
-- Applies default values only if specific fields are missing from the timer configuration.
----------------------------------------------------------------------------------------------------
local function load_individual_timer_settings(content, timer_name)
    local lower_timer_name = timer_name:lower()
    local timer_section = nil
    local matched_name = nil

    -- Case-insensitive search for the timer name in the XML
    for name in content:gmatch('<timer name="(.-)".->') do
        if name:lower() == lower_timer_name then
            timer_section = content:match('<timer name="' .. name .. '".->(.-)</timer>')
            matched_name = name -- Preserve exact XML casing for display
            break
        end
    end

    -- Reference default timer settings with fallbacks
    local defaults = {
        fontsize = timer_config.font.size,
        duration = timer_config.defaults.timer_length,
        audible_notification = timer_config.defaults.audible_notification,
        overwrite_timer = timer_config.defaults.overwrite_timer,  -- Use default overwrite_timer setting
        position = timer_config.defaults.position,
        color_key = timer_config.defaults.color,
        background = timer_config.defaults.background
    }

    -- Return nil if no specific settings are found for the timer
    if not timer_section then
        return nil
    end


    -- Extract overwrite_timer explicitly and debug it
    local overwrite_timer_tag = timer_section:match("<overwrite_timer>(.-)</overwrite_timer>")
    local overwrite_timer
    if overwrite_timer_tag == "True" then
        overwrite_timer = true
    elseif overwrite_timer_tag == "False" then
        overwrite_timer = false
    else
        overwrite_timer = defaults.overwrite_timer  -- Use default if not specified in XML
    end

    -- Parse other settings with fallback to defaults
    return {
        name = matched_name or timer_name,  -- Use XML casing if matched
        fontsize = tonumber(timer_section:match("<fontsize>(%d+)</fontsize>")) or defaults.fontsize,
        duration = tonumber(timer_section:match("<timer_length>(%d+)</timer_length>")) or defaults.duration,
        audible_notification = (timer_section:match("<audible_notification>(True)</audible_notification>") == "True")
                                or defaults.audible_notification,
        overwrite_timer = overwrite_timer,  -- Apply correctly parsed overwrite_timer value
        position = {
            tonumber(timer_section:match("<x_position>(%d+)")) or defaults.position[1],
            tonumber(timer_section:match("<y_position>(%d+)")) or defaults.position[2]
        },
        color_key = tonumber(timer_section:match("<color>(%d+)</color>")) or defaults.color_key,
        background = timer_section:match("<background>(%a+)") or defaults.background
    }
end

----------------------------------------------------------------------------------------------------
-- load_individual_stopwatch_settings
-- Loads settings for an individual stopwatch from the XML content.
-- This function performs case-insensitive matching for the stopwatch name, and if the stopwatch is 
-- found, it uses the original XML casing for display.
-- Applies default values only if specific fields are missing from the stopwatch configuration.
----------------------------------------------------------------------------------------------------
local function load_individual_stopwatch_settings(content, stopwatch_name)
    local lower_stopwatch_name = stopwatch_name:lower()
    local stopwatch_section = nil
    local matched_name = nil

    -- Case-insensitive search for the stopwatch name in the XML
    for name in content:gmatch('<stopwatch name="(.-)".->') do
        if name:lower() == lower_stopwatch_name then
            stopwatch_section = content:match('<stopwatch name="' .. name .. '".->(.-)</stopwatch>')
            matched_name = name -- Preserve exact XML casing for display
            break
        end
    end

    -- Return nil if no specific settings are found for the stopwatch
    if not stopwatch_section then
        return nil
    end

    -- Reference default stopwatch settings with fallbacks
    local defaults = {
        fontsize = timer_config.font.size,
        position = timer_config.defaults.stopwatch_position,
        color_key = timer_config.defaults.stopwatch_color,
        background = timer_config.defaults.stopwatch_background,
        overwrite_watch = timer_config.defaults.overwrite_watch
    }

    -- Parse settings with fallback to defaults
    return {
        name = matched_name or stopwatch_name,  -- Use XML casing if matched
        fontsize = tonumber(stopwatch_section:match("<fontsize>(%d+)</fontsize>")) or defaults.fontsize,
        position = {
            tonumber(stopwatch_section:match("<x_position>(%d+)")) or defaults.position[1],
            tonumber(stopwatch_section:match("<y_position>(%d+)")) or defaults.position[2]
        },
        color_key = tonumber(stopwatch_section:match("<color>(%d+)</color>")) or defaults.color_key,
        background = stopwatch_section:match("<background>(%w+)</background>") or defaults.background,
        overwrite_watch = (stopwatch_section:match("<overwrite_watch>(True)</overwrite_watch>") == "True")
                           or defaults.overwrite_watch
    }
end

----------------------------------------------------------------------------------------------------
-- apply_background_settings
-- Helper function to apply the background opacity settings consistently for both timers and stopwatches.
----------------------------------------------------------------------------------------------------
local function apply_background_settings(font, background_type)
    -- Define opacity levels to match the exact configuration in the colortest function
    local background_opacity = {
        light = math.d3dcolor(64, 255, 255, 255),
        regular = math.d3dcolor(128, 0, 0, 0),
        dark = math.d3dcolor(224, 0, 0, 0)
    }
    local bg_color = background_opacity[background_type] or background_opacity.regular
    font:GetBackground():SetVisibility(true)
    font:GetBackground():SetColor(bg_color)
end

----------------------------------------------------------------------------------------------------
-- apply_timer_settings
-- Sets up font color and background based on color_key and background type for timers.
----------------------------------------------------------------------------------------------------
local function apply_timer_settings(timer)
    local color = get_color(timer.color_key)
    
    timer.font:SetColor(math.d3dcolor(255, unpack(color))) -- Apply font color
    apply_background_settings(timer.font, timer.background) -- Apply background color with exact opacity
    timer.font:SetVisibility(true)                          -- Ensure font is visible
end

----------------------------------------------------------------------------------------------------
-- apply_stopwatch_settings
-- Sets up font color and background based on color_key and background type for stopwatches.
----------------------------------------------------------------------------------------------------
local function apply_stopwatch_settings(stopwatch)
    local color = get_color(stopwatch.color_key)
    
    stopwatch.font:SetColor(math.d3dcolor(255, unpack(color))) -- Apply font color
    apply_background_settings(stopwatch.font, stopwatch.background) -- Apply background color with exact opacity
    stopwatch.font:SetVisibility(true)                          -- Ensure font is visible
end

----------------------------------------------------------------------------------------------------
-- render
-- Render event called every frame, used to update active timers and stopwatches.
-- Removes expired timers and plays a sound if audible notification is enabled.
-- Timers and stopwatches are displayed in (TimerName) hh:mm:ss format.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    -- Process active timers
    for i = #timer_config.timers, 1, -1 do
        local timer = timer_config.timers[i]
        local elapsed = os.difftime(os.time(), timer.start_time)
        local remaining = timer.duration - elapsed

        if remaining > 0 then
            local hours = math.floor(remaining / 3600)
            local minutes = math.floor((remaining % 3600) / 60)
            local seconds = remaining % 60
            timer.font:SetText(string.format('(%s)    %02d:%02d:%02d', timer.name, hours, minutes, seconds))
            apply_timer_settings(timer)  -- Apply the color and background settings on each render
        else
            print('\31\200[\31\05' .. _addon.name .. '\31\200] Timer "' .. timer.name .. '" has completed!')

            -- Check if the audible notification is enabled and play sound
            if timer.audible_notification then
                play_alert_sound()
            end

            -- Delete font and remove timer from the list
            AshitaCore:GetFontManager():Delete(timer.font:GetAlias())
            table.remove(timer_config.timers, i)
        end
    end

    -- Process active stopwatches
    for i = #timer_config.stopwatches, 1, -1 do
        local stopwatch = timer_config.stopwatches[i]
        local elapsed = os.difftime(os.time(), stopwatch.start_time)
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = elapsed % 60
        stopwatch.font:SetText(string.format('(%s)    %02d:%02d:%02d', stopwatch.name, hours, minutes, seconds))
        apply_stopwatch_settings(stopwatch)  -- Apply the color and background settings on each render
    end
end)

----------------------------------------------------------------------------------------------------
-- stop_all_timers
-- Helper function to stop and remove all active timers from the screen.
----------------------------------------------------------------------------------------------------
local function stop_all_timers()
    for i = #timer_config.timers, 1, -1 do
        local timer = timer_config.timers[i]
        if timer.font then
            AshitaCore:GetFontManager():Delete(timer.font:GetAlias())
        end
        table.remove(timer_config.timers, i)
    end
    print('\31\200[\31\05' .. _addon.name .. '\31\200] All timers stopped.')
end


----------------------------------------------------------------------------------------------------
-- stop_all_stopwatches
-- Helper function to stop and remove all active stopwatches from the screen.
----------------------------------------------------------------------------------------------------
local function stop_all_stopwatches()
    for i = #timer_config.stopwatches, 1, -1 do
        local stopwatch = timer_config.stopwatches[i]
        if stopwatch.font then
            AshitaCore:GetFontManager():Delete(stopwatch.font:GetAlias())
        end
        table.remove(timer_config.stopwatches, i)
    end
    print('\31\200[\31\05' .. _addon.name .. '\31\200] All stopwatches stopped.')
end

----------------------------------------------------------------------------------------------------
-- command - Handles incoming commands for timers and stopwatches.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    return safe_call(function()
        local args = command:args()
        local cmd = args[1]:lower()
        if (cmd ~= '/time' and cmd ~= '/sw') then
            return false
        end

        if not args[2] or args[2]:lower() == 'help' then
            print_help()
            return true
        end

        -- Color and Sound Tests for Timers
        if cmd == '/time' and args[2] == 'colortest' then
            colortest()
            return true
        end

        if cmd == '/time' and args[2] == 'soundtest' then
            play_alert_sound()
            return true
        end

-- Start a Timer with Overwrite Handling
if cmd == '/time' and args[2] == 'start' then
    local name = args[3]
    if not name then
        print_help()
        return true
    end

    local duration = nil
    local x_position = nil
    local y_position = nil
    local duration_type = nil

    -- Parse remaining arguments for duration, x_position, and y_position
    for i = 4, #args do
        local arg = args[i]:lower()

        if arg:match("^(%d+)h$") then
            if duration_type then
                print_help()
                return true
            end
            duration = tonumber(arg:match("(%d+)")) * 3600  -- Hours to seconds
            duration_type = "h"
        elseif arg:match("^(%d+)m$") then
            if duration_type then
                print_help()
                return true
            end
            duration = tonumber(arg:match("(%d+)")) * 60  -- Minutes to seconds
            duration_type = "m"
        elseif arg:match("^(%d+)s$") then
            if duration_type then
                print_help()
                return true
            end
            duration = tonumber(arg:match("(%d+)"))  -- Seconds
            duration_type = "s"
        elseif arg:match("^(%d+):(%d+):(%d+)$") then
            if duration_type then
                print_help()
                return true
            end
            local h, m, s = arg:match("(%d+):(%d+):(%d+)")
            duration = (tonumber(h) * 3600) + (tonumber(m) * 60) + tonumber(s)
            duration_type = "hh:mm:ss"
        elseif arg:match("^(%d+):(%d+)$") then
            if duration_type then
                print_help()
                return true
            end
            local m, s = arg:match("(%d+):(%d+)")
            duration = (tonumber(m) * 60) + tonumber(s)
            duration_type = "mm:ss"  -- Also handles m:ss format
        elseif arg:match("^(%d+)x$") then
            x_position = tonumber(arg:match("(%d+)"))
        elseif arg:match("^(%d+)y$") then
            y_position = tonumber(arg:match("(%d+)"))
        else
            print_help()
            return true
        end
    end


    -- Load settings from XML or apply defaults if timer not found
    local content = io.open(settings_file, "r"):read("*all")
    local timer_settings = load_individual_timer_settings(content, name)

    -- Apply default duration if not specified in arguments
    if not duration then
        duration = (timer_settings and timer_settings.duration) or timer_config.defaults.timer_length
    end

    -- Apply settings if they exist in XML; otherwise, apply defaults
    local final_timer_settings = {
        name = name,
        duration = duration,
        position = {
            x_position or (timer_settings and timer_settings.position[1]) or timer_config.defaults.position[1],
            y_position or (timer_settings and timer_settings.position[2]) or timer_config.defaults.position[2]
        },
        color_key = (timer_settings and timer_settings.color_key) or timer_config.defaults.color,
        background = (timer_settings and timer_settings.background) or timer_config.defaults.background,
        fontsize = (timer_settings and timer_settings.fontsize) or timer_config.font.size,
        audible_notification = (timer_settings and timer_settings.audible_notification) or timer_config.defaults.audible_notification,
    }

    -- Only assign `overwrite_timer` from `timer_settings` if it's defined
    if timer_settings and timer_settings.overwrite_timer ~= nil then
        final_timer_settings.overwrite_timer = timer_settings.overwrite_timer
    else
        final_timer_settings.overwrite_timer = timer_config.defaults.overwrite_timer
    end

    -- Check if a timer with the same name exists
    local existing_index = find_timer(name)
    if existing_index then

        -- Apply overwrite behavior based on `overwrite_timer` setting
        if final_timer_settings.overwrite_timer then
            -- Delete existing timer before recreating
            local existing_timer = table.remove(timer_config.timers, existing_index)
            AshitaCore:GetFontManager():Delete(existing_timer.font:GetAlias())
        else
            -- Skip creating a new timer if overwrite is disabled
            print('\31\200[\31\05' .. _addon.name .. '\31\200] Timer "' .. name .. '" already exists and overwrite is disabled.')
            return true
        end
    end

    -- Create the new timer with updated settings
    local font = AshitaCore:GetFontManager():Create('__timer_' .. final_timer_settings.name)
    font:SetFontFamily(timer_config.font.family)
    font:SetFontHeight(final_timer_settings.fontsize)
    font:SetBold(true)
    font:SetPositionX(final_timer_settings.position[1])
    font:SetPositionY(final_timer_settings.position[2])

    local new_timer = {
        name = final_timer_settings.name,
        duration = final_timer_settings.duration,
        start_time = os.time(),  -- Set start time to current time for reset
        font = font,
        color_key = final_timer_settings.color_key,
        background = final_timer_settings.background,
        audible_notification = final_timer_settings.audible_notification
    }
    table.insert(timer_config.timers, new_timer)
    apply_timer_settings(new_timer)

    local hours = math.floor(duration / 3600)
    local minutes = math.floor((duration % 3600) / 60)
    local seconds = duration % 60

    print(string.format('\31\200[\31\05' .. _addon.name .. '\31\200] Timer "%s" started for %02d:%02d:%02d [hh:mm:ss].', final_timer_settings.name, hours, minutes, seconds))

    return true
end


        -- Stop a Specific Timer or All Timers
        if cmd == '/time' and args[2] == 'stop' then
            if args[3] then
                local name = args[3]
                local index = find_timer(name)
                if index then
                    local timer = table.remove(timer_config.timers, index)
                    if timer and timer.font then
                        AshitaCore:GetFontManager():Delete(timer.font:GetAlias())
                    end
                    print('\31\200[\31\05' .. _addon.name .. '\31\200] Timer "' .. name .. '" stopped and removed from screen.')
                else
                    print('\31\200[\31\05Error:\31\200] Timer "' .. name .. '" not found.')
                end
            else
                -- Stop all timers if no specific name is given
                stop_all_timers()
            end
            return true
        end

        -- Kill All Timers and Stopwatches
        if cmd == '/time' and args[2] == 'kill' then
            cleanup_timers_and_stopwatches(true)
            print('\31\200[\31\05' .. _addon.name .. '\31\200] All timers and stopwatches stopped.')
            return true
        end

        -- Start a Stopwatch with Flexible Argument Parsing
        if cmd == '/sw' and args[2] == 'start' then
            local name = args[3]
            if not name then
                print_help()
                return true
            end

            local x_position = nil
            local y_position = nil

            -- Parse remaining arguments for x and y positions
            for i = 4, #args do
                local arg = args[i]:lower()

                if arg:match("^(%d+)x$") then
                    x_position = tonumber(arg:match("(%d+)"))
                elseif arg:match("^(%d+)y$") then
                    y_position = tonumber(arg:match("(%d+)"))
                else
                    print_help()
                    return true
                end
            end

            -- Load settings from XML or apply defaults if stopwatch not found
            local content = io.open(settings_file, "r"):read("*all")
            local stopwatch_settings = load_individual_stopwatch_settings(content, name)
            if stopwatch_settings then
                stopwatch_settings.name = stopwatch_settings.name -- Preserve XML capitalization
            else
                stopwatch_settings = {
                    name = name,
                    position = { x_position or timer_config.defaults.stopwatch_position[1], y_position or timer_config.defaults.stopwatch_position[2] },
                    color_key = timer_config.defaults.stopwatch_color,
                    background = timer_config.defaults.stopwatch_background,
                    fontsize = timer_config.defaults.fontsize or 12  -- Use default font size
                }
            end

            -- Create stopwatch and apply settings with a default font size
            local font = AshitaCore:GetFontManager():Create('__stopwatch_' .. stopwatch_settings.name)
            font:SetFontFamily(timer_config.font.family)
            font:SetFontHeight(stopwatch_settings.fontsize)  -- Apply the font size from XML or default
            font:SetBold(true)
            font:SetPositionX(x_position or stopwatch_settings.position[1])
            font:SetPositionY(y_position or stopwatch_settings.position[2])

            local new_stopwatch = {
                name = stopwatch_settings.name,
                start_time = os.time(),
                font = font,
                color_key = stopwatch_settings.color_key,
                background = stopwatch_settings.background
            }
            table.insert(timer_config.stopwatches, new_stopwatch)
            apply_stopwatch_settings(new_stopwatch)
            print('\31\200[\31\05' .. _addon.name .. '\31\200] Stopwatch "' .. stopwatch_settings.name .. '" started.')
            return true
        end

        -- Stop All Stopwatches
        if cmd == '/sw' and args[2] == 'stop' then
            stop_all_stopwatches()
            return true
        end

        print('\31\200[\31\05' .. _addon.name .. '\31\200] Invalid command. Please use a valid command:')
        print_help()
        return true
    end)
end)

----------------------------------------------------------------------------------------------------
-- unload
-- Event triggered when the addon is unloaded or reloaded.
-- Cleans up all timers, stopwatches, and any active color test fonts to prevent lingering objects.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Stop any active color test to ensure fonts are cleaned up
    if color_test_active then
        stop_colortest()
    end
    cleanup_timers_and_stopwatches(true)  -- Pass true to avoid printing the cleanup message during unload.
end)

-- Attempt to load settings from Config/settings.xml
safe_call(load_settings_from_xml, settings_file)
