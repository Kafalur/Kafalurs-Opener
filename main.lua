local local_player = get_local_player();
if local_player == nil then
    return
end

local patterns = {
    ["^HarvestNode"] = true,
    ["Door"] = true,
    ["Chest"] = true,
    ["Clicky"] = true,
    ["Cairn"] = true,
    ["Break"] = true,
    ["LooseStone"] = true,
    ["Corpse"] = true,
    ["Switch"] = true,
    ["Shrine"] = true
}
local menu = require("menu");

local last_interact_time = 0
local next_move_time = 0.0

local function matchesAnyPattern(skin_name)
    for pattern, _ in pairs(patterns) do
        if skin_name:match(pattern) then
            return true
        end
    end
    return false
end

on_render_menu(function()
    if not menu.main_tree:push("Kafalurs Opener") then
        return;
    end;
	
    menu.main_boolean:render("Enable Plugin", "");
    if menu.main_boolean:get() == false then
        menu.main_tree:pop();
        return;
    end;
    menu.main_openDoors:render("Open Doors", "");
    menu.main_walkToContainers:render("Walk To Containers", "");
    menu.main_showContainers:render("Show Containers", "");
    menu.main_walkToShrine:render("Walk To Shrine","")
    if menu.main_walkToShrine:get() or menu.main_walkToContainers:get() then
        menu.main_walkDistance:render("Walk Distance", "Set the max distance for walking to shrines and containers", 1)
    end
    menu.main_interactDelay:render("Interaction Delay", "Set the delay between interactions", 1)
    menu.main_tree:pop();
end)

local function get_locked_door(max_distance)
    local actors = actors_manager:get_all_actors()
    local player_pos = get_player_position()

    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name and name:match("Door") then
            local actor_pos = actor:get_position()
            local distance = player_pos:dist_to(actor_pos)
            if distance <= max_distance then
                return actor
            end
        end
    end

    return nil
end

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

local function shouldInteract(obj, playerPos)
    local skin_name = obj:get_skin_name()
    local position = obj:get_position()
    local distanceThreshold = 1.5 -- Default

    if skin_name:match("Shrine") then
        distanceThreshold = 2.5
        if menu.main_walkToShrine:get() and position:dist_to(playerPos) < menu.main_walkDistance:get() then
            if get_time_since_inject() > next_move_time then
                pathfinder.request_move(position)
            end
        end
    elseif skin_name:match("Gate") then
        distanceThreshold = 1.5
    elseif matchesAnyPattern(skin_name) then
        distanceThreshold = 2.5
        if menu.main_walkToContainers:get() and position:dist_to(playerPos) < menu.main_walkDistance:get() then
            if get_time_since_inject() > next_move_time then
                pathfinder.request_move(position)
            end
        end
    else
        return false
    end

    return position:dist_to(playerPos) < distanceThreshold
end

local function process_interactables()
    local playerPos = get_local_player():get_position()
    local objects = actors_manager.get_ally_actors()
    
    for _, obj in ipairs(objects) do 
        if obj:is_interactable() then
            local should_interact = shouldInteract(obj, playerPos)
            if should_interact then
                local success, error_message = pcall(interact_object, obj)
                if success then
                    console.print("Interacting with " .. obj:get_skin_name())
                    last_interact_time = get_time_since_inject()
                    next_move_time = last_interact_time + menu.main_interactDelay:get() + 1.0
                    return true -- Exit the function after interacting with one object
                else
                    console.print("Failed to interact: " .. error_message)
                end
            end
        end
    end
    return false
end

on_update(function()
    local local_player = get_local_player()
    
    if not local_player or not menu.main_boolean:get() then
        return
    end

    local current_time = get_time_since_inject()
    if current_time - last_interact_time >= menu.main_interactDelay:get() then
        if menu.main_walkToContainers:get() then
            if process_interactables() then
                return
            end
        end

        check_and_interact_with_door()
    end
end)

on_render(function()
    local local_player = get_local_player()
    if not local_player or not menu.main_showContainers:get() then
        return
    end

    local objects = actors_manager.get_ally_actors()
    for _, obj in ipairs(objects) do
        if obj:is_interactable() and matchesAnyPattern(obj:get_skin_name()) then
            graphics.circle_3d(obj:get_position(), 1, color_green(255))
            graphics.text_3d("Open", obj:get_position(), 15, color_green(255))
        end
    end
end)

console.print("Kafalurs Opener - Version 1.6");