local State = require "state"
local Console = require "modules.console"
local Camera = require "modules.camera"
local SceneManager = require "modules.scene_manager"

local Tilemap = {
    currentTile = nil,
    tileSize = 32,
    mapWidth = 20,
    mapHeight = 15,
    showGrid = true,
    brushSize = 1,
    eraserMode = false,
    selectedLayer = 1,
    showTilemapWindow = false,
    lastMouseDown = false -- Sürekli tıklamaları önlemek için
}

function Tilemap:init()
    self.tilesets = {}
    self.currentTileset = nil
    self.lastMouseDown = false
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
    
    -- Veri kontrolü
    if not asset.data then
        Console:log("Asset data is missing", "error")
        return nil
    end
    
    -- Resim boyutlarını kontrol et
    local imgWidth = asset.data:getWidth()
    local imgHeight = asset.data:getHeight()
    
    if imgWidth <= 0 or imgHeight <= 0 then
        Console:log("Invalid image dimensions: " .. imgWidth .. "x" .. imgHeight, "error")
        return nil
    end
    
    -- Tilesets tablosunun varlığını garanti et
    if not self.tilesets then
        self.tilesets = {}
    end
    
    -- Tileset boyutlarını hesapla
    local tileWidth = self.tileSize
    local tileHeight = self.tileSize
    local columns = math.floor(imgWidth / tileWidth)
    local rows = math.floor(imgHeight / tileHeight)
    
    -- Bu kontrol önemli
    if columns <= 0 or rows <= 0 then
        Console:log("Image too small for tile size. Try decreasing tile size.", "error")
        return nil
    end
    
    local tileset = {
        image = asset,
        tileWidth = tileWidth,
        tileHeight = tileHeight,
        columns = columns,
        rows = rows,
        tiles = {}
    }
    
    -- Quad'ları oluştur
    for y = 0, rows - 1 do
        for x = 0, columns - 1 do
            local id = y * columns + x + 1
            
            -- Quad oluşturmadan önce sınırları kontrol et
            if x * tileWidth < imgWidth and y * tileHeight < imgHeight and
               (x + 1) * tileWidth <= imgWidth and (y + 1) * tileHeight <= imgHeight then
                
                tileset.tiles[id] = love.graphics.newQuad(
                    x * tileWidth,
                    y * tileHeight,
                    tileWidth,
                    tileHeight,
                    imgWidth, imgHeight -- getDimensions yerine doğrudan değerleri kullan
                )
            else
                Console:log("Warning: Tile at " .. x .. "," .. y .. " exceeds image bounds", "warning")
            end
        end
    end
    
    -- Quad'ları kontrol et
    if #tileset.tiles == 0 then
        Console:log("No valid tiles could be created from this image", "error")
        return nil
    end
    
    -- Debug bilgisi
    Console:log("Loaded tileset: " .. asset.name .. " with " .. #tileset.tiles .. " tiles", "info")
    Console:log("Tileset dimensions: " .. imgWidth .. "x" .. imgHeight, "info")
    Console:log("Tile size: " .. tileWidth .. "x" .. tileHeight, "info")
    Console:log("Grid: " .. columns .. "x" .. rows, "info")
    
    -- Global değişkenleri güncelle
    self.currentTileset = tileset
    self.currentTile = 1  -- İlk tile'ı seç
    
    return tileset
end

function Tilemap:setTile(entity, layerIndex, x, y, tileId)
    if not entity or not entity.components.tilemap then 
        Console:log("setTile: No entity or tilemap component", "error")
        return 
    end
    
    local tilemap = entity.components.tilemap
    
    -- Koordinatları doğrula
    if x < 1 or x > tilemap.width or y < 1 or y > tilemap.height then
        Console:log("setTile: Coordinates out of bounds: " .. x .. "," .. y, "warning")
        return
    end
    
    -- Layer'ı doğrula
    if not tilemap.layers or layerIndex < 1 or layerIndex > #tilemap.layers then
        Console:log("setTile: Invalid layer index: " .. layerIndex, "warning")
        return
    end
    
    local layer = tilemap.layers[layerIndex]
    
    -- Tile array'in varlığını kontrol et
    if not layer.tiles then
        Console:log("setTile: Layer has no tiles array, creating", "info")
        layer.tiles = {}
    end
    
    -- Satırın varlığını kontrol et
    if not layer.tiles[y] then
        Console:log("setTile: Row " .. y .. " doesn't exist, creating", "info")
        layer.tiles[y] = {}
    end
    
    -- Tile'ın varlığını kontrol et
    if not layer.tiles[y][x] then
        layer.tiles[y][x] = {
            id = tileId,
            rotation = 0,
            flipX = false,
            flipY = false
        }
    else
        layer.tiles[y][x].id = tileId
    end
    
    Console:log("Set tile at " .. x .. "," .. y .. " on layer " .. layerIndex .. " to ID " .. tileId, "info")
end

function Tilemap:drawTilemap(entity)
    if not entity or not entity.components.tilemap then 
        return 
    end
    
    local tilemap = entity.components.tilemap
    
    -- Temel değerlerin doğru olduğundan emin ol
    if not tilemap.width or type(tilemap.width) ~= "number" then
        tilemap.width = self.mapWidth
    end
    
    if not tilemap.height or type(tilemap.height) ~= "number" then
        tilemap.height = self.mapHeight
    end
    
    if not tilemap.tileSize or type(tilemap.tileSize) ~= "number" then
        tilemap.tileSize = self.tileSize
    end
    
    -- Tilemap'in bir tileset'i olup olmadığını kontrol et
    if not tilemap.tileset or not tilemap.tileset.image then
        if self.showGrid then
            -- Eğer tileset atanmamışsa boş ızgara çiz
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
    
    -- Katmanların varlığını garanti et
    if not tilemap.layers or type(tilemap.layers) ~= "table" or #tilemap.layers == 0 then
        -- Varsayılan bir katman oluştur
        tilemap.layers = {
            {
                name = "Layer 1",
                tiles = {},
                visible = true
            }
        }
        
        -- Boş tile'ları başlat
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
    
    -- Tüm katmanları çiz
    for layerIndex, layer in ipairs(tilemap.layers) do
        if layer.visible then
            -- Katmandaki her tile'ı çiz
            for y = 1, tilemap.height do
                if layer.tiles[y] then
                    for x = 1, tilemap.width do
                        if layer.tiles[y][x] then
                            local tile = layer.tiles[y][x]
                            if tile.id and tile.id > 0 and 
                               tilemap.tileset.tiles and tilemap.tileset.tiles[tile.id] then
                                
                                local drawX = entity.x + (x - 1) * tilemap.tileSize
                                local drawY = entity.y + (y - 1) * tilemap.tileSize
                                
                                -- Tile çizimi
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
                                
                                -- DEBUG: Tile sınırlarını göster - bu hattı aktifleştirerek test edebilirsiniz
                                -- love.graphics.setColor(1, 0, 0, 0.3)
                                -- love.graphics.rectangle("line", drawX, drawY, tilemap.tileSize, tilemap.tileSize)
                                
                                -- DEBUG: Tile ID'sini göster - bu hattı aktifleştirerek test edebilirsiniz
                                -- love.graphics.setColor(1, 1, 1, 0.8)
                                -- love.graphics.print(tile.id, drawX + 5, drawY + 5)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Grid overlay'i etkinse çiz
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
        
        -- Tileset Grid Visualization - Animatör stili
        if tilemap.tileset and tilemap.tileset.image then
            imgui.Text("Tileset Preview:")
            
            -- Grid önizleme alanı
            local previewSize = 300
            imgui.BeginChild("TilesetGridPreview", previewSize, previewSize, true)
            
            -- ImGui penceresinin pozisyonunu al
            local wx, wy = imgui.GetWindowPos()
            local cx, cy = imgui.GetCursorScreenPos()
            
            -- Dünya koordinatlarına dönüştür
            local worldX, worldY = engine.sceneManager:screenToWorld(cx, cy)
            
            -- Tileset resmini dünya koordinatlarında çiz
            love.graphics.push("all")
            
            -- Tileset resmini çiz
            love.graphics.setColor(1, 1, 1, 1)
            tilemap.tileset.image.data:setFilter("nearest", "nearest")
            love.graphics.draw(tilemap.tileset.image.data, worldX, worldY, 0, 
                previewSize / tilemap.tileset.image.data:getWidth() / Camera.scaleX,
                previewSize / tilemap.tileset.image.data:getHeight() / Camera.scaleY)
            
            -- Grid çizgileri
            local cellWidth = (previewSize / tilemap.tileset.columns) / Camera.scaleX
            local cellHeight = (previewSize / tilemap.tileset.rows) / Camera.scaleY
            
            -- Grid çizgilerini çiz
            love.graphics.setColor(1, 1, 0, 0.3)
            for i = 1, tilemap.tileset.columns do
                love.graphics.line(
                    worldX + i * cellWidth, worldY,
                    worldX + i * cellWidth, worldY + (previewSize / Camera.scaleY)
                )
            end
            
            for i = 1, tilemap.tileset.rows do
                love.graphics.line(
                    worldX, worldY + i * cellHeight,
                    worldX + (previewSize / Camera.scaleX), worldY + i * cellHeight
                )
            end
            
            -- Mouse pozisyonu ve seçim
            local mx, my = love.mouse.getPosition()
            local worldMX, worldMY = engine.sceneManager:screenToWorld(mx, my)
            
            -- Mouse'un tileset alanı içinde olup olmadığını kontrol et
            if worldMX >= worldX and worldMX < worldX + (previewSize / Camera.scaleX) and
               worldMY >= worldY and worldMY < worldY + (previewSize / Camera.scaleY) then
                
                -- Grid hücre koordinatlarını hesapla
                local gridX = math.floor((worldMX - worldX) / cellWidth)
                local gridY = math.floor((worldMY - worldY) / cellHeight)
                
                -- Geçerli grid sınırları içinde mi kontrol et
                if gridX >= 0 and gridX < tilemap.tileset.columns and
                   gridY >= 0 and gridY < tilemap.tileset.rows then
                    
                    -- Hücre üzerine gelindiğinde vurgula
                    love.graphics.setColor(1, 1, 0, 0.2)
                    love.graphics.rectangle("fill", 
                        worldX + gridX * cellWidth, 
                        worldY + gridY * cellHeight, 
                        cellWidth, 
                        cellHeight
                    )
                    
                    -- Tıklama ile tile seç
                    local tileId = gridY * tilemap.tileset.columns + gridX + 1
                    if tileId <= #tilemap.tileset.tiles then
                        if love.mouse.isDown(1) and not self.lastMouseDown then
                            self.currentTile = tileId
                            self.eraserMode = false
                            Console:log("Selected tile ID: " .. tileId, "info")
                            self.lastMouseDown = true
                        end
                    end
                end
            end
            
            -- Seçili tile'ı vurgula
            if self.currentTile and self.currentTile <= #tilemap.tileset.tiles then
                local tileIndex = self.currentTile - 1
                local tileX = tileIndex % tilemap.tileset.columns
                local tileY = math.floor(tileIndex / tilemap.tileset.columns)
                
                -- Seçili tile'ı daha belirgin şekilde vurgula
                love.graphics.setColor(0, 1, 0, 0.4)  -- Yeşil renkte vurgula
                love.graphics.rectangle("fill", 
                    worldX + tileX * cellWidth, 
                    worldY + tileY * cellHeight, 
                    cellWidth, 
                    cellHeight
                )
                
                -- Seçili tile'ın etrafına çerçeve çiz
                love.graphics.setColor(0, 1, 0, 1)  -- Parlak yeşil çerçeve
                love.graphics.rectangle("line", 
                    worldX + tileX * cellWidth, 
                    worldY + tileY * cellHeight, 
                    cellWidth, 
                    cellHeight
                )
                
                -- Tile ID'sini görüntüle
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print("ID: " .. self.currentTile, 
                    worldX + tileX * cellWidth + 5, 
                    worldY + tileY * cellHeight + 5)
            end
            
            love.graphics.pop()
            
            imgui.EndChild()
            
            -- Seçili tile bilgisi
            imgui.Text("Selected Tile: " .. self.currentTile)
            
            -- Eraser modu bilgisi
            if self.eraserMode then
                imgui.TextColored(1, 0, 0, 1, "ERASER MODE ACTIVE")
            end
            
            -- Eraser butonu
            if imgui.Button(self.eraserMode and "Disable Eraser" or "Enable Eraser") then
                self.eraserMode = not self.eraserMode
                Console:log("Eraser mode " .. (self.eraserMode and "enabled" or "disabled"), "info")
            end
        else
            imgui.Text("No tileset selected")
            
            -- Tileset seçme imkanı sağla
            if imgui.Button("Select Tileset") then
                imgui.OpenPopup("TilesetSelectPopup")
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

    if not love.mouse.isDown(1) then
        self.lastMouseDown = false
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
            
            -- Debug koordinatları göster
            -- Console:log("Mouse world pos: " .. worldX .. "," .. worldY .. ", Entity pos: " .. entity.x .. "," .. entity.y, "info")
            
            -- Check if mouse is within the tilemap area
            if worldX >= entity.x and worldX < entity.x + tilemap.width * tilemap.tileSize and
               worldY >= entity.y and worldY < entity.y + tilemap.height * tilemap.tileSize then
                
                -- Calculate tile coordinates
                local tileX = math.floor((worldX - entity.x) / tilemap.tileSize) + 1
                local tileY = math.floor((worldY - entity.y) / tilemap.tileSize) + 1
                
                -- Console:log("Placing at tile coordinates: " .. tileX .. "," .. tileY, "info")
                
                -- Check if layers exist
                if not tilemap.layers or #tilemap.layers == 0 then
                    Console:log("No layers, creating default", "warning")
                    self:createTilemap(entity, tilemap.width, tilemap.height, tilemap.tileSize)
                end
                
                -- Make sure selectedLayer is valid
                if self.selectedLayer < 1 or self.selectedLayer > #tilemap.layers then
                    Console:log("Invalid selected layer: " .. self.selectedLayer .. ", setting to 1", "warning")
                    self.selectedLayer = 1
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
                            -- Console:log("Setting tile at " .. targetX .. "," .. targetY .. " to " .. tileId, "info")
                            self:setTile(entity, self.selectedLayer, targetX, targetY, tileId)
                        end
                    end
                end
            end
        end
    end
end

return Tilemap