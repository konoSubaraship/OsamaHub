-- Clean up
if library and typeof(library) == 'table' and library.unload_menu then 
    library:unload_menu()
end 

-- Variables 
local uis = game:GetService("UserInputService") 
local players = game:GetService("Players") 
local ws = game:GetService("Workspace")
local http_service = game:GetService("HttpService")
local gui_service = game:GetService("GuiService")
local run = game:GetService("RunService")
local coregui = game:GetService("CoreGui")
local tween_service = game:GetService("TweenService")
local stats_service = game:GetService("Stats")

local vec2 = Vector2.new
local dim2 = UDim2.new
local dim = UDim.new 
local dim_offset = UDim2.fromOffset

local color = Color3.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new
local numseq = NumberSequence.new
local numkey = NumberSequenceKeypoint.new

local camera = ws.CurrentCamera
local lp = players.LocalPlayer 
local mouse = lp:GetMouse() 
local gui_offset = gui_service:GetGuiInset().Y

local floor = math.floor 
local min = math.min 
local max = math.max
local clamp = math.clamp 

local insert = table.insert 
local find = table.find 
local remove = table.remove
local concat = table.concat
-- 

-- Library init
getgenv().library = {
    directory = "avenir",
    project_name = "default",
    folders = {"/fonts", "/configs"},
    flags = {},
    config_flags = {},
    connections = {},
    dependencies = {},
    notifications = {notifs = {}, enabled = false},
    auto_load_config_name = nil,
    notifications_on = false,
    current_open = nil,
    auto_show = true,
    tooltip = nil,
    keybinds = {},
    keybind_list_visible = true,
    watermark_visible = true,
    watermark_elements = {fps = true, ping = true, time = true},
    dpi_scale = 1,
    is_mobile = uis.TouchEnabled and not uis.KeyboardEnabled,
    icons = loadstring(game:HttpGet('https://github.com/Footagesus/Icons/raw/refs/heads/main/sfsymbols/dist/Icons.lua'))(),
}

local themes = {
    preset = {
        accent = rgb(155, 150, 219),
    }, 
    utility = {
        accent = {
            BackgroundColor3 = {},  
            TextColor3 = {}, 
            ImageColor3 = {}, 
        },
    }
}

library.__index = library

local flags = library.flags 
local config_flags = library.config_flags
local notifications = library.notifications 

local fonts = {}

pcall(function()
    local function Register_Font(Name, Weight, Style, Asset)
        if not isfile(Asset.Id) then
            writefile(Asset.Id, Asset.Font)
        end
        if isfile(Name .. ".font") then
            delfile(Name .. ".font")
        end
        local Data = {
            name = Name,
            faces = {{name = "Normal", weight = Weight, style = Style, assetId = getcustomasset(Asset.Id)}}
        }
        writefile(Name .. ".font", http_service:JSONEncode(Data))
        return getcustomasset(Name .. ".font")
    end
    
    local Medium = Register_Font("Medium", 200, "Normal", {
        Id = "Medium.ttf",
        Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-Medium.ttf"),
    })
    local SemiBold = Register_Font("SemiBold", 200, "Normal", {
        Id = "SemiBold.ttf",
        Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Inter_28pt-SemiBold.ttf"),
    })
    fonts = {
        small = Font.new(Medium, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        font = Font.new(SemiBold, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
    }
end)

local customIcons = loadstring(game:HttpGet('https://github.com/konoSubaraship/OsamaHub/raw/refs/heads/main/assets/icons.luau'))() 

for i,v in next, customIcons do 
    if not isfile('osamahub/icons/' .. i .. '.png') then
        writefile('osamahub/icons/' .. i .. '.png', game:HttpGet(v))
    end  

    library.icons[i] = getcustomasset('osamahub/icons/' .. i .. '.png')
end 

if not fonts.small then
    fonts.small = Font.fromEnum(Enum.Font.Gotham)
    fonts.font = Font.fromEnum(Enum.Font.GothamBold)
end
--

-- DPI Scaling
function library:scale(value)
    return value * library.dpi_scale
end

function library:scale_udim2(x_scale, x_offset, y_scale, y_offset)
    return dim2(x_scale, self:scale(x_offset), y_scale, self:scale(y_offset))
end

function library:scale_offset(x, y)
    return dim_offset(self:scale(x), self:scale(y))
end

function library:set_dpi(scale)
    library.dpi_scale = scale
    library:save_library_settings()
end
--

-- Library functions 
function library:tween(obj, properties, easing_style, time) 
    tween_service:Create(obj, TweenInfo.new(time or 0.25, easing_style or Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), properties):Play()
end

function library:init_folders()
    pcall(function()
        if not isfolder(library.directory) then makefolder(library.directory) end
        for _, path in next, library.folders do 
            if not isfolder(library.directory .. path) then
                makefolder(library.directory .. path)
            end
        end
        local project_path = library.directory .. "/configs/" .. library.project_name
        if not isfolder(project_path) then makefolder(project_path) end
    end)
end

function library:get_config_path()
    return library.directory .. "/configs/" .. library.project_name
end

function library:next_flag()
    local index = 0
    for _ in pairs(library.flags) do index = index + 1 end
    return string.format("flag_%s", index + 1)
end 

function library:draggify_simple(frame)
    local dragging = false 
    local start_pos = frame.Position
    local start_input
    
    local function update(input)
        local delta = input.Position - start_input.Position
        local new_pos = dim_offset(
            clamp(start_pos.X.Offset + delta.X, 0, camera.ViewportSize.X - frame.AbsoluteSize.X),
            clamp(start_pos.Y.Offset + delta.Y, 0, camera.ViewportSize.Y - frame.AbsoluteSize.Y)
        )
        frame.Position = new_pos
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start_input = input
            start_pos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

function library:resizify_simple(frame, min_size, max_size)
    local resizing = false 
    local start_size, start_input
    local og_size = min_size or frame.Size
    local max_s = max_size or dim_offset(500, 500)

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local frame_pos = frame.AbsolutePosition
            local frame_size = frame.AbsoluteSize
            
            if pos.X >= frame_pos.X + frame_size.X - 15 and pos.Y >= frame_pos.Y + frame_size.Y - 15 then
                resizing = true
                start_input = input
                start_size = frame.Size
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizing = false
                    end
                end)
            end
        end
    end)

    frame.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - start_input.Position
            local new_size = dim_offset(
                clamp(start_size.X.Offset + delta.X, og_size.X.Offset, max_s.X.Offset),
                clamp(start_size.Y.Offset + delta.Y, og_size.Y.Offset, max_s.Y.Offset)
            )
            frame.Size = new_size
        end
    end)
end

function library:resizify(frame, min_size) 
    local resize_button = Instance.new("TextButton")
    resize_button.Position = dim2(1, -12, 1, -12)
    resize_button.Size = dim2(0, 12, 0, 12)
    resize_button.BorderSizePixel = 0
    resize_button.BackgroundTransparency = 1
    resize_button.Text = "◢"
    resize_button.TextColor3 = rgb(50, 50, 55)
    resize_button.TextSize = 10
    resize_button.Font = Enum.Font.Gotham
    resize_button.Parent = frame
    resize_button.ZIndex = 10

    local resizing = false 
    local start_size, start
    local og_size = min_size or frame.Size

    resize_button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            start = input.Position
            start_size = frame.Size
        end
    end)

    resize_button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    library:connection(uis.InputChanged, function(input) 
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport_x, viewport_y = camera.ViewportSize.X, camera.ViewportSize.Y
            local current_size = dim2(
                start_size.X.Scale,
                clamp(start_size.X.Offset + (input.Position.X - start.X), og_size.X.Offset, viewport_x - frame.Position.X.Offset),
                start_size.Y.Scale,
                clamp(start_size.Y.Offset + (input.Position.Y - start.Y), og_size.Y.Offset, viewport_y - frame.Position.Y.Offset)
            )
            library:tween(frame, {Size = current_size}, Enum.EasingStyle.Linear, 0.05)
        end
    end)
end 

function library:draggify(frame, drag_object)
    local dragging = false 
    local start_size = frame.Position
    local start 
    local drag_target = drag_object or frame

    drag_target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            start_size = frame.Position
        end
    end)

    drag_target.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    library:connection(uis.InputChanged, function(input) 
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local viewport_x, viewport_y = camera.ViewportSize.X, camera.ViewportSize.Y
            local current_position = dim2(
                0,
                clamp(start_size.X.Offset + (input.Position.X - start.X), 0, viewport_x - frame.Size.X.Offset),
                0,
                clamp(start_size.Y.Offset + (input.Position.Y - start.Y), 0, viewport_y - frame.Size.Y.Offset)
            )
            library:tween(frame, {Position = current_position}, Enum.EasingStyle.Linear, 0.05)
            library:close_element()
        end
    end)
end 

function library:convert_enum(enum)
    local enum_parts = {}
    for part in string.gmatch(enum, "[%w_]+") do
        insert(enum_parts, part)
    end
    local enum_table = Enum
    for i = 2, #enum_parts do
        enum_table = enum_table[enum_parts[i]]
    end
    return enum_table
end

function library:get_settings_path()
    return library.directory .. "/configs/" .. library.project_name .. "/settings.json"
end

function library:save_library_settings()
    local settings_data = {
        auto_load_config = library.auto_load_config_name,
        notifications_enabled = library.notifications_on,
        keybind_list_visible = library.keybind_list_visible,
        watermark_visible = library.watermark_visible,
        watermark_elements = library.watermark_elements,
        dpi_scale = library.dpi_scale,
    }
    pcall(function()
        writefile(library:get_settings_path(), http_service:JSONEncode(settings_data))
    end)
end

function library:load_library_settings()
    local path = library:get_settings_path()
    pcall(function()
        if isfile(path) then
            local data = http_service:JSONDecode(readfile(path))
            library.auto_load_config_name = data.auto_load_config
            library.notifications_on = data.notifications_enabled or false
            notifications.enabled = library.notifications_on
            library.keybind_list_visible = data.keybind_list_visible ~= false
            library.watermark_visible = data.watermark_visible ~= false
            library.watermark_elements = data.watermark_elements or {fps = true, ping = true, time = true}
            library.dpi_scale = data.dpi_scale or 1
        end
    end)
end

function library:set_auto_load(config_name)
    library.auto_load_config_name = config_name
    library:save_library_settings()
end

function library:clear_auto_load()
    library.auto_load_config_name = nil
    library:save_library_settings()
end

function library:toggle_notifications(enabled)
    library.notifications_on = enabled
    notifications.enabled = enabled
    library:save_library_settings()
end

function library:do_auto_load()
    library:load_library_settings()
    if library.auto_load_config_name then
        local config_path = library:get_config_path() .. "/" .. library.auto_load_config_name .. ".cfg"
        pcall(function()
            if isfile(config_path) then
                task.spawn(function()
                    task.wait(0.5)
                    library:load_config(readfile(config_path))
                    if notifications.enabled then
                        notifications:create_notification({name = "Auto Load", info = "Loaded: " .. library.auto_load_config_name})
                    end
                end)
            end
        end)
    end
end

local config_holder
function library:update_config_list() 
    if not config_holder then return end
    local list = {}
    pcall(function()
        local config_path = library:get_config_path()
        for _, file in ipairs(listfiles(config_path)) do
            local name = file:match("([^/\\]+)%.cfg$")
            if name then list[#list + 1] = name end
        end
    end)
    if #list == 0 then list = {"No Configs"} end
    config_holder.refresh_options(list)
end 

function library:get_config()
    local Config = {}
    for flag, value in pairs(flags) do
        if flag == "config_name_list" or flag == "config_name_text" then continue end
        if type(value) == "table" and value["Transparency"] ~= nil and value["Color"] then
            Config[flag] = {Transparency = value["Transparency"], Color = value["Color"]:ToHex()}
        elseif type(value) == "table" and value["mode"] and value["key"] then
            local key_str = "NONE"
            if value["key"] and tostring(value["key"]) ~= "NONE" and tostring(value["key"]) ~= "Enums" then
                key_str = tostring(value["key"])
            end
            Config[flag] = {mode = value["mode"], key = key_str, active = value["active"]}
        else
            Config[flag] = value
        end
    end 
    return http_service:JSONEncode(Config)
end

function library:load_config(config_json) 
    local success, config = pcall(function()
        return http_service:JSONDecode(config_json)
    end)
    if not success then return end
    for flag, value in pairs(config) do 
        local setter = config_flags[flag]
        if flag == "config_name_list" or flag == "config_name_text" then continue end
        if setter then 
            pcall(function()
                if type(value) == "table" and value["Transparency"] ~= nil and value["Color"] then
                    setter(hex(value["Color"]), value["Transparency"])
                elseif type(value) == "table" and value["mode"] and value["key"] then
                    setter(value)
                else
                    setter(value)
                end
            end)
        end 
    end 
end 

function library:round(number, float) 
    local multiplier = 1 / (float or 1)
    return floor(number * multiplier + 0.5) / multiplier
end 

function library:apply_theme(instance, theme, property) 
    insert(themes.utility[theme][property], instance)
end

function library:update_theme(theme, new_color)
    for property, objects in pairs(themes.utility[theme]) do 
        for _, object in pairs(objects) do 
            pcall(function()
                if object[property] ~= nil then object[property] = new_color end
            end)
        end 
    end 
    themes.preset[theme] = new_color
    if library.keybind_list_items and library.keybind_list_items["accent_line"] then
        library.keybind_list_items["accent_line"].BackgroundColor3 = new_color
    end
    if library.watermark_items and library.watermark_items["accent_line"] then
        library.watermark_items["accent_line"].BackgroundColor3 = new_color
    end
end 

function library:connection(signal, callback)
    local connection = signal:Connect(callback)
    insert(library.connections, connection)
    return connection 
end

function library:close_element(new_path) 
    local open_element = library.current_open
    if open_element and new_path ~= open_element then
        pcall(function()
            if open_element.close then
                open_element.close()
            end
            open_element.open = false
        end)
    end 
    if new_path ~= open_element then 
        library.current_open = new_path or nil
    end
end 

function library:create(instance, options)
    local ins = Instance.new(instance) 
    for prop, value in pairs(options) do 
        pcall(function() ins[prop] = value end)
    end
    return ins 
end

function library:unload_menu() 
    pcall(function()
        if library["items"] then library["items"]:Destroy() end
        if library["other"] then library["other"]:Destroy() end
        for _, connection in pairs(library.connections) do 
            connection:Disconnect() 
        end
        library.connections = {}
        library.flags = {}
        library.config_flags = {}
        library.keybinds = {}
    end)
end 

function library:get_players()
    local player_list = {}
    for _, player in pairs(players:GetPlayers()) do
        if player ~= lp then insert(player_list, player.Name) end
    end
    if #player_list == 0 then player_list = {"No Players"} end
    return player_list
end

function library:add_dependency(element, flag, condition)
    if not library.dependencies[flag] then
        library.dependencies[flag] = {}
    end
    insert(library.dependencies[flag], {element = element, condition = condition})
    local current_value = flags[flag]
    if current_value ~= nil then
        local should_show = condition(current_value)
        if element.items and element.items["toggle"] then
            element.items["toggle"].Visible = should_show
        elseif element.items and element.items["slider_object"] then
            element.items["slider_object"].Visible = should_show
        elseif element.items and element.items["dropdown_object"] then
            element.items["dropdown_object"].Visible = should_show
        end
    end
end

function library:update_dependencies(flag, value)
    local deps = library.dependencies[flag]
    if deps then
        for _, dep in pairs(deps) do
            local should_show = dep.condition(value)
            local element = dep.element
            if element.items then
                for _, item in pairs(element.items) do
                    if typeof(item) == "Instance" then
                        pcall(function() item.Visible = should_show end)
                    end
                end
            end
        end
    end
end

function library:create_tooltip()
    library.tooltip = library:create("Frame", {
        Parent = library["items"],
        Size = dim2(0, 150, 0, 30),
        BackgroundColor3 = rgb(20, 20, 24),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 200,
    })
    
    library:create("UICorner", {
        Parent = library.tooltip,
        CornerRadius = dim(0, 4)
    })
    
    library:create("UIStroke", {
        Parent = library.tooltip,
        Color = rgb(45, 45, 50),
        Thickness = 1,
    })
    
    library.tooltip_text = library:create("TextLabel", {
        Parent = library.tooltip,
        Size = dim2(1, -10, 1, 0),
        Position = dim2(0, 5, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = rgb(180, 180, 180),
        TextSize = 11,
        FontFace = fonts.small,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 201,
    })
end

function library:show_tooltip(text, element)
    if not library.tooltip then return end
    library.tooltip_text.Text = text
    
    local text_size = game:GetService("TextService"):GetTextSize(text, 11, Enum.Font.Gotham, Vector2.new(200, 100))
    library.tooltip.Size = dim2(0, text_size.X + 20, 0, text_size.Y + 10)
    
    -- Position tooltip near the mouse cursor
    local mousePos = uis:GetMouseLocation()
    local tooltip_width = text_size.X + 20
    local tooltip_height = text_size.Y + 10
    
    -- Adjust position to stay on screen
    local pos_x = mousePos.X + 10
    local pos_y = mousePos.Y + 10
    
    if pos_x + tooltip_width > camera.ViewportSize.X then
        pos_x = mousePos.X - tooltip_width - 10
    end
    
    if pos_y + tooltip_height > camera.ViewportSize.Y then
        pos_y = mousePos.Y - tooltip_height - 10
    end
    
    library.tooltip.Position = dim_offset(pos_x, pos_y)
    library.tooltip.Visible = true
end

function library:hide_tooltip()
    if library.tooltip then
        library.tooltip.Visible = false
    end
end
--

-- Keybind List
function library:create_keybind_list()
    library.keybind_list_items = {}
    local items = library.keybind_list_items
    
    items["main"] = library:create("Frame", {
        Parent = library["other"],
        Position = dim_offset(10, 150),
        Size = dim_offset(180, 30),
        BackgroundColor3 = rgb(20, 20, 24),
        BorderSizePixel = 0,
        Visible = library.keybind_list_visible,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    library:create("UICorner", {Parent = items["main"], CornerRadius = dim(0, 4)})
    
    items["accent_line"] = library:create("Frame", {
        Parent = items["main"],
        Size = dim2(1, 0, 0, 2),
        BackgroundColor3 = themes.preset.accent,
        BorderSizePixel = 0,
    })
    library:apply_theme(items["accent_line"], "accent", "BackgroundColor3")
    library:create("UICorner", {Parent = items["accent_line"], CornerRadius = dim(0, 2)})
    
    items["title"] = library:create("TextLabel", {
        Parent = items["main"],
        Position = dim2(0, 8, 0, 6),
        Size = dim2(1, -16, 0, 16),
        BackgroundTransparency = 1,
        Text = "Keybinds",
        TextColor3 = rgb(200, 200, 205),
        TextSize = 12,
        FontFace = fonts.font,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    items["container"] = library:create("Frame", {
        Parent = items["main"],
        Position = dim2(0, 0, 0, 24),
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    library:create("UIListLayout", {Parent = items["container"], Padding = dim(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
    library:create("UIPadding", {Parent = items["container"], PaddingLeft = dim(0, 8), PaddingRight = dim(0, 8), PaddingBottom = dim(0, 6)})
    
    items["keybind_entries"] = {}
    
    -- Only draggable, no resize
    library:draggify_simple(items["main"])
end

function library:register_keybind(name, flag, key, mode)
    local keys_map = {
        [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
        [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
        [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
        [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.LeftAlt] = "LA",
        [Enum.KeyCode.RightAlt] = "RA", [Enum.KeyCode.CapsLock] = "CAPS",
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
        [Enum.KeyCode.Escape] = "ESC", [Enum.KeyCode.Space] = "SPC",
    }
    
    local key_text = "None"
    if key and tostring(key) ~= "Enums" and key ~= "NONE" then
        key_text = keys_map[key] or tostring(key):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
    end
    
    library.keybinds[flag] = {
        name = name,
        key = key,
        key_text = key_text,
        mode = mode,
        active = false,
    }
end

function library:update_keybind_mode(flag, mode)
    if library.keybinds[flag] then
        library.keybinds[flag].mode = mode
        library:update_keybind_list()
    end
end

function library:update_keybind_list()
    if not library.keybind_list_items or not library.keybind_list_items["container"] then return end
    
    local items = library.keybind_list_items
    
    for _, entry in pairs(items["keybind_entries"]) do
        entry:Destroy()
    end
    items["keybind_entries"] = {}
    
    local has_active = false
    for flag, data in pairs(library.keybinds) do
        if data.active and data.key and data.key ~= "NONE" then
            has_active = true
            local entry = library:create("TextLabel", {
                Parent = items["container"],
                Size = dim2(1, 0, 0, 14),
                BackgroundTransparency = 1,
                Text = string.format("[%s] %s (%s)", data.key_text, data.name, data.mode),
                TextColor3 = rgb(150, 150, 155),
                TextSize = 10,
                FontFace = fonts.small,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            insert(items["keybind_entries"], entry)
        end
    end
    
    if not has_active then
        local empty = library:create("TextLabel", {
            Parent = items["container"],
            Size = dim2(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = "No active keybinds",
            TextColor3 = rgb(80, 80, 85),
            TextSize = 10,
            FontFace = fonts.small,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        insert(items["keybind_entries"], empty)
    end
end

function library:set_keybind_active(flag, active)
    if library.keybinds[flag] then
        library.keybinds[flag].active = active
        library:update_keybind_list()
    end
end

function library:toggle_keybind_list(visible)
    library.keybind_list_visible = visible
    if library.keybind_list_items and library.keybind_list_items["main"] then
        library.keybind_list_items["main"].Visible = visible
    end
    library:save_library_settings()
end
--

-- Watermark
function library:create_watermark(window_name)
    library.watermark_items = {}
    local items = library.watermark_items
    
    items["main"] = library:create("Frame", {
        Parent = library["other"],
        Position = dim_offset(10, 10),
        Size = dim_offset(200, 24),
        BackgroundColor3 = rgb(20, 20, 24),
        BorderSizePixel = 0,
        Visible = library.watermark_visible,
    })
    library:create("UICorner", {Parent = items["main"], CornerRadius = dim(0, 4)})
    
    items["accent_line"] = library:create("Frame", {
        Parent = items["main"],
        Size = dim2(1, 0, 0, 2),
        BackgroundColor3 = themes.preset.accent,
        BorderSizePixel = 0,
    })
    library:apply_theme(items["accent_line"], "accent", "BackgroundColor3")
    library:create("UICorner", {Parent = items["accent_line"], CornerRadius = dim(0, 2)})
    
    items["text"] = library:create("TextLabel", {
        Parent = items["main"],
        Position = dim2(0, 8, 0, 2),
        Size = dim2(1, -16, 1, -2),
        BackgroundTransparency = 1,
        Text = window_name or "avenirtech",
        TextColor3 = rgb(200, 200, 205),
        TextSize = 11,
        FontFace = fonts.font,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.X,
    })
    
    library:draggify_simple(items["main"])
    library:resizify_simple(items["main"], dim_offset(100, 24), dim_offset(400, 24))
    
    library:start_watermark_updates(window_name)
end

function library:start_watermark_updates(window_name)
    local last_fps_update = 0
    local fps_value = 0
    local frame_count = 0
    
    library:connection(run.RenderStepped, function(dt)
        if not library.watermark_items or not library.watermark_items["text"] then return end
        if not library.watermark_visible then return end
        
        frame_count = frame_count + 1
        last_fps_update = last_fps_update + dt
        
        if last_fps_update >= 0.5 then
            fps_value = floor(frame_count / last_fps_update)
            frame_count = 0
            last_fps_update = 0
        end
        
        local parts = {window_name or "avenirtech"}
        
        if library.watermark_elements.fps then
            insert(parts, fps_value .. " fps")
        end
        
        if library.watermark_elements.ping then
            local ping = floor(stats_service.Network.ServerStatsItem["Data Ping"]:GetValue())
            insert(parts, ping .. " ms")
        end
        
        if library.watermark_elements.time then
            insert(parts, os.date("%H:%M:%S"))
        end
        
        library.watermark_items["text"].Text = concat(parts, " | ")
        
        local text_size = game:GetService("TextService"):GetTextSize(
            library.watermark_items["text"].Text, 
            11, 
            Enum.Font.GothamBold, 
            Vector2.new(1000, 24)
        )
        library.watermark_items["main"].Size = dim_offset(text_size.X + 20, 24)
    end)
end

function library:toggle_watermark(visible)
    library.watermark_visible = visible
    if library.watermark_items and library.watermark_items["main"] then
        library.watermark_items["main"].Visible = visible
    end
    library:save_library_settings()
end

function library:set_watermark_element(element, visible)
    library.watermark_elements[element] = visible
    library:save_library_settings()
end
--

-- Mobile Support
function library:create_mobile_toggle()
    if not library.is_mobile then return end
    
    local toggle_btn = library:create("TextButton", {
        Parent = library["items"],
        Position = dim_offset(10, camera.ViewportSize.Y - 60),
        Size = dim_offset(50, 50),
        BackgroundColor3 = themes.preset.accent,
        Text = "☰",
        TextColor3 = rgb(255, 255, 255),
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    })
    library:create("UICorner", {Parent = toggle_btn, CornerRadius = dim(0, 25)})
    library:apply_theme(toggle_btn, "accent", "BackgroundColor3")
    
    toggle_btn.MouseButton1Click:Connect(function()
        library["items"].Enabled = not library["items"].Enabled
    end)
    
    library:connection(library["items"]:GetPropertyChangedSignal("Enabled"), function()
        toggle_btn.Visible = true
    end)
end
--

-- Window
function library:window(properties)
    local cfg = { 
        suffix = properties.suffix or "tech",
        name = properties.name or "avenir",
        game_name = properties.gameInfo or "Avenir UI",
        size = properties.size or dim2(0, 550, 0, 720),
        selected_tab = nil,
        items = {},
    }
    
    library.project_name = properties.project or properties.name or "default"
    library.auto_show = properties.auto_show ~= false
    library:init_folders()
    library:load_library_settings()
    
    library["items"] = library:create("ScreenGui", {
        Parent = coregui,
        Name = "AvenirUI",
        Enabled = library.auto_show,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
    })
    
    library["other"] = library:create("ScreenGui", {
        Parent = coregui,
        Name = "AvenirOther",
        Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
    })

    local items = cfg.items
    local scale = library.dpi_scale
    
    items["main"] = library:create("Frame", {
        Parent = library["items"],
        Size = dim_offset(cfg.size.X.Offset * scale, cfg.size.Y.Offset * scale),
        Position = dim2(0.5, -(cfg.size.X.Offset * scale) / 2, 0.5, -(cfg.size.Y.Offset * scale) / 2),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(18, 18, 22)
    })
    items["main"].Position = dim2(0, items["main"].AbsolutePosition.X, 0, items["main"].AbsolutePosition.Y)
    
    library:create("UICorner", {Parent = items["main"], CornerRadius = dim(0, 6)})
    library:create("UIStroke", {Color = rgb(35, 35, 42), Parent = items["main"], Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    
    items["top_bar"] = library:create("Frame", {
        Parent = items["main"],
        Size = dim2(1, 0, 0, library:scale(32)),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(22, 22, 26)
    })
    library:create("UICorner", {Parent = items["top_bar"], CornerRadius = dim(0, 6)})
    library:create("Frame", {Parent = items["top_bar"], AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 6), BorderSizePixel = 0, BackgroundColor3 = rgb(22, 22, 26)})
    
    items["title"] = library:create("TextLabel", {
        FontFace = fonts.font,
        Parent = items["top_bar"],
        Text = string.format('<u>%s</u><font color="rgb(255,255,255)">%s</font>', cfg.name, cfg.suffix),
        Position = dim2(0, library:scale(12), 0.5, 0),
        AnchorPoint = vec2(0, 0.5),
        BackgroundTransparency = 1,
        TextColor3 = themes.preset.accent,
        RichText = true,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = library:scale(16),
    })
    library:apply_theme(items["title"], "accent", "TextColor3")
    
    items["tab_holder"] = library:create("Frame", {
        Parent = items["top_bar"],
        Position = dim2(0, library:scale(90), 0, 0),
        Size = dim2(1, library:scale(-120), 1, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
    })
    library:create("UIListLayout", {Parent = items["tab_holder"], Padding = dim(0, 0), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center})
    library:create("UIPadding", {Parent = items["tab_holder"], PaddingLeft = dim(0, 5)})
    
    items["sub_tab_bar"] = library:create("Frame", {
        Parent = items["main"],
        Position = dim2(0, 0, 0, library:scale(32)),
        Size = dim2(1, 0, 0, library:scale(26)),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(20, 20, 24)
    })
    library:create("Frame", {Parent = items["sub_tab_bar"], AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 1), BorderSizePixel = 0, BackgroundColor3 = rgb(35, 35, 42)})
    
    items["content_area"] = library:create("Frame", {
        Parent = items["main"],
        Position = dim2(0, 0, 0, library:scale(58)),
        Size = dim2(1, 0, 1, library:scale(-80)),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
    })
    
    items["global_fade"] = library:create("Frame", {
        Parent = items["main"],
        BackgroundTransparency = 1,
        Position = dim2(0, 0, 0, library:scale(58)),
        Size = dim2(1, 0, 1, library:scale(-80)),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(18, 18, 22),
        ZIndex = 2,
    })
    
    items["info"] = library:create("Frame", {
        AnchorPoint = vec2(0, 1),
        Parent = items["main"],
        Position = dim2(0, 0, 1, 0),
        Size = dim2(1, 0, 0, library:scale(22)),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(22, 22, 26)
    })
    library:create("UICorner", {Parent = items["info"], CornerRadius = dim(0, 6)})
    library:create("Frame", {Parent = items["info"], Size = dim2(1, 0, 0, 6), BorderSizePixel = 0, BackgroundColor3 = rgb(22, 22, 26)})
    library:create("TextLabel", {
        FontFace = fonts.font,
        Parent = items["info"],
        TextColor3 = rgb(72, 72, 73),
        Text = cfg.game_name .. " | " .. library.project_name,
        AnchorPoint = vec2(0, 0.5),
        Position = dim2(0, library:scale(10), 0.5, -1),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = library:scale(11),
    })

    library:draggify(items["main"], items["top_bar"])
    library:resizify(items["main"], dim2(0, 400, 0, 400))
    library:create_tooltip()
    library:create_keybind_list()
    library:create_watermark(cfg.name .. cfg.suffix)
    library:create_mobile_toggle()

    function cfg.toggle_menu(bool) 
        library["items"].Enabled = bool
    end 
        
    return setmetatable(cfg, library)
end 
--

-- Tab
function library:tab(properties)
    local cfg = {
        name = properties.name or "Tab", 
        icon = properties.icon and self.icons[properties.icon] or properties.icon or "http://www.roblox.com/asset/?id=6034767608",
        tabs = properties.tabs or {"Main"},
        pages = {},
        current_multi = nil, 
        items = {},
    } 

    local items = cfg.items
    
    items["button"] = library:create("TextButton", {
        FontFace = fonts.font,
        Text = "",
        Parent = self.items["tab_holder"],
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = dim2(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = library:scale(12),
    })
    library:create("UIPadding", {Parent = items["button"], PaddingLeft = dim(0, 8), PaddingRight = dim(0, 8)})
    
    items["icon"] = library:create("ImageLabel", {
        ImageColor3 = rgb(72, 72, 73),
        Parent = items["button"],
        AnchorPoint = vec2(0, 0.5),
        Image = cfg.icon,
        BackgroundTransparency = 1,
        Position = dim2(0, 0, 0.5, 0),
        Size = dim_offset(library:scale(16), library:scale(16)),
    })
    library:apply_theme(items["icon"], "accent", "ImageColor3")
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = rgb(120, 120, 125),
        Text = cfg.name,
        Parent = items["button"],
        Position = dim2(0, library:scale(18), 0, 0),
        Size = dim2(0, 0, 1, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = library:scale(12),
    })
    
    items["accent_line"] = library:create("Frame", {
        AnchorPoint = vec2(0.5, 1),
        Parent = items["button"],
        Position = dim2(0.5, 0, 1, 0),
        Size = dim2(0.8, 0, 0, 2),
        BackgroundColor3 = themes.preset.accent,
        BackgroundTransparency = 1,
    })
    library:apply_theme(items["accent_line"], "accent", "BackgroundColor3")
    library:create("UICorner", {Parent = items["accent_line"], CornerRadius = dim(0, 2)})
    
    items["tab_content"] = library:create("Frame", {
        Parent = library["other"],
        Visible = false,
        BackgroundTransparency = 1,
        Size = dim2(1, -12, 1, -6),
        Position = dim2(0, 6, 0, 3),
    })
    
    items["sub_tab_holder"] = library:create("Frame", {
        Parent = library["other"],
        BackgroundTransparency = 1,
        Visible = false,
        Size = dim2(1, 0, 1, 0),
    })
    library:create("UIListLayout", {Parent = items["sub_tab_holder"], Padding = dim(0, 0), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center})
    library:create("UIPadding", {Parent = items["sub_tab_holder"], PaddingTop = dim(0, 3), PaddingLeft = dim(0, 8)})

    for _, section in ipairs(cfg.tabs) do
        local data = {items = {}} 
        local sub_items = data.items
        
        sub_items["button"] = library:create("TextButton", {
            FontFace = fonts.font,
            TextColor3 = rgb(90, 90, 95),
            AutoButtonColor = false,
            Text = "",
            Parent = items["sub_tab_holder"],
            Size = dim2(0, 0, 0, library:scale(18)),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            TextSize = library:scale(11),
        })
        library:create("UIPadding", {Parent = sub_items["button"], PaddingRight = dim(0, 12), PaddingLeft = dim(0, 4)})
        
        sub_items["name"] = library:create("TextLabel", {
            FontFace = fonts.small,
            TextColor3 = rgb(90, 90, 95),
            Text = section,
            Parent = sub_items["button"],
            Size = dim2(0, 0, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.XY,
            TextSize = library:scale(11),
        })
        
        sub_items["page"] = library:create("Frame", {
            Parent = library["other"],
            BackgroundTransparency = 1,
            Size = dim2(1, 0, 1, 0),
            Visible = false,
        })
        library:create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Parent = sub_items["page"], Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalFlex = Enum.UIFlexAlignment.Fill})
        library:create("UIPadding", {PaddingTop = dim(0, 6), PaddingBottom = dim(0, 6), Parent = sub_items["page"]})

        data.text = sub_items["name"]
        data.button = sub_items["button"]
        data.page = sub_items["page"]
        
        local sub = setmetatable(data, library):sub_tab({})
        data.parent = sub.items["tab_parent"]

        function data.open_page()
            local page = cfg.current_multi
            if page and page.text ~= data.text then 
                self.items["global_fade"].BackgroundTransparency = 0
                library:tween(self.items["global_fade"], {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.3)
            end
            if page then
                library:tween(page.text, {TextColor3 = rgb(90, 90, 95)})
                page.page.Visible = false
                page.page.Parent = library["other"] 
            end 
            library:tween(data.text, {TextColor3 = themes.preset.accent})
            data.page.Visible = true
            data.page.Parent = items["tab_content"]
            cfg.current_multi = data
            library:close_element()
        end

        sub_items["button"].MouseButton1Down:Connect(function()
            data.open_page() 
        end)

        cfg.pages[#cfg.pages + 1] = setmetatable(data, library)
    end 

    cfg.pages[1].open_page()

    function cfg.open_tab() 
        local selected_tab = self.selected_tab
        if selected_tab then 
            if selected_tab[4] ~= items["tab_content"] then 
                self.items["global_fade"].BackgroundTransparency = 0
                library:tween(self.items["global_fade"], {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, 0.3)
            end
            library:tween(selected_tab[1], {BackgroundTransparency = 1})
            library:tween(selected_tab[2], {ImageColor3 = rgb(72, 72, 73)})
            library:tween(selected_tab[3], {TextColor3 = rgb(120, 120, 125)})
            library:tween(selected_tab[5], {BackgroundTransparency = 1})
            selected_tab[4].Visible = false
            selected_tab[4].Parent = library["other"]
            selected_tab[6].Visible = false
            selected_tab[6].Parent = library["other"]
        end
        library:tween(items["button"], {BackgroundTransparency = 0.95})
        library:tween(items["icon"], {ImageColor3 = themes.preset.accent})
        library:tween(items["name"], {TextColor3 = rgb(255, 255, 255)})
        library:tween(items["accent_line"], {BackgroundTransparency = 0})
        items["tab_content"].Visible = true 
        items["tab_content"].Parent = self.items["content_area"]
        items["sub_tab_holder"].Visible = true 
        items["sub_tab_holder"].Parent = self.items["sub_tab_bar"]
        self.selected_tab = {items["button"], items["icon"], items["name"], items["tab_content"], items["accent_line"], items["sub_tab_holder"]}
        library:close_element()
    end

    items["button"].MouseButton1Down:Connect(function()
        cfg.open_tab()
    end)
    
    if not self.selected_tab then cfg.open_tab() end

    return unpack(cfg.pages)
end

function library:seperator(properties)
    local cfg = {items = {}}
    cfg.items["separator"] = library:create("Frame", {
        Parent = self.items["tab_holder"],
        Size = dim2(0, 1, 0, library:scale(14)),
        BackgroundColor3 = rgb(45, 45, 52),
    })
    library:create("UIPadding", {Parent = cfg.items["separator"], PaddingLeft = dim(0, 6), PaddingRight = dim(0, 6)})
    return setmetatable(cfg, library)
end 

function library:column(properties) 
    local cfg = {items = {}, size = properties.size or 1}
    cfg.items["column"] = library:create("Frame", {
        Parent = self["parent"] or self.items["tab_parent"],
        BackgroundTransparency = 1,
        Size = dim2(0, 0, cfg.size, 0),
    })
    library:create("UIPadding", {PaddingBottom = dim(0, 4), Parent = cfg.items["column"]})
    library:create("UIListLayout", {Parent = cfg.items["column"], HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = dim(0, 6), FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder})
    return setmetatable(cfg, library)
end 

function library:sub_tab(properties) 
    local cfg = {items = {}, size = properties.size or 1}
    cfg.items["tab_parent"] = library:create("Frame", {
        Parent = self.items["page"],
        BackgroundTransparency = 1,
        Size = dim2(0, 0, cfg.size, 0),
        Visible = true,
    })
    library:create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, VerticalFlex = Enum.UIFlexAlignment.Fill, Parent = cfg.items["tab_parent"], Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
    return setmetatable(cfg, library)
end 
--

-- Section
function library:section(properties)
    local cfg = {
        name = properties.name or "Section", 
        size = properties.size or 0.5, 
        icon = properties.icon and self.icons[properties.icon] or properties.icon or "http://www.roblox.com/asset/?id=6034767608",
        items = {},
    }
    
    local items = cfg.items
    
    items["outline"] = library:create("Frame", {
        Parent = self.items["column"],
        Size = dim2(0, 0, cfg.size, -3),
        BackgroundColor3 = rgb(24, 24, 28)
    })
    library:create("UICorner", {Parent = items["outline"], CornerRadius = dim(0, 4)})
    library:create("UIStroke", {Color = rgb(35, 35, 42), Parent = items["outline"], Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    
    items["header"] = library:create("Frame", {
        Parent = items["outline"],
        Size = dim2(1, 0, 0, library:scale(24)),
        BackgroundColor3 = rgb(28, 28, 32)
    })
    library:create("UICorner", {Parent = items["header"], CornerRadius = dim(0, 4)})
    --library:create("Frame", {Parent = items["header"], AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 4), BackgroundColor3 = rgb(28, 28, 32)})
    
    items["Icon"] = library:create("ImageLabel", {
        ImageColor3 = themes.preset.accent,
        Parent = items["header"],
        AnchorPoint = vec2(0, 0.5),
        Image = cfg.icon,
        BackgroundTransparency = 1,
        Position = dim2(0, library:scale(6), 0.5, 0),
        Size = dim_offset(library:scale(12), library:scale(12)),
    })
    library:apply_theme(items["Icon"], "accent", "ImageColor3")
    
    items["section_title"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = rgb(200, 200, 200),
        Text = cfg.name,
        Parent = items["header"],
        Position = dim2(0, library:scale(24), 0, 0),
        Size = dim2(0, 0, 1, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.X,
        TextSize = library:scale(11),
    })
    
    items["scrolling"] = library:create("ScrollingFrame", {
        ScrollBarImageColor3 = rgb(50, 50, 55),
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        Parent = items["outline"],
        Size = dim2(1, 0, 1, library:scale(-24)),
        BackgroundTransparency = 1,
        Position = dim2(0, 0, 0, library:scale(24)),
        CanvasSize = dim2(0, 0, 0, 0)
    })
    
    items["elements"] = library:create("Frame", {
        Parent = items["scrolling"],
        BackgroundTransparency = 1,
        Position = dim2(0, 6, 0, 4),
        Size = dim2(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    library:create("UIListLayout", {Parent = items["elements"], Padding = dim(0, library:scale(5)), SortOrder = Enum.SortOrder.LayoutOrder})
    library:create("UIPadding", {PaddingBottom = dim(0, 8), Parent = items["elements"]})

    return setmetatable(cfg, library)
end  
--

-- Tab Box
function library:tabbox(properties)
    local cfg = {
        tabs = properties.tabs or {"Tab 1", "Tab 2"},
        current_tab = nil,
        tab_data = {},
        items = {},
    }
    
    local items = cfg.items
    
    items["tabbox"] = library:create("Frame", {
        Parent = self.items["elements"],
        Size = dim2(1, 0, 0, 0),
        BackgroundColor3 = rgb(22, 22, 26),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    library:create("UICorner", {Parent = items["tabbox"], CornerRadius = dim(0, 4)})
    library:create("UIStroke", {Color = rgb(35, 35, 42), Parent = items["tabbox"], Thickness = 1})
    
    items["tab_buttons"] = library:create("Frame", {
        Parent = items["tabbox"],
        Size = dim2(1, 0, 0, library:scale(22)),
        BackgroundColor3 = rgb(26, 26, 30),
    })
    library:create("UICorner", {Parent = items["tab_buttons"], CornerRadius = dim(0, 4)})
    library:create("Frame", {Parent = items["tab_buttons"], AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 4), BackgroundColor3 = rgb(26, 26, 30)})
    library:create("UIListLayout", {Parent = items["tab_buttons"], FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder})
    
    items["content"] = library:create("Frame", {
        Parent = items["tabbox"],
        Position = dim2(0, 0, 0, library:scale(22)),
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    
    for i, tab_name in ipairs(cfg.tabs) do
        local tab = {}
        
        tab.button = library:create("TextButton", {
            Parent = items["tab_buttons"],
            Size = dim2(1 / #cfg.tabs, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = tab_name,
            TextColor3 = rgb(100, 100, 105),
            TextSize = library:scale(10),
            FontFace = fonts.small,
            AutoButtonColor = false,
        })
        library:apply_theme(tab.button, "accent", "TextColor3")
        
        tab.page = library:create("Frame", {
            Parent = items["content"],
            Size = dim2(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false,
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        
        tab.elements = library:create("Frame", {
            Parent = tab.page,
            Size = dim2(1, -8, 0, 0),
            Position = dim2(0, 4, 0, 4),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        library:create("UIListLayout", {Parent = tab.elements, Padding = dim(0, library:scale(5)), SortOrder = Enum.SortOrder.LayoutOrder})
        library:create("UIPadding", {Parent = tab.elements, PaddingBottom = dim(0, 6)})
        
        tab.button.MouseButton1Click:Connect(function()
            if cfg.current_tab then
                cfg.current_tab.page.Visible = false
                library:tween(cfg.current_tab.button, {TextColor3 = rgb(100, 100, 105)})
            end
            tab.page.Visible = true
            library:tween(tab.button, {TextColor3 = themes.preset.accent})
            cfg.current_tab = tab
        end)
        
        cfg.tab_data[tab_name] = {items = {elements = tab.elements}}
        
        if i == 1 then
            tab.page.Visible = true
            tab.button.TextColor3 = themes.preset.accent
            cfg.current_tab = tab
        end
    end
    
    function cfg.get_tab(name)
        return setmetatable(cfg.tab_data[name], library)
    end
    
    return cfg
end
--

-- Label
function library:label(options)
    local cfg = {
        name = options.name or "Label",
        items = {},
    }
    
    cfg.items["label"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(140, 140, 145),
        Text = cfg.name,
        Parent = self.items["elements"],
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        TextSize = library:scale(11),
    })
    library:create("UIPadding", {Parent = cfg.items["label"], PaddingLeft = dim(0, 2)})
    
    function cfg.set_text(text)
        cfg.items["label"].Text = text
    end
    
    return setmetatable(cfg, library)
end
--

-- Toggle
function library:toggle(options) 
    local cfg = {
        name = options.name or "Toggle",
        flag = options.flag or library:next_flag(),
        default = options.default or false,
        callback = options.callback or function() end,
        tooltip = options.tooltip,
        items = {},
        enabled = options.default or false,
    }

    flags[cfg.flag] = cfg.default
    local items = cfg.items
    
    items["toggle"] = library:create("TextButton", {
        FontFace = fonts.small,
        Text = "",
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, library:scale(18)),
        TextSize = library:scale(11),
    })
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(180, 180, 180),
        Text = cfg.name,
        Parent = items["toggle"],
        Size = dim2(1, -35, 1, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = library:scale(11),
    })
    library:create("UIPadding", {Parent = items["name"], PaddingLeft = dim(0, 2)})
    
    items["toggle_button"] = library:create("Frame", {
        AnchorPoint = vec2(1, 0.5),
        Parent = items["toggle"],
        Position = dim2(1, -2, 0.5, 0),
        Size = dim_offset(library:scale(28), library:scale(14)),
        BackgroundColor3 = rgb(45, 45, 50)
    })
    library:create("UICorner", {Parent = items["toggle_button"], CornerRadius = dim(0, 7)})
    
    items["circle"] = library:create("Frame", {
        Parent = items["toggle_button"],
        Position = dim2(0, 2, 0, 2),
        Size = dim_offset(library:scale(10), library:scale(10)),
        BackgroundColor3 = rgb(70, 70, 75)
    })
    library:create("UICorner", {Parent = items["circle"], CornerRadius = dim(0, 5)})
    
    function cfg.set(bool)
        cfg.enabled = bool
        library:tween(items["toggle_button"], {BackgroundColor3 = bool and themes.preset.accent or rgb(45, 45, 50)}, Enum.EasingStyle.Quad, 0.15)
        library:tween(items["circle"], {
            BackgroundColor3 = bool and rgb(255, 255, 255) or rgb(70, 70, 75), 
            Position = bool and dim2(1, -12, 0, 2) or dim2(0, 2, 0, 2)
        }, Enum.EasingStyle.Quad, 0.15)
        flags[cfg.flag] = bool
        cfg.callback(bool)
        library:update_dependencies(cfg.flag, bool)
    end 
    
    items["toggle"].MouseButton1Click:Connect(function()
        cfg.enabled = not cfg.enabled 
        cfg.set(cfg.enabled)
    end)
    
    if cfg.tooltip then
        items["toggle"].MouseEnter:Connect(function()
            library:show_tooltip(cfg.tooltip, items["toggle"])
        end)
        items["toggle"].MouseLeave:Connect(function()
            library:hide_tooltip()
        end)
    end

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end 
--

-- Slider
function library:slider(options) 
    local cfg = {
        name = options.name or "Slider",
        suffix = options.suffix or "",
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end, 
        min = options.min or 0,
        max = options.max or 100,
        intervals = options.interval or 1,
        default = options.default or 10,
        tooltip = options.tooltip,
        value = options.default or 10, 
        dragging = false,
        items = {}
    } 

    flags[cfg.flag] = cfg.default
    local items = cfg.items
    
    items["slider_object"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, library:scale(32)),
    })
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(180, 180, 180),
        Text = cfg.name,
        Parent = items["slider_object"],
        Size = dim2(1, 0, 0, library:scale(14)),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = library:scale(11),
    })
    library:create("UIPadding", {Parent = items["name"], PaddingLeft = dim(0, 2)})
    
    items["value"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(100, 100, 105),
        Text = "0",
        Parent = items["slider_object"],
        Size = dim2(1, -4, 0, library:scale(14)),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = library:scale(10),
    })
    
    items["slider"] = library:create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Parent = items["slider_object"],
        Size = dim2(1, -4, 0, library:scale(8)),
        Position = dim2(0, 2, 0, library:scale(18)),
        BackgroundColor3 = rgb(40, 40, 45)
    })
    library:create("UICorner", {Parent = items["slider"], CornerRadius = dim(0, 4)})
    
    items["fill"] = library:create("Frame", {
        Parent = items["slider"],
        Size = dim2(0.5, 0, 1, 0),
        BackgroundColor3 = themes.preset.accent
    })
    library:apply_theme(items["fill"], "accent", "BackgroundColor3")
    library:create("UICorner", {Parent = items["fill"], CornerRadius = dim(0, 4)})
    
    items["circle"] = library:create("Frame", {
        AnchorPoint = vec2(0.5, 0.5),
        Parent = items["fill"],
        Position = dim2(1, 0, 0.5, 0),
        Size = dim_offset(library:scale(14), library:scale(14)),
        BackgroundColor3 = rgb(255, 255, 255)
    })
    library:create("UICorner", {Parent = items["circle"], CornerRadius = dim(0, 7)})

    function cfg.set(value)
        cfg.value = clamp(library:round(value, cfg.intervals), cfg.min, cfg.max)
        library:tween(items["fill"], {Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)}, Enum.EasingStyle.Linear, 0.05)
        items["value"].Text = tostring(cfg.value) .. cfg.suffix
        flags[cfg.flag] = cfg.value
        cfg.callback(cfg.value)
        library:update_dependencies(cfg.flag, cfg.value)
    end

    items["slider"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.dragging = true 
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if cfg.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then 
            local size_x = (input.Position.X - items["slider"].AbsolutePosition.X) / items["slider"].AbsoluteSize.X
            cfg.set(((cfg.max - cfg.min) * size_x) + cfg.min)
        end
    end)

    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.dragging = false
        end 
    end)
    
    if cfg.tooltip then
        items["slider_object"].MouseEnter:Connect(function()
            library:show_tooltip(cfg.tooltip, items["slider_object"])
        end)
        items["slider_object"].MouseLeave:Connect(function()
            library:hide_tooltip()
        end)
    end

    cfg.set(cfg.default)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end 
--

-- Dropdown
function library:dropdown(options) 
    local cfg = {
        name = options.name or "Dropdown",
        flag = options.flag or library:next_flag(),
        options = options.items or {"Option 1", "Option 2"},
        callback = options.callback or function() end,
        multi = options.multi or false,
        tooltip = options.tooltip,
        open = false,
        option_instances = {},
        multi_items = {},
        items = {},
        y_size = 0,
    }   

    cfg.default = options.default or (cfg.multi and {cfg.options[1]}) or cfg.options[1] or "None"
    flags[cfg.flag] = cfg.default
    local items = cfg.items
    
    items["dropdown_object"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, library:scale(32)),
    })
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(180, 180, 180),
        Text = cfg.name,
        Parent = items["dropdown_object"],
        Size = dim2(1, 0, 0, library:scale(14)),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = library:scale(11),
    })
    library:create("UIPadding", {Parent = items["name"], PaddingLeft = dim(0, 2)})
    
    items["dropdown"] = library:create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Parent = items["dropdown_object"],
        Position = dim2(0, 0, 0, library:scale(16)),
        Size = dim2(1, 0, 0, library:scale(16)),
        BackgroundColor3 = rgb(35, 35, 40)
    })
    library:create("UICorner", {Parent = items["dropdown"], CornerRadius = dim(0, 4)})
    
    items["sub_text"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(150, 150, 155),
        Text = "",
        Parent = items["dropdown"],
        Size = dim2(1, -20, 1, 0),
        Position = dim2(0, 6, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextSize = library:scale(10),
    })
    
    items["arrow"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = rgb(100, 100, 105),
        Text = "▼",
        Parent = items["dropdown"],
        AnchorPoint = vec2(1, 0.5),
        Position = dim2(1, -6, 0.5, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = library:scale(8),
    })

    items["dropdown_holder"] = library:create("Frame", {
        Parent = items["dropdown_object"],
        Visible = false,
        Position = dim2(0, 0, 0, library:scale(33)),
        Size = dim2(1, 0, 0, 0),
        BackgroundColor3 = rgb(30, 30, 35),
        ClipsDescendants = true,
        ZIndex = 50,
    })
    library:create("UICorner", {Parent = items["dropdown_holder"], CornerRadius = dim(0, 4)})
    
    items["scroll_frame"] = library:create("ScrollingFrame", {
        Parent = items["dropdown_holder"],
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = rgb(60, 60, 65),
        CanvasSize = dim2(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        ZIndex = 50,
    })
    
    items["option_list"] = library:create("Frame", {
        Parent = items["scroll_frame"],
        Size = dim2(1, -4, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    library:create("UIListLayout", {Parent = items["option_list"], Padding = dim(0, 1), SortOrder = Enum.SortOrder.LayoutOrder})
    library:create("UIPadding", {Parent = items["option_list"], PaddingTop = dim(0, 3), PaddingBottom = dim(0, 3), PaddingLeft = dim(0, 3), PaddingRight = dim(0, 3)})

    function cfg.render_option(text)
        local button = library:create("TextButton", {
            FontFace = fonts.small,
            TextColor3 = rgb(130, 130, 135),
            Text = text,
            Parent = items["option_list"],
            Size = dim2(1, 0, 0, library:scale(16)),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = library:scale(10),
            ZIndex = 51,
        })
        library:create("UIPadding", {Parent = button, PaddingLeft = dim(0, 4)})
        return button
    end
    
    function cfg.close()
        cfg.open = false
        library:tween(items["dropdown_holder"], {Size = dim2(1, 0, 0, 0)}, Enum.EasingStyle.Quad, 0.15)
        task.delay(0.15, function()
            if not cfg.open then
                items["dropdown_holder"].Visible = false
            end
        end)
        library:tween(items["arrow"], {Rotation = 0}, Enum.EasingStyle.Quad, 0.1)
    end
    
    function cfg.set_visible(bool)
        if bool then
            items["dropdown_holder"].Visible = true
            local target_height = min(cfg.y_size, library:scale(120))
            library:tween(items["dropdown_holder"], {Size = dim2(1, 0, 0, target_height)}, Enum.EasingStyle.Quad, 0.15)
            library:tween(items["arrow"], {Rotation = 180}, Enum.EasingStyle.Quad, 0.1)
            library.current_open = cfg
        else
            cfg.close()
        end
    end
    
    function cfg.set(value)
        local selected = {}
        local isTable = type(value) == "table"
        for _, option in pairs(cfg.option_instances) do 
            if option.Text == value or (isTable and find(value, option.Text)) then 
                insert(selected, option.Text)
                cfg.multi_items = selected
                option.TextColor3 = themes.preset.accent
            else
                option.TextColor3 = rgb(130, 130, 135)
            end
        end
        items["sub_text"].Text = isTable and concat(selected, ", ") or selected[1] or ""
        flags[cfg.flag] = isTable and selected or selected[1]
        cfg.callback(flags[cfg.flag])
        library:update_dependencies(cfg.flag, flags[cfg.flag])
    end
    
    function cfg.refresh_options(list) 
        cfg.y_size = 8
        for _, option in pairs(cfg.option_instances) do option:Destroy() end
        cfg.option_instances = {} 
        for _, option in ipairs(list) do 
            local button = cfg.render_option(option)
            cfg.y_size = cfg.y_size + library:scale(17)
            insert(cfg.option_instances, button)
            button.MouseButton1Click:Connect(function()
                if cfg.multi then 
                    local selected_index = find(cfg.multi_items, button.Text)
                    if selected_index then remove(cfg.multi_items, selected_index)
                    else insert(cfg.multi_items, button.Text) end
                    cfg.set(cfg.multi_items)
                else 
                    cfg.set_visible(false)
                    library.current_open = nil
                    cfg.set(button.Text)
                end
            end)
        end
    end

    items["dropdown"].MouseButton1Click:Connect(function()
        if cfg.open then
            cfg.set_visible(false)
            library.current_open = nil
        else
            library:close_element()
            cfg.open = true
            cfg.set_visible(true)
        end
    end)
    
    if cfg.tooltip then
        items["dropdown_object"].MouseEnter:Connect(function()
            library:show_tooltip(cfg.tooltip, items["dropdown_object"])
        end)
        items["dropdown_object"].MouseLeave:Connect(function()
            library:hide_tooltip()
        end)
    end

    config_flags[cfg.flag] = cfg.set
    cfg.refresh_options(cfg.options)
    cfg.set(cfg.default)
        
    return setmetatable(cfg, library)
end
--

-- Player Dropdown
function library:player_dropdown(options)
    options.items = library:get_players()
    local dropdown = self:dropdown(options)
    players.PlayerAdded:Connect(function() dropdown.refresh_options(library:get_players()) end)
    players.PlayerRemoving:Connect(function() task.wait(0.1) dropdown.refresh_options(library:get_players()) end)
    return dropdown
end
--

-- Colorpicker
function library:colorpicker(options) 
    local cfg = {
        name = options.name or "Color", 
        flag = options.flag or library:next_flag(),
        color = options.color or color(1, 1, 1),
        alpha = options.alpha and 1 - options.alpha or 0,
        open = false, 
        callback = options.callback or function() end,
        tooltip = options.tooltip,
        items = {},
    }

    local dragging_sat, dragging_hue, dragging_alpha = false, false, false
    local h, s, v = cfg.color:ToHSV() 
    local a = cfg.alpha 

    flags[cfg.flag] = {Color = cfg.color, Transparency = cfg.alpha}
    local items = cfg.items
    
    items["colorpicker_object"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, library:scale(18)),
    })
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(180, 180, 180),
        Text = cfg.name,
        Parent = items["colorpicker_object"],
        Size = dim2(1, -30, 1, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = library:scale(11),
    })
    library:create("UIPadding", {Parent = items["name"], PaddingLeft = dim(0, 2)})
    
    items["colorpicker"] = library:create("TextButton", {
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0.5),
        Parent = items["colorpicker_object"],
        Position = dim2(1, -2, 0.5, 0),
        Size = dim_offset(library:scale(22), library:scale(14)),
        BackgroundColor3 = cfg.color
    })
    library:create("UICorner", {Parent = items["colorpicker"], CornerRadius = dim(0, 3)})

    items["colorpicker_holder"] = library:create("Frame", {
        Parent = items["colorpicker_object"],
        Position = dim2(0, 0, 0, library:scale(20)),
        Size = dim2(1, 0, 0, 0),
        BackgroundColor3 = rgb(28, 28, 32),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 50,
    })
    library:create("UICorner", {Parent = items["colorpicker_holder"], CornerRadius = dim(0, 4)})

    items["saturation_holder"] = library:create("Frame", {
        Parent = items["colorpicker_holder"],
        Position = dim2(0, 5, 0, 5),
        Size = dim2(1, -10, 0, library:scale(80)),
        BackgroundColor3 = hsv(h, 1, 1),
        ZIndex = 51,
    })
    library:create("UICorner", {Parent = items["saturation_holder"], CornerRadius = dim(0, 3)})
    
    items["sat"] = library:create("TextButton", {
        Parent = items["saturation_holder"],
        Size = dim2(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 52,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    library:create("UICorner", {Parent = items["sat"], CornerRadius = dim(0, 3)})
    library:create("UIGradient", {Rotation = 270, Transparency = numseq{numkey(0, 0), numkey(1, 1)}, Parent = items["sat"], Color = rgbseq{rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(0, 0, 0))}})
    
    items["val"] = library:create("Frame", {
        Parent = items["saturation_holder"],
        Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = rgb(255, 255, 255),
        ZIndex = 51,
    })
    library:create("UIGradient", {Parent = items["val"], Transparency = numseq{numkey(0, 0), numkey(1, 1)}})
    library:create("UICorner", {Parent = items["val"], CornerRadius = dim(0, 3)})
    
    items["satvalpicker"] = library:create("Frame", {
        AnchorPoint = vec2(0.5, 0.5),
        Parent = items["saturation_holder"],
        Position = dim2(s, 0, 1 - v, 0),
        Size = dim_offset(library:scale(8), library:scale(8)),
        ZIndex = 53,
        BackgroundColor3 = hsv(h, s, v)
    })
    library:create("UICorner", {Parent = items["satvalpicker"], CornerRadius = dim(0, 4)})
    library:create("UIStroke", {Color = rgb(255, 255, 255), Parent = items["satvalpicker"], Thickness = 1})
    
    items["hue_gradient"] = library:create("TextButton", {
        Parent = items["colorpicker_holder"],
        Position = dim2(0, 5, 0, library:scale(90)),
        Size = dim2(1, -10, 0, library:scale(12)),
        BackgroundColor3 = rgb(255, 255, 255),
        AutoButtonColor = false,
        Text = "",
        ZIndex = 51,
    })
    library:create("UIGradient", {Color = rgbseq{rgbkey(0, rgb(255, 0, 0)), rgbkey(0.17, rgb(255, 255, 0)), rgbkey(0.33, rgb(0, 255, 0)), rgbkey(0.5, rgb(0, 255, 255)), rgbkey(0.67, rgb(0, 0, 255)), rgbkey(0.83, rgb(255, 0, 255)), rgbkey(1, rgb(255, 0, 0))}, Parent = items["hue_gradient"]})
    library:create("UICorner", {Parent = items["hue_gradient"], CornerRadius = dim(0, 3)})
    
    items["hue_picker"] = library:create("Frame", {
        AnchorPoint = vec2(0.5, 0.5),
        Parent = items["hue_gradient"],
        Position = dim2(h, 0, 0.5, 0),
        Size = dim_offset(library:scale(4), library:scale(14)),
        ZIndex = 52,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    library:create("UICorner", {Parent = items["hue_picker"], CornerRadius = dim(0, 2)})
    
    items["alpha_gradient"] = library:create("TextButton", {
        Parent = items["colorpicker_holder"],
        Position = dim2(0, 5, 0, library:scale(107)),
        Size = dim2(1, -10, 0, library:scale(12)),
        BackgroundColor3 = rgb(25, 25, 29),
        AutoButtonColor = false,
        Text = "",
        ZIndex = 51,
    })
    library:create("UICorner", {Parent = items["alpha_gradient"], CornerRadius = dim(0, 3)})
    library:create("UIGradient", {Color = rgbseq{rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(255, 255, 255))}, Parent = items["alpha_gradient"]})
    
    items["alpha_picker"] = library:create("Frame", {
        AnchorPoint = vec2(0.5, 0.5),
        Parent = items["alpha_gradient"],
        Position = dim2(1 - a, 0, 0.5, 0),
        Size = dim_offset(library:scale(4), library:scale(14)),
        ZIndex = 52,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    library:create("UICorner", {Parent = items["alpha_picker"], CornerRadius = dim(0, 2)})

    function cfg.close()
        cfg.open = false
        library:tween(items["colorpicker_holder"], {Size = dim2(1, 0, 0, 0)}, Enum.EasingStyle.Quad, 0.15)
        task.delay(0.15, function()
            if not cfg.open then
                items["colorpicker_holder"].Visible = false
            end
        end)
    end

    function cfg.set_visible(bool)
        if bool then
            items["colorpicker_holder"].Visible = true
            library:tween(items["colorpicker_holder"], {Size = dim2(1, 0, 0, library:scale(125))}, Enum.EasingStyle.Quad, 0.15)
            library.current_open = cfg
        else
            cfg.close()
        end
    end

    function cfg.set(new_color, alpha_val)
        if type(new_color) == "boolean" then return end 
        if new_color then h, s, v = new_color:ToHSV() end
        if alpha_val then a = alpha_val end 
        local Color = hsv(h, s, v)
        items["hue_picker"].Position = dim2(h, 0, 0.5, 0)
        items["alpha_picker"].Position = dim2(1 - a, 0, 0.5, 0)
        items["satvalpicker"].Position = dim2(s, 0, 1 - v, 0)
        items["colorpicker"].BackgroundColor3 = Color
        items["saturation_holder"].BackgroundColor3 = hsv(h, 1, 1)
        items["satvalpicker"].BackgroundColor3 = hsv(h, s, v)
        flags[cfg.flag] = {Color = Color, Transparency = a}
        cfg.callback(Color, a)
    end
    
    function cfg.update_color() 
        local mousePos = uis:GetMouseLocation() 
        local offset = vec2(mousePos.X, mousePos.Y - gui_offset) 
        if dragging_sat then    
            s = clamp((offset.X - items["sat"].AbsolutePosition.X) / items["sat"].AbsoluteSize.X, 0, 1)
            v = 1 - clamp((offset.Y - items["sat"].AbsolutePosition.Y) / items["sat"].AbsoluteSize.Y, 0, 1)
        elseif dragging_hue then
            h = clamp((offset.X - items["hue_gradient"].AbsolutePosition.X) / items["hue_gradient"].AbsoluteSize.X, 0, 1)
        elseif dragging_alpha then
            a = 1 - clamp((offset.X - items["alpha_gradient"].AbsolutePosition.X) / items["alpha_gradient"].AbsoluteSize.X, 0, 1)
        end
        cfg.set()
    end

    items["colorpicker"].MouseButton1Click:Connect(function()
        if cfg.open then
            cfg.set_visible(false)
            library.current_open = nil
        else
            library:close_element()
            cfg.open = true
            cfg.set_visible(true)
        end
    end)

    library:connection(uis.InputChanged, function(input)
        if (dragging_sat or dragging_hue or dragging_alpha) and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            cfg.update_color() 
        end
    end)

    library:connection(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging_sat = false
            dragging_hue = false
            dragging_alpha = false
        end
    end)    

    items["alpha_gradient"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging_alpha = true
        end
    end)
    
    items["hue_gradient"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging_hue = true
        end
    end)
    
    items["sat"].InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging_sat = true
        end
    end)
    
    if cfg.tooltip then
        items["colorpicker_object"].MouseEnter:Connect(function()
            library:show_tooltip(cfg.tooltip, items["colorpicker_object"])
        end)
        items["colorpicker_object"].MouseLeave:Connect(function()
            library:hide_tooltip()
        end)
    end
    
    cfg.set(cfg.color, cfg.alpha)
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end 
--

-- Textbox
function library:textbox(options) 
    local cfg = {
        name = options.name or "TextBox",
        placeholder = options.placeholder or "...",
        default = options.default or "",
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        tooltip = options.tooltip,
        items = {},
    }

    flags[cfg.flag] = cfg.default
    local items = cfg.items
    
    items["textbox"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, library:scale(34)),
    })
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(180, 180, 180),
        Text = cfg.name,
        Parent = items["textbox"],
        Size = dim2(1, 0, 0, library:scale(14)),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = library:scale(11),
    })
    library:create("UIPadding", {Parent = items["name"], PaddingLeft = dim(0, 2)})
    
    items["input"] = library:create("TextBox", {
        FontFace = fonts.small,
        Text = cfg.default,
        Parent = items["textbox"],
        Position = dim2(0, 0, 0, library:scale(16)),
        Size = dim2(1, 0, 0, library:scale(18)),
        PlaceholderText = cfg.placeholder,
        PlaceholderColor3 = rgb(80, 80, 85),
        CursorPosition = -1,
        ClearTextOnFocus = false,
        TextSize = library:scale(10),
        TextColor3 = rgb(180, 180, 185),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = rgb(30, 30, 35)
    })
    library:create("UICorner", {Parent = items["input"], CornerRadius = dim(0, 4)})
    library:create("UIPadding", {Parent = items["input"], PaddingLeft = dim(0, 6), PaddingRight = dim(0, 6)})
    
    function cfg.set(text) 
        flags[cfg.flag] = text
        items["input"].Text = text
        cfg.callback(text)
    end 
    
    items["input"]:GetPropertyChangedSignal("Text"):Connect(function()
        cfg.set(items["input"].Text) 
    end)

    items["input"].Focused:Connect(function()
        library:tween(items["input"], {TextColor3 = rgb(220, 220, 225)})
    end)

    items["input"].FocusLost:Connect(function()
        library:tween(items["input"], {TextColor3 = rgb(180, 180, 185)})
    end)
    
    if cfg.tooltip then
        items["textbox"].MouseEnter:Connect(function()
            library:show_tooltip(cfg.tooltip, items["textbox"])
        end)
        items["textbox"].MouseLeave:Connect(function()
            library:hide_tooltip()
        end)
    end

    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end
--

-- Button
function library:button(options) 
    local cfg = {
        name = options.name or "Button",
        callback = options.callback or function() end,
        tooltip = options.tooltip,
        items = {},
    }
    
    local items = cfg.items
    
    items["button_element"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, library:scale(28)),
    })
    
    items["button_outer"] = library:create("Frame", {
        Parent = items["button_element"],
        Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = rgb(50, 50, 58)
    })
    library:create("UICorner", {Parent = items["button_outer"], CornerRadius = dim(0, 5)})
    
    items["button_middle"] = library:create("Frame", {
        Parent = items["button_outer"],
        Position = dim2(0, 1, 0, 1),
        Size = dim2(1, -2, 1, -2),
        BackgroundColor3 = rgb(42, 42, 48)
    })
    library:create("UICorner", {Parent = items["button_middle"], CornerRadius = dim(0, 4)})
    
    items["button"] = library:create("TextButton", {
        FontFace = fonts.small,
        Text = "",
        AutoButtonColor = false,
        Parent = items["button_middle"],
        Position = dim2(0, 1, 0, 1),
        Size = dim2(1, -2, 1, -2),
        BackgroundColor3 = rgb(35, 35, 42)
    })
    library:create("UICorner", {Parent = items["button"], CornerRadius = dim(0, 4)})
    
    items["gradient"] = library:create("Frame", {
        Parent = items["button"],
        Size = dim2(1, 0, 0.4, 0),
        BackgroundColor3 = rgb(255, 255, 255),
        BackgroundTransparency = 0.92,
    })
    library:create("UICorner", {Parent = items["gradient"], CornerRadius = dim(0, 4)})
    library:create("UIGradient", {Parent = items["gradient"], Rotation = 90, Transparency = numseq{numkey(0, 0), numkey(1, 1)}})
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = rgb(210, 210, 215),
        Text = cfg.name,
        Parent = items["button"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        TextSize = library:scale(12),
        ZIndex = 2,
    })

    items["button"].MouseButton1Click:Connect(function()
        cfg.callback()
        items["name"].TextColor3 = themes.preset.accent 
        library:tween(items["button"], {BackgroundColor3 = rgb(45, 45, 55)}, Enum.EasingStyle.Quad, 0.08)
        task.wait(0.08)
        library:tween(items["button"], {BackgroundColor3 = rgb(35, 35, 42)}, Enum.EasingStyle.Quad, 0.1)
        library:tween(items["name"], {TextColor3 = rgb(210, 210, 215)})
    end)
    
    items["button"].MouseEnter:Connect(function()
        library:tween(items["button"], {BackgroundColor3 = rgb(42, 42, 50)}, Enum.EasingStyle.Quad, 0.1)
        library:tween(items["name"], {TextColor3 = rgb(240, 240, 245)}, Enum.EasingStyle.Quad, 0.1)
    end)
    
    items["button"].MouseLeave:Connect(function()
        library:tween(items["button"], {BackgroundColor3 = rgb(35, 35, 42)}, Enum.EasingStyle.Quad, 0.1)
        library:tween(items["name"], {TextColor3 = rgb(210, 210, 215)}, Enum.EasingStyle.Quad, 0.1)
    end)
    
    if cfg.tooltip then
        items["button_element"].MouseEnter:Connect(function()
            library:show_tooltip(cfg.tooltip, items["button_element"])
        end)
        items["button_element"].MouseLeave:Connect(function()
            library:hide_tooltip()
        end)
    end
    
    return setmetatable(cfg, library)
end 

function library:keybind(options) 
    local cfg = {
        flag = options.flag or library:next_flag(),
        callback = options.callback or function() end,
        name = options.name or "Keybind", 
        key = options.key or nil, 
        mode = options.mode or "Toggle",
        active = options.default or false, 
        open = false,
        binding = nil, 
        tooltip = options.tooltip,
        show_in_list = options.show_in_list ~= false,
        items = {},
    }

    local keys_map = {
        [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
        [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
        [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
        [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.LeftAlt] = "LA",
        [Enum.KeyCode.RightAlt] = "RA", [Enum.KeyCode.CapsLock] = "CAPS",
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
        [Enum.KeyCode.Escape] = "ESC", [Enum.KeyCode.Space] = "SPC",
    }

    flags[cfg.flag] = {mode = cfg.mode, key = cfg.key, active = cfg.active}
    local items = cfg.items
    
    items["keybind_element"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, library:scale(18)),
    })
    
    items["name"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(180, 180, 180),
        Text = cfg.name,
        Parent = items["keybind_element"],
        Size = dim2(1, -60, 1, 0),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = library:scale(11),
    })
    library:create("UIPadding", {Parent = items["name"], PaddingLeft = dim(0, 2)})
    
    items["keybind_holder"] = library:create("TextButton", {
        Text = "",
        Parent = items["keybind_element"],
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 0.5),
        Size = dim_offset(library:scale(50), library:scale(14)),
        Position = dim2(1, -2, 0.5, 0),
        BackgroundColor3 = rgb(35, 35, 40)
    })
    library:create("UICorner", {Parent = items["keybind_holder"], CornerRadius = dim(0, 4)})
    
    items["key"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(130, 130, 135),
        Text = "None",
        Parent = items["keybind_holder"],
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextSize = library:scale(9),
    })

    items["dropdown"] = library:create("Frame", {
        Parent = items["keybind_element"],
        Position = dim2(1, -52, 0, library:scale(20)),
        Size = dim_offset(library:scale(50), 0),
        BackgroundColor3 = rgb(28, 28, 32),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 50,
    })
    library:create("UICorner", {Parent = items["dropdown"], CornerRadius = dim(0, 4)})
    
    items["mode_list"] = library:create("Frame", {
        Parent = items["dropdown"],
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
    })
    library:create("UIListLayout", {Parent = items["mode_list"], Padding = dim(0, 1), SortOrder = Enum.SortOrder.LayoutOrder})
    library:create("UIPadding", {Parent = items["mode_list"], PaddingTop = dim(0, 2), PaddingBottom = dim(0, 2)})
    
    local mode_options = {"Hold", "Toggle", "Always"}
    local mode_buttons = {}
    
    for _, option in ipairs(mode_options) do                        
        local btn = library:create("TextButton", {
            FontFace = fonts.small,
            TextColor3 = rgb(110, 110, 115),
            Text = option,
            Parent = items["mode_list"],
            Size = dim2(1, 0, 0, library:scale(14)),
            BackgroundTransparency = 1,
            TextSize = library:scale(9),
            ZIndex = 51,
        })
        mode_buttons[option] = btn
        
        btn.MouseButton1Click:Connect(function()
            cfg.mode = option
            for name, b in pairs(mode_buttons) do
                b.TextColor3 = name == option and themes.preset.accent or rgb(110, 110, 115)
            end
            if option == "Always" then 
                cfg.active = true 
                cfg.callback(true) 
            end
            flags[cfg.flag].mode = option
            -- Update keybind list with correct mode
            if cfg.show_in_list and library.keybinds[cfg.flag] then
                library.keybinds[cfg.flag].mode = option
                library:update_keybind_list()
            end
            cfg.close()
            library.current_open = nil
        end)
    end
    mode_buttons[cfg.mode].TextColor3 = themes.preset.accent

    function cfg.close()
        cfg.open = false
        library:tween(items["dropdown"], {Size = dim_offset(library:scale(50), 0)}, Enum.EasingStyle.Quad, 0.15)
        task.delay(0.15, function()
            if not cfg.open then
                items["dropdown"].Visible = false
            end
        end)
    end

    function cfg.set(input)
        if type(input) == "boolean" then 
            cfg.active = input
            if cfg.mode == "Always" then cfg.active = true end
            if cfg.show_in_list then
                library:set_keybind_active(cfg.flag, cfg.active)
            end
        elseif tostring(input):find("Enum") then 
            input = input.Name == "Escape" and "NONE" or input
            cfg.key = input or "NONE"
            -- Update keybind registry with current mode
            local key_text = "None"
            if cfg.key and tostring(cfg.key) ~= "Enums" and cfg.key ~= "NONE" then
                key_text = keys_map[cfg.key] or tostring(cfg.key):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
            end
            if cfg.show_in_list then
                library:register_keybind(cfg.name, cfg.flag, cfg.key, cfg.mode)
            end
        elseif type(input) == "table" then 
            if type(input.key) == "string" and input.key ~= "NONE" then
                pcall(function() input.key = library:convert_enum(input.key) end)
            end
            if input.key == Enum.KeyCode.Escape then input.key = "NONE" end
            cfg.key = input.key or "NONE"
            cfg.mode = input.mode or "Toggle"
            if input.active ~= nil then cfg.active = input.active end
            for name, b in pairs(mode_buttons) do
                b.TextColor3 = name == cfg.mode and themes.preset.accent or rgb(110, 110, 115)
            end
            if cfg.show_in_list then
                library:register_keybind(cfg.name, cfg.flag, cfg.key, cfg.mode)
                library:set_keybind_active(cfg.flag, cfg.active)
            end
        end 
        cfg.callback(cfg.active)
        local text = "None"
        if cfg.key and tostring(cfg.key) ~= "Enums" and cfg.key ~= "NONE" then
            text = keys_map[cfg.key] or tostring(cfg.key):gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
        end
        items["key"].Text = text
        flags[cfg.flag] = {mode = cfg.mode, key = cfg.key, active = cfg.active}
    end

    items["keybind_holder"].MouseButton1Down:Connect(function()
        task.wait()
        items["key"].Text = "..."   
        cfg.binding = library:connection(uis.InputBegan, function(keycode)  
            cfg.set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)
            cfg.binding:Disconnect() 
            cfg.binding = nil
        end)
    end)

    items["keybind_holder"].MouseButton2Down:Connect(function()
        if cfg.open then
            cfg.close()
            library.current_open = nil
        else
            library:close_element()
            cfg.open = true
            items["dropdown"].Visible = true
            library:tween(items["dropdown"], {Size = dim_offset(library:scale(50), library:scale(50))}, Enum.EasingStyle.Quad, 0.15)
            library.current_open = cfg
        end
    end)

    library:connection(uis.InputBegan, function(input, game_event) 
        if not game_event then
            local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
            if selected_key == cfg.key then 
                if cfg.mode == "Toggle" then 
                    cfg.active = not cfg.active
                    cfg.set(cfg.active)
                elseif cfg.mode == "Hold" then 
                    cfg.set(true)
                end
            end
        end
    end)    

    library:connection(uis.InputEnded, function(input, game_event) 
        if game_event then return end 
        local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
        if selected_key == cfg.key and cfg.mode == "Hold" then 
            cfg.set(false)
        end
    end)
    
    if cfg.tooltip then
        items["keybind_element"].MouseEnter:Connect(function()
            library:show_tooltip(cfg.tooltip, items["keybind_element"])
        end)
        items["keybind_element"].MouseLeave:Connect(function()
            library:hide_tooltip()
        end)
    end
    
    -- Register keybind for list with the correct mode from options
    if cfg.show_in_list then
        library:register_keybind(cfg.name, cfg.flag, cfg.key, cfg.mode)
    end
    
    cfg.set({mode = cfg.mode, active = cfg.active, key = cfg.key})           
    config_flags[cfg.flag] = cfg.set

    return setmetatable(cfg, library)
end

-- List
function library:list(properties) 
    local cfg = {
        items = {},
        options = properties.options or {"1", "2", "3"},
        flag = properties.flag or library:next_flag(),
        callback = properties.callback or function() end,
        data_store = {},
        current_element = nil,
    }

    local items = cfg.items
    
    items["list"] = library:create("Frame", {
        Parent = self.items["elements"],
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    library:create("UIListLayout", {Parent = items["list"], Padding = dim(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})

    function cfg.refresh_options(options_to_refresh)
        for _, option in pairs(cfg.data_store) do option:Destroy() end
        cfg.data_store = {}
        for _, option_data in ipairs(options_to_refresh) do
            local button_outer = library:create("Frame", {
                Parent = items["list"],
                Size = dim2(1, 0, 0, library:scale(24)),
                BackgroundColor3 = rgb(40, 40, 46)
            })
            cfg.data_store[#cfg.data_store + 1] = button_outer
            library:create("UICorner", {Parent = button_outer, CornerRadius = dim(0, 4)})
            
            local button = library:create("TextButton", {
                Text = "",
                AutoButtonColor = false,
                Parent = button_outer,
                Position = dim2(0, 1, 0, 1),
                Size = dim2(1, -2, 1, -2),
                BackgroundColor3 = rgb(32, 32, 38)
            })
            library:create("UICorner", {Parent = button, CornerRadius = dim(0, 4)})

            local name = library:create("TextLabel", {
                FontFace = fonts.small,
                TextColor3 = rgb(130, 130, 135),
                Text = option_data,
                Parent = button,
                BackgroundTransparency = 1,
                Size = dim2(1, 0, 1, 0),
                TextSize = library:scale(11),
            })

            button.MouseButton1Click:Connect(function()
                if cfg.current_element and cfg.current_element ~= name then 
                    library:tween(cfg.current_element, {TextColor3 = rgb(130, 130, 135)})
                end
                flags[cfg.flag] = option_data
                cfg.callback(option_data)
                library:tween(name, {TextColor3 = rgb(230, 230, 235)})
                cfg.current_element = name
            end)

            button.MouseEnter:Connect(function()
                if cfg.current_element == name then return end 
                library:tween(name, {TextColor3 = rgb(170, 170, 175)})
                library:tween(button, {BackgroundColor3 = rgb(38, 38, 44)})
            end)

            button.MouseLeave:Connect(function()
                if cfg.current_element == name then return end 
                library:tween(name, {TextColor3 = rgb(130, 130, 135)})
                library:tween(button, {BackgroundColor3 = rgb(32, 32, 38)})
            end)
        end
    end

    cfg.refresh_options(cfg.options)
    return setmetatable(cfg, library)
end 

function library:init_config(window) 
    library:load_library_settings()
    
    window:seperator({})
    local main, settings_tab = window:tab({name = "Settings", icon = "http://www.roblox.com/asset/?id=6031280882", tabs = {"Configs", "Menu"}})
    
    -- Configs Tab
    do
        local column = main:column({})
        local section = column:section({name = "Config List", size = 1, icon = "http://www.roblox.com/asset/?id=6022668898"})
        config_holder = section:list({options = {"No Configs"}, callback = function() end, flag = "config_name_list"})
        library:update_config_list()
        
        local column2 = main:column({})
        local section2 = column2:section({name = "Actions", size = 0.5, icon = "http://www.roblox.com/asset/?id=6034509993"})
        section2:textbox({name = "Config Name", flag = "config_name_text", placeholder = "name..."})
        
        section2:button({name = "Save Config", callback = function() 
            local config_name = flags["config_name_text"]
            if config_name == "" then config_name = flags["config_name_list"] end
            if config_name and config_name ~= "" and config_name ~= "No Configs" then
                pcall(function() writefile(library:get_config_path() .. "/" .. config_name .. ".cfg", library:get_config()) end)
                library:update_config_list() 
                if notifications.enabled then notifications:create_notification({name = "Saved", info = config_name}) end
            end
        end}) 
        
        section2:button({name = "Load Config", callback = function() 
            local config_name = flags["config_name_list"]
            if config_name and config_name ~= "No Configs" then
                local path = library:get_config_path() .. "/" .. config_name .. ".cfg"
                pcall(function()
                    if isfile(path) then
                        library:load_config(readfile(path))
                        library:update_config_list() 
                        if notifications.enabled then notifications:create_notification({name = "Loaded", info = config_name}) end
                    end
                end)
            end
        end})
        
        section2:button({name = "Delete Config", callback = function() 
            local config_name = flags["config_name_list"]
            if config_name and config_name ~= "No Configs" then
                local path = library:get_config_path() .. "/" .. config_name .. ".cfg"
                pcall(function()
                    if isfile(path) then
                        delfile(path)
                        library:update_config_list() 
                        if notifications.enabled then notifications:create_notification({name = "Deleted", info = config_name}) end
                    end
                end)
            end
        end})
        
        section2:button({name = "Refresh", callback = function() library:update_config_list() end})
        
        local auto_section = column2:section({name = "Auto Load", size = 0.5, icon = "http://www.roblox.com/asset/?id=6026568198"})
        local auto_label = auto_section:label({name = "Current: " .. (library.auto_load_config_name or "None")})
        
        auto_section:button({name = "Set Auto Load", callback = function()
            local config_name = flags["config_name_list"]
            if config_name and config_name ~= "No Configs" then
                library:set_auto_load(config_name)
                auto_label.set_text("Current: " .. config_name)
            end
        end})
        
        auto_section:button({name = "Clear Auto Load", callback = function()
            library:clear_auto_load()
            auto_label.set_text("Current: None")
        end})
    end
    
    -- Menu Settings Tab
    do
        local column = settings_tab:column({})
        local ui_section = column:section({name = "Menu Settings", size = 0.6, icon = "http://www.roblox.com/asset/?id=6031280882"})
        
        ui_section:keybind({name = "Menu Key", flag = "menu_keybind", key = Enum.KeyCode.Insert, mode = "Toggle", default = true, show_in_list = false, callback = function(bool) window.toggle_menu(bool) end})
        ui_section:colorpicker({name = "Accent Color", flag = "menu_accent", callback = function(clr) library:update_theme("accent", clr) end, color = themes.preset.accent})
        
        ui_section:dropdown({
            name = "DPI Scale",
            flag = "dpi_scale",
            items = {"100%", "110%", "125%", "150%"},
            default = library.dpi_scale == 1 and "100%" or library.dpi_scale == 1.1 and "110%" or library.dpi_scale == 1.25 and "125%" or "150%",
            callback = function(value)
                local scale_map = {["100%"] = 1, ["110%"] = 1.1, ["125%"] = 1.25, ["150%"] = 1.5}
                library:set_dpi(scale_map[value])
                if notifications.enabled then
                    notifications:create_notification({name = "DPI", info = "Restart menu to apply"})
                end
            end
        })
        
        ui_section:button({name = "Unload Menu", callback = function()
            library:unload_menu()
        end})
        
        -- Watermark Settings
        local watermark_section = column:section({name = "Watermark", size = 0.4, icon = "http://www.roblox.com/asset/?id=6026568210"})
        
        watermark_section:toggle({name = "Show Watermark", flag = "watermark_visible", default = library.watermark_visible, callback = function(bool)
            library:toggle_watermark(bool)
        end})
        
        watermark_section:toggle({name = "Show FPS", flag = "watermark_fps", default = library.watermark_elements.fps, callback = function(bool)
            library:set_watermark_element("fps", bool)
        end})
        
        watermark_section:toggle({name = "Show Ping", flag = "watermark_ping", default = library.watermark_elements.ping, callback = function(bool)
            library:set_watermark_element("ping", bool)
        end})
        
        watermark_section:toggle({name = "Show Time", flag = "watermark_time", default = library.watermark_elements.time, callback = function(bool)
            library:set_watermark_element("time", bool)
        end})
        
        local column2 = settings_tab:column({})
        
        -- Keybind List Settings
        local keybind_section = column2:section({name = "Keybind List", size = 0.4, icon = "http://www.roblox.com/asset/?id=6034509993"})
        
        keybind_section:toggle({name = "Show Keybind List", flag = "keybind_list_visible", default = library.keybind_list_visible, callback = function(bool)
            library:toggle_keybind_list(bool)
        end})
        
        -- Notifications
        local notif_section = column2:section({name = "Notifications", size = 0.6, icon = "http://www.roblox.com/asset/?id=6026568210"})
        
        notif_section:toggle({name = "Enable Notifications", flag = "notif_toggle", default = notifications.enabled, callback = function(bool) 
            library:toggle_notifications(bool)
            if bool then notifications:create_notification({name = "Notifications", info = "Enabled!"}) end
        end})
        
        notif_section:button({name = "Test Notification", callback = function()
            if notifications.enabled then notifications:create_notification({name = "Test", info = "Hello!", lifetime = 3}) end
        end})
    end
    
    -- Update keybind list initially
    library:update_keybind_list()
    
    task.spawn(function()
        task.wait(0.5)
        library:do_auto_load()
    end)
end
--

-- Notifications
function notifications:refresh_notifs() 
    local offset = 50
    for _, v in pairs(notifications.notifs) do
        library:tween(v, {Position = dim_offset(20, offset)}, Enum.EasingStyle.Quad, 0.3)
        offset = offset + v.AbsoluteSize.Y + 5
    end
    return offset
end

function notifications:fade(path, is_fading)
    local fading = is_fading and 1 or 0 
    library:tween(path, {BackgroundTransparency = fading}, Enum.EasingStyle.Quad, 0.5)
    for _, instance in pairs(path:GetDescendants()) do 
        pcall(function()
            if instance:IsA("UIStroke") then library:tween(instance, {Transparency = fading}, Enum.EasingStyle.Quad, 0.5)
            elseif instance:IsA("TextLabel") then library:tween(instance, {TextTransparency = fading})
            elseif instance:IsA("Frame") then library:tween(instance, {BackgroundTransparency = is_fading and 1 or 0.4}, Enum.EasingStyle.Quad, 0.5) end
        end)
    end
end 

function notifications:create_notification(options)
    if not notifications.enabled then return end
    
    local cfg = {
        name = options.name or "Notification",
        info = options.info or "Info",
        lifetime = options.lifetime or 3,
        items = {},
    }

    local items = cfg.items
    
    items["notification"] = library:create("Frame", {
        Parent = library["items"],
        Size = dim_offset(library:scale(180), library:scale(45)),
        BackgroundTransparency = 1,
        AnchorPoint = vec2(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(24, 24, 28)
    })
    library:create("UICorner", {Parent = items["notification"], CornerRadius = dim(0, 5)})
    library:create("UIStroke", {Color = rgb(45, 45, 52), Parent = items["notification"], Transparency = 1, Thickness = 1})
    
    items["title"] = library:create("TextLabel", {
        FontFace = fonts.font,
        TextColor3 = rgb(220, 220, 225),
        Text = cfg.name,
        Parent = items["notification"],
        BackgroundTransparency = 1,
        Position = dim2(0, 8, 0, 6),
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = library:scale(11),
    })
    
    items["info"] = library:create("TextLabel", {
        FontFace = fonts.small,
        TextColor3 = rgb(150, 150, 155),
        Text = cfg.info,
        Parent = items["notification"],
        Position = dim2(0, 8, 0, library:scale(20)),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = library:scale(10),
    })
    library:create("UIPadding", {PaddingBottom = dim(0, 14), PaddingRight = dim(0, 8), Parent = items["info"]})
    
    items["bar"] = library:create("Frame", {
        AnchorPoint = vec2(0, 1),
        Parent = items["notification"],
        Position = dim2(0, 0, 1, 0),
        Size = dim2(0, 0, 0, 3),
        BackgroundTransparency = 1,
        BackgroundColor3 = themes.preset.accent
    })
    library:apply_theme(items["bar"], "accent", "BackgroundColor3")
    library:create("UICorner", {Parent = items["bar"], CornerRadius = dim(0, 2)})
    
    local index = #notifications.notifs + 1
    notifications.notifs[index] = items["notification"]

    notifications:fade(items["notification"], false)
    
    local offset = notifications:refresh_notifs()
    items["notification"].Position = dim_offset(20, offset)

    library:tween(items["notification"], {AnchorPoint = vec2(0, 0)}, Enum.EasingStyle.Quad, 0.5)
    library:tween(items["bar"], {Size = dim2(1, 0, 0, 3)}, Enum.EasingStyle.Quad, cfg.lifetime)

    task.spawn(function()
        task.wait(cfg.lifetime)
        notifications.notifs[index] = nil
        notifications:fade(items["notification"], true)
        library:tween(items["notification"], {AnchorPoint = vec2(1, 0)}, Enum.EasingStyle.Quad, 0.5)
        task.wait(0.5)
        items["notification"]:Destroy() 
    end)
end

return library
