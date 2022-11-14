-- start
local name = "Isurus";
local version = "1.0";

local username = "VoidMasterX";
local repository = "Isurus";
local baseUrl = "https://raw.githubusercontent.com/" .. username .. "/" .. repository .. "/main";

local function import(file)
    return game:HttpGet(baseUrl .. file);
end

local function loadLibrary(library)
    return loadstring(import("/libraries/" .. library .. ".lua"))();
end

-- libraries
local library = loadLibrary("ui");

-- ui
do
    local window = library:load({
        name = name .. " - v" .. version,
        sizex = 450,
        sizey = 460,
        theme = "Midnight",
        folder = name,
        extension = ".json"
    }); do
        local legitbot = window:tab("Legitbot"); do
            local aimbot = legitbot:section({ name = "Aimbot", side = "left" }); do
                aimbot:toggle({ name = "Enabled", flag = "legitbot_aimbot_enabled" });
            end
        end

        local settings = window:tab("Settings"); do
            local configuration = settings:section({ name = "Configuration", side = "left" }); do
                configuration:button({ name = "Unload", callback = function()
                    library:Unload();
                end });
            end
        end
    end
end