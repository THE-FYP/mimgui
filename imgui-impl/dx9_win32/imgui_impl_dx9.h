// ImGui Renderer for: DirectX9
// This needs to be used along with a Platform Binding (e.g. Win32)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'LPDIRECT3DTEXTURE9' as ImTextureID. Read the FAQ about ImTextureID in imgui.cpp.
//  [X] Renderer: Support for large meshes (64k+ vertices) with 16-bits indices.

// You can copy and use unmodified imgui_impl_* files in your project. See main.cpp for an example of using this.
// If you are new to dear imgui, read examples/README.txt and read the documentation at the top of imgui.cpp.
// https://github.com/ocornut/imgui

#include <d3d9.h>

struct ImGui_ImplDX9_Context
{
	LPDIRECT3DDEVICE9        pd3dDevice;
	LPDIRECT3DVERTEXBUFFER9  pVB;
	LPDIRECT3DINDEXBUFFER9   pIB;
	LPDIRECT3DTEXTURE9       FontTexture;
	int                      VertexBufferSize;
	int                      IndexBufferSize;
};

IMGUI_IMPL_API ImGui_ImplDX9_Context* ImGui_ImplDX9_Init(LPDIRECT3DDEVICE9 device);
IMGUI_IMPL_API void ImGui_ImplDX9_Shutdown(ImGui_ImplDX9_Context* context);
IMGUI_IMPL_API void ImGui_ImplDX9_NewFrame(ImGui_ImplDX9_Context* context);
IMGUI_IMPL_API void ImGui_ImplDX9_RenderDrawData(ImGui_ImplDX9_Context* context, ImDrawData* draw_data);

// Use if you want to reset your rendering device without losing ImGui state.
IMGUI_IMPL_API void ImGui_ImplDX9_InvalidateDeviceObjects(ImGui_ImplDX9_Context* context);
IMGUI_IMPL_API bool ImGui_ImplDX9_CreateFontsTexture(ImGui_ImplDX9_Context* context); // replaces ImGui_ImplDX9_CreateDeviceObjects since they are the same
IMGUI_IMPL_API void ImGui_ImplDX9_InvalidateFontsTexture(ImGui_ImplDX9_Context* context);

IMGUI_IMPL_API LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFile(LPDIRECT3DDEVICE9 device, LPCTSTR path);
IMGUI_IMPL_API LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFileInMemory(LPDIRECT3DDEVICE9 device, LPCVOID src, UINT size);
IMGUI_IMPL_API void ImGui_ImplDX9_ReleaseTexture(LPDIRECT3DTEXTURE9 tex);
