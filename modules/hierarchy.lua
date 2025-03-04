local State = require "state"
local Console = require "modules.console"
local SceneManager = require "modules.scene_manager"

local Hierarchy = {
    showWindow = true,
    selectedEntity = nil,
    draggedEntity = nil
}

-- ImGui flag'lerini tanımla
local TreeNodeFlags = {
    Selected = 1,
    OpenOnArrow = 32,
    SpanAvailWidth = 2048,
    DefaultOpen = 64
}

function Hierarchy:init()
    State.showWindows.hierarchy = true
    State.windowSizes.hierarchy = {width = 250, height = 400}
end

function Hierarchy:draw()
    if not State.showWindows.hierarchy then return end
    
    imgui.SetNextWindowSize(State.windowSizes.hierarchy.width, State.windowSizes.hierarchy.height, imgui.Cond_FirstUseEver)
    if imgui.Begin("Hierarchy", State.showWindows.hierarchy) then
        -- Yeni entity oluşturma butonu
        if imgui.Button("Create Entity") then
            SceneManager:createEntity(0, 0)
        end
        
        imgui.Separator()
        
        -- Entityleri listele
        for i, entity in ipairs(SceneManager.entities) do
            local flags = TreeNodeFlags.OpenOnArrow
            
            -- Seçili entity'yi vurgula
            if State.selectedEntity == entity then
                flags = flags + TreeNodeFlags.Selected
            end
            
            -- Entity'nin alt öğeleri varsa TreeNode, yoksa Selectable olarak göster
            local isOpen = false
            if #(entity.children or {}) > 0 then
                isOpen = imgui.TreeNodeEx(entity.name or "Entity " .. i, flags)
            else
                local selected = imgui.Selectable(entity.name or "Entity " .. i, State.selectedEntity == entity)
                if selected then
                    State.selectedEntity = entity
                end
            end
            
            -- Sağ tık menüsü
            if imgui.BeginPopupContextItem() then
                if imgui.MenuItem("Delete") then
                    SceneManager:deleteEntity(entity)
                end
                if imgui.MenuItem("Rename") then
                    -- TODO: Yeniden adlandırma işlevi eklenecek
                    
                end
                if imgui.MenuItem("Duplicate") then
                    local newEntity = SceneManager:createEntity(entity.x + 32, entity.y + 32)
                    for k, v in pairs(entity) do
                        if k ~= "name" then
                            newEntity[k] = v
                        end
                    end
                    newEntity.name = entity.name .. " (Copy)"
                end
                imgui.EndPopup()
            end
            
            -- Drag & Drop işlemleri
            if imgui.BeginDragDropSource() then
                self.draggedEntity = entity
                -- Eğer SetDragDropPayload fonksiyonu yoksa, alternatif bir yöntem kullanın
                -- imgui.SetDragDropPayload("ENTITY", i)
                imgui.Text(entity.name or "Entity " .. i)
                
                imgui.EndDragDropSource()
            end
            
            if imgui.BeginDragDropTarget() then
                -- Eğer AcceptDragDropPayload fonksiyonu yoksa, alternatif bir yöntem kullanın
                -- local payload = imgui.AcceptDragDropPayload("ENTITY")
                local newEntity = SceneManager:createEntity(entity.x + 32, entity.y + 32)
                    for k, v in pairs(entity) do
                        if k ~= "name" then
                            newEntity[k] = v
                        end
                    end
                    newEntity.name = entity.name .. " (Copy)"
                local payload = true -- Basit bir alternatif
                if payload then
                    -- Sürüklenen entity'yi hedef entity'nin child'ı yap
                    if self.draggedEntity and self.draggedEntity ~= entity then
                        entity.children = entity.children or {}
                        table.insert(entity.children, self.draggedEntity)
                        -- Ana listeden kaldır
                        for j, e in ipairs(SceneManager.entities) do
                            if e == self.draggedEntity then
                                table.remove(SceneManager.entities, j)
                                break
                            end
                        end
                    end
                end
                imgui.EndDragDropTarget()
            end
            
            if isOpen then
                if entity.children then
                    for _, child in ipairs(entity.children) do
                        imgui.Indent()
                        -- Recursive olarak alt öğeleri göster
                        -- TODO: Alt öğeleri gösterme fonksiyonu eklenecek
                        imgui.Unindent()
                    end
                end
                imgui.TreePop()
            end
        end
    end
    imgui.End()
end
return Hierarchy 