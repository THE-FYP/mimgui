script_name 'mimgui hello world'

local imgui = require 'mimgui'

imgui.OnFrame(
function() -- condition
    return isPlayerPlaying(PLAYER_HANDLE)
end,
function() -- render frame
    imgui.Begin('mimgui')
    imgui.Text('Hello, World!')
    imgui.End()
end)
