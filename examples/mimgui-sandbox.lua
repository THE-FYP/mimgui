script_name 'mimgui sandbox'
script_author 'FYP'

local imgui, ffi = require 'mimgui', require 'ffi'
local new, str = imgui.new, ffi.string

local imguiStack = {}
local function wrapPushFunction(fn, popFn)
	return function(...)
		table.insert(imguiStack, popFn)
		return fn(...)
	end
end

local function wrapPopFunction(fn)
	return function(...)
		if #imguiStack > 0 then
			table.remove(imguiStack, #imguiStack)
		end
		return fn(...)
	end
end

local function useStrict(tbl)
	local getinfo, error, rawset, rawget = debug.getinfo, error, rawset, rawget
	local mt = getmetatable(tbl)
	if mt == nil then
	  mt = {}
	  setmetatable(tbl, mt)
	end
	mt.__declared = {}
	mt.__newindex = function (t, n, v)
	  if not mt.__declared[n] then
	    local info = getinfo(2, "S")
	    if info and info.linedefined > 0 then
	      error("assign to undeclared variable '"..n.."'", 2)
	    end
	    mt.__declared[n] = true
	  end
	  rawset(t, n, v)
	end
	mt.__index = function (t, n)
	  if not mt.__declared[n] then
	    local info = getinfo(2, "S")
	    if info and info.what ~= 'C' then
	      error("variable '"..n.."' is not declared", 2)
	    end
	  end
	  return rawget(t, n)
	end
end

local function createSandboxEnv()
	local env = {}
	for k, v in pairs(_G) do
		env[k] = v
	end
	env.imgui = {}
	for k, v in pairs(imgui) do
		env.imgui[k] = v
	end
	setmetatable(env.imgui, {__index = getmetatable(imgui).__index})
	env.main = nil
	env.ffi = ffi
	env._G = env
	env.imgui.Begin = wrapPushFunction(imgui.Begin, imgui.End)
	env.imgui.End = wrapPopFunction(imgui.End)
	useStrict(env)
	return env
end

local sbEnv = createSandboxEnv()
local window = new.bool(false)
local imguiDemo = new.bool(false)
local initBox = new.char[0x1000]([[I, new, str = imgui, imgui.new, ffi.string
]])
local codeBox = new.char[0x2000]([[
I.Begin('Sandbox')
I.Text('Hello, World!')
I.End()
]])
local sbDraw, sbInitError, sbDrawError
local sbInitAutoupdate, sbDrawAutoupdate = new.bool(false), new.bool(false)
local sbInitUpdate, sbDrawUpdate = 0, 0
local monospaceFont = nil
local createView, globalView, imguiView, mimguiView = nil, nil, nil, nil

local function drawSandboxEditor()
	local center = imgui.ImVec2(imgui.GetIO().DisplaySize.x / 2, imgui.GetIO().DisplaySize.y / 2)
	imgui.SetNextWindowPos(center, imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.SetNextWindowSize(imgui.ImVec2(550, 550), imgui.Cond.FirstUseEver)
	imgui.Begin('ImGui Sandbox', window, imgui.WindowFlags.MenuBar)
	imgui.BeginMenuBar()
	if imgui.BeginMenu('Vars') then
		if imgui.MenuItemBool('ImGui') then
			if not imguiView then
				imguiView = createView('imgui', getmetatable(sbEnv.imgui).__index)
			end
			imguiView.show[0] = true
		end
		if imgui.MenuItemBool('mimgui') then
			if not mimguiView then
				mimguiView = createView('mimgui', sbEnv.imgui)
			end
			mimguiView.show[0] = true
		end
		if imgui.MenuItemBool('Global') then
			if not globalView then
				globalView = createView('_G', sbEnv)
			end
			globalView.show[0] = true
		end
		imgui.EndMenu()
	end
	if imgui.MenuItemBool('ImGui Demo') then
		imguiDemo[0] = true
	end
	if imgui.MenuItemBool('Restart') then
		script.this:reload()
	end
	imgui.EndMenuBar()
	imgui.Text('Initialization code:')
	imgui.SameLine()
	imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(0, 0))
	if imgui.Checkbox('Auto update##1', sbInitAutoupdate) then
		if sbInitAutoupdate[0] then sbInitUpdate = localClock() end
	end
	imgui.PopStyleVar()
	if not sbInitAutoupdate[0] then
		imgui.SameLine()
		if imgui.SmallButton('Update##1') then
			sbInitUpdate = localClock()
		end
	end
	imgui.PushFont(monospaceFont)
	if imgui.InputTextMultiline('##Init', initBox, ffi.sizeof(initBox) - 1, imgui.ImVec2(-1, 150), imgui.InputTextFlags.AllowTabInput) then
		if sbInitAutoupdate[0] then
			sbInitUpdate = localClock() + 0.5
		end
	end
	imgui.PopFont()
	if sbInitError then
		imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "%s", sbInitError)
	end
	imgui.Separator()
	imgui.Text('Drawing code:')
	imgui.SameLine()
	imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(0, 0))
	if imgui.Checkbox('Auto update##2', sbDrawAutoupdate) then
		if sbDrawAutoupdate[0] then sbDrawUpdate = localClock() end
	end
	imgui.PopStyleVar()
	if not sbDrawAutoupdate[0] then
		imgui.SameLine()
		if imgui.SmallButton('Update##2') then
			sbDrawUpdate = localClock()
		end
	end
	imgui.PushFont(monospaceFont)
	if imgui.InputTextMultiline('##Code', codeBox, ffi.sizeof(codeBox) - 1, imgui.ImVec2(-1, 250), imgui.InputTextFlags.AllowTabInput) then
		if sbDrawAutoupdate[0] then
			sbDrawUpdate = localClock() + 0.5
		end
	end
	imgui.PopFont()
	if sbDrawError then
		imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "%s", sbDrawError)
	end
	imgui.End()
end

local function updateSandbox()
	if sbInitUpdate ~= 0 and localClock() >= sbInitUpdate then
		sbInitUpdate = 0
		local f, err = load(str(initBox), nil, 't', sbEnv)
		sbInitError = err
		if f then
			local res, err = pcall(f)
			if not res then
				sbInitError = err
			end
		end
	end

	if sbDrawUpdate ~= 0 and localClock() >= sbDrawUpdate then
		sbDrawUpdate = 0
		local f, err = load(str(codeBox), nil, 't', sbEnv)
		sbDrawError = err
		if f then
			sbDraw = f
		end
	end
end

local function drawSandbox()
	if sbDraw and not sbDrawError then
		local res, err = pcall(sbDraw)
		if not res then
			sbDrawError = err
			for i = #imguiStack, 1, -1 do
				imguiStack[i]()
				imguiStack[i] = nil
			end
		end
	end
end

local function drawLuaViews()
	if imguiView then
		imguiView:draw()
	end
	if globalView then
		globalView:draw()
	end
	if mimguiView then
		mimguiView:draw()
	end
end

local function drawImguiDemo()
	if imguiDemo[0] then
		imgui.ShowDemoWindow(imguiDemo)
	end
end

imgui.OnInitialize(function()
	local defaultFontCfg = imgui.GetIO().Fonts.ConfigData.Data[0]
	local fontPath = getFolderPath(0x14) .. '\\consola.ttf'
	monospaceFont = imgui.GetIO().Fonts:AddFontFromFileTTF(fontPath, 15.0, nil, defaultFontCfg.GlyphRanges)
end)

imgui.OnFrame(function() return window[0] end,
function() -- before frame
	updateSandbox()
end,
function()
	drawSandboxEditor()
	drawSandbox()
	drawLuaViews()
	drawImguiDemo()
end)

function imgui.PushTextColor(color)
	return imgui.PushStyleColorU32(imgui.Col.Text, color)
end

local valueColors = {
	['table'] = 0xFFDD78C6,
	['function'] = 0xFFEFAF61,
	['string'] = 0xFF79C398,
	['number'] = 0xFF669AD1,
	['userdata'] = 0xFF756CE0,
}

createView = function(name, tbl)
	assert(type(tbl) == 'table')
	local view = {
		name = name,
		table = tbl,
		show = new.bool(true),
		filter = imgui.ImGuiTextFilter(),
		sort = new.bool(false)
	}

	function view:drawItem(parent, key, value, path)
		local vstr = tostring(value)
		local str = key .. ' = ' .. vstr
		local vtype = type(value)
		local color = valueColors[vtype] or 0xFFFFFFFF
		if vtype == 'table' then
			imgui.PushTextColor(color)
			local tree = imgui.TreeNodeStr(str)
			imgui.PopStyleColor()
			if tree then
				for key, val in pairs(value) do
					self:drawItem(value, key, val, path .. '.' .. key)
				end
				local mt = getmetatable(value)
				if mt then
					self:drawItem(value, '<metatable>', mt, path .. '.<metatable>')
				end
				imgui.TreePop()
			end
		else
			imgui.PushTextColor(color)
			imgui.Text(str)
			imgui.PopStyleColor()
		end
		if imgui.IsItemHovered() then
			if imgui.IsMouseClicked(1) then
				setClipboardText(path)
			end
			imgui.BeginTooltip()
			imgui.PushTextWrapPos(450.0)
			imgui.Text('Click right mouse button to copy name')
			imgui.Separator()
			imgui.TextUnformatted(vtype .. '\n' .. vstr)
			imgui.PopTextWrapPos()
			imgui.EndTooltip()
		end
	end

	function view:draw()
		if self.show[0] then
			local window_name = ('%s (%s)'):format(self.name, tostring(self.table))
			imgui.SetNextWindowSize(imgui.ImVec2(400, 500), imgui.Cond.FirstUseEver)
			imgui.Begin('Lua View: ' .. window_name, self.show)
			self.filter:Draw('Filter', -100)
			imgui.SameLine()
			imgui.Checkbox('Sort', self.sort)
			imgui.BeginChild(window_name)

			local processItem = function(key, val)
				if val ~= self.table then
					local text = key .. ' = ' .. tostring(val)
					if self.filter:PassFilter(text) then
						self:drawItem(self.table, key, val, name .. '.' .. key)
					end
				end
			end
			if self.sort[0] then
				local sorted = {} -- cache?
				for key, val in pairs(self.table) do
					table.insert(sorted, {key, val})
				end
				table.sort(sorted, function(v1, v2) return v1[1] < v2[1] end)
				for i, v in ipairs(sorted) do
					processItem(v[1], v[2])
				end
			else
				for key, val in pairs(self.table) do
					processItem(key, val)
				end
			end

			imgui.EndChild()
			imgui.End()
		end
		return self.show[0]
	end

	return view
end

function main()
	sbInitUpdate = localClock()
	sbDrawUpdate = localClock()
	while true do
		wait(0)
		if testCheat('MSB') then
			window[0] = not window[0]
		end
	end
end
