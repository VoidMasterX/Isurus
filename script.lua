local version = "1.0";
local username = "VoidMasterX";
local repository = "Isurus";
local baseUrl = "https://raw.githubusercontent.com/" .. username .. "/" .. repository .. "/main/";

local function import(file)
    return game:HttpGet(baseUrl .. file);
end

local function loadLibrary(library)
    return loadstring(import("libraries/" .. library .. ".lua"))();
end

local libraries = {
    ui = loadLibrary("ui"),
    esp = loadLibrary("esp"),
};

local sharedRequire = getrenv().shared.require;
local replicationInterface = sharedRequire("ReplicationInterface");

local framework = {};

-- combat
do
    
end

-- visuals
do
    local espLibrary = libraries.esp;

    function espLibrary._getCharacter(player)
        local entry = replicationInterface.getEntry(player);
        local thirdPersonObject = entry and entry:getThirdPersonObject();
        local character = thirdPersonObject and thirdPersonObject:getCharacterModel();
        return character, character and character:FindFirstChild("Torso");
    end

    function espLibrary._getPlayerFromCharacter(character)
        return replicationInterface.getPlayerFromBodyPart(character:FindFirstChild("Torso"));
    end

    function espLibrary._getHealth(player)
        local entry = replicationInterface.getEntry(player);

        if (entry) then
            return entry:getHealth();
        end

        return 100, 100;
    end

    function espLibrary._getWeapon(player, _)
        local entry = replicationInterface.getEntry(player);
        return entry and entry:getThirdPersonObject()._weaponname or "Unknown";
    end

    espLibrary.settings.teamUseTeamColor = true;

    espLibrary:Load();
end

-- hooks
do
    
end

-- ui
do
    local library = libraries.ui;

    library.font = (worldtoscreen ~= nil) and 1 or 2;

    local window = library:load({
        name = repository .. " - v" .. version,
        sizex = 450,
        sizey = 460,
        theme = "Midnight",
        folder = repository,
        extension = ".json"
    }); do
        local legitbot = window:tab("Legitbot"); do
            local aimbot = legitbot:section({ name = "Aimbot", side = "left" }); do
                aimbot:toggle({ name = "Enabled", flag = "legitbot_aimbot_enabled" });
                aimbot:toggle({ name = "Visible Check", flag = "legitbot_aimbot_visiblecheck" });
                local showFOV = aimbot:toggle({ name = "Show Field Of View", flag = "legitbot_aimbot_showfov" });
                showFOV:colorpicker({ default = Color3.new(1, 1, 1), flag = "legitbot_aimbot_fovcolor" });
                showFOV:slider({ name = "Field Of View", min = 0, max = 20, default = 10, flag = "legitbot_aimbot_fov" });
                aimbot:slider({
                    name = "Smoothing", min = 3, max = 100, default = 10, flag = "legitbot_aimbot_smoothing" });
                end
            end
    
            local visuals = window:tab("Visuals"); do
                local esp = visuals:section({ name = "Esp", side = "left" }); do
                    esp:toggle({ name = "Enabled", flag = "visuals_esp_enabled", callback = function(state)
                        espLibrary.settings.enabled = state;
                    end });
                    esp:toggle({ name = "Names", flag = "visuals_esp_names", callback = function(state)
                        espLibrary.settings.names = state;
                    end });
                    esp:toggle({ name = "Team", flag = "visuals_esp_team", callback = function(state)
                        espLibrary.settings.teams = state;
                    end });
                    local boxes = esp:toggle({ name = "Boxes", flag = "visuals_esp_boxes", callback = function(state)
                        espLibrary.settings.boxes = state;
                    end });
                    boxes:colorpicker({ default = Color3.new(1, 1, 1), flag = "visuals_esp_boxcolor" });
                    esp:toggle({ name = "Health", flag = "visuals_esp_health", callback = function(state)
                        espLibrary.settings.health = state;
                    end });
                    esp:toggle({ name = "Weapons", flag = "visuals_esp_weapons", callback = function(state)
                        espLibrary.settings.weapons = state;
                    end });
                end
    
                local chams = visuals:section({ name = "Chams", side = "right" }); do
                    chams:toggle({ name = "Enabled", flag = "visuals_chams_enabled", callback = function(state)
                        espLibrary.settings.chams = state;
                    end });
                    chams:colorpicker({ default = Color3.new(1, 1, 1), flag = "visuals_chams_color" });
                    chams:toggle({ name = "Material", flag = "visuals_chams_material", callback = function(state)
                        espLibrary.settings.chamsMaterial = state;
                    end });
                    chams:dropdown({ name = "Material Type", options = { "Plastic", "Neon", "Glow", "Glass", "Crystal", "Gold" }, flag = "visuals_chams_materialtype" });
                    chams:toggle({ name = "Wireframe", flag = "visuals_chams_wireframe", callback = function(state)
                        espLibrary.settings.wireframe = state;
                    end });
                end
            end
    
            local radar = window:tab("Radar"); do
                local settings = radar:section({ name = "Settings", side = "left" }); do
                    settings:toggle({ name = "Enabled", flag = "radar_enabled" });
                    settings:toggle({ name = "Show Team", flag = "radar_showteam" });
                    settings:toggle({ name = "Show Enemy", flag = "radar_showenemy" });
                    settings:toggle({ name = "Show Weapons", flag = "radar_showweapons" });
                    local size = settings:slider({ name = "Size", min = 200, max = 800, default = 400, flag = "radar_size" });
                    size:slider({ name = "X Offset", min = 0, max = 800, default = 400, flag = "radar_offset_x" });
                    size:slider({ name = "Y Offset", min = 0, max = 600, default = 300, flag = "radar_offset_y" });
                end
    
                local colors = radar:section({ name = "Colors", side = "right" }); do
                    colors:colorpicker({ default = Color3.new(1, 1, 1), flag = "radar_color_ally" });
                    colors:colorpicker({ default = Color3.new(1, 1, 1), flag = "radar_color_enemy" });
                    colors:colorpicker({ default = Color3.new(1, 1, 1), flag = "radar_color_weapon" });
                end
            end
        end
    
        window:show();
    end
