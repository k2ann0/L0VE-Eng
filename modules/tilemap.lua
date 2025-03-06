local State = require "state"
local Console = require "modules.console"
local Camera = require "modules.camera"

local Tilemap = {
    currentTile = nil,
    tileSize = 32,
    mapWidth = 20,
    mapHeight = 15,
    showGrid = true,
    brushSize = 1,
    eraserMode = false,
    selectedLayer = 1,
    showTilemapWindow = false
}

function Tilemap:init()
    self.tilesets = {}
    self.currentTileset = nil
    State.showWindows.tilemap = false
    State.windowSizes.tilemap = {width = 400, height = 500}
    Console:log("Tilemap module initialized")
end

function Tilemap:createTilemap(entity, width, height, tileSize)
    if not entity.components.tilemap then
        entity.components.tilemap = {
            tileSize = tileSize or self.tileSize,
            width = width or self.mapWidth,
            height = height or self.mapHeight,
            layers = {
                {
                    name = "Background",
                    tiles = {},
                    visible = true
                },
                {
                    name = "Main",
                    tiles = {},
                    visible = true
                },
                {
                    name = "Foreground",
                    tiles = {},
                    visible = true
                }
            },
            tileset = nil
        }
        
        -- Initialize empty tiles for all layers
        for layerIndex, layer in ipairs(entity.components.tilemap.layers) do
            layer.tiles = {}
            for y = 1, entity.components.tilemap.height do
                layer.tiles[y] = {}
                for x = 1, entity.components.tilemap.width do
                    layer.tiles[y][x] = {
                        id = 0,  -- 0 means empty tile
                        rotation = 0,
                        flipX = false,
                        flipY = false
                    }
                end
            end
        end
        
        -- Update entity dimensions based on tilemap size
        entity.width = entity.components.tilemap.width * entity.components.tilemap.tileSize
        entity.height = entity.components.tilemap.height * entity.components.tilemap.tileSize
        
        Console:log("Created tilemap component for entity: " .. (entity.name or "unnamed"))
    else
        Console:log("Entity already has a tilemap component", "warning")
    end
    
    return entity.components.tilemap
end

function Tilemap:loadTileset(asset)
    if not asset or asset.type ~= "image" then
        Console:log("Invalid tileset image", "error")
        return nil
    end
    
    -- Initialize tilesets table if it doesn't exist
    if not self.tilesets then
        self.tilesets = {}
    end
    
    local tileset = {
        image = asset,
        tileWidth = self.tileSize,
        tileHeight = self.tileSize,
        columns = math.floor(asset.data:getWidth() / self.tileSize),
        rows = math.floor(asset.data:getHeight() / self.tileSize),
        tiles = {}
    }
    
    -- Create quads for each tile in the tileset
    for y = 0, tileset.rows - 1 do
        for x = 0, tileset.columns - 1 do
            local id = y * tileset.columns + x + 1
            tileset.tiles[id] = love.graphics.newQuad(
                x * tileset.tileWidth,
                y * tileset.tileHeight,
                tileset.tileWidth,
                tileset.tileHeight,
                asset.data:getDimensions()
            )
        end
    end
    
    table.insert(self.tilesets, tileset)
    self.currentTileset = tileset
    Console:log("Loaded tileset: " .. asset.name .. " with " .. #tileset.tiles .. " tiles")
    
    return tileset
end

function Tilemap:setTile(entity, layerIndex, x, y, tileId)
    if not entity or not entity.components.tilemap then return end
    
    local tilemap = entity.components.tilemap
    
    -- Validate coordinates
    if x < 1 or x > tilemap.width or y < 1 or y > tilemap.height then
        return
    end
    
    -- Validate layer
    if layerIndex < 1 or layerIndex > #tilemap.layers then
        return
    end
    
    -- Set the tile
    tilemap.layers[layerIndex].tiles[y][x].id = tileId
end

function Tilemap:drawTilemap(entity)
    if not entity or not entity.components.tilemap then return end
    
    local tilemap = entity.components.tilemap

    if not tilemap.width or type(tilemap.width) ~= "number" then
        tilemap.width = self.mapWidth
    end
    
    if not tilemap.height or type(tilemap.height) ~= "number" then
        tilemap.height = self.mapHeight
    end
    
    if not tilemap.tileSize or type(tilemap.tileSize) ~= "number" then
        tilemap.tileSize = self.tileSize
    end

    
     -- Check if tilemap has a tileset
     if not tilemap.tileset or not tilemap.tileset.image then
        if self.showGrid then
            -- Draw empty grid if no tileset is assigned
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            for x = 0, tilemap.width do
                love.graphics.line(
                    entity.x + x * tilemap.tileSize,
                    entity.y,
                    entity.x + x * tilemap.tileSize,
                    entity.y + tilemap.height * tilemap.tileSize
                )
            end
            
            for y = 0, tilemap.height do
                love.graphics.line(
                    entity.x,
                    entity.y + y * tilemap.tileSize,
                    entity.x + tilemap.width * tilemap.tileSize,
                    entity.y + y * tilemap.tileSize
                )
            end
            love.graphics.setColor(1, 1, 1, 1)
        end
        return
    end
    
    -- Ensure layers exist
    if not tilemap.layers or type(tilemap.layers) ~= "table" or #tilemap.layers == 0 then
        -- Initialize a default layer
        tilemap.layers = {
            {
                name = "Layer 1",
                tiles = {},
                visible = true
            }
        }
        
        -- Initialize empty tiles
        local layer = tilemap.layers[1]
        for y = 1, tilemap.height do
            layer.tiles[y] = {}
            for x = 1, tilemap.width do
                layer.tiles[y][x] = {
                    id = 0,
                    rotation = 0,
                    flipX = false,
                    flipY = false
                }
            end
        end
        Console:log("Initialized missing layers in tilemap")
    end
    
   -- Draw all layers
   for layerIndex, layer in ipairs(tilemap.layers) do
    if layer.visible then
        -- Draw each tile in the layer
        for y = 1, tilemap.height do
            if layer.tiles[y] then  -- Make sure the row exists
                for x = 1, tilemap.width do
                    -- Make sure the tile exists
                    if layer.tiles[y][x] then
                        local tile = layer.tiles[y][x]
                        if tile.id and tile.id > 0 and tilemap.tileset.tiles and tilemap.tileset.tiles[tile.id] then
                            love.graphics.setColor(1, 1, 1, 1)
                            -- Doğru pozisyonda çizildiğinden emin olun
                            local drawX = entity.x + (x - 1) * tilemap.tileSize
                            local drawY = entity.y + (y - 1) * tilemap.tileSize
                            
                            -- Debug: tile pozisyonlarını göster
                            love.graphics.setColor(0, 1, 0, 0.2)
                            love.graphics.rectangle("fill", drawX, drawY, tilemap.tileSize, tilemap.tileSize)
                            
                            -- Tile'ı çiz
                            love.graphics.setColor(1, 1, 1, 1)
                            love.graphics.draw(
                                tilemap.tileset.image.data,
                                tilemap.tileset.tiles[tile.id],
                                drawX,
                                drawY,
                                tile.rotation or 0,
                                tile.flipX and -1 or 1,
                                tile.flipY and -1 or 1,
                                tile.flipX and tilemap.tileSize or 0,
                                tile.flipY and tilemap.tileSize or 0
                            )
                        end
                    end
                end
            end
        end
    end
end
    
    -- Draw grid overlay if enabled
    if self.showGrid then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        for x = 0, tilemap.width do
            love.graphics.line(
                entity.x + x * tilemap.tileSize,
                entity.y,
                entity.x + x * tilemap.tileSize,
                entity.y + tilemap.height * tilemap.tileSize
            )
        end
        
        for y = 0, tilemap.height do
            love.graphics.line(
                entity.x,
                entity.y + y * tilemap.tileSize,
                entity.x + tilemap.width * tilemap.tileSize,
                entity.y + y * tilemap.tileSize
            )
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Tilemap:drawTilemapEditor()
    if not self.showTilemapWindow then return end
    
    local entity = State.selectedEntity
    if not entity or not entity.components.tilemap then return end
    
    local tilemap = entity.components.tilemap
    
    -- Initialize layers if they don't exist
    if not tilemap.layers then
        tilemap.layers = {
            {
                name = "Layer 1",
                tiles = {},
                visible = true
            }
        }
        
        -- Initialize empty tiles for the first layer
        local layer = tilemap.layers[1]
        for y = 1, tilemap.height do
            layer.tiles[y] = {}
            for x = 1, tilemap.width do
                layer.tiles[y][x] = {
                    id = 0,
                    rotation = 0,
                    flipX = false,
                    flipY = false
                }
            end
        end
        
        Console:log("Initialized missing layers in tilemap")
    end
    
    imgui.SetNextWindowSize(State.windowSizes.tilemap.width, State.windowSizes.tilemap.height, imgui.Cond_FirstUseEver)
    if imgui.Begin("Tilemap Editor", self.showTilemapWindow) then
        -- Tileset selection
        imgui.Text("Current Tileset:")
        
        local tilesetName = tilemap.tileset and tilemap.tileset.image.name or "None"
        if imgui.Button(tilesetName .. "##TilesetSelect") then
            imgui.OpenPopup("TilesetSelectPopup")
        end
        
        if imgui.BeginPopup("TilesetSelectPopup") then
            imgui.Text("Select a Tileset")
            imgui.Separator()
            
            -- Show available image assets as potential tilesets
            for _, asset in ipairs(State.assets) do
                if asset.type == "image" then
                    if imgui.Selectable(asset.name) then
                        -- Ensure loading works
                        local newTileset = self:loadTileset(asset)
                        if newTileset then
                            tilemap.tileset = newTileset
                            Console:log("Selected tileset: " .. asset.name .. " with " .. 
                                       #newTileset.tiles .. " tiles for entity: " .. 
                                       (entity.name or "unnamed"))
                        else
                            Console:log("Failed to load tileset: " .. asset.name, "error")
                        end
                    end
                end
            end
            imgui.EndPopup()
        end
        
        imgui.Separator()
        
        -- Tilemap properties
        imgui.Text("Tilemap Properties:")
        
        local tileSize = imgui.SliderInt("Tile Size", tilemap.tileSize, 8, 64)
        if tileSize ~= tilemap.tileSize then
            tilemap.tileSize = tileSize
            
            -- Update tileset properties if one is selected
            if tilemap.tileset then
                tilemap.tileset.tileWidth = tileSize
                tilemap.tileset.tileHeight = tileSize
                tilemap.tileset.columns = math.floor(tilemap.tileset.image.data:getWidth() / tileSize)
                tilemap.tileset.rows = math.floor(tilemap.tileset.image.data:getHeight() / tileSize)
                
                -- Recreate quads
                tilemap.tileset.tiles = {}
                for y = 0, tilemap.tileset.rows - 1 do
                    for x = 0, tilemap.tileset.columns - 1 do
                        local id = y * tilemap.tileset.columns + x + 1
                        tilemap.tileset.tiles[id] = love.graphics.newQuad(
                            x * tileSize,
                            y * tileSize,
                            tileSize,
                            tileSize,
                            tilemap.tileset.image.data:getDimensions()
                        )
                    end
                end
            end
            
            -- Update entity dimensions
            entity.width = tilemap.width * tileSize
            entity.height = tilemap.height * tileSize
        end
        
        local mapWidth = imgui.SliderInt("Map Width", tilemap.width or 16, 1, 100)
        if mapWidth ~= tilemap.width then
            -- Adjust tile array size
            for layerIndex, layer in ipairs(tilemap.layers) do
                -- Add new columns if needed
                if mapWidth > tilemap.width then
                    for y = 1, tilemap.height do
                        for x = tilemap.width + 1, mapWidth do
                            layer.tiles[y][x] = {
                                id = 0,
                                rotation = 0,
                                flipX = false,
                                flipY = false
                            }
                        end
                    end
                end
                -- Or remove columns if shrinking
                if mapWidth < tilemap.width then
                    for y = 1, tilemap.height do
                        for x = tilemap.width, mapWidth + 1, -1 do
                            layer.tiles[y][x] = nil
                        end
                    end
                end
            end
            
            tilemap.width = mapWidth
            entity.width = tilemap.width * tilemap.tileSize
        end
        
        local mapHeight = imgui.SliderInt("Map Height", tilemap.height or 16, 1, 100)
        if mapHeight ~= tilemap.height then
            -- Adjust tile array size
            for layerIndex, layer in ipairs(tilemap.layers) do
                -- Add new rows if needed
                if mapHeight > tilemap.height then
                    for y = tilemap.height + 1, mapHeight do
                        layer.tiles[y] = {}
                        for x = 1, tilemap.width do
                            layer.tiles[y][x] = {
                                id = 0,
                                rotation = 0,
                                flipX = false,
                                flipY = false
                            }
                        end
                    end
                end
                -- Or remove rows if shrinking
                if mapHeight < tilemap.height then
                    for y = tilemap.height, mapHeight + 1, -1 do
                        layer.tiles[y] = nil
                    end
                end
            end
            
            tilemap.height = mapHeight
            entity.height = tilemap.height * tilemap.tileSize
        end
        
        imgui.Separator()
        
        -- Layer management
        imgui.Text("Layers:")
        
        -- Ensure we have a valid selected layer
        if self.selectedLayer > #tilemap.layers then
            self.selectedLayer = #tilemap.layers
        end
        
        for i, layer in ipairs(tilemap.layers) do
            if imgui.Selectable(layer.name, self.selectedLayer == i) then
                self.selectedLayer = i
            end
            
            imgui.SameLine()
            local visible = imgui.Checkbox("##Visible" .. i, layer.visible)
            if visible ~= layer.visible then
                layer.visible = visible
            end
            
            imgui.SameLine()
            if imgui.Button("Rename##" .. i) then
                -- TODO: Add rename functionality
                Console:log("Rename feature coming soon", "info")
            end
        end
        
        if imgui.Button("Add Layer") then
            table.insert(tilemap.layers, {
                name = "Layer " .. (#tilemap.layers + 1),
                tiles = {},
                visible = true
            })
            
            -- Initialize new layer with empty tiles
            local newLayer = tilemap.layers[#tilemap.layers]
            for y = 1, tilemap.height do
                newLayer.tiles[y] = {}
                for x = 1, tilemap.width do
                    newLayer.tiles[y][x] = {
                        id = 0,
                        rotation = 0,
                        flipX = false,
                        flipY = false
                    }
                end
            end
            
            Console:log("Added new layer: " .. newLayer.name)
        end
        
        imgui.SameLine()
        
        if imgui.Button("Remove Layer") and #tilemap.layers > 1 then
            table.remove(tilemap.layers, self.selectedLayer)
            if self.selectedLayer > #tilemap.layers then
                self.selectedLayer = #tilemap.layers
            end
            Console:log("Removed layer")
        end
        
        imgui.Separator()
        
        -- Tool options
        imgui.Text("Tools:")
        
        -- Toggle grid
        local showGrid = imgui.Checkbox("Show Grid", self.showGrid)
        if showGrid ~= self.showGrid then
            self.showGrid = showGrid
        end
        
        -- Brush size
        local brushSize = imgui.SliderInt("Brush Size", self.brushSize, 1, 5)
        if brushSize ~= self.brushSize then
            self.brushSize = brushSize
        end
        
        -- Eraser mode
        local eraserMode = imgui.Checkbox("Eraser Mode", self.eraserMode)
        if eraserMode ~= self.eraserMode then
            self.eraserMode = eraserMode
        end
        
        imgui.Separator()
        
        -- Tileset preview
        if tilemap.tileset and tilemap.tileset.image then
            imgui.Text("Tileset Preview:")
            
            -- Calculate preview size
            local previewWidth = imgui.GetWindowWidth() - 20
            local tilesetAspect = tilemap.tileset.image.data:getWidth() / tilemap.tileset.image.data:getHeight()
            local previewHeight = previewWidth / tilesetAspect
            
            -- Only draw the tileset preview if there's enough space
            if previewHeight < 300 then
                imgui.BeginChild("TilesetPreview", previewWidth, previewHeight, true)
                
                -- Get the ImGui window position and cursor position
                local wx, wy = imgui.GetWindowPos()
                local cx, cy = imgui.GetCursorScreenPos()
                
                -- Draw the tileset image
                love.graphics.push("all")
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(
                    tilemap.tileset.image.data,
                    cx, cy, 0,
                    previewWidth / tilemap.tileset.image.data:getWidth(),
                    previewHeight / tilemap.tileset.image.data:getHeight()
                )
                
                -- Draw grid lines over the tileset
                if self.showGrid then
                    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
                    
                    local scaledTileWidth = (previewWidth / tilemap.tileset.columns)
                    local scaledTileHeight = (previewHeight / tilemap.tileset.rows)
                    
                    -- Vertical lines
                    for i = 0, tilemap.tileset.columns do
                        love.graphics.line(
                            cx + i * scaledTileWidth, cy,
                            cx + i * scaledTileWidth, cy + previewHeight
                        )
                    end
                    
                    -- Horizontal lines
                    for i = 0, tilemap.tileset.rows do
                        love.graphics.line(
                            cx, cy + i * scaledTileHeight,
                            cx + previewWidth, cy + i * scaledTileHeight
                        )
                    end
                    
                    love.graphics.setColor(1, 1, 1, 1)
                end
                
                -- Highlight selected tile
                if self.currentTile and self.currentTile <= #tilemap.tileset.tiles then
                    local tileIndex = self.currentTile - 1
                    local tileX = tileIndex % tilemap.tileset.columns
                    local tileY = math.floor(tileIndex / tilemap.tileset.columns)
                    
                    local scaledTileWidth = (previewWidth / tilemap.tileset.columns)
                    local scaledTileHeight = (previewHeight / tilemap.tileset.rows)
                    
                    love.graphics.setColor(1, 1, 0, 0.3)
                    love.graphics.rectangle(
                        "fill",
                        cx + tileX * scaledTileWidth,
                        cy + tileY * scaledTileHeight,
                        scaledTileWidth,
                        scaledTileHeight
                    )
                    
                    love.graphics.setColor(1, 1, 0, 1)
                    love.graphics.rectangle(
                        "line",
                        cx + tileX * scaledTileWidth,
                        cy + tileY * scaledTileHeight,
                        scaledTileWidth,
                        scaledTileHeight
                    )
                end
                
                -- Handle mouse clicks on the tileset
                local mx, my = love.mouse.getPosition()
                if mx >= cx and mx < cx + previewWidth and
                   my >= cy and my < cy + previewHeight and
                   imgui.IsWindowHovered() and love.mouse.isDown(1) then
                    
                    local relX = (mx - cx) / previewWidth
                    local relY = (my - cy) / previewHeight
                    
                    local tileX = math.floor(relX * tilemap.tileset.columns)
                    local tileY = math.floor(relY * tilemap.tileset.rows)
                    
                    local tileId = tileY * tilemap.tileset.columns + tileX + 1
                    if tileId <= #tilemap.tileset.tiles then
                        self.currentTile = tileId
                        self.eraserMode = false
                        Console:log("Selected tile ID: " .. tileId)
                    end
                end
                
                love.graphics.pop()
                
                imgui.EndChild()
            else
                imgui.Text("Tileset preview is too large to display")
            end
        end
        
        imgui.End()
    end
end

function Tilemap:update(dt)
    -- Check if we should show the tilemap editor window
    if State.selectedEntity and State.selectedEntity.components.tilemap and not self.showTilemapWindow then
        self.showTilemapWindow = true
    elseif (not State.selectedEntity or not State.selectedEntity.components.tilemap) and self.showTilemapWindow then
        self.showTilemapWindow = false
    end
    
    -- Handle tilemap editing
    if self.showTilemapWindow and State.selectedEntity and State.selectedEntity.components.tilemap then
        local entity = State.selectedEntity
        local tilemap = entity.components.tilemap
        
        -- Make sure needed properties exist
        if not tilemap.width then tilemap.width = self.mapWidth end
        if not tilemap.height then tilemap.height = self.mapHeight end
        if not tilemap.tileSize then tilemap.tileSize = self.tileSize end
        
        -- Only handle input if ImGui doesn't want to capture the mouse
        if not imgui.GetWantCaptureMouse() and love.mouse.isDown(1) and self.currentTile and tilemap.tileset then
            local mx, my = love.mouse.getPosition()
            local worldX, worldY = engine.sceneManager:screenToWorld(mx, my)
            
            -- Check if mouse is within the tilemap area
            if worldX >= entity.x and worldX < entity.x + tilemap.width * tilemap.tileSize and
               worldY >= entity.y and worldY < entity.y + tilemap.height * tilemap.tileSize then
                
                -- Calculate tile coordinates
                local tileX = math.floor((worldX - entity.x) / tilemap.tileSize) + 1
                local tileY = math.floor((worldY - entity.y) / tilemap.tileSize) + 1
                
                -- Check if layers exist
                if not tilemap.layers or #tilemap.layers == 0 then
                    self:createTilemap(entity, tilemap.width, tilemap.height, tilemap.tileSize)
                end
                
                -- Handle brush size
                for brushY = 0, self.brushSize - 1 do
                    for brushX = 0, self.brushSize - 1 do
                        local targetX = tileX + brushX
                        local targetY = tileY + brushY
                        
                        -- Set the tile (or erase it)
                        if targetX > 0 and targetX <= tilemap.width and
                           targetY > 0 and targetY <= tilemap.height then
                            
                            local tileId = self.eraserMode and 0 or self.currentTile
                            self:setTile(entity, self.selectedLayer, targetX, targetY, tileId)
                        end
                    end
                end
            end
        end
    end
end

return Tilemap