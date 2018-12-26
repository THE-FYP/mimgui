// ImGui Platform Binding for: Windows (standard windows API for 32 and 64 bits applications)
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)

// Implemented features:
//  [X] Platform: Clipboard support (for Win32 this is actually part of core imgui)
//  [X] Platform: Mouse cursor shape and visibility. Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'.
//  [X] Platform: Keyboard arrays indexed using VK_* Virtual Key Codes, e.g. ImGui::IsKeyPressed(VK_SPACE).

#include <windows.h>

IMGUI_IMPL_API bool     ImGui_ImplWin32_Init(HWND hwnd, INT64* ticksPerSecond, INT64* time);
IMGUI_IMPL_API void     ImGui_ImplWin32_NewFrame(HWND hwnd, INT64 ticksPerSecond, INT64* time);
IMGUI_IMPL_API LRESULT  ImGui_ImplWin32_WndProcHandler(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
