-- start
local isSynV3 = worldtoscreen ~= nil;

-- localization
local game, workspace, table, math, cframe, vector2, vector3, color3, instance, drawing, raycastParams = game, workspace, table, math, CFrame, Vector2, Vector3, Color3, Instance, Drawing, RaycastParams;
local getService, isA, findFirstChild, getChildren = game.GetService, game.IsA, game.FindFirstChild, game.GetChildren;
local raycast = workspace.Raycast;
local tableInsert, tableFind = table.insert, table.find;
local mathFloor, mathSin, mathCos, mathRad, mathTan, mathAtan2, mathClamp = math.floor, math.sin, math.cos, math.rad, math.tan, math.atan2, math.clamp;
local cframeNew, vector2New, vector3New = cframe.new, vector2.new, vector3.new;
local color3New = color3.new;
local instanceNew, drawingNew = instance.new, drawing.new;
local raycastParamsNew = raycastParams.new;

-- services
local players = getService(game, "Players");
local coreGui = getService(game, "CoreGui");
local runService = getService(game, "RunService");

-- cache
local localPlayer = players.LocalPlayer;
local currentCamera = workspace.CurrentCamera;
local filterType = Enum.RaycastFilterType.Blacklist;
local depthMode = Enum.HighlightDepthMode;
local pi = math.pi;
local lastScale, lastFov;

-- function localization
local getBoundingBox; do
    local model = instanceNew("Model");
    getBoundingBox = model.GetBoundingBox;
    model:Destroy();
end
local ccWorldToViewportPoint = currentCamera.WorldToViewportPoint;
local pointToObjectSpace = cframeNew().PointToObjectSpace;

-- support functions
local function format(tbl, tblMerge, format)
    local formatted = tbl;
    local formattedMerge = tblMerge;

    if (format) then
        for index, value in next, tbl do
            if (typeof(index) == "string") then
                formatted[index:lower()] = value;
            else
                formatted[index] = value;
            end
        end

        for index, value in next, tblMerge do
            if (typeof(index) == "string") then
                formattedMerge[index:lower()] = value;
            else
                formattedMerge[index] = value;
            end
        end
    end

    if (tblMerge) then
        for index, _ in next, formatted do
            if (formattedMerge[index] ~= nil and typeof(formattedMerge[index]) == typeof(formatted[index])) then
                formatted[index] = formattedMerge[index];
            end
        end
    end

    return formatted;
end

local function worldToViewportPoint(position)
    if (isSynV3) then
        local screenPosition = worldtoscreen({ position })[1];
        local depth = screenPosition.Z;
        return vector2New(screenPosition.X, screenPosition.Y), depth > 0, depth;
    end

    local screenPosition, onScreen = ccWorldToViewportPoint(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
end

local function isDrawing(type)
    return type == "Line" or type == "Text" or type == "Image" or type == "Circle" or type == "Square" or type == "Quad" or type == "Triangle"
end

local function create(type, properties)
    local drawing = isDrawing(type);
    local object = drawing and drawingNew(type) or instanceNew(type);

    if (properties) then
        for property, value in next, properties do
            object[property] = value;
        end
    end

    return object;
end

local function rotateVector(vector, angle)
    local c = mathCos(mathRad(angle));
    local s = mathSin(mathRad(angle));
    return vector2New(c * vector.X - s * vector.Y, s * vector.X + c * vector.Y);
end

local function roundVector(vector)
    return vector2New(mathFloor(vector.X), mathFloor(vector.Y));
end

-- main module
local library = {
    _initialized = false,
    _connections = {},
    _espCache = {},
    _soundCache = {},
    _chamsCache = {},
    _objectCache = {},
    _screenGui = create("ScreenGui", {
        Parent = coreGui,
    }),
    settings = {
        enabled = false,
        visibleOnly = false,
        teamCheck = false,
        boxStaticWidth = 4,
        boxStaticHeight = 5,
        maxBoxWidth = 6,
        maxBoxHeight = 6,

        chams = false,
        chamsDepthMode = "AlwaysOnTop",
        chamsInlineColor = color3New(0.701960, 0.721568, 1),
        chamsInlineTransparency = 0,
        chamsOutlineColor = color3New(),
        chamsOutlineTransparency = 0,
        sound = false,
        soundColor = color3New(1, 0, 0),
        names = false,
        nameColor = color3New(1, 1, 1),
        teams = false,
        teamColor = color3New(1, 1, 1),
        teamUseTeamColor = false,
        boxes = false,
        boxColor = color3New(1, 0, 0),
        boxType = "Dynamic",
        boxFill = false,
        boxFillColor = color3New(1, 0, 0),
        boxFillTransparency = 0.5,
        healthbar = false,
        healthbarColor = color3New(0, 1, 0.4),
        healthbarSize = 1,
        healthtext = false,
        healthtextColor = color3New(1, 1, 1),
        distance = false,
        distanceColor = color3New(1, 1, 1),
        weapon = false,
        weaponColor = color3New(1, 1, 1),
        oofArrows = false,
        oofArrowsColor = color3New(0.8, 0.2, 0.2),
        oofArrowsAlpha = 1,
        oofArrowsSize = 30,
        oofArrowsRadius = 150,
    }
};
library.__index = library;

-- support functions
function library:AddConnection(signal, callback)
    local connection = signal:Connect(callback);
    tableInsert(self._connections, connection);
    return connection;
end

-- main functions
function library._getTeam(player)
    return player.Team;
end

function library._getCharacter(player)
    local character = player.Character;
    return character, character and findFirstChild(character, "HumanoidRootPart");
end

function library._getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");

    if (humanoid) then
        return humanoid.Health, humanoid.MaxHealth;
    end

    return 100, 100;
end

function library._getWeapon(player, character)
    return "Hands";
end

function library._visibleCheck(character, origin, target)
    local params = raycastParamsNew();

    params.FilterDescendantsInstances = { library._getCharacter(localPlayer), character, currentCamera };
    params.FilterType = filterType;
    params.IgnoreWater = true;

    return raycast(workspace, origin, target - origin, params) == nil;
end

function library._getScaleFactor(fov, depth)
    if (lastFov ~= fov) then
        lastScale = mathTan(mathRad(fov * 0.5)) * 2;
        lastFov = fov;
    end

    return 1 / (lastScale * depth) * 1000;
end

function library._getBoxSize(model)
    if (library.settings.boxType == "Static" or not isA(model, "Model")) then
        return vector2New(library.settings.boxStaticWidth, library.settings.boxStaticHeight);
    end

    local _, size = getBoundingBox(model);
    return vector2New(mathClamp(size.X, 0, library.settings.maxBoxWidth), mathClamp(size.Y, 0, library.settings.maxBoxHeight));
end

function library._getBoxData(model, depth)
    local size = (typeof(model) == "Vector2" or typeof(model) == "Vector3") and model or library._getBoxSize(model);
    local scaleFactor = library._getScaleFactor(currentCamera.FieldOfView, depth);
    return mathFloor(size.X * scaleFactor), mathFloor(size.Y * scaleFactor);
end

function library._addEsp(player)
    if (player == localPlayer) then
        return
    end

    local font = isSynV3 and 1 or 2;

    local objects = {
        name = create("Text", {
            Color = library.settings.nameColor,
            Text = player.Name,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        team = create("Text", {
            Color = library.settings.teamColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        boxOutline = create("Square", {
            Color = color3New(),
            Transparency = 0.5,
            Thickness = 3,
            Filled = false
        }),
        box = create("Square", {
            Color = library.settings.boxColor,
            Thickness = 1,
            Filled = false
        }),
        boxFill = create("Square", {
            Color = library.settings.boxFillColor,
            Transparency = library.settings.boxFillTransparency,
            Thickness = 1,
            Filled = true
        }),
        healthbarOutline = create("Square", {
            Color = color3New(),
            Transparency = 0.5,
            Thickness = 1,
            Filled = true
        }),
        healthbar = create("Square", {
            Color = library.settings.healthbarColor,
            Thickness = 1,
            Filled = true
        }),
        healthtext = create("Text", {
            Color = library.settings.healthtextColor,
            Size = 13,
            Center = false,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        distance = create("Text", {
            Color = library.settings.distanceColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        weapon = create("Text", {
            Color = library.settings.weaponColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        dot = create("Circle", {
            Color = library.settings.soundColor,
            Thickness = 1,
            NumSides = 128,
            Radius = 5,
            Filled = true,
        }),
        arrow = create("Triangle", {
            Color = library.settings.oofArrowsColor,
            Thickness = 1,
            Filled = true
        })
    };

    library._espCache[player] = objects;
    library._soundCache[player] = 0;
end

function library._removeEsp(player)
    local espCache = library._espCache[player];

    if (espCache) then
        for index, object in next, espCache do
            object:Remove();
            espCache[index] = nil;
        end

        library._espCache[player] = nil;
        library._soundCache[player] = nil;
    end
end

function library._addChams(player)
    if (player == localPlayer) then
        return
    end

    library._chamsCache[player] = create("Highlight", {
        Parent = library._screenGui,
        DepthMode = depthMode[library.settings.chamsDepthMode],
        FillColor = library.settings.chamsInlineColor,
        FillTransparency = library.settings.chamsInlineTransparency,
        OutlineColor = library.settings.chamsOutlineColor,
        OutlineTransparency = library.settings.chamsOutlineTransparency,
    });
end

function library._removeChams(player)
    local chamsCache = library._chamsCache[player];

    if (chamsCache) then
        chamsCache:Destroy();
        library._chamsCache[player] = nil;
    end
end

function library._addObject(object, root, options)
    if (library._objectCache[object]) then
        return
    end

    local font = isSynV3 and 1 or 2;

    local objects = {
        name = create("Text", {
            Color = options.nameColor,
            Text = options.name,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        info = create("Text", {
            Color = options.infoColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        boxOutline = create("Square", {
            Color = color3New(),
            Transparency = 0.5,
            Thickness = 3,
            Filled = false
        }),
        box = create("Square", {
            Color = options.boxColor,
            Thickness = 1,
            Filled = false
        }),
        boxFill = create("Square", {
            Color = options.boxFillColor,
            Transparency = options.boxFillTransparency,
            Thickness = 1,
            Filled = true
        }),
        distance = create("Text", {
            Color = options.distanceColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        })
    };

    library._objectCache[object] = {
        _root = root,
        _options = options,
        _objects = objects
    };
end

function library._removeObject(object)
    local cache = library._objectCache[object];

    if (cache) then
        for index, object in next, cache._objects do
            object:Remove();
            cache[index] = nil;
        end

        library._objectCache[object] = nil;
    end
end

function library:SoundPulsate(player, magnitude)
    local espCache = self._espCache[player];

    if (espCache) then
        espCache.dot.Radius = magnitude * pi;
        self._soundCache[player] = 1;
    end
end

function library:AddObject(object, root, options)
    local defaultOptions = format({
        enabled = false,
        limitDistance = false,
        maxDistance = 250,
        name = object.Name,
        names = false,
        nameColor = color3New(1, 1, 1),
        boxes = false,
        boxColor = color3New(1, 0, 0),
        boxFill = false,
        boxFillColor = color3New(1, 0, 0),
        boxFillTransparency = 0.5,
        text = "",
        info = false,
        infoColor = color3New(1, 1, 1),
        distance = false,
        distanceColor = color3New(1, 1, 1)
    }, options, true);

    if (isA(object, "Model") or isA(object, "BasePart")) then
        self._addObject(object, root, defaultOptions);
    end

    return defaultOptions;
end

function library:RemoveObject(object)
    self._removeObject(object);
end

function library:Load()
    if (self._initialized) then
        return
    end

    self._initialized = true;

    for _, player in next, players:GetPlayers() do
        self._addEsp(player);
        self._addChams(player);
    end

    self:AddConnection(players.PlayerAdded, function(player)
        self._addEsp(player);
        self._addChams(player);
    end);

    self:AddConnection(players.PlayerRemoving, function(player)
        self._removeEsp(player);
        self._removeChams(player);
    end);

    self:AddConnection(workspace.DescendantRemoving, function(object)
        self._removeObject(object);
    end);

    self:AddConnection(runService.Heartbeat, function()
        for object, cache in next, self._objectCache do
            local options, objects, root = cache._options, cache._objects, cache._root;

            local cameraCFrame = currentCamera.CFrame;
            local cameraPosition, rootPosition = cameraCFrame.Position, root.Position;
            local magnitude = (cameraPosition - rootPosition).Magnitude;

            local enabled = options.enabled;

            if (options.limitDistance and magnitude > options.maxDistance) then
                enabled = false;
            end

            if (options and objects and root and enabled) then
                local rootPosition, onScreen, depth = worldToViewportPoint(rootPosition);

                local x, y = rootPosition.X, rootPosition.Y;
                local width, height = self._getBoxData(object, depth);
                local boxSize = vector2New(width, height);
                local boxPosition = vector2New(mathFloor(x - width * 0.5), mathFloor(y - height * 0.5));

                objects.name.Visible = onScreen and options.names;
                objects.name.Position = vector2New(x, boxPosition.Y - objects.name.TextBounds.Y - 2);

                objects.info.Visible = onScreen and options.info;
                objects.info.Text = options.text;
                objects.info.Color = options.infoColor;
                objects.info.Position = vector2New(x + width * 0.5 + objects.info.TextBounds.X * 0.5 + 2, boxPosition.Y - 2);

                objects.box.Visible = onScreen and options.boxes;
                objects.box.Color = options.boxColor;
                objects.box.Size = boxSize;
                objects.box.Position = boxPosition;

                objects.boxOutline.Visible = objects.box.Visible;
                objects.boxOutline.Size = boxSize;
                objects.boxOutline.Position = boxPosition;

                objects.boxFill.Visible = onScreen and options.boxFill;
                objects.boxFill.Color = options.boxFillColor;
                objects.boxFill.Transparency = options.boxFillTransparency;
                objects.boxFill.Size = boxSize;
                objects.boxFill.Position = boxPosition;

                objects.distance.Visible = onScreen and options.distance;
                objects.distance.Text = mathFloor(magnitude) .. " Studs";
                objects.distance.Color = options.distanceColor;
                objects.distance.Position = vector2New(x, boxPosition.Y + height);
            else
                for _, object in next, objects do
                    object.Visible = false;
                end
            end
        end
    end);

    self:AddConnection(runService.Heartbeat, function()
        for player, highlight in next, self._chamsCache do
            local team = self._getTeam(player);
            local character = self._getCharacter(player);

            if (character) then
                local enabled = self.settings.enabled and self.settings.chams;

                if (self.settings.teamCheck and team == self._getTeam(localPlayer)) then
                    enabled = false
                end

                highlight.Enabled = enabled;
                highlight.Adornee = character;
                highlight.DepthMode = depthMode[self.settings.chamsDepthMode];
                highlight.FillColor = self.settings.chamsInlineColor;
                highlight.FillTransparency = self.settings.chamsInlineTransparency;
                highlight.OutlineColor = self.settings.chamsOutlineColor;
                highlight.OutlineTransparency = self.settings.chamsOutlineTransparency;
            else
                highlight.Enabled = false;
                highlight.Adornee = nil;
            end
        end
    end);

    self:AddConnection(runService.Heartbeat, function(deltaTime)
        for player, cache in next, self._espCache do
            self._soundCache[player] = math.clamp(self._soundCache[player] - (deltaTime * 5), 0, 1);

            local team = self._getTeam(player);
            local character, root = self._getCharacter(player);
            local enabled = self.settings.enabled;

            if (self.settings.teamCheck and team == self._getTeam(localPlayer)) then
                enabled = false
            end

            if (enabled and character and root) then
                local enabled = true;
                local cameraCFrame = currentCamera.CFrame;
                local cameraPosition, rootPosition = cameraCFrame.Position, root.Position;

                if (self.settings.visibleOnly and not self._visibleCheck(character, cameraPosition, rootPosition)) then
                    enabled = false;
                end

                if (enabled) then
                    local torsoPosition, onScreen, depth = worldToViewportPoint(rootPosition);

                    local x, y = torsoPosition.X, torsoPosition.Y;
                    local width, height = self._getBoxData(character, depth);
                    local boxSize = vector2New(width, height);
                    local boxPosition = vector2New(mathFloor(x - width * 0.5), mathFloor(y - height * 0.5));

                    local health, maxHealth = self._getHealth(player, character);
                    local barSize = self.settings.healthbarSize;
                    local healthbarSize = vector2New(isSynV3 and barSize - 1 or barSize, height);
                    local healthbarPosition = boxPosition - vector2New(healthbarSize.X + (isSynV3 and 4 or 3), 0);

                    local objectSpace = pointToObjectSpace(cameraCFrame, rootPosition);
                    local angle = mathAtan2(objectSpace.Z, objectSpace.X);
                    local direction = vector2New(mathCos(angle), mathSin(angle));
                    local viewportSize = currentCamera.ViewportSize;
                    local screenCenter = vector2New(viewportSize.X * 0.5, viewportSize.Y * 0.5);
                    local arrowPosition = screenCenter + direction * self.settings.oofArrowsRadius;

                    cache.arrow.Visible = not onScreen and self.settings.oofArrows;

                    if (cache.arrow.Visible) then
                        cache.arrow.Color = self.settings.oofArrowsColor;
                        cache.arrow.Transparency = self.settings.oofArrowsAlpha;
                        cache.arrow.PointA = roundVector(arrowPosition);
                        cache.arrow.PointB = roundVector(arrowPosition - rotateVector(direction, 30) * self.settings.oofArrowsSize);
                        cache.arrow.PointC = roundVector(arrowPosition - rotateVector(direction, -30) * self.settings.oofArrowsSize);
                    end

                    cache.dot.Visible = not onScreen and self.settings.sound;

                    if (cache.dot.Visible) then
                        cache.dot.Color = self.settings.soundColor;
                        cache.dot.Transparency = self._soundCache[player];
                        cache.dot.Position = roundVector(screenCenter + direction * 250);
                    end

                    cache.name.Visible = onScreen and self.settings.names;

                    if (cache.name.Visible) then
                        cache.name.Color = self.settings.nameColor;
                        cache.name.Position = vector2New(x, boxPosition.Y - cache.name.TextBounds.Y - 2);
                    end

                    cache.team.Visible = onScreen and self.settings.teams;

                    if (cache.team.Visible) then
                        cache.team.Text = team ~= nil and team.Name or "No Team";
                        cache.team.Color = (self.settings.teamUseTeamColor and team ~= nil) and team.TeamColor.Color or self.settings.teamColor;
                        cache.team.Position = vector2New(x + width * 0.5 + cache.team.TextBounds.X * 0.5 + 2, boxPosition.Y - 2);
                    end

                    cache.box.Visible = onScreen and self.settings.boxes;

                    if (cache.box.Visible) then
                        cache.box.Color = self.settings.boxColor;
                        cache.box.Size = boxSize;
                        cache.box.Position = boxPosition;
                    end

                    cache.boxOutline.Visible = cache.box.Visible;

                    if (cache.boxOutline.Visible) then
                        cache.boxOutline.Size = boxSize;
                        cache.boxOutline.Position = boxPosition;
                    end

                    cache.boxFill.Visible = onScreen and self.settings.boxFill;

                    if (cache.boxFill.Visible) then
                        cache.boxFill.Color = self.settings.boxFillColor;
                        cache.boxFill.Transparency = self.settings.boxFillTransparency;
                        cache.boxFill.Size = boxSize;
                        cache.boxFill.Position = boxPosition;
                    end

                    cache.healthbar.Visible = onScreen and self.settings.healthbar;

                    if (cache.healthbar.Visible) then
                        cache.healthbar.Color = self.settings.healthbarColor;
                        cache.healthbar.Size = vector2New(healthbarSize.X, -(height * (health / maxHealth)));
                        cache.healthbar.Position = healthbarPosition + vector2New(0, height);
                    end

                    cache.healthbarOutline.Visible = cache.healthbar.Visible;

                    if (cache.healthbarOutline.Visible) then
                        cache.healthbarOutline.Size = healthbarSize + vector2New(2, 2);
                        cache.healthbarOutline.Position = healthbarPosition - vector2New(1, 1);
                    end

                    cache.healthtext.Visible = onScreen and self.settings.healthtext;

                    if (cache.healthtext.Visible) then
                        cache.healthtext.Text = mathFloor(health) .. " HP";
                        cache.healthtext.Color = self.settings.healthtextColor;
                        cache.healthtext.Position = healthbarPosition - vector2New(cache.healthtext.TextBounds.X + 2, -(height * (1 - (health / maxHealth))) + 2);
                    end

                    cache.distance.Visible = onScreen and self.settings.distance;

                    if (cache.distance.Visible) then
                        cache.distance.Text = mathFloor((cameraPosition - rootPosition).Magnitude) .. " Studs";
                        cache.distance.Color = self.settings.distanceColor;
                        cache.distance.Position = vector2New(x, boxPosition.Y + height);
                    end

                    cache.weapon.Visible = onScreen and self.settings.weapon;

                    if (cache.weapon.Visible) then
                        cache.weapon.Text = self._getWeapon(player, character);
                        cache.weapon.Color = self.settings.weaponColor;
                        cache.weapon.Position = vector2New(x, boxPosition.Y + height + (cache.distance.Visible and cache.distance.TextBounds.Y + 1 or 0));
                    end
                else
                    for _, object in next, cache do
                        object.Visible = false;
                    end
                end
            else
                for _, object in next, cache do
                    object.Visible = false;
                end
            end
        end
    end);
end

function library:Unload()
    if (not self._initialized) then
        return
    end

    self._initialized = false;
    self._screenGui:Destroy();

    for index, connection in next, self._connections do
        connection:Disconnect();
        self._connections[index] = nil;
    end

    for _, player in next, players:GetPlayers() do
        self._removeEsp(player);
        self._removeChams(player);
    end

    for object, _ in next, self._objectCache do
        self._removeObject(object);
    end
end

return setmetatable({}, library);
