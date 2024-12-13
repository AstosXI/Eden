--[[ 
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'atom0s';
_addon.name     = 'debuff';
_addon.version  = '3.0.0';

require 'common'

-- Default configuration
local default_config = {
    font = {
        family = 'Tahoma',
        size = 12,
        color = 0xFFFFFFFF,
        position = {200, 200},
    },
    bgcolor = 0x80000000,
    bgvisible = true,
};
local debuff_config = default_config

local show_buffs = false
local buff_font = nil  -- Font object to display buffs

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Load the configuration
    debuff_config = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', debuff_config)

    -- Create the font object for displaying buffs
    buff_font = AshitaCore:GetFontManager():Create('__buff_display')
    buff_font:SetFontFamily(debuff_config.font.family)
    buff_font:SetFontHeight(debuff_config.font.size)
    buff_font:SetColor(debuff_config.font.color)
    buff_font:SetPositionX(debuff_config.font.position[1])
    buff_font:SetPositionY(debuff_config.font.position[2])
    buff_font:GetBackground():SetColor(debuff_config.bgcolor)
    buff_font:GetBackground():SetVisibility(debuff_config.bgvisible)
    buff_font:SetText("")  -- Set initial text to empty
    buff_font:SetVisibility(false)  -- Initially hidden
end)

----------------------------------------------------------------------------------------------------
-- func: getPlayerBuffs
-- desc: Retrieves the player's active buffs with their IDs and names.
----------------------------------------------------------------------------------------------------
local function getPlayerBuffs()
    local player = AshitaCore:GetDataManager():GetPlayer()
    if not player then
        return {}
    end

    local resources = AshitaCore:GetResourceManager()
    local buffs = {}

    -- Collect active buffs for the player
    for i = 0, 31 do
        local buff_id = player:GetBuffs()[i]
        if buff_id ~= -1 then
            local buff_name = resources:GetString('statusnames', buff_id) or "Unknown"
            table.insert(buffs, { id = buff_id, name = buff_name })
        end
    end
    return buffs
end

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is rendering.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    if not show_buffs or buff_font == nil then
        return
    end

    -- Retrieve active buffs
    local buffs = getPlayerBuffs()
    local buff_text = {}

    -- Build text display for each active buff
    for _, buff_info in ipairs(buffs) do
        table.insert(buff_text, string.format('[%d] %s', buff_info.id, buff_info.name))
    end

    -- Update font display text
    buff_font:SetText(table.concat(buff_text, '\n'))
    buff_font:SetVisibility(true)
end)

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    local args = command:args()
    if args[1] == '/debuff' or args[1] == '/cancel' then
        if #args ~= 2 then return true end

        local buffid = tonumber(args[2])
        if buffid == nil then
            local buffname = command:gsub('([\/%w]+) ', '', 1):trim()
            for x = 0, 640 do
                local name = AshitaCore:GetResourceManager():GetString('statusnames', x)
                if name and name:lower() == buffname:lower() then
                    buffid = x
                    break
                end
            end
        end

        if buffid and buffid > 0 then
            local debuff = struct.pack("bbbbhbb", 0xF1, 0x04, 0x00, 0x00, buffid, 0x00, 0x00):totable()
            AddOutgoingPacket(0xF1, debuff)
        end
        return true
    elseif args[1] == '/showbuffs' then
        show_buffs = not show_buffs
        print('[Debuff] Buff display ' .. (show_buffs and 'enabled' or 'disabled'))

        if not show_buffs and buff_font then
            buff_font:SetVisibility(false)
            buff_font:SetText("")  -- Clear text when disabled
        end
        return true
    end

    return false
end)

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    if buff_font then
        debuff_config.font.position = { buff_font:GetPositionX(), buff_font:GetPositionY() }
        AshitaCore:GetFontManager():Delete('__buff_display')
        buff_font = nil
    end
end)
