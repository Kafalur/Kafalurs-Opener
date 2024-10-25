--- Get the local player object
local local_player = get_local_player();
if local_player == nil then
    return
end

--- loading modules
local patterns = require("data.patterns")
local menu_module = require("menu")
local menu = menu_module.elements;

--- Initialize timing variables
local last_interact_time = 0
local next_move_time = 0.0

--- Check if a skin name matches any of the defined patterns
---@param skin_name string The skin name to check
---@param patterns table A table of pattern strings to match against
---@return boolean True if the skin name matches any pattern, false otherwise
local function matchesAnyPattern(skin_name, patterns)
    for _, pattern in ipairs(patterns) do
        if skin_name:match(pattern) then
            return true
        end
    end
    return false
end



--- Get the nearest locked door within a specified distance
---@param max_distance number The maximum distance to search for a door
---@return Actor|nil The nearest locked door actor, or nil if none found
local function get_locked_door(max_distance)
    local actors = actors_manager:get_all_actors()
    local player_pos = get_player_position()

    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name and name:match(patterns["DoorLocked"]) then
            local actor_pos = actor:get_position()
            local distance = player_pos:dist_to(actor_pos)
            if distance <= max_distance then
                return actor
            end
        end
    end

    return nil
end

--- Check for and interact with a nearby door
local function check_and_interact_with_door()
    if not menu.main_openDoors:get() then
        return
    end

    local locked_door = get_locked_door(10)
    if locked_door then
        if locked_door:get_position():dist_to(get_local_player():get_position()) < 4 then
            local success, error_message = pcall(interact_object, locked_door)
            if success then
                last_interact_time = get_time_since_inject()
                next_move_time = get_time_since_inject() + menu.main_interactDelay:get() + 1.0
            else
                console.print("Failed to interact with door: " .. error_message)
            end
        end
    end
end

--- Helper function to get the nearest object matching any of the given patterns
---@param playerPos Vector3 The player's position
---@param categoryPatterns table A table of pattern strings to match against
---@return Actor|nil The nearest matching object, or nil if none found
local function get_nearest_object(playerPos, categoryPatterns)
    local objects = actors_manager:get_all_actors()
    local nearest_obj = nil
    local min_distance = math.huge

    for _, obj in ipairs(objects) do
        if obj and obj:is_interactable() then
            local obj_name
            if obj.get_name then
                obj_name = obj:get_name()
            elseif obj.get_skin_name then
                obj_name = obj:get_skin_name()
            else
                obj_name = "Unknown"
            end

            for _, pattern in ipairs(categoryPatterns) do
                if obj_name and patterns[pattern] and obj_name:match(pattern) then
                    local distance = obj:get_position():dist_to(playerPos)
                    if distance < min_distance and distance <= menu.main_walkDistance:get() then
                        min_distance = distance
                        nearest_obj = obj
                    end
                    break  -- No need to check other patterns for this object
                end
            end
        end
    end

    return nearest_obj
end

--- Central function to handle movement towards different object categories
---@param playerPos Vector3 The current position of the player
---@return boolean True if movement was initiated, false otherwise
local function handle_movement(playerPos)
    local categories = {
        {name = "Containers", menuOption = menu.main_walkToContainers, showOption = menu.main_showContainers, patterns = {
            "^HarvestNode", "Chest", "Clicky", "Cairn", "Break", "LooseStone", "Corpse", "Switch", "Clickable"
        }},
        {name = "Shrines", menuOption = menu.main_walkToShrine, showOption = menu.main_showShrines, patterns = {"Shrine"}},
        {name = "Doors", menuOption = menu.main_walkToDoors, showOption = menu.main_openDoors, patterns = {"DoorLocked"}},
    }

    for _, category in ipairs(categories) do
        if category.menuOption:get() then
            local nearest_obj = get_nearest_object(playerPos, category.patterns)
            if nearest_obj then
                local obj_pos = nearest_obj:get_position()
                local distance = obj_pos:dist_to(playerPos)
                
                if distance > 2.5 and get_time_since_inject() > next_move_time then
                    pathfinder.request_move(obj_pos)
                    next_move_time = get_time_since_inject() + 0.5
                    console.print("Moving towards " .. category.name)
                    return true
                elseif distance <= 2.5 then
                    local success, error_message = pcall(interact_object, nearest_obj)
                    if success then
                        local obj_name = nearest_obj:get_skin_name() or "Unknown object"
                        console.print("Interacting with " .. obj_name)
                        last_interact_time = get_time_since_inject()
                        next_move_time = last_interact_time + menu.main_interactDelay:get() + 1.0
                        return true
                    else
                        console.print("Failed to interact: " .. error_message)
                    end
                end
            end
        end
    end
    return false
end

--- Update function called every frame
on_update(function()
    local local_player = get_local_player()
    
    if not local_player or not menu.main_boolean:get() then
        return
    end

    local current_time = get_time_since_inject()
    if current_time - last_interact_time >= menu.main_interactDelay:get() then
        local playerPos = local_player:get_position()
        handle_movement(playerPos)
    end
end)

--- Render function called every frame
on_render(function()
    local local_player = get_local_player()
    if not local_player then
        return
    end

    local objects = actors_manager:get_all_actors()
    for _, obj in ipairs(objects) do
        if obj:is_interactable() then
            local obj_name = obj:get_skin_name() or "Unknown"
            
            local categories = {
                {showOption = menu.main_showContainers, patterns = {"^HarvestNode", "Chest", "Clicky", "Cairn", "Break", "LooseStone", "Corpse", "Switch", "Clickable"}, color = color_yellow(255)},
                {showOption = menu.main_showShrines, patterns = {"Shrine"}, color = color_yellow(200)},  -- Slightly dimmer yellow
                {showOption = menu.main_openDoors, patterns = {"DoorLocked"}, color = color_green(255)},
            }

            for _, category in ipairs(categories) do
                if category.showOption:get() and matchesAnyPattern(obj_name, category.patterns) then
                    graphics.circle_3d(obj:get_position(), 1, category.color)
                    graphics.text_3d(obj_name, obj:get_position(), 15, category.color)
                    break
                end
            end
        end
    end
end)

--- Version information
local VERSION = {
    MAJOR = 1,
    MINOR = 1,
    PATCH = 0
}

--- Function to get the formatted version string
local function get_version_string()
    return string.format("V%d.%d.%d", VERSION.MAJOR, VERSION.MINOR, VERSION.PATCH)
end

--- Print the plugin version to the console
console.print(string.format("Kafalurs Opener %s", get_version_string()));

--- Render the plugin menu
on_render_menu(function()
    menu_module.render()
end)
