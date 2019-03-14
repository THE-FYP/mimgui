script_name 'mimgui overlay example'

local imgui = require 'mimgui'
local vk = require 'vkeys'
local new = imgui.new

-- overlay
local overlay = {
    show = new.bool(true),
    offset = new.int(10),
    position = new.int(1)
}
imgui.OnFrame(function() return overlay.show[0] and not isGamePaused() end,
function()
    local io = imgui.GetIO()
    local pos = overlay.position[0]
    if pos > 0 then
        x = (pos == 1 or pos == 3) and overlay.offset[0] or io.DisplaySize.x - overlay.offset[0]
        y = (pos == 1 or pos == 2) and overlay.offset[0] or io.DisplaySize.y - overlay.offset[0]
        local window_pos_pivot = imgui.ImVec2((pos == 1 or pos == 3) and 0 or 1, (pos == 1 or pos == 2) and 0 or 1)
        imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.Always, window_pos_pivot)
    end
    local flags = imgui.WindowFlags.NoDecoration + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoSavedSettings
    if pos ~= 0 then
        flags = flags + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoInputs
    end
    imgui.Begin('overlay', nil, flags)
    imgui.Text('Simple overlay\nin the corner of the screen.\nPress key 2 to open settings menu')
    imgui.Separator()
    if imgui.IsMousePosValid() then
        imgui.Text('Mouse Position: (%.1f, %.1f)', io.MousePos.x, io.MousePos.y)
    else
        imgui.Text('Mouse Position: <invalid>')
    end
    imgui.End()
end).HideCursor = true

-- settings window
local show_settings_window = new.bool()
imgui.OnFrame(function() return show_settings_window[0] end,
function()
    imgui.Begin('Overlay settings', show_settings_window)
    imgui.Checkbox('Show', overlay.show)
    imgui.DragInt('Offset', overlay.offset, 1, 0, 200)
    imgui.ComboStr('Position', overlay.position, 'Free\0Up-Left\0Up-Right\0Down-Left\0Down-Right\0\0')
    imgui.End()
end)

function main()
    while true do
        wait(20)
        if wasKeyPressed(vk.VK_2) then
            show_settings_window[0] = not show_settings_window[0]
        end
    end
end
