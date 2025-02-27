local State = require "state"
local Console = require "modules.console"
local Camera = require "modules.camera"

local SceneManager = {}

function SceneManager:init()
    self.scenes = {}
    self.entities = {}
    self.selectedEntity = nil
    self.gridSize = 32
    self.showGrid = true
    self.lastMouseX = 0
    self.lastMouseY = 0
    
    -- Create a default scene
    self:createNewScene("Default Scene")
end

function SceneManager:createNewScene(name)
    local scene = {
        name = name,
        entities = {},
        background = {r = 0.1, g = 0.1, b = 0.1}
    }
    
    table.insert(self.scenes, scene)
    State.currentScene = scene
    Console:log("Created new scene: " .. name)
    return scene
end

function SceneManager:createEntity(x, y)
    local entity = {
        name = "Entity " .. (#self.entities + 1),
        x = x or 0,
        y = y or 0,
        width = 32,
        height = 32,
        rotation = 0,
        sprite = nil,
        animation = nil,
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

-- function SceneManager:drawEntities()
--     for _, entity in ipairs(self.entities) do
--         -- Sprite veya Animator component'i varsa
--         if entity.components then
--             if entity.components.animator and 
--                entity.components.animator.currentAnimation and 
--                entity.components.animator.playing then
--                 -- Animasyon çiz
--                 local animator = entity.components.animator
--                 local anim = animator.currentAnimation
                
--                 if anim and anim.frames and #anim.frames > 0 then
--                     local frame = anim.frames[animator.currentFrame]
--                     if frame and frame.quad then
--                         love.graphics.setColor(1, 1, 1, 1)
--                         love.graphics.draw(
--                             anim.source.data,
--                             frame.quad,
--                             entity.x + entity.width/2,
--                             entity.y + entity.height/2,
--                             entity.rotation or 0,
--                             entity.width / anim.frameWidth,
--                             entity.height / anim.frameHeight,
--                             anim.frameWidth/2,
--                             anim.frameHeight/2
--                         )
--                     end
--                 end
--             elseif entity.components.sprite and entity.components.sprite.image then
--                 -- Normal sprite çiz
--                 local sprite = entity.components.sprite
--                 local color = sprite.color or {1, 1, 1, 1}
                
--                 love.graphics.setColor(color[1], color[2], color[3], color[4])
                
--                 local img = sprite.image.data
--                 local w, h = img:getDimensions()
                
--                 love.graphics.draw(
--                     img,
--                     entity.x + entity.width/2,
--                     entity.y + entity.height/2,
--                     entity.rotation or 0,
--                     entity.width / w,
--                     entity.height / h,
--                     w/2, h/2
--                 )
--             else
--                 -- Placeholder çiz
--                 love.graphics.setColor(0.5, 0.5, 0.5, 1)
--                 love.graphics.rectangle("fill", entity.x, entity.y, entity.width, entity.height)
--                 love.graphics.setColor(0.8, 0.8, 0.8, 1)
--                 love.graphics.rectangle("line", entity.x, entity.y, entity.width, entity.height)
--                 love.graphics.setColor(1, 1, 1, 1)
--                 love.graphics.print(entity.name or "Entity", entity.x + 2, entity.y + 2)
--             end
--         end
--     end
--     love.graphics.setColor(1, 1, 1, 1)  -- Rengi resetle
-- end
function SceneManager:drawEntities()
    for _, entity in ipairs(self.entities) do
        -- Sprite veya Animator component'i varsa
        if entity.components then
            if entity.components.animator and entity.components.animator.currentAnimation then
                -- Animasyon çiz (playing olsun veya olmasın)
                local animator = entity.components.animator
                local anim = animator.currentAnimation
                
                if anim and anim.frames and #anim.frames > 0 then
                    local frame = anim.frames[animator.currentFrame]
                    if frame and frame.quad then
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.draw(
                            anim.source.data,
                            frame.quad,
                            entity.x + entity.width/2,
                            entity.y + entity.height/2,
                            entity.rotation or 0,
                            entity.width / anim.frameWidth,
                            entity.height / anim.frameHeight,
                            anim.frameWidth/2,
                            anim.frameHeight/2
                        )
                    end
                end
            elseif entity.components.sprite and entity.components.sprite.image then
                -- Normal sprite çiz
                local sprite = entity.components.sprite
                local color = sprite.color or {1, 1, 1, 1}
                
                love.graphics.setColor(color[1], color[2], color[3], color[4])
                
                local img = sprite.image.data
                local w, h = img:getDimensions()
                
                love.graphics.draw(
                    img,
                    entity.x + entity.width/2,
                    entity.y + entity.height/2,
                    entity.rotation or 0,
                    entity.width / w,
                    entity.height / h,
                    w/2, h/2
                )
            else
                -- Placeholder çiz
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
                love.graphics.rectangle("fill", entity.x, entity.y, entity.width, entity.height)
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                love.graphics.rectangle("line", entity.x, entity.y, entity.width, entity.height)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(entity.name or "Entity", entity.x + 2, entity.y + 2)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)  -- Rengi resetle
end

function SceneManager:handleInput()
    -- Check for entity selection/manipulation
    if love.mouse.isDown(1) and not imgui.GetWantCaptureMouse() then
        local mouseX, mouseY = love.mouse.getPosition()
        local worldX, worldY = self:screenToWorld(mouseX, mouseY)
        
        -- Calculate mouse delta
        local dx = mouseX - self.lastMouseX
        local dy = mouseY - self.lastMouseY
        
        -- Check if clicked on an entity
        local clickedEntity = nil
        for _, entity in ipairs(self.entities) do
            if worldX >= entity.x and worldX <= entity.x + entity.width and
               worldY >= entity.y and worldY <= entity.y + entity.height then
                clickedEntity = entity
                break
            end
        end
        
        if clickedEntity then
            State.selectedEntity = clickedEntity
            -- Move entity with mouse drag
            if State.selectedEntity then
                entity = State.selectedEntity
                entity.x = entity.x + dx / Camera.scaleX
                entity.y = entity.y + dy / Camera.scaleY
            end
        else
            -- Create new entity at click position
            if love.keyboard.isDown("lctrl") then
                self:createEntity(worldX, worldY)
            else
                State.selectedEntity = nil
            end
        end
        
        -- Update last mouse position
        self.lastMouseX = mouseX
        self.lastMouseY = mouseY
    else
        -- Reset last mouse position when not dragging
        self.lastMouseX = love.mouse.getX()
        self.lastMouseY = love.mouse.getY()
    end

    -- Delete entity with right-click
    if love.mouse.isDown(2) and State.selectedEntity then
        self:deleteEntity(State.selectedEntity)
    end

    -- Zoom in/out with mouse wheel
    if love.mouse.isDown(4) then
        Camera:zoom(1.1)  -- Zoom in
    elseif love.mouse.isDown(5) then
        Camera:zoom(0.9)  -- Zoom out
    end
end

function SceneManager:screenToWorld(x, y)
    -- Convert screen coordinates to world coordinates
    local scaleX = Camera.scaleX
    local scaleY = Camera.scaleY
    local offsetX = Camera.x
    local offsetY = Camera.y
    local worldX = (x - love.graphics.getWidth() / 2) / scaleX + offsetX
    local worldY = (y - love.graphics.getHeight() / 2) / scaleY + offsetY
    return worldX, worldY
end

function SceneManager:selectEntityAt(mouseX, mouseY)
    -- Select entity based on mouse click position
    local worldX, worldY = self:screenToWorld(mouseX, mouseY)
    
    -- Check for entity collision with mouse click
    for _, entity in ipairs(self.entities) do
        if worldX >= entity.x and worldX <= entity.x + entity.width and
           worldY >= entity.y and worldY <= entity.y + entity.height then
            State.selectedEntity = entity
            Console:log("Selected entity: " .. entity.name)
            return
        end
    end
end

function SceneManager:drawSceneEditor()
    -- Draw grid and entities in the scene editor window
    self:drawGrid()
    self:drawEntities()
end

function SceneManager:update(dt)
    -- Entity'lerin animasyonlarını güncelle
    for _, entity in ipairs(self.entities) do
        if entity.components and entity.components.animator then
            local animator = entity.components.animator
            if animator.playing and animator.currentAnimation then
                animator.timer = animator.timer + dt
                
                local currentFrame = animator.currentAnimation.frames[animator.currentFrame]
                if currentFrame and animator.timer >= currentFrame.duration then
                    animator.timer = animator.timer - currentFrame.duration
                    animator.currentFrame = animator.currentFrame + 1
                    
                    -- Animasyon bittiğinde başa dön
                    if animator.currentFrame > #animator.currentAnimation.frames then
                        animator.currentFrame = 1
                    end
                end
            end
        end
    end
end

return SceneManager
