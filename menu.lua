--- Prefix for plugin-specific hashes
local plugin_label = "Kafalurs_Opener_PLUGIN_"

--- Generate a unique hash for a plugin element
---@param name string The name of the plugin element
---@return number The generated hash
local function get_plugin_hash(name)
    return get_hash(plugin_label .. name)
end

--- Menu elements for the Kafalurs Opener plugin
---@type table<string, any>
local menu_elements = {
    --- Main tree node for the plugin
    main_tree = tree_node:new(0),
    --- Checkbox to enable/disable the plugin
    main_boolean = checkbox:new(true, get_plugin_hash("main_boolean")),
    --- Checkbox to enable/disable door opening
    main_openDoors = checkbox:new(true, get_plugin_hash("main_openDoors")),
    --- Checkbox to enable/disable walking to containers
    main_walkToContainers = checkbox:new(true, get_plugin_hash("main_walkToContainers")),
    --- Checkbox to enable/disable showing containers
    main_showContainers = checkbox:new(true, get_plugin_hash("main_showContainers")),
    --- Checkbox to enable/disable walking to shrines
    main_walkToShrine = checkbox:new(true, get_plugin_hash("main_walkToShrine")),
    --- Slider to set the maximum walk distance
    main_walkDistance = slider_float:new(0.0, 20.0, 12.0, get_hash("main_walkDistance")),
    --- Slider to set the interaction delay
    main_interactDelay = slider_float:new(0.0, 10.0, 1.0, get_hash("main_interactDelay"))
}

--- Return the menu elements table
return menu_elements