local State = require "state"
local Console = require "modules.console"

local Inspector = {
    showWindow = true,
    componentTypes = {
        "Transform",
        "Tilemap"
    }
}

function Inspector:init()
    State.showWindows.inspector = true
    State.windowSizes.inspector = {width = 300, height = 400}
end

function Inspector:drawTransformComponent(entity)
    imgui.Text("Transform")
    
    -- Entity'nin değerlerini başlangıçta sayısal değerlere dönüştür
    if type(entity.x) ~= "number" then entity.x = tonumber(entity.x) or 0 end
    if type(entity.y) ~= "number" then entity.y = tonumber(entity.y) or 0 end
    if type(entity.width) ~= "number" then entity.width = tonumber(entity.width) or 32 end
    if type(entity.height) ~= "number" then entity.height = tonumber(entity.height) or 32 end
    if type(entity.rotation) ~= "number" then entity.rotation = tonumber(entity.rotation) or 0 end
    
    -- X pozisyonu
    local changed, newValue = imgui.DragFloat("X##Transform", entity.x, 1.0)
    if changed and type(newValue) == "number" then 
        entity.x = newValue
    end
    
    -- Y pozisyonu
    changed, newValue = imgui.DragFloat("Y##Transform", entity.y, 1.0)
    if changed and type(newValue) == "number" then 
        entity.y = newValue
    end
    
    -- Genişlik
    changed, newValue = imgui.DragFloat("Width##Transform", entity.width, 1.0)
    if changed and type(newValue) == "number" then 
        entity.width = newValue
    end
    
    -- Yükseklik
    changed, newValue = imgui.DragFloat("Height##Transform", entity.height, 1.0)
    if changed and type(newValue) == "number" then 
        entity.height = newValue
    end
    
    -- Rotasyon
    changed, newValue = imgui.DragFloat("Rotation##Transform", entity.rotation, 0.01)
    if changed and type(newValue) == "number" then 
        entity.rotation = newValue
    end
end

function Inspector:drawTilemapComponent(entity)
    if not entity.components.tilemap then
        if imgui.Button("Add Tilemap Component") then
            entity.components.tilemap = {
                width = 20,
                height = 15,
                tileSize = 32,
                layers = {
                    {
                        name = "Background",
                        tiles = {},
                        visible = true
                    }
                },
                tileset = nil
            }
            
            -- Initialize empty tiles
            for layerIndex, layer in ipairs(entity.components.tilemap.layers) do
                layer.tiles = {}
                for y = 1, entity.components.tilemap.height do
                    layer.tiles[y] = {}
                    for x = 1, entity.components.tilemap.width do
                        layer.tiles[y][x] = {
                            id = 0,
                            rotation = 0,
                            flipX = false,
                            flipY = false
                        }
                    end
                end
            end
            
            -- Update entity dimensions
            entity.width = entity.components.tilemap.width * entity.components.tilemap.tileSize
            entity.height = entity.components.tilemap.height * entity.components.tilemap.tileSize
            
            -- Open tilemap editor window
            State.showWindows.tilemap = true
            
            Console:log("Added tilemap component to: " .. (entity.name or "unnamed"))
        end
        return
    end

    if imgui.CollapsingHeader("Tilemap") then
        -- Show basic tilemap info
        if entity.components.tilemap.tileset then
            imgui.Text("Tileset: " .. entity.components.tilemap.tileset.name)
        else
            imgui.Text("Tileset: None")
        end
        
        imgui.Text("Size: " .. entity.components.tilemap.width .. "x" .. entity.components.tilemap.height)
        imgui.Text("Tile Size: " .. entity.components.tilemap.tileSize .. "px")
        
        -- Open editor button
        if imgui.Button("Open Tilemap Editor") then
            State.showWindows.tilemap = true
        end
        
        -- Remove component button
        if imgui.Button("Remove Tilemap Component") then
            entity.components.tilemap = nil
            State.showWindows.tilemap = false
            Console:log("Removed tilemap component from: " .. (entity.name or "unnamed"))
        end
    end
end

function Inspector:draw()
    if not State.showWindows.inspector then return end
    
    imgui.SetNextWindowSize(State.windowSizes.inspector.width, State.windowSizes.inspector.height, imgui.Cond_FirstUseEver)
    if imgui.Begin("Inspector", State.showWindows.inspector) then
        local entity = State.selectedEntity
        
        if entity then
            -- Entity name
            local name = imgui.InputText("Name", entity.name or "", 100)
            if name ~= entity.name then entity.name = name end
            
            imgui.Separator()
            
            -- Initialize components table if it doesn't exist
            entity.components = entity.components or {}
            
            -- Draw components
            self:drawTransformComponent(entity)
            self:drawTilemapComponent(entity)
            
            -- Add Component Button
            if imgui.Button("Add Component") then
                imgui.OpenPopup("AddComponentPopup")
            end
            
            if imgui.BeginPopup("AddComponentPopup") then
                for _, componentType in ipairs(self.componentTypes) do
                    if not entity.components[string.lower(componentType)] then
                        if imgui.MenuItem(componentType) then
                            entity.components[string.lower(componentType)] = {}
                            Console:log("Added " .. componentType .. " component to " .. entity.name)
                        end
                    end
                end
                imgui.EndPopup()
            end
        else
            imgui.Text("No entity selected")
        end
    end
    imgui.End()
end

return Inspector 