local State = require "state"
local Console = require "modules.console"

local Inspector = {
    showWindow = true,
    componentTypes = {
        "Transform",
        "Sprite",
        "Collider",
        "Script",
        "Animation"
    }
}

function Inspector:init()
    State.showWindows.inspector = true
    State.windowSizes.inspector = {width = 300, height = 400}
end

function Inspector:drawTransformComponent(entity)
    if imgui.CollapsingHeader("Transform", imgui.TreeNodeFlags_DefaultOpen) then
        -- Position
        local x = imgui.DragFloat("X##Transform", entity.x, 0.1, -1000, 1000)
        if x ~= entity.x then entity.x = x end
        
        local y = imgui.DragFloat("Y##Transform", entity.y, 0.1, -1000, 1000)
        if y ~= entity.y then entity.y = y end
        
        -- Scale
        local width = imgui.DragFloat("Scale X##Transform", entity.width, 0.1, 1, 1000)
        if width ~= entity.width then entity.width = width end
        
        local height = imgui.DragFloat("Scale Y##Transform", entity.height, 0.1, 1, 1000)
        if height ~= entity.height then entity.height = height end
        
        -- Rotation
        local rotation = imgui.DragFloat("Rotation##Transform", entity.rotation or 0, 0.1, -360, 360)
        if rotation ~= (entity.rotation or 0) then entity.rotation = rotation end
    end
end

function Inspector:drawSpriteComponent(entity)
    if not entity.components.sprite then
        if imgui.Button("Add Sprite Component") then
            entity.components.sprite = {
                image = nil,
                color = {1, 1, 1, 1}
            }
        end
        return
    end

    if imgui.CollapsingHeader("Sprite") then
        -- Sprite seçimi
        imgui.Text("Image:")
        
        -- Mevcut resmi göster
        local currentImage = entity.components.sprite.image and entity.components.sprite.image.name or "None"
        if imgui.Button(currentImage .. "##SpriteSelect") then
            imgui.OpenPopup("SpriteSelectPopup")
        end
        
        -- Resim seçme popup'ı
        if imgui.BeginPopup("SpriteSelectPopup") then
            imgui.Text("Select an Image")
            imgui.Separator()
            
            -- Asset listesinden sadece resimleri göster
            for _, asset in ipairs(State.assets) do
                if asset.type == "image" then
                    if imgui.Selectable(asset.name) then
                        entity.components.sprite.image = asset
                        Console:log("Selected image: " .. asset.name .. " for entity: " .. (entity.name or "unnamed"))
                    end
                end
            end
            imgui.EndPopup()
        end
        
        -- Clear image button
        imgui.SameLine()
        if imgui.Button("X##ClearSprite") then
            entity.components.sprite.image = nil
            Console:log("Cleared sprite image for entity: " .. (entity.name or "unnamed"))
        end
        
        -- Color picker
        local color = entity.components.sprite.color
        color[1], color[2], color[3] = imgui.ColorEdit3("Color##Sprite", color[1], color[2], color[3])
        
        -- Alpha slider
        imgui.SliderFloat("Alpha##Sprite", color[4], 0, 1)
        
        -- Component'i silme butonu
        if imgui.Button("Remove Sprite Component") then
            entity.components.sprite = nil
            Console:log("Removed sprite component from entity: " .. (entity.name or "unnamed"))
        end
    end
end

function Inspector:drawColliderComponent(entity)
    if not entity.components.collider then
        if imgui.Button("Add Collider Component") then
            entity.components.collider = {
                type = "box",
                width = entity.width,
                height = entity.height,
                offset = {x = 0, y = 0},
                isTrigger = false
            }
        end
        return
    end

    if imgui.CollapsingHeader("Collider") then
        -- Collider tipi seçimi
        local colliderTypes = "box\0circle\0\0"  -- ImGui için null-terminated string
        local currentTypeIndex = entity.components.collider.type == "box" and 0 or 1
        
        -- Combo box
        local newIndex = imgui.Combo("Type##Collider", currentTypeIndex, colliderTypes)
        if newIndex ~= currentTypeIndex then
            entity.components.collider.type = newIndex == 0 and "box" or "circle"
            Console:log("Changed collider type to: " .. entity.components.collider.type)
        end
        
        -- Size
        local width = imgui.DragFloat("Width##Collider", entity.components.collider.width, 0.1, 1, 1000)
        if width ~= entity.components.collider.width then 
            entity.components.collider.width = width 
        end
        
        local height = imgui.DragFloat("Height##Collider", entity.components.collider.height, 0.1, 1, 1000)
        if height ~= entity.components.collider.height then 
            entity.components.collider.height = height 
        end
        
        -- Offset
        local offsetX = imgui.DragFloat("Offset X##Collider", entity.components.collider.offset.x, 0.1, -100, 100)
        if offsetX ~= entity.components.collider.offset.x then 
            entity.components.collider.offset.x = offsetX 
        end
        
        local offsetY = imgui.DragFloat("Offset Y##Collider", entity.components.collider.offset.y, 0.1, -100, 100)
        if offsetY ~= entity.components.collider.offset.y then 
            entity.components.collider.offset.y = offsetY 
        end
        
        -- Is Trigger
        local isTrigger = imgui.Checkbox("Is Trigger##Collider", entity.components.collider.isTrigger)
        if isTrigger ~= entity.components.collider.isTrigger then 
            entity.components.collider.isTrigger = isTrigger 
        end
        
        -- Component'i silme butonu
        if imgui.Button("Remove Collider Component") then
            entity.components.collider = nil
            Console:log("Removed collider component from entity: " .. (entity.name or "unnamed"))
        end
    end
end

function Inspector:drawAnimatorComponent(entity)
    if not entity.components.animator then
        if imgui.Button("Add Animator Component") then
            entity.components.animator = {
                currentAnimation = nil,
                animations = {},
                playing = false,
                timer = 0,
                currentFrame = 1
            }
            -- Animator penceresini aç
            State.showWindows.animator = true
            Console:log("Added animator component to: " .. (entity.name or "unnamed"))
        end
        return
    end

    if imgui.CollapsingHeader("Animator") then
        -- Animator penceresini açma butonu
        if imgui.Button("Open Animator Window##AnimatorOpen") then
            State.showWindows.animator = true
        end
        
        -- Component'i silme butonu
        if imgui.Button("Remove Animator Component") then
            entity.components.animator = nil
            -- Animator penceresini kapat
            State.showWindows.animator = false
            Console:log("Removed animator component from: " .. (entity.name or "unnamed"))
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
            self:drawSpriteComponent(entity)
            self:drawColliderComponent(entity)
            self:drawAnimatorComponent(entity)
            
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