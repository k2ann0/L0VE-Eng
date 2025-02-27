local State = require "state"
local Console = require "modules.console"

local Animator = {
    currentFrame = 1,
    previewScale = 1,
    playing = false,
    timer = 0,
    showGridSystem = false,  -- Yeni flag
    gridWindow = {
        animationName = "New Animation",
        colCount = 1,
        rowCount = 1,
        selectedFrames = {},
        asset = nil,  -- Seçili asset'i tutmak için
        entity = nil  -- Seçili entity'yi tutmak için
    }
}
Animator.__index = Animator

local rowCount, colCount = 1, 1
local selectedFrames = {}  -- Seçili frame'leri tutacak tablo
local gridSignal, startSignal = false, false
local showGridWindow = false
local currentAsset = nil  -- Geçerli asset'i tutacak değişken
local lastClickTime = 0   -- Son tıklama zamanını tutacak değişken
local animationName = ""  -- Animasyon ismi için yeni değişken

function Animator:init()
    self.animations = {}
    self.currentFrame = 1
    self.playing = false
    self.looping = true
    self.frameTime = 0.1
    self.timer = 0
    self.previewScale = 1
    self.framesPerRow = 1
    self.numRows = 1
    -- Başlangıçta pencere kapalı olsun
    State.showWindows.animator = false
end

function Animator:GridSystem(asset, entity)
    self.showGridSystem = true
    self.gridWindow.asset = asset
    self.gridWindow.entity = entity
    self.gridWindow.selectedFrames = {}
end

function Animator:createFromImage(imageAsset, name)
    local animation = {
        name = name,  -- Kullanıcının girdiği ismi kullan
        source = imageAsset,
        
        frames = {},
        frameDuration = 0.1,
        loop = true
    }
    
    if gridSignal then
        local frameWidth = imageAsset.data:getWidth() / colCount
        local frameHeight = imageAsset.data:getHeight() / rowCount
        
        -- Sadece seçili frame'leri ekle
        for frameIndex, isSelected in pairs(selectedFrames) do
            if isSelected then
                local row = math.floor((frameIndex - 1) / colCount)
                local col = (frameIndex - 1) % colCount
                
                local frame = {
                    quad = love.graphics.newQuad(
                        col * frameWidth,
                        row * frameHeight,
                        frameWidth,
                        frameHeight,
                        imageAsset.data:getDimensions()
                    ),
                    duration = 0.1
                }
                table.insert(animation.frames, frame)
            end
        end
    end
    
    table.insert(self.animations, animation)
    State.currentAnimation = animation
    Console:log("Created animation: " .. animation.name, "info")
    return animation
end

-- Animasyonun hangi grid hücresinde olduğunu hesapla
function Animator:GetFramePosition(frame)
    local row = math.floor((frame - 1) / self.framesPerRow)
    local col = (frame - 1) % self.framesPerRow
    return col * self.frameWidth, row * self.frameHeight
end

function Animator:update(dt)
    if not State.showWindows.animator then return end
    
    -- Seçili entity'nin animator component'ini kontrol et
    local entity = State.selectedEntity
    if not entity or not entity.components.animator then return end
    
    local animator = entity.components.animator
    if animator.playing and animator.currentAnimation then
        animator.timer = animator.timer + dt
        
        local currentFrame = animator.currentAnimation.frames[animator.currentFrame]
        if currentFrame and animator.timer >= currentFrame.duration then
            animator.timer = animator.timer - currentFrame.duration
            animator.currentFrame = animator.currentFrame + 1
            
            if animator.currentFrame > #animator.currentAnimation.frames then
                animator.currentFrame = 1
            end
        end
    end
end

function Animator:draw()
    if not State.showWindows.animator then return end
    
    local entity = State.selectedEntity
    if not entity or not entity.components.animator then return end
    
    imgui.SetNextWindowSize(State.windowSizes.animator.width, State.windowSizes.animator.height, imgui.Cond_FirstUseEver)
    if imgui.Begin("Animator", State.showWindows.animator) then
        -- Yeni animasyon oluşturma butonu
        if imgui.Button("Create New Animation") then
            if State.selectedAsset and State.selectedAsset.type == "image" then
                self:GridSystem(State.selectedAsset, entity)
            else
                Console:log("Please select an image asset first!")
            end
        end
        
        imgui.Separator()
        
        -- Entity'nin animasyonlarını listele
        imgui.Text("Animations:")
        for i, anim in ipairs(entity.components.animator.animations) do
            if imgui.Selectable(anim.name, entity.components.animator.currentAnimation == anim) then
                entity.components.animator.currentAnimation = anim
                entity.components.animator.currentFrame = 1
                entity.components.animator.timer = 0
            end
            
            -- Sağ tık menüsü
            if imgui.BeginPopupContextItem() then
                if imgui.MenuItem("Delete") then
                    table.remove(entity.components.animator.animations, i)
                    if entity.components.animator.currentAnimation == anim then
                        entity.components.animator.currentAnimation = nil
                    end
                end
                if imgui.MenuItem("Rename") then
                    -- TODO: Yeniden adlandırma işlevi
                end
                imgui.EndPopup()
            end
        end
        
        imgui.Separator()
        
        -- Seçili animasyonun kontrolleri
        local animator = entity.components.animator
        if animator.currentAnimation then
            -- Play/Pause butonu
            if animator.playing then
                if imgui.Button("Pause") then
                    animator.playing = false
                end
            else
                if imgui.Button("Play") then
                    animator.playing = true
                    animator.timer = 0  -- Timer'ı resetle
                end
            end
            
            -- Frame slider
            if animator.currentAnimation.frames then
                local frameCount = #animator.currentAnimation.frames
                local newFrame = imgui.SliderInt("Frame", animator.currentFrame, 1, frameCount)
                if newFrame ~= animator.currentFrame then
                    animator.currentFrame = newFrame
                    animator.timer = 0  -- Frame değiştiğinde timer'ı resetle
                end
            end
            
            -- Frame duration slider
            if animator.currentAnimation.frames[animator.currentFrame] then
                local duration = imgui.SliderFloat("Frame Duration", 
                    animator.currentAnimation.frames[animator.currentFrame].duration, 
                    0.01, 1.0)
                if duration ~= animator.currentAnimation.frames[animator.currentFrame].duration then
                    animator.currentAnimation.frames[animator.currentFrame].duration = duration
                end
            end
        end
        
        imgui.End()
    end
    
    -- Grid System penceresi
    if self.showGridSystem then
        if imgui.Begin("Grid System##popup", true) then
            -- Animasyon ismi
            self.gridWindow.animationName = imgui.InputText("Animation Name", self.gridWindow.animationName, 100)
            
            imgui.Separator()
            
            -- Grid boyutları
            self.gridWindow.colCount = imgui.SliderInt("Columns", self.gridWindow.colCount, 1, 10)
            self.gridWindow.rowCount = imgui.SliderInt("Rows", self.gridWindow.rowCount, 1, 10)
            
            -- Grid önizleme
            local previewSize = 300
            if imgui.BeginChild("GridPreview", previewSize, previewSize, true) then
                local cx, cy = imgui.GetCursorScreenPos()
                local wx, wy = imgui.GetWindowPos()
                
                -- Sprite sheet'i çiz
                love.graphics.setColor(1, 1, 1, 1)
                self.gridWindow.asset.data:setFilter("nearest", "nearest")
                love.graphics.draw(self.gridWindow.asset.data, cx, cy, 0, 
                    previewSize / self.gridWindow.asset.data:getWidth(),
                    previewSize / self.gridWindow.asset.data:getHeight())
                
                -- Grid çizgileri
                local cellWidth = previewSize / self.gridWindow.colCount
                local cellHeight = previewSize / self.gridWindow.rowCount
                
                -- Grid çizgilerini çiz
                love.graphics.setColor(1, 1, 0, 0.3)
                for i = 1, self.gridWindow.colCount do
                    love.graphics.line(cx + i * cellWidth, cy, cx + i * cellWidth, cy + previewSize)
                end
                for i = 1, self.gridWindow.rowCount do
                    love.graphics.line(cx, cy + i * cellHeight, cx + previewSize, cy + i * cellHeight)
                end
                
                -- Mouse pozisyonu ve seçim
                local mx, my = love.mouse.getPosition()
                mx = mx - cx
                my = my - cy
                
                if mx >= 0 and mx < previewSize and my >= 0 and my < previewSize then
                    local gridX = math.floor(mx / cellWidth)
                    local gridY = math.floor(my / cellHeight)
                    
                    -- Seçili hücreyi vurgula
                    love.graphics.setColor(1, 1, 0, 0.2)
                    love.graphics.rectangle("fill", 
                        cx + gridX * cellWidth, 
                        cy + gridY * cellHeight, 
                        cellWidth, 
                        cellHeight)
                    
                    -- Tıklama ile frame seç
                    if love.mouse.isDown(1) and imgui.IsWindowHovered() then
                        local frameIndex = gridY * self.gridWindow.colCount + gridX + 1
                        if love.mouse.isDown(1) and not self.lastMouseDown then
                            if not self.gridWindow.selectedFrames[frameIndex] then
                                self.gridWindow.selectedFrames[frameIndex] = {
                                    quad = love.graphics.newQuad(
                                        gridX * (self.gridWindow.asset.data:getWidth() / self.gridWindow.colCount),
                                        gridY * (self.gridWindow.asset.data:getHeight() / self.gridWindow.rowCount),
                                        self.gridWindow.asset.data:getWidth() / self.gridWindow.colCount,
                                        self.gridWindow.asset.data:getHeight() / self.gridWindow.rowCount,
                                        self.gridWindow.asset.data:getDimensions()
                                    ),
                                    duration = 0.1,
                                    x = gridX,
                                    y = gridY
                                }
                                Console:log("Selected frame " .. frameIndex)
                            else
                                self.gridWindow.selectedFrames[frameIndex] = nil
                                Console:log("Deselected frame " .. frameIndex)
                            end
                        end
                    end
                end
                
                -- Seçili frame'leri göster
                for i, frame in pairs(self.gridWindow.selectedFrames) do
                    local fx = frame.x
                    local fy = frame.y
                    love.graphics.setColor(0, 1, 0, 0.3)
                    love.graphics.rectangle("fill", 
                        cx + fx * cellWidth, 
                        cy + fy * cellHeight, 
                        cellWidth, 
                        cellHeight)
                end
                
                -- Rengi resetle
                love.graphics.setColor(1, 1, 1, 1)
                
                imgui.EndChild()
            end
            
            -- Mouse durumunu güncelle
            self.lastMouseDown = love.mouse.isDown(1)
            
            -- Create Animation butonu
            if imgui.Button("Create Animation") then
                -- Frame'leri sırala
                local sortedFrames = {}
                for i = 1, self.gridWindow.colCount * self.gridWindow.rowCount do
                    if self.gridWindow.selectedFrames[i] then
                        table.insert(sortedFrames, self.gridWindow.selectedFrames[i])
                    end
                end
                
                if #sortedFrames > 0 then
                    -- Entity'nin animator component'ini kontrol et
                    if not self.gridWindow.entity.components.animator.animations then
                        self.gridWindow.entity.components.animator.animations = {}
                    end
                    
                    local animation = {
                        name = self.gridWindow.animationName,
                        source = self.gridWindow.asset,
                        frames = sortedFrames,
                        frameWidth = self.gridWindow.asset.data:getWidth() / self.gridWindow.colCount,
                        frameHeight = self.gridWindow.asset.data:getHeight() / self.gridWindow.rowCount
                    }
                    
                    -- Animasyonu entity'ye ekle
                    table.insert(self.gridWindow.entity.components.animator.animations, animation)
                    self.gridWindow.entity.components.animator.currentAnimation = animation
                    self.gridWindow.entity.components.animator.currentFrame = 1
                    self.gridWindow.entity.components.animator.timer = 0
                    
                    Console:log("Created animation: " .. self.gridWindow.animationName)
                    self.showGridSystem = false  -- Grid System'i kapat
                    
                    -- Grid window'u resetle
                    self.gridWindow.selectedFrames = {}
                    self.gridWindow.animationName = "New Animation"
                else
                    Console:log("Please select at least one frame!")
                end
            end
            
            if imgui.Button("Cancel") then
                self.showGridSystem = false  -- Grid System'i kapat
            end
            
            imgui.End()
        end
    end
end

return Animator
