local local_player = get_local_player();
if local_player == nil then
    return
end

local patterns = { "^HarvestNode","Door", "Chest", "Clicky", "Cairn", "Break", "LooseStone", "Corpse", "Switch" }
local menu = require("menu");

local last_update_time = 0
local update_interval = 0.1

local function matchesAnyPattern(skin_name, extra)
    for _, pattern in ipairs(patterns) do
        if not extra and skin_name:match(pattern) or extra and (skin_name:match(pattern) or skin_name:match("Shrine")) then
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
    menu.main_openContainers:render("Open Containers", "");
    menu.main_showContainers:render("Show Containers", "");
    menu.main_walkToShrine:render("Walk To Shrine","")
    if menu.main_walkToShrine:get() then
        menu.main_walkDistance:render("Distance", "Set the max distance", 1)
    end
    menu.main_interactDelay:render("Interaction Delay", "Set the delay between interactions", 0.1, 0.1, 1.0, 0.1)
    menu.main_tree:pop();
end)

local actors_cache = {}
local Interact_Delay = 0.0;

local function contains(s, substring)
    return s:find(substring) ~= nil
end

local function get_locked_door(max_distance)
    local actors = actors_manager:get_all_actors()
    local player_pos = get_player_position()

    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name and (contains(name, "Door")) then
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
            interact_object(locked_door)
            Interact_Delay = get_time_since_inject() + menu.main_interactDelay:get()
        end
    end
end

local function shouldInteract(obj, playerPos)
    local skin_name = obj:get_skin_name()
    local position = obj:get_position()
    local distanceThreshold = 1.5 -- Default

    -- Determine interaction threshold based on object type
    if skin_name:match("Shrine") then
        distanceThreshold = 2.5
        if menu.main_walkToShrine:get() and position:dist_to(playerPos) < menu.main_walkDistance:get() then
            pathfinder.request_move(position)
        end
    elseif skin_name:match("Gate") then
        distanceThreshold = 1.5
    elseif not matchesAnyPattern(skin_name) then
        return false
    end

    return position:dist_to(playerPos) < distanceThreshold
end

on_update(function()
    local local_player = get_local_player()
    
    if not local_player or not menu.main_boolean:get() or get_time_since_inject() < Interact_Delay then
        return
    end

    if menu.main_openContainers:get() then
        local playerPos = local_player:get_position()
        local objects = actors_manager.get_ally_actors()
        
        actors_cache = {}
        
        for _, obj in ipairs(objects) do 
            if obj:is_interactable() then
                local should_interact = shouldInteract(obj, playerPos)
                if should_interact then
                    -- Add error handling for interact_object
                    local success, error_message = pcall(function()
                        interact_object(obj)
                    end)
                    if success then
                        console.print("Interacting with " .. obj:get_skin_name())
                        Interact_Delay = get_time_since_inject() + menu.main_interactDelay:get()
                        break -- Exit the loop after interacting with one object
                    else
                        console.print("Failed to interact: " .. error_message)
                    end
                end
                -- Add object to cache regardless of interaction
                table.insert(actors_cache, {Object = obj, position = obj:get_position(), skin_name = obj:get_skin_name()})
            end
        end
    end

    check_and_interact_with_door()
end)

on_render(function()
    local local_player = get_local_player()
    if not local_player or not menu.main_showContainers:get() then
        return
    end

    for _, obj in ipairs(actors_cache) do
        if obj.Object:is_interactable() and matchesAnyPattern(obj.skin_name, true) then
            graphics.circle_3d(obj.position, 1, color_green(255))
            graphics.text_3d("Open", obj.position, 15, color_green(255))
        end
    end
end);

console.print("Kafalurs Opener - Version 1.3");