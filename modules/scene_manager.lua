local State = require "state"
local Console = require "modules.console"
local Camera = require "modules.camera"
local imgui = require "imgui"

local SceneManager = {}

function SceneManager:init()
    self.entities = {}
    self.selectedEntity = nil
    self.gridSize = 32
    self.showGrid = true
    self.lastMouseX = 0
    self.lastMouseY = 0
    self.handleSize = 4
end

function SceneManager:createEntity(x, y)
    local entity = {
        name = "Entity " .. (#self.entities + 1),
        x = x or 0,
        y = y or 0,
        width = 32,
        height = 32,
        rotation = 0,
        components = {}
    }
    
    table.insert(self.entities, entity)
    State.selectedEntity = entity
    Console:log("Created entity: " .. entity.name)
    return entity
end

function SceneManager:deleteEntity(entity)
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            if State.selectedEntity == entity then
                State.selectedEntity = nil
            end
            Console:log("Deleted entity: " .. entity.name)
            return true
        end
    end
    return false
end

function SceneManager:drawGrid()
    if not self.showGrid then return end
    
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    
    local w, h = love.graphics.getDimensions()
    local startX = math.floor(-Camera.x / self.gridSize) * self.gridSize
    local startY = math.floor(-Camera.y / self.gridSize) * self.gridSize
    local endX = startX + w / Camera.scaleX + self.gridSize * 2
    local endY = startY + h / Camera.scaleY + self.gridSize * 2
    
    for x = startX, endX, self.gridSize do
        love.graphics.line(x, startY, x, endY)
    end
    
    for y = startY, endY, self.gridSize do
        love.graphics.line(startX, y, endX, y)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function SceneManager:drawEntities()
    for _, entity in ipairs(self.entities) do
        if entity.visible ~= false then
            -- Entity tipine göre çizim yap
            if entity.type == "tilemap" then
                -- Tilemap entity'si çiz - Tilemap modülüne bırak
                -- Burada hiçbir şey yapmıyoruz, Tilemap modülü kendi entity'lerini çizecek
            else
                -- Varsayılan dikdörtgen çiz
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                local entityX = tonumber(entity.x) or 0
                local entityY = tonumber(entity.y) or 0
                local entityWidth = tonumber(entity.width) or 32
                local entityHeight = tonumber(entity.height) or 32
                
                love.graphics.rectangle("line", entityX, entityY, entityWidth, entityHeight)
            end
            
            -- Seçili entity'yi vurgula
            if entity == State.selectedEntity then
                self:drawSelectionOutline(entity)
            end
        end
    end
end

function SceneManager:drawSelectionOutline(entity)
    if not entity then return end
    
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.setLineWidth(2)
    
    local entityX = tonumber(entity.x) or 0
    local entityY = tonumber(entity.y) or 0
    local entityWidth = tonumber(entity.width) or 32
    local entityHeight = tonumber(entity.height) or 32
    
    love.graphics.rectangle("line", entityX, entityY, entityWidth, entityHeight)
    love.graphics.setColor(1, 1, 1, 1)
end

function SceneManager:handleInput()
    local mouseX, mouseY = love.mouse.getPosition()
    local worldX, worldY = self:screenToWorld(mouseX, mouseY)
    
    if love.mouse.isDown(1) and not imgui.GetWantCaptureMouse() then
        -- Entity seçimi
        local clickedEntity = self:getEntityAtPosition(worldX, worldY)
        if clickedEntity then
            State.selectedEntity = clickedEntity
        else
            -- Yeni entity oluştur
            if love.keyboard.isDown("lctrl") then
                self:createEntity(worldX, worldY)
            else
                State.selectedEntity = nil
            end
        end
    end
    
    self.lastMouseX = mouseX
    self.lastMouseY = mouseY
end

function SceneManager:getEntityAtPosition(x, y)
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        local entityX = tonumber(entity.x) or 0
        local entityY = tonumber(entity.y) or 0
        local entityWidth = tonumber(entity.width) or 32
        local entityHeight = tonumber(entity.height) or 32
        
        if x >= entityX and x <= entityX + entityWidth and
           y >= entityY and y <= entityY + entityHeight then
            return entity
        end
    end
    return nil
end

function SceneManager:screenToWorld(x, y)
    local scaleX = Camera.scaleX
    local scaleY = Camera.scaleY
    local offsetX = Camera.x
    local offsetY = Camera.y
    local worldX = (x - love.graphics.getWidth() / 2) / scaleX + offsetX
    local worldY = (y - love.graphics.getHeight() / 2) / scaleY + offsetY
    return worldX, worldY
end

function SceneManager:drawSceneEditor()
    self:drawGrid()
    self:drawEntities()
end

function SceneManager:update(dt)
    -- Temel güncelleme işlemleri
end

return SceneManager
