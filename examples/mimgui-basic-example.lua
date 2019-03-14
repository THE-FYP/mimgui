script_name 'mimgui basic example'

local imgui = require 'mimgui'
local new = imgui.new
local vk = require 'vkeys'

local imgui_example = {
	show = false,
	show_demo_window = new.bool(),
	show_another_window = new.bool(),
	f = new.float(0.0),
	counter = new.int(0),
	clear_color = new.float[3](0.45, 0.55, 0.60)
}
imgui.OnFrame(function() return imgui_example.show end,
function()
	-- 1. Show the big demo window (Most of the sample code is in imgui.ShowDemoWindow()! You can browse its code to learn more about Dear ImGui!).
	if imgui_example.show_demo_window[0] then
		imgui.ShowDemoWindow(imgui_example.show_demo_window)
	end
	
	-- 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
	imgui.Begin("Hello, world!") -- Create a window called "Hello, world!" and append into it.

	imgui.Text("This is some useful text.") -- Display some text (you can use a format strings too)
	imgui.Checkbox("Demo Window", imgui_example.show_demo_window) -- Edit bools storing our window open/close state
	imgui.Checkbox("Another Window", imgui_example.show_another_window)

	imgui.SliderFloat("float", imgui_example.f, 0.0, 1.0) -- Edit 1 float using a slider from 0.0 to 1.0    
	imgui.ColorEdit3("clear color", imgui_example.clear_color) -- Edit 3 floats representing a color

	if imgui.Button("Button") then -- Buttons return true when clicked (most widgets return true when edited/activated)
		imgui_example.counter[0] = imgui_example.counter[0] + 1
	end
	imgui.SameLine()
	imgui.Text("counter = %g", imgui_example.counter[0])

	imgui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / imgui.GetIO().Framerate, imgui.GetIO().Framerate)
	imgui.End()
	
	-- 3. Show another simple window.
	if imgui_example.show_another_window[0] then
		imgui.Begin("Another Window", imgui_example.show_another_window) -- Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
		imgui.Text("Hello from another window!")
		if imgui.Button("Close Me") then
			imgui_example.show_another_window[0] = false
		end
		imgui.End()
	end
end)

function main()
	while true do
		wait(20)
		if wasKeyPressed(vk.VK_1) then
			imgui_example.show = not imgui_example.show
		end
	end
end
