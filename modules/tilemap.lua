local State = require "state"
local Console = require "modules.console"
local SceneManager = require "modules.scene_manager"
local Camera = require "modules.camera"

local Tilemap = {
    tilesets = {},
    maps = {},
    activeTileset = nil,
    activeMap = nil,
    tileSize = 32,
    gridSize = 32,
    selectedTile = nil,
    hoveredTile = nil,
    showGrid = true,
    windowOpen = true,
    previewScale = 2.0,
    mapScale = 1.0,
    entities = {} -- Tilemap entity'lerini saklamak için
}

function Tilemap:init()
    Console:log("Tilemap modülü başlatıldı")
end

function Tilemap:loadTileset(path, name, tileSize)
    local tileset = {
        image = love.graphics.newImage(path),
        name = name,
        tileSize = tileSize or self.tileSize,
        path = path
    }
    
    tileset.width = tileset.image:getWidth()
    tileset.height = tileset.image:getHeight()
    tileset.cols = math.floor(tileset.width / tileset.tileSize)
    tileset.rows = math.floor(tileset.height / tileset.tileSize)
    
    self.tilesets[name] = tileset
    
    if not self.activeTileset then
        self.activeTileset = tileset
    end
    
    Console:log("Tileset yüklendi: " .. name)
    return tileset
end

function Tilemap:createMap(width, height, name)
    local map = {
        width = width,
        height = height,
        name = name,
        layers = {},
        tileSize = self.tileSize
    }
    
    -- Varsayılan katman oluştur
    self:addLayer(map, "Zemin")
    
    self.maps[name] = map
    
    if not self.activeMap then
        self.activeMap = map
    end
    
    Console:log("Harita oluşturuldu: " .. name)
    
    -- Haritayı otomatik olarak entity olarak ekle
    if SceneManager and SceneManager.createEntity then
        local entity = SceneManager:createEntity(name)
        entity.type = "tilemap"
        entity.mapName = name
        entity.gridSize = self.gridSize
        entity.showGrid = self.showGrid
        
        -- Tilemap entity'lerini takip etmek için listeye ekle
        table.insert(self.entities, entity)
        
        Console:log("Harita entity olarak eklendi: " .. name)
    else
        Console:log("Uyarı: SceneManager bulunamadı, harita entity olarak eklenemedi")
    end
    
    return map
end

-- Yeni: Tilemap entity'si oluştur
function Tilemap:createTilemapEntity(mapName, x, y, scale)
    local map = self.maps[mapName]
    if not map then
        Console:log("Hata: Harita bulunamadı: " .. mapName)
        return nil
    end
    
    local entity = {
        type = "tilemap",
        name = "Tilemap: " .. mapName,
        mapName = mapName,
        x = x or 0,
        y = y or 0,
        rotation = 0,
        scaleX = scale or 1,
        scaleY = scale or 1,
        visible = true,
        gridSize = self.gridSize,
        showGrid = self.showGrid
    }
    
    table.insert(self.entities, entity)
    
    -- Entity'yi SceneManager'a ekle
    if SceneManager and SceneManager.addEntity then
        SceneManager:addEntity(entity)
    end
    
    Console:log("Tilemap entity'si oluşturuldu: " .. entity.name)
    return entity
end

-- Yeni: Entity'yi güncelle
function Tilemap:updateEntity(entity, dt)
    if not entity or entity.type ~= "tilemap" then return end
    
    -- Entity'nin transform değerlerini güncelle
    -- Burada animasyon veya diğer güncellemeler yapılabilir
end

-- Yeni: Entity'yi çiz
function Tilemap:drawEntity(entity)
    if not entity or not entity.mapName then return end
    
    local map = self.maps[entity.mapName]
    if not map then return end
    
    love.graphics.push()
    
    -- Koordinatları sayısal değerlere dönüştür
    local x = tonumber(entity.x) or 0
    local y = tonumber(entity.y) or 0
    local rotation = tonumber(entity.rotation) or 0
    local scaleX = tonumber(entity.scaleX) or 1
    local scaleY = tonumber(entity.scaleY) or 1
    
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation)
    love.graphics.scale(scaleX, scaleY)
    
    -- Görünürlük kontrolü
    if entity.visible == false then 
        love.graphics.pop()
        return 
    end
    
    -- Haritayı çiz
    self:drawMap(map, entity.gridSize or self.gridSize, entity.showGrid)
    
    love.graphics.pop()
end

-- Yeni: Entity'yi sil
function Tilemap:removeEntity(entity)
    if not entity or entity.type ~= "tilemap" then return end
    
    -- Entity'yi listeden kaldır
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            break
        end
    end
    
    -- Entity'yi SceneManager'dan kaldır
    if SceneManager and SceneManager.removeEntity then
        SceneManager:removeEntity(entity)
    end
    
    Console:log("Tilemap entity'si silindi: " .. entity.name)
end

function Tilemap:addLayer(map, name)
    local layer = {
        name = name,
        tiles = {},
        visible = true
    }
    
    -- Boş ızgara oluştur
    for y = 1, map.height do
        layer.tiles[y] = {}
        for x = 1, map.width do
            layer.tiles[y][x] = nil -- nil = boş karo
        end
    end
    
    table.insert(map.layers, layer)
    return layer
end

function Tilemap:setTile(map, layer, x, y, tilesetName, tileId)
    if not map or not map.layers[layer] then 
        Console:log("Hata: Geçersiz harita veya katman")
        return 
    end
    
    local layerData = map.layers[layer]
    
    if x < 1 or x > map.width or y < 1 or y > map.height then
        Console:log(string.format("Hata: Geçersiz karo pozisyonu (%d,%d)", x, y))
        return
    end
    
    if not tilesetName or not tileId then
        Console:log("Hata: Geçersiz tileset veya karo ID")
        return
    end
    
    -- Tileset'in var olduğundan emin ol
    if not self.tilesets[tilesetName] then
        Console:log("Hata: Tileset bulunamadı: " .. tilesetName)
        return
    end
    
    layerData.tiles[y][x] = {
        tilesetName = tilesetName,
        tileId = tileId
    }
    
    Console:log(string.format("Karo ayarlandı: %s, ID: %d, Pozisyon: %d,%d", 
        tilesetName, tileId, x, y))
end

function Tilemap:getTileFromTileset(tileset, tileId)
    if not tileset then return nil end
    
    local col = (tileId - 1) % tileset.cols
    local row = math.floor((tileId - 1) / tileset.cols)
    
    return {
        quad = love.graphics.newQuad(
            col * tileset.tileSize, 
            row * tileset.tileSize, 
            tileset.tileSize, 
            tileset.tileSize, 
            tileset.width, 
            tileset.height
        ),
        tileId = tileId,
        col = col,
        row = row
    }
end

function Tilemap:getTileIdFromPosition(tileset, x, y)
    if not tileset then return nil end
    
    local col = math.floor(x / tileset.tileSize)
    local row = math.floor(y / tileset.tileSize)
    
    if col < 0 or col >= tileset.cols or row < 0 or row >= tileset.rows then
        return nil
    end
    
    return row * tileset.cols + col + 1
end

-- Yardımcı fonksiyon: Ekran koordinatlarını dünya koordinatlarına dönüştür
function Tilemap:screenToWorld(screenX, screenY)
    -- Camera modülünün yapısına bağlı olarak farklı yaklaşımlar kullanabiliriz
    
    -- Yöntem 1: Eğer Camera modülü doğrudan screenToWorld fonksiyonu sağlıyorsa
    if Camera.screenToWorld then
        return Camera:screenToWorld(screenX, screenY)
    end
    
    -- Yöntem 2: Eğer Camera modülü x, y ve scale değerlerini sağlıyorsa
    if Camera.x and Camera.y and Camera.scaleX and Camera.scaleY then
        local worldX = (screenX - love.graphics.getWidth() / 2) / Camera.scaleX + Camera.x
        local worldY = (screenY - love.graphics.getHeight() / 2) / Camera.scaleY + Camera.y
        return worldX, worldY
    end
    
    -- Yöntem 3: Eğer Camera modülü başka bir yapıya sahipse
    -- Bu durumda Camera modülünün yapısına göre özel bir dönüşüm yapmalıyız
    
    -- Varsayılan olarak, hiçbir dönüşüm yapmadan ekran koordinatlarını döndür
    Console:log("Uyarı: Camera modülü screenToWorld fonksiyonu bulunamadı, dönüşüm yapılamıyor.")
    return screenX, screenY
end

function Tilemap:update(dt)
    -- Fare pozisyonunu kontrol et (tileset önizleme için)
    if self.activeTileset and self.windowOpen then
        local mouseX, mouseY = love.mouse.getPosition()
        
        -- ImGui pencere pozisyonunu ve içerik pozisyonunu al
        if imgui.IsWindowFocused() then
            local windowX, windowY = imgui.GetWindowPos()
            local contentX, contentY = imgui.GetCursorScreenPos()
            
            -- Tileset görüntüsünün pozisyonunu bul
            -- Not: Bu değerler ImGui sürümünüze bağlı olarak değişebilir
            -- Eğer hala sorun yaşıyorsanız, bu değerleri debug ederek doğru değerleri bulabilirsiniz
            local imageStartX = contentX
            local imageStartY = contentY
            
            -- Fare pozisyonunun tileset görüntüsü üzerinde olup olmadığını kontrol et
            local tilesetX = mouseX - imageStartX
            local tilesetY = mouseY - imageStartY
            
            -- Ölçeklendirmeyi hesaba kat
            if type(self.previewScale) == "number" then
                tilesetX = tilesetX / self.previewScale
                tilesetY = tilesetY / self.previewScale
            else
                self.previewScale = 2.0
                tilesetX = tilesetX / 2.0
                tilesetY = tilesetY / 2.0
            end
            
            -- Debug bilgisi
            if love.keyboard.isDown("d") then
                Console:log(string.format("Fare: %d,%d | Tileset: %d,%d", mouseX, mouseY, tilesetX, tilesetY))
            end
            
            -- Fare tileset üzerinde mi kontrol et
            if tilesetX >= 0 and tilesetX < self.activeTileset.width and
               tilesetY >= 0 and tilesetY < self.activeTileset.height then
                
                -- Üzerinde gezinilen karoyu hesapla
                self.hoveredTile = self:getTileIdFromPosition(self.activeTileset, tilesetX, tilesetY)
                
                -- Fare tıklaması ile karo seç
                if love.mouse.isDown(1) then
                    self.selectedTile = self.hoveredTile
                    Console:log("Karo seçildi: " .. tostring(self.selectedTile))
                end
            else
                self.hoveredTile = nil
            end
        end
    end
    
    -- Sahne üzerine karo yerleştirme
    if self.selectedTile and self.activeTileset and self.activeMap and 
       not imgui.GetWantCaptureMouse() and love.mouse.isDown(1) then
        
        local mouseX, mouseY = love.mouse.getPosition()
        
        -- Kendi screenToWorld fonksiyonumuzu kullan
        local worldX, worldY = self:screenToWorld(mouseX, mouseY)
        
        -- Izgara pozisyonunu hesapla
        local gridX = math.floor(worldX / self.gridSize) + 1
        local gridY = math.floor(worldY / self.gridSize) + 1
        
        -- Geçerli ızgara sınırları içinde olduğundan emin ol
        if gridX >= 1 and gridX <= self.activeMap.width and
           gridY >= 1 and gridY <= self.activeMap.height then
            
            -- Karo yerleştir
            self:setTile(
                self.activeMap, 
                1, -- Aktif katman (şimdilik sadece ilk katman)
                gridX, 
                gridY, 
                self.activeTileset.name, 
                self.selectedTile
            )
            
            -- Debug bilgisi
            Console:log(string.format("Karo yerleştirildi: %d, Pozisyon: %d,%d", 
                self.selectedTile, gridX, gridY))
        end
    end
    
    -- Tüm tilemap entity'lerini güncelle
    for _, entity in ipairs(self.entities) do
        if entity.type == "tilemap" then
            self:updateEntity(entity, dt)
        end
    end
end

function Tilemap:drawTilemapWindow()
    if not self.windowOpen then return end
    
    imgui.Begin("Tilemap Editörü", true, {"ImGuiWindowFlags_MenuBar"})
    
    if imgui.BeginMenuBar() then
        if imgui.BeginMenu("Dosya") then
            if imgui.MenuItem("Yeni Harita") then
                -- Yeni harita oluşturma işlevi buraya gelecek
            end
            
            if imgui.MenuItem("Tileset Yükle") then
                -- Tileset yükleme işlevi buraya gelecek
            end
            
            imgui.EndMenu()
        end
        
        if imgui.BeginMenu("Görünüm") then
            if imgui.MenuItem("Izgarayı Göster", nil, self.showGrid) then
                self.showGrid = not self.showGrid
            end
            
            imgui.EndMenu()
        end
        
        imgui.EndMenuBar()
    end
    
    -- Tileset seçimi
    if #self.tilesets > 0 then
        imgui.Text("Aktif Tileset:")
        
        local tilesetNames = {}
        local currentTilesetIndex = 1
        local i = 1
        
        for name, _ in pairs(self.tilesets) do
            tilesetNames[i] = name
            if self.activeTileset and self.activeTileset.name == name then
                currentTilesetIndex = i
            end
            i = i + 1
        end
        
        local changed, newIndex = imgui.Combo("##TilesetCombo", currentTilesetIndex - 1, tilesetNames, #tilesetNames)
        if changed then
            self.activeTileset = self.tilesets[tilesetNames[newIndex + 1]]
        end
    else
        if imgui.Button("Tileset Yükle") then
            -- Örnek bir tileset yükle
            self:loadTileset("assets/tilesets/example.png", "Örnek Tileset", 32)
        end
    end
    
    -- Tileset önizleme
    if self.activeTileset then
        imgui.Separator()
        imgui.Text("Tileset Önizleme:")
        
        -- Önizleme ölçeği ayarı - ImGui kullanımını düzeltiyoruz
        -- Eğer previewScale bir sayı değilse, varsayılan değere ayarla
        if type(self.previewScale) ~= "number" then
            self.previewScale = 2.0
        end
        
        -- ImGui.SliderFloat kullanımı - farklı ImGui sürümleri için uyumlu hale getiriyoruz
        local previewScaleChanged = false
        local newPreviewScale = self.previewScale
        
        -- Slider'ı çiz ve değişikliği kontrol et
        -- NOT: ImGui sürümünüze bağlı olarak bu çağrı farklı olabilir
        -- Birkaç farklı yöntemi deniyoruz
        
        -- Yöntem 1: Doğrudan değer döndüren sürüm
        newPreviewScale = imgui.SliderFloat("Ölçek##PreviewScale", self.previewScale, 0.5, 4.0)
        if newPreviewScale ~= self.previewScale then
            previewScaleChanged = true
        end
        
        -- Değeri güncelle
        if previewScaleChanged and type(newPreviewScale) == "number" then
            self.previewScale = newPreviewScale
            Console:log("Önizleme ölçeği değiştirildi: " .. tostring(self.previewScale))
        end
        
        -- Tileset bilgileri
        imgui.Text(string.format("Boyut: %dx%d, Karo: %dx%d", 
            self.activeTileset.width, 
            self.activeTileset.height,
            self.activeTileset.cols,
            self.activeTileset.rows
        ))
        
        -- Seçilen karo bilgisi
        if self.selectedTile then
            imgui.Text(string.format("Seçilen Karo: %d", self.selectedTile))
        else
            imgui.Text("Karo seçilmedi")
        end
        
        -- Tileset görüntüsünü çiz
        local availWidth = imgui.GetContentRegionAvail()
        
        -- previewScale'in sayı olduğundan emin ol
        local scale = self.previewScale
        if type(scale) ~= "number" then
            scale = 2.0
            self.previewScale = scale
        end
        
        local imageWidth = self.activeTileset.width * scale
        local imageHeight = self.activeTileset.height * scale
        
        -- Tileset görüntüsünü çizmeden önce pozisyonu kaydet
        local cursorX, cursorY = imgui.GetCursorPos()
        
        imgui.Image(self.activeTileset.image, imageWidth, imageHeight)
        
        -- Fare tıklamasını kontrol et
        if imgui.IsItemHovered() and love.mouse.isDown(1) then
            local mouseX, mouseY = imgui.GetMousePos()
            local itemX, itemY = imgui.GetItemRectMin()
            
            -- Tileset içindeki pozisyonu hesapla
            local tilesetX = (mouseX - itemX) / scale
            local tilesetY = (mouseY - itemY) / scale
            
            -- Karo ID'sini hesapla
            local tileId = self:getTileIdFromPosition(self.activeTileset, tilesetX, tilesetY)
            if tileId then
                self.selectedTile = tileId
                Console:log("Karo seçildi (ImGui): " .. tostring(self.selectedTile))
            end
        end
        
        -- Seçilen ve üzerinde gezinilen karoları görselleştir
        if self.selectedTile or self.hoveredTile then
            -- Seçilen karo
            if self.selectedTile then
                local tile = self:getTileFromTileset(self.activeTileset, self.selectedTile)
                if tile then
                    -- Seçilen karonun pozisyonunu hesapla
                    local tileX = tile.col * self.activeTileset.tileSize * scale
                    local tileY = tile.row * self.activeTileset.tileSize * scale
                    local tileW = self.activeTileset.tileSize * scale
                    local tileH = self.activeTileset.tileSize * scale
                    
                    -- Seçilen karoyu vurgula - basit bir metin ile
                    imgui.Text(string.format("Seçilen Karo: %d (Sütun: %d, Satır: %d)", 
                        self.selectedTile, tile.col + 1, tile.row + 1))
                end
            end
            
            -- Üzerinde gezinilen karo
            if self.hoveredTile and self.hoveredTile ~= self.selectedTile then
                local tile = self:getTileFromTileset(self.activeTileset, self.hoveredTile)
                if tile then
                    -- Üzerinde gezinilen karonun pozisyonunu hesapla
                    local tileX = tile.col * self.activeTileset.tileSize * scale
                    local tileY = tile.row * self.activeTileset.tileSize * scale
                    local tileW = self.activeTileset.tileSize * scale
                    local tileH = self.activeTileset.tileSize * scale
                    
                    -- Üzerinde gezinilen karoyu vurgula - basit bir metin ile
                    imgui.Text(string.format("Üzerinde Gezinilen Karo: %d (Sütun: %d, Satır: %d)", 
                        self.hoveredTile, tile.col + 1, tile.row + 1))
                end
            end
        end
    end
    
    -- Harita ayarları
    imgui.Separator()
    imgui.Text("Harita Ayarları:")
    
    if #self.maps > 0 then
        local mapNames = {}
        local currentMapIndex = 1
        local i = 1
        
        for name, _ in pairs(self.maps) do
            mapNames[i] = name
            if self.activeMap and self.activeMap.name == name then
                currentMapIndex = i
            end
            i = i + 1
        end
        
        local changed, newIndex = imgui.Combo("##MapCombo", currentMapIndex - 1, mapNames, #mapNames)
        if changed then
            self.activeMap = self.maps[mapNames[newIndex + 1]]
        end
    else
        if imgui.Button("Yeni Harita") then
            self:createMap(20, 15, "Yeni Harita")
        end
    end
    
    if self.activeMap then
        imgui.Text(string.format("Boyut: %dx%d", self.activeMap.width, self.activeMap.height))
        
        -- Izgara boyutu ayarı - ImGui kullanımını düzeltiyoruz
        -- Eğer gridSize bir sayı değilse, varsayılan değere ayarla
        if type(self.gridSize) ~= "number" then
            self.gridSize = 32
        end
        
        -- ImGui.SliderInt kullanımı - farklı ImGui sürümleri için uyumlu hale getiriyoruz
        local gridSizeChanged = false
        local newGridSize = self.gridSize
        
        -- Slider'ı çiz ve değişikliği kontrol et
        newGridSize = imgui.SliderInt("Izgara Boyutu##GridSize", self.gridSize, 16, 64)
        if newGridSize ~= self.gridSize then
            gridSizeChanged = true
        end
        
        -- Değeri güncelle
        if gridSizeChanged and type(newGridSize) == "number" then
            self.gridSize = newGridSize
            
            -- Tüm tilemap entity'lerinin ızgara boyutunu güncelle
            for _, entity in ipairs(self.entities) do
                if entity.type == "tilemap" then
                    entity.gridSize = self.gridSize
                end
            end
            
            Console:log("Izgara boyutu değiştirildi: " .. tostring(self.gridSize))
        end
        
        -- Izgara gösterme seçeneği
        local showGridChanged, newShowGrid = imgui.Checkbox("Izgarayı Göster", self.showGrid)
        if showGridChanged then
            self.showGrid = newShowGrid
            
            -- Tüm tilemap entity'lerinin ızgara görünürlüğünü güncelle
            for _, entity in ipairs(self.entities) do
                if entity.type == "tilemap" then
                    entity.showGrid = self.showGrid
                end
            end
        end
        
        -- Entity oluşturma düğmesi
        if imgui.Button("Haritayı Entity Olarak Ekle") then
            self:createTilemapEntity(self.activeMap.name, 0, 0, 1)
        end
        
        -- Entity listesi
        if #self.entities > 0 then
            imgui.Separator()
            imgui.Text("Tilemap Entity'leri:")
            
            for i, entity in ipairs(self.entities) do
                if entity.type == "tilemap" then
                    if imgui.TreeNode(entity.name .. "##" .. i) then
                        -- X pozisyonu
                        local xValue = entity.x or 0
                        local xChanged, newX = imgui.DragFloat("X##" .. i, xValue, 1.0)
                        if xChanged then entity.x = newX end
                        
                        -- Y pozisyonu
                        local yValue = entity.y or 0
                        local yChanged, newY = imgui.DragFloat("Y##" .. i, yValue, 1.0)
                        if yChanged then entity.y = newY end
                        
                        -- Rotasyon
                        local rotValue = entity.rotation or 0
                        local rotChanged, newRot = imgui.SliderFloat("Rotasyon##" .. i, rotValue, 0, math.pi * 2)
                        if rotChanged then entity.rotation = newRot end
                        
                        -- Ölçek X
                        local scaleXValue = entity.scaleX or 1
                        local scaleXChanged, newScaleX = imgui.SliderFloat("Ölçek X##" .. i, scaleXValue, 0.1, 5.0)
                        if scaleXChanged then entity.scaleX = newScaleX end
                        
                        -- Ölçek Y
                        local scaleYValue = entity.scaleY or 1
                        local scaleYChanged, newScaleY = imgui.SliderFloat("Ölçek Y##" .. i, scaleYValue, 0.1, 5.0)
                        if scaleYChanged then entity.scaleY = newScaleY end
                        
                        -- Görünürlük
                        local visibleValue = entity.visible
                        if visibleValue == nil then visibleValue = true end
                        local visibleChanged, newVisible = imgui.Checkbox("Görünür##" .. i, visibleValue)
                        if visibleChanged then entity.visible = newVisible end
                        
                        -- Izgara boyutu
                        local gridSizeValue = entity.gridSize or self.gridSize
                        local entityGridSizeChanged, newEntityGridSize = imgui.SliderInt("Izgara Boyutu##" .. i, gridSizeValue, 16, 64)
                        if entityGridSizeChanged then entity.gridSize = newEntityGridSize end
                        
                        -- Izgara gösterme
                        local showGridValue = entity.showGrid
                        if showGridValue == nil then showGridValue = true end
                        local entityShowGridChanged, newEntityShowGrid = imgui.Checkbox("Izgarayı Göster##" .. i, showGridValue)
                        if entityShowGridChanged then entity.showGrid = newEntityShowGrid end
                        
                        -- Silme düğmesi
                        if imgui.Button("Sil##" .. i) then
                            if SceneManager and SceneManager.removeEntity then
                                SceneManager:removeEntity(entity)
                            end
                            
                            -- Entity'yi listeden kaldır
                            for j, e in ipairs(self.entities) do
                                if e == entity then
                                    table.remove(self.entities, j)
                                    break
                                end
                            end
                        end
                        
                        imgui.TreePop()
                    end
                end
            end
        end
    end
    
    imgui.End()
end

-- Değiştirildi: drawMap fonksiyonu artık gridSize ve showGrid parametrelerini alıyor
function Tilemap:drawMap(map, gridSize, showGrid)
    if not map then return end
    
    -- Varsayılan değerleri kullan eğer parametre verilmemişse
    gridSize = gridSize or self.gridSize
    if showGrid == nil then showGrid = self.showGrid end
    
    -- Her katmanı çiz
    for layerIndex, layer in ipairs(map.layers) do
        if layer.visible then
            for y = 1, map.height do
                for x = 1, map.width do
                    local tile = layer.tiles[y][x]
                    if tile then
                        local tileset = self.tilesets[tile.tilesetName]
                        if tileset then
                            local tileData = self:getTileFromTileset(tileset, tile.tileId)
                            if tileData then
                                love.graphics.setColor(1, 1, 1, 1) -- Tam opaklık ile çiz
                                love.graphics.draw(
                                    tileset.image,
                                    tileData.quad,
                                    (x - 1) * gridSize,
                                    (y - 1) * gridSize,
                                    0,
                                    gridSize / tileset.tileSize,
                                    gridSize / tileset.tileSize
                                )
                            else
                                Console:log(string.format("Hata: Karo verisi bulunamadı: %d", tile.tileId))
                            end
                        else
                            Console:log(string.format("Hata: Tileset bulunamadı: %s", tile.tilesetName))
                        end
                    end
                end
            end
        end
    end
    
    -- Izgara çizgileri
    if showGrid then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        love.graphics.setLineWidth(1) -- Çizgi kalınlığını ayarla
        
        -- Yatay çizgiler
        for y = 0, map.height do
            love.graphics.line(
                0, 
                y * gridSize, 
                map.width * gridSize, 
                y * gridSize
            )
        end
        
        -- Dikey çizgiler
        for x = 0, map.width do
            love.graphics.line(
                x * gridSize, 
                0, 
                x * gridSize, 
                map.height * gridSize
            )
        end
        
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Tilemap:drawInScene()
    -- Aktif haritayı çiz (editör görünümü)
    if self.activeMap then
        self:drawMap(self.activeMap, self.gridSize, self.showGrid)
    end
    
    -- Tüm tilemap entity'lerini çiz
    for _, entity in ipairs(self.entities) do
        if entity.type == "tilemap" then
            self:drawEntity(entity)
        end
    end
    
    -- Fare pozisyonunda seçilen karoyu göster (yerleştirme önizlemesi)
    if self.selectedTile and self.activeTileset and not imgui.GetWantCaptureMouse() then
        local mouseX, mouseY = love.mouse.getPosition()
        
        -- Kendi screenToWorld fonksiyonumuzu kullan
        local worldX, worldY = self:screenToWorld(mouseX, mouseY)
        
        -- Izgara pozisyonunu hesapla
        local gridX = math.floor(worldX / self.gridSize)
        local gridY = math.floor(worldY / self.gridSize)
        
        -- Seçilen karoyu çiz
        local tileData = self:getTileFromTileset(self.activeTileset, self.selectedTile)
        if tileData then
            love.graphics.setColor(1, 1, 1, 0.7) -- Yarı saydam
            love.graphics.draw(
                self.activeTileset.image,
                tileData.quad,
                gridX * self.gridSize,
                gridY * self.gridSize,
                0,
                self.gridSize / self.activeTileset.tileSize,
                self.gridSize / self.activeTileset.tileSize
            )
            love.graphics.setColor(1, 1, 1, 1) -- Rengi sıfırla
            
            -- Izgara vurgusu
            love.graphics.setColor(1, 1, 0, 0.5)
            love.graphics.rectangle(
                "line",
                gridX * self.gridSize,
                gridY * self.gridSize,
                self.gridSize,
                self.gridSize
            )
            love.graphics.setColor(1, 1, 1, 1) -- Rengi sıfırla
        end
    end
    
    -- Debug bilgisi - aktif harita ve seçilen karo hakkında bilgi
    if love.keyboard.isDown("t") then
        local info = "Tilemap Bilgisi:\n"
        
        if self.activeMap then
            info = info .. string.format("Aktif Harita: %s (%dx%d)\n", 
                self.activeMap.name, self.activeMap.width, self.activeMap.height)
            
            -- Katman bilgisi
            info = info .. string.format("Katman Sayısı: %d\n", #self.activeMap.layers)
            
            -- Karo sayısı
            local tileCount = 0
            for _, layer in ipairs(self.activeMap.layers) do
                for y = 1, self.activeMap.height do
                    for x = 1, self.activeMap.width do
                        if layer.tiles[y][x] then
                            tileCount = tileCount + 1
                        end
                    end
                end
            end
            
            info = info .. string.format("Toplam Karo Sayısı: %d\n", tileCount)
        else
            info = info .. "Aktif Harita Yok\n"
        end
        
        if self.selectedTile then
            info = info .. string.format("Seçilen Karo: %d\n", self.selectedTile)
        else
            info = info .. "Karo Seçilmedi\n"
        end
        
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 10, 10, 300, 100)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(info, 20, 20)
    end
end

-- Orijinal draw fonksiyonunu güncelle
function Tilemap:draw()
    -- Bu fonksiyon artık drawInScene fonksiyonunu çağırır
    self:drawInScene()
end

return Tilemap