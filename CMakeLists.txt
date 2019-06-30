cmake_minimum_required(VERSION 3.13)
project(mimgui VERSION 1.6.2)

# configure cmake
set(CMAKE_SHARED_LIBRARY_PREFIX "")

# set cimgui sources
set(CIMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/LuaJIT-ImGui/cimgui")
set(IMGUI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/LuaJIT-ImGui/cimgui/imgui")
set(IMGUI_SOURCES "${CIMGUI_DIR}/cimgui.cpp" "${IMGUI_DIR}/imgui.cpp" "${IMGUI_DIR}/imgui_draw.cpp" "${IMGUI_DIR}/imgui_demo.cpp" "${IMGUI_DIR}/imgui_widgets.cpp")
set(IMGUI_SOURCES_IMPL_DX9 imgui-impl/dx9_win32/imgui_impl_dx9.cpp imgui-impl/dx9_win32/imgui_impl_win32.cpp)

# rebuild cimgui sources
set(LUA "lua" CACHE STRING "Lua interpreter")
file(TO_NATIVE_PATH "${LUA}" LUA)
execute_process(COMMAND "${LUA}" generator.lua gcc WORKING_DIRECTORY "${CIMGUI_DIR}/generator" RESULT_VARIABLE RET)
if (NOT "${RET}" EQUAL "0")
  message(FATAL_ERROR "Error running lua: ${RET}")
endif()

# cimgui target: bare cimgui + custom dx9 imgui renderer
add_library(cimguidx9 SHARED ${IMGUI_SOURCES} ${IMGUI_SOURCES_IMPL_DX9})
target_include_directories(cimguidx9 PUBLIC "${CIMGUI_DIR}" "${IMGUI_DIR}" imgui-impl "$ENV{DXSDK_DIR}/Include")
target_link_libraries(cimguidx9 PUBLIC "$ENV{DXSDK_DIR}/Lib/x86/d3dx9.lib")
target_compile_definitions(cimguidx9 PUBLIC
  -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
  "-DIMGUI_IMPL_API=extern \"C\" __declspec\(dllexport\)"
  -D_USING_V110_SDK71
  -D_WIN32_WINNT=0x0501
)
target_compile_options(cimguidx9 PUBLIC /Zc:threadSafeInit-)
target_link_options(cimguidx9 PUBLIC /SUBSYSTEM:WINDOWS)

# mimgui target: LuaJIT-ImGui-generated bindings with some changes
file(TO_NATIVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/lua/imgui_base.lua" IMGUI_BASE_LUA)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/lua/imgui_base_cdefs.lua" IMGUI_CDEFS_LUA)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/imgui.lua" IMGUI_LUA_OUT)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/cdefs.lua" CDEFS_LUA_OUT)
add_custom_command(OUTPUT "${IMGUI_LUA_OUT}" "${CDEFS_LUA_OUT}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/LuaJIT-ImGui/lua"
  COMMAND "${LUA}" generator.lua "${IMGUI_CDEFS_LUA}" "${CDEFS_LUA_OUT}" "${IMGUI_BASE_LUA}" "${IMGUI_LUA_OUT}"
  VERBATIM
)
add_custom_target(mimgui ALL DEPENDS "${IMGUI_LUA_OUT}" "${CDEFS_LUA_OUT}")

# installation rules
install(TARGETS cimguidx9 RUNTIME DESTINATION "${LUALIBDIR}/mimgui")
install(FILES lua/dx9.lua lua/init.lua "${IMGUI_LUA_OUT}" "${CDEFS_LUA_OUT}" DESTINATION "${LUADIR}/mimgui")
