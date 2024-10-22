local plugin_label = "Kafalurs_Opener_PLUGIN_"

local function get_plugin_hash(name)
    return get_hash(plugin_label .. name)
end

local menu_elements = {
    main_tree = tree_node:new(0),
    main_boolean = checkbox:new(true, get_plugin_hash("main_boolean")),
    main_openDoors = checkbox:new(true, get_plugin_hash("main_openDoors")),
    main_walkToContainers = checkbox:new(true, get_plugin_hash("main_walkToContainers")),
    main_showContainers = checkbox:new(true, get_plugin_hash("main_showContainers")),
    main_walkToShrine = checkbox:new(true, get_plugin_hash("main_walkToShrine")),
    main_walkDistance = slider_float:new(0.0, 20.0, 12.0, get_hash("main_walkDistance")),
}

return menu_elements