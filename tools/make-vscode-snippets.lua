local json = require 'dkjson'
local fmt = string.format

local output = ({...})[1]
local fundefs = dofile([[..\LuaJIT-ImGui\cimgui\generator\output\definitions.lua]])
local structs_enums = dofile([[..\LuaJIT-ImGui\cimgui\generator\output\structs_and_enums.lua]])
local structdefs, enumdefs = structs_enums.structs, structs_enums.enums
local typedefs = dofile([[..\LuaJIT-ImGui\cimgui\generator\output\typedefs_dict.lua]])

snippets = {}
function add_snippet(name, prefix, body, desc)
    snippets['imgui.'..name] = {
        prefix = prefix,
        scope = 'lua',
        body = body,
        description = desc .. '\n\n'
    }
end

function print_json(data)
    print(json.encode(data, {indent = true}))
end

function save_json(data, out)
    local f = io.open(out, 'w')
    f:write(json.encode(data, {indent = true}))
    f:close()
end

function make_typedefs()
    local skip = {const_iterator=1,iterator=1,value_type=1}
    for k, v in pairs(typedefs) do
        if not skip[k] then
            add_snippet(k, 'new.'..k, 'new.'..k..'($1)', 'typedef '..v..' '..k)
        end
    end
end

function make_functions()
    for k, defs in pairs(fundefs) do
        for _, def in ipairs(defs) do
            if not def.nonUDT and not def.constructor and not def.destructor then
                local ovfname = def.ov_cimguiname or def.cimguiname
                local st = def.stname
                if #st == 0 then st = nil end
                ovfname = st and ovfname:match('^'..st..'_(.*)') or ovfname:match('^ig(.*)')
                if ovfname == 'end' then ovfname = '_end' end
                local prefix = st and st..':' or 'imgui.'
				if not def.argsoriginal then
					def.argsoriginal = def.args
				end
                local argsoriginal = def.argsoriginal:gsub(',([^ ])', ', %1')
                local desc = fmt('[C++] %s %s::%s%s', def.ret, st and def.stname or def.namespace, def.funcname, argsoriginal)
                local idx = 1
                local callargs = def.call_args:gsub('(,?)([%w_]+)', function(comma, name)
                    local default_value = def.defaults[name]
                    local result
                    if default_value then
                        result = fmt('${%d:[%s%s=%s]}', idx, (#comma > 0 and ', ' or ''), name, default_value)
                    else
                        result = fmt('%s${%d:%s}', (#comma > 0 and ', ' or ''), idx, name)
                    end
                    idx = idx + 1
                    return result
                end)
                add_snippet(def.ov_cimguiname or def.cimguiname, prefix..def.funcname, prefix..ovfname..callargs, desc)
            end
        end
    end
end

function make_mimgui_enums()
    for name, enum in pairs(enumdefs) do
        local trimmed_name = name:match('^Im(.*)_$')
        trimmed_name = trimmed_name:match('^Gui(.*)') or trimmed_name
        for i, val in ipairs(enum) do
            local val_name = val.name:sub(#name + 1)
            local enum_var = fmt('imgui.%s.%s', trimmed_name, val_name)
            add_snippet(val.name, enum_var, enum_var, fmt('[C++] %s = %s', val.name, val.value))
        end
    end
end

function make_structs()
    for name, fields in pairs(structdefs) do
        for i, field in ipairs(fields) do
            if field.name:match('[%w_]+') then -- skip fields with corrupted names (Pair)
                local full_name = name..'.'..field.name
                if name:sub(1, 2) ~= 'Im' then
                    full_name = 'imgui.'..full_name
                end
                local desc = fmt('[C++] %s %s::%s', field.type, name, field.name)
                add_snippet(name..'.'..field.name, full_name, full_name, desc)
            end
        end
    end
end

function make_mimgui_snippets()
    local vars = {
        {name='HideCursor', type='bool'},
        {name='LockPlayer', type='bool'},
        {name='DisableInput', type='bool'},
        {name='_VERSION', type='string'},
    }
    local functions = {
        {name='OnInitialize', args='${1:callback}', ret='function unsubscribe'},
        {name='OnFrame', args='${1:condCallback}${2:[, beforeFrameCallback]}, ${3:drawFrameCallback}', ret='function unsubscribe'},
        {name='SwitchContext', args=''},
        {name='CreateTextureFromFile', args='${1:path}', ret='cdata<LPDIRECT3DTEXTURE9> tex'},
        {name='CreateTextureFromFileInMemory', args='${1:src}, ${2:size}', ret='cdata<LPDIRECT3DTEXTURE9> tex'},
        {name='ReleaseTexture', args='${1:tex}'},
        {name='CreateFontsTexture', args='', ret='bool success'},
        {name='InvalidateFontsTexture', args=''},
        {name='GetRenderer', args='', ret='table dx9renderer'},
        {name='IsInitialized', args='', ret='bool status'},
        {name='StrCopy', args='${1:dst}, ${2:src}${3:[, len]}'}
    }
    for i, v in ipairs(vars) do
        add_snippet(v.name, 'imgui.'..v.name, 'imgui.'..v.name, '[mimgui variable]\n\nType: '..v.type)
    end
    for i, v in ipairs(functions) do
        local desc_ret = v.ret and '\n\nReturns: '..v.ret or ''
        add_snippet(v.name, 'imgui.'..v.name, fmt('imgui.%s(%s)', v.name, v.args), '[mimgui function]'..desc_ret)
    end

    add_snippet('new', 'imgui.new', 'imgui.new', [[[mimgui special type]

Usage:
-- alloc var TYPE[1]
new.TYPE()
-- same. alloc var TYPE[1]
new.TYPE[1]()
-- alloc var TYPE[10][20]
new.TYPE[10][20]()
-- alloc var with initializer values
new.TYPE[2](init1, init2)
-- alloc var TYPE (not TYPE[1]) with initializer value
new('TYPE', init1)]])
end

make_mimgui_snippets()
make_functions()
make_mimgui_enums()
make_structs()
make_typedefs()
--print_json(snippets)
save_json(snippets, output)
