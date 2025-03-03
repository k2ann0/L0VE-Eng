local State = require "state"
local Console = require "modules.console"

local AssetManager = {
    currentPath = "assets",
    filter = "",
    supportedTypes = {
        image = {"png", "jpg", "jpeg", "bmp"},
        sound = {"mp3", "wav", "ogg"},
        font = {"ttf", "otf"},
        script = {"lua"}
    }
}

function AssetManager:init()
    State.showWindows.assetManager = true
    State.windowSizes.assetManager = {width = 300, height = 300}
    
    -- Eğer assets klasörü yoksa oluştur
    if not love.filesystem.getInfo("assets") then
        love.filesystem.createDirectory("assets")
        Console:log("Created assets directory")
    end
    
    -- Başlangıçta assets klasöründeki dosyaları yükle
    self:scanDirectory("assets")
end

function AssetManager:getFileType(filename)
    local extension = filename:match("%.(%w+)$"):lower()
    
    for type, extensions in pairs(self.supportedTypes) do
        for _, ext in ipairs(extensions) do
            if extension == ext then
                return type
            end
        end
    end
    
    return "unknown"
end

function AssetManager:scanDirectory(path)
    local items = love.filesystem.getDirectoryItems(path)
    local directories = {}
    local files = {}
    
    -- Önce klasörleri ve dosyaları ayır
    for _, item in ipairs(items) do
        local fullPath = path .. "/" .. item
        local info = love.filesystem.getInfo(fullPath)
        
        if info.type == "directory" then
            table.insert(directories, {name = item, path = fullPath, type = "directory"})
        else
            local fileType = self:getFileType(item)
            if fileType ~= "unknown" then
                table.insert(files, {name = item, path = fullPath, type = fileType})
            end
        end
    end
    
    -- Klasörleri ve dosyaları birleştir (klasörler önce)
    local result = {}
    for _, dir in ipairs(directories) do
        table.insert(result, dir)
    end
    for _, file in ipairs(files) do
        table.insert(result, file)
    end
    
    return result
end

function AssetManager:loadAsset(assetType, path)
    -- Daha önce yüklenmiş mi kontrol et
    for _, asset in ipairs(State.assets) do
        if asset.path == path then
            Console:log("Asset already loaded: " .. path)
            return asset
        end
    end
    
    local asset = {
        type = assetType,
        path = path,
        name = path:match("([^/\\]+)$"),
        data = nil
    }
    
    if assetType == "image" then
        asset.data = love.graphics.newImage(path)
    elseif assetType == "sound" then
        asset.data = love.audio.newSource(path, "static")
    elseif assetType == "font" then
        asset.data = love.graphics.newFont(path, 12)
    elseif assetType == "script" then
        asset.data = love.filesystem.read(path)
    end
    
    table.insert(State.assets, asset)
    Console:log("Loaded asset: " .. asset.name)
    return asset
end

function AssetManager:draw()
    if not State.showWindows.assetManager then return end
    
    imgui.SetNextWindowSize(State.windowSizes.assetManager.width, State.windowSizes.assetManager.height, imgui.Cond_FirstUseEver)
    if imgui.Begin("Asset Manager", State.showWindows.assetManager) then
        -- Üst toolbar
        if imgui.Button("Import Asset") then
            -- Gerçek bir uygulamada dosya seçici kullanılır
            -- Bu örnek için simüle ediyoruz
            Console:log("Import Asset clicked - would open file picker")
        end
        
        imgui.SameLine()
        if imgui.Button("Create Folder") then
            local newFileName = ""
            newFileName = imgui.InputText("##NewFileName", newFileName, 128)
            local newFolderPath = self.currentPath .. newFileName
            love.filesystem.createDirectory(newFolderPath)
            local file = love.filesystem.newFile("deneme.txt")
            Console:log("Created new folder: " .. newFolderPath)
        end
        
        imgui.SameLine()
        if imgui.Button("Refresh") then
            Console:log("Refreshed asset directory")
        end
        
        -- Mevcut klasör yolu
        imgui.Text("Current Path: " .. self.currentPath)
        
        -- Üst klasöre gitme butonu
        if self.currentPath ~= "assets" then
            if imgui.Button("..") then
                self.currentPath = self.currentPath:match("(.+)/[^/]+$") or "assets"
                Console:log("Navigated to: " .. self.currentPath)
            end
        end
        
        imgui.Separator()
        
        -- Filtre
        imgui.Text("Filter:")
        imgui.SameLine()
        self.filter = imgui.InputText("##AssetFilter", self.filter, 128)
        
        -- Dosya ve klasör listesi
        if imgui.BeginChild("AssetList", 0, 0, true) then
            local items = self:scanDirectory(self.currentPath)
            
            for _, item in ipairs(items) do
                local isVisible = self.filter == "" or item.name:lower():find(self.filter:lower(), 1, true)
                
                if isVisible then
                    -- Dosya tipine göre renk
                    if item.type == "directory" then
                        imgui.PushStyleColor(imgui.Col_Text, 1, 1, 0, 1)
                    elseif item.type == "image" then
                        imgui.PushStyleColor(imgui.Col_Text, 0.5, 1, 0.5, 1)
                    elseif item.type == "sound" then
                        imgui.PushStyleColor(imgui.Col_Text, 0.5, 0.5, 1, 1)
                    elseif item.type == "font" then
                        imgui.PushStyleColor(imgui.Col_Text, 1, 0.5, 0.5, 1)
                    else
                        imgui.PushStyleColor(imgui.Col_Text, 1, 1, 1, 1)
                    end
                    
                    -- Klasör veya dosya tıklama
                    if imgui.Selectable(item.name, State.selectedAsset and State.selectedAsset.path == item.path) then
                        if item.type == "directory" then
                            self.currentPath = item.path
                            Console:log("Navigated to: " .. item.path)
                        else
                            -- Dosyayı yükle ve seç
                            local asset = self:loadAsset(item.type, item.path)
                            State.selectedAsset = asset
                            Console:log("Selected asset: " .. asset.name)
                        end
                    end
                    
                    -- Sağ tık menüsü
                    if imgui.BeginPopupContextItem() then
                        if imgui.MenuItem("Delete") then
                            if item.type == "directory" then
                                -- Klasör silme işlemi
                                love.filesystem.remove(item.path)
                                Console:log("Deleted directory: " .. item.name)
                            else
                                -- Dosya silme işlemi
                                love.filesystem.remove(item.path)
                                Console:log("Deleted file: " .. item.name)
                                
                                -- Yüklü asset'i de sil
                                for i, asset in ipairs(State.assets) do
                                    if asset.path == item.path then
                                        table.remove(State.assets, i)
                                        if State.selectedAsset == asset then
                                            State.selectedAsset = nil
                                        end
                                        break
                                    end
                                end
                            end
                        end
                        
                        if imgui.MenuItem("Rename") then
                            Console:log("Rename option clicked for: " .. item.name)
                        end
                        
                        if item.type == "image" and imgui.MenuItem("Create Animation") then
                            -- Önce asset'i yükle
                            local asset = self:loadAsset(item.type, item.path)
                            
                            -- Seçili entity'yi kontrol et
                            if State.selectedEntity and State.selectedEntity.components.animator then
                                engine.animator:GridSystem(asset, State.selectedEntity)
                            else
                                Console:log("Please select an entity with Animator component!")
                            end
                        end
                        
                        imgui.EndPopup()
                    end
                    
                    imgui.PopStyleColor()
                end
            end
            
            imgui.EndChild()
        end
    end
    imgui.End()
end

return AssetManager