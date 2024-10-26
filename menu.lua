--- Prefix for plugin-specific hashes
local plugin_version = "1.0.1"
local plugin_label = "Auto Opener | Kafalur | V" .. plugin_version

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
    
    -- New submenus
    doors_tree = tree_node:new(0),
    containers_tree = tree_node:new(0),
    shrine_tree = tree_node:new(0),
    settings_tree = tree_node:new(0),

    -- Existing elements
    main_openDoors = checkbox:new(true, get_plugin_hash("main_openDoors")),
    main_walkToDoors = checkbox:new(true, get_plugin_hash("main_walkToDoors")),
    main_walkToContainers = checkbox:new(true, get_plugin_hash("main_walkToContainers")),
    main_showContainers = checkbox:new(true, get_plugin_hash("main_showContainers")),
    main_walkToShrine = checkbox:new(true, get_plugin_hash("main_walkToShrine")),
    main_walkDistance = slider_float:new(0.0, 20.0, 12.0, get_hash("main_walkDistance")),
    main_interactDelay = slider_float:new(0.0, 10.0, 1.0, get_hash("main_interactDelay")),
    main_showShrines = checkbox:new(true, get_plugin_hash("main_showShrines")),
}

--- Render the plugin menu
local function render_menu()
    if not menu_elements.main_tree:push(plugin_label) then
        return
    end
    
    menu_elements.main_boolean:render("Enable Plugin", "Activates or deactivates the entire plugin")
    
    if menu_elements.doors_tree:push("Doors") then
        menu_elements.main_walkToDoors:render("Walk to Doors", "Walk to doors to open them")
        menu_elements.main_openDoors:render("Show Doors", "Highlight doors in the vicinity")
        menu_elements.doors_tree:pop()
    end
    
    if menu_elements.containers_tree:push("Containers") then
        menu_elements.main_walkToContainers:render("Walk to Containers", "Automatically walk to containers")
        menu_elements.main_showContainers:render("Show Containers", "Highlight containers in the vicinity")
        menu_elements.containers_tree:pop()
    end
    
    if menu_elements.shrine_tree:push("Shrines") then
        menu_elements.main_walkToShrine:render("Walk to Shrines", "Automatically walk to shrines")
        -- Add this new line
        menu_elements.main_showShrines:render("Show Shrines", "Highlight shrines in the vicinity")
        menu_elements.shrine_tree:pop()
    end
    
    if menu_elements.settings_tree:push("Settings") then
        menu_elements.main_walkDistance:render("Walk Distance", "Maximum distance for walking to objects", 1)
        menu_elements.main_interactDelay:render("Interaction Delay", "Delay between interactions", 1)
        menu_elements.settings_tree:pop()
    end
    
    menu_elements.main_tree:pop()
end

--- Return the menu elements table and render function
return {
    elements = menu_elements,
    render = render_menu
}
