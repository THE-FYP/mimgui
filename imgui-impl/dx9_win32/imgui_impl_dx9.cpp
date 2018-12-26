// ImGui Renderer for: DirectX9
// This needs to be used along with a Platform Binding (e.g. Win32)

// Implemented features:
//  [X] Renderer: User texture binding. Use 'LPDIRECT3DTEXTURE9' as ImTextureID. Read the FAQ about ImTextureID in imgui.cpp.

// You can copy and use unmodified imgui_impl_* files in your project. See main.cpp for an example of using this.
// If you are new to dear imgui, read examples/README.txt and read the documentation at the top of imgui.cpp.
// https://github.com/ocornut/imgui

// CHANGELOG 
// (minor and older changes stripped away, please see git history for details)
//  2018-06-08: Misc: Extracted imgui_impl_dx9.cpp/.h away from the old combined DX9+Win32 example.
//  2018-06-08: DirectX9: Use draw_data->DisplayPos and draw_data->DisplaySize to setup projection matrix and clipping rectangle.
//  2018-05-07: Render: Saving/restoring Transform because they don't seem to be included in the StateBlock. Setting shading mode to Gouraud.
//  2018-02-16: Misc: Obsoleted the io.RenderDrawListsFn callback and exposed ImGui_ImplDX9_RenderDrawData() in the .h file so you can call it yourself.
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.

#include "imgui.h"
#include "imgui_impl_dx9.h"

// DirectX
#include <d3dx9tex.h>
#define DIRECTINPUT_VERSION 0x0800
#include <dinput.h>

struct CUSTOMVERTEX
{
    float    pos[3];
    D3DCOLOR col;
    float    uv[2];
};
#define D3DFVF_CUSTOMVERTEX (D3DFVF_XYZ|D3DFVF_DIFFUSE|D3DFVF_TEX1)

// Render function.
// (this used to be set in io.RenderDrawListsFn and called by ImGui::Render(), but you can now call this directly from your main loop)
IMGUI_IMPL_API void ImGui_ImplDX9_RenderDrawData(ImGui_ImplDX9_Context* context, ImDrawData* draw_data)
{
    // Avoid rendering when minimized
    if (draw_data->DisplaySize.x <= 0.0f || draw_data->DisplaySize.y <= 0.0f)
        return;

    // Create and grow buffers if needed
    if (!context->pVB || context->VertexBufferSize < draw_data->TotalVtxCount)
    {
        if (context->pVB) { context->pVB->Release(); context->pVB = NULL; }
        context->VertexBufferSize = draw_data->TotalVtxCount + 5000;
        if (context->pd3dDevice->CreateVertexBuffer(context->VertexBufferSize * sizeof(CUSTOMVERTEX), D3DUSAGE_DYNAMIC | D3DUSAGE_WRITEONLY, D3DFVF_CUSTOMVERTEX, D3DPOOL_DEFAULT, &context->pVB, NULL) < 0)
            return;
    }
    if (!context->pIB || context->IndexBufferSize < draw_data->TotalIdxCount)
    {
        if (context->pIB) { context->pIB->Release(); context->pIB = NULL; }
        context->IndexBufferSize = draw_data->TotalIdxCount + 10000;
        if (context->pd3dDevice->CreateIndexBuffer(context->IndexBufferSize * sizeof(ImDrawIdx), D3DUSAGE_DYNAMIC | D3DUSAGE_WRITEONLY, sizeof(ImDrawIdx) == 2 ? D3DFMT_INDEX16 : D3DFMT_INDEX32, D3DPOOL_DEFAULT, &context->pIB, NULL) < 0)
            return;
    }

    // Backup the DX9 state
    IDirect3DStateBlock9* d3d9_state_block = NULL;
    if (context->pd3dDevice->CreateStateBlock(D3DSBT_ALL, &d3d9_state_block) < 0)
        return;

    // Backup the DX9 transform (DX9 documentation suggests that it is included in the StateBlock but it doesn't appear to)
    D3DMATRIX last_world, last_view, last_projection;
    context->pd3dDevice->GetTransform(D3DTS_WORLD, &last_world);
    context->pd3dDevice->GetTransform(D3DTS_VIEW, &last_view);
    context->pd3dDevice->GetTransform(D3DTS_PROJECTION, &last_projection);

    // Copy and convert all vertices into a single contiguous buffer, convert colors to DX9 default format.
    // FIXME-OPT: This is a waste of resource, the ideal is to use imconfig.h and
    //  1) to avoid repacking colors:   #define IMGUI_USE_BGRA_PACKED_COLOR
    //  2) to avoid repacking vertices: #define IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT struct ImDrawVert { ImVec2 pos; float z; ImU32 col; ImVec2 uv; }
    CUSTOMVERTEX* vtx_dst;
    ImDrawIdx* idx_dst;
    if (context->pVB->Lock(0, (UINT)(draw_data->TotalVtxCount * sizeof(CUSTOMVERTEX)), (void**)&vtx_dst, D3DLOCK_DISCARD) < 0)
        return;
    if (context->pIB->Lock(0, (UINT)(draw_data->TotalIdxCount * sizeof(ImDrawIdx)), (void**)&idx_dst, D3DLOCK_DISCARD) < 0)
        return;
    for (int n = 0; n < draw_data->CmdListsCount; n++)
    {
        const ImDrawList* cmd_list = draw_data->CmdLists[n];
        const ImDrawVert* vtx_src = cmd_list->VtxBuffer.Data;
        for (int i = 0; i < cmd_list->VtxBuffer.Size; i++)
        {
            vtx_dst->pos[0] = vtx_src->pos.x;
            vtx_dst->pos[1] = vtx_src->pos.y;
            vtx_dst->pos[2] = 0.0f;
            vtx_dst->col = (vtx_src->col & 0xFF00FF00) | ((vtx_src->col & 0xFF0000) >> 16) | ((vtx_src->col & 0xFF) << 16);     // RGBA --> ARGB for DirectX9
            vtx_dst->uv[0] = vtx_src->uv.x;
            vtx_dst->uv[1] = vtx_src->uv.y;
            vtx_dst++;
            vtx_src++;
        }
        memcpy(idx_dst, cmd_list->IdxBuffer.Data, cmd_list->IdxBuffer.Size * sizeof(ImDrawIdx));
        idx_dst += cmd_list->IdxBuffer.Size;
    }
    context->pVB->Unlock();
    context->pIB->Unlock();
    context->pd3dDevice->SetStreamSource(0, context->pVB, 0, sizeof(CUSTOMVERTEX));
    context->pd3dDevice->SetIndices(context->pIB);
    context->pd3dDevice->SetFVF(D3DFVF_CUSTOMVERTEX);

    // Setup viewport
    D3DVIEWPORT9 vp;
    vp.X = vp.Y = 0;
    vp.Width = (DWORD)draw_data->DisplaySize.x;
    vp.Height = (DWORD)draw_data->DisplaySize.y;
    vp.MinZ = 0.0f;
    vp.MaxZ = 1.0f;
    context->pd3dDevice->SetViewport(&vp);

    // Setup render state: fixed-pipeline, alpha-blending, no face culling, no depth testing, shade mode (for gradient)
    context->pd3dDevice->SetPixelShader(NULL);
    context->pd3dDevice->SetVertexShader(NULL);
    context->pd3dDevice->SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
    context->pd3dDevice->SetRenderState(D3DRS_LIGHTING, false);
    context->pd3dDevice->SetRenderState(D3DRS_ZENABLE, false);
    context->pd3dDevice->SetRenderState(D3DRS_ALPHABLENDENABLE, true);
    context->pd3dDevice->SetRenderState(D3DRS_ALPHATESTENABLE, false);
    context->pd3dDevice->SetRenderState(D3DRS_BLENDOP, D3DBLENDOP_ADD);
    context->pd3dDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
    context->pd3dDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
    context->pd3dDevice->SetRenderState(D3DRS_SCISSORTESTENABLE, true);
    context->pd3dDevice->SetRenderState(D3DRS_SHADEMODE, D3DSHADE_GOURAUD);
    context->pd3dDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
    context->pd3dDevice->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    context->pd3dDevice->SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
    context->pd3dDevice->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    context->pd3dDevice->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    context->pd3dDevice->SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
    context->pd3dDevice->SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
    context->pd3dDevice->SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);

    // Setup orthographic projection matrix
    // Our visible imgui space lies from draw_data->DisplayPps (top left) to draw_data->DisplayPos+data_data->DisplaySize (bottom right).
    // Being agnostic of whether <d3dx9.h> or <DirectXMath.h> can be used, we aren't relying on D3DXMatrixIdentity()/D3DXMatrixOrthoOffCenterLH() or DirectX::XMMatrixIdentity()/DirectX::XMMatrixOrthographicOffCenterLH()
    {
        float L = draw_data->DisplayPos.x + 0.5f;
        float R = draw_data->DisplayPos.x + draw_data->DisplaySize.x + 0.5f;
        float T = draw_data->DisplayPos.y + 0.5f;
        float B = draw_data->DisplayPos.y + draw_data->DisplaySize.y + 0.5f;
        D3DMATRIX mat_identity = { { 1.0f, 0.0f, 0.0f, 0.0f,  0.0f, 1.0f, 0.0f, 0.0f,  0.0f, 0.0f, 1.0f, 0.0f,  0.0f, 0.0f, 0.0f, 1.0f } };
        D3DMATRIX mat_projection =
        {
            2.0f/(R-L),   0.0f,         0.0f,  0.0f,
            0.0f,         2.0f/(T-B),   0.0f,  0.0f,
            0.0f,         0.0f,         0.5f,  0.0f,
            (L+R)/(L-R),  (T+B)/(B-T),  0.5f,  1.0f,
        };
        context->pd3dDevice->SetTransform(D3DTS_WORLD, &mat_identity);
        context->pd3dDevice->SetTransform(D3DTS_VIEW, &mat_identity);
        context->pd3dDevice->SetTransform(D3DTS_PROJECTION, &mat_projection);
    }

    // Render command lists
    int vtx_offset = 0;
    int idx_offset = 0;
    ImVec2 pos = draw_data->DisplayPos;
    for (int n = 0; n < draw_data->CmdListsCount; n++)
    {
        const ImDrawList* cmd_list = draw_data->CmdLists[n];
        for (int cmd_i = 0; cmd_i < cmd_list->CmdBuffer.Size; cmd_i++)
        {
            const ImDrawCmd* pcmd = &cmd_list->CmdBuffer[cmd_i];
            if (pcmd->UserCallback)
            {
                pcmd->UserCallback(cmd_list, pcmd);
            }
            else
            {
                const RECT r = { (LONG)(pcmd->ClipRect.x - pos.x), (LONG)(pcmd->ClipRect.y - pos.y), (LONG)(pcmd->ClipRect.z - pos.x), (LONG)(pcmd->ClipRect.w - pos.y) };
                const LPDIRECT3DTEXTURE9 texture = (LPDIRECT3DTEXTURE9)pcmd->TextureId;
                context->pd3dDevice->SetTexture(0, texture);
                context->pd3dDevice->SetScissorRect(&r);
                context->pd3dDevice->DrawIndexedPrimitive(D3DPT_TRIANGLELIST, vtx_offset, 0, (UINT)cmd_list->VtxBuffer.Size, idx_offset, pcmd->ElemCount/3);
            }
            idx_offset += pcmd->ElemCount;
        }
        vtx_offset += cmd_list->VtxBuffer.Size;
    }

    // Restore the DX9 transform
    context->pd3dDevice->SetTransform(D3DTS_WORLD, &last_world);
    context->pd3dDevice->SetTransform(D3DTS_VIEW, &last_view);
    context->pd3dDevice->SetTransform(D3DTS_PROJECTION, &last_projection);

    // Restore the DX9 state
    d3d9_state_block->Apply();
    d3d9_state_block->Release();
}

IMGUI_IMPL_API ImGui_ImplDX9_Context* ImGui_ImplDX9_Init(LPDIRECT3DDEVICE9 device)
{
	if (!device)
		return NULL;
	ImGui_ImplDX9_Context* context = new ImGui_ImplDX9_Context;
    context->pd3dDevice = device;
	context->pVB = NULL;
	context->pIB = NULL;
	context->FontTexture = NULL;
	context->VertexBufferSize = 5000;
	context->IndexBufferSize = 10000;
    return context;
}

IMGUI_IMPL_API void ImGui_ImplDX9_Shutdown(ImGui_ImplDX9_Context* context)
{
	if (!context)
		return;
    ImGui_ImplDX9_InvalidateDeviceObjects(context);
	delete context;
}

IMGUI_IMPL_API bool ImGui_ImplDX9_CreateFontsTexture(ImGui_ImplDX9_Context* context)
{
	if (!context->pd3dDevice || context->FontTexture)
		return false;

    // Build texture atlas
    ImGuiIO& io = ImGui::GetIO();
    unsigned char* pixels;
    int width, height, bytes_per_pixel;
    io.Fonts->GetTexDataAsRGBA32(&pixels, &width, &height, &bytes_per_pixel);

    // Upload texture to graphics system
    context->FontTexture = NULL;
    if (context->pd3dDevice->CreateTexture(width, height, 1, D3DUSAGE_DYNAMIC, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, &context->FontTexture, NULL) < 0)
        return false;
    D3DLOCKED_RECT tex_locked_rect;
    if (context->FontTexture->LockRect(0, &tex_locked_rect, NULL, 0) != D3D_OK)
        return false;
    for (int y = 0; y < height; y++)
        memcpy((unsigned char *)tex_locked_rect.pBits + tex_locked_rect.Pitch * y, pixels + (width * bytes_per_pixel) * y, (width * bytes_per_pixel));
    context->FontTexture->UnlockRect(0);

    // Store our identifier
    io.Fonts->TexID = (ImTextureID)context->FontTexture;

    return true;
}

IMGUI_IMPL_API void ImGui_ImplDX9_InvalidateFontsTexture(ImGui_ImplDX9_Context* context)
{
	if (!context->FontTexture)
		return;
	// At this point note that we set ImGui::GetIO().Fonts->TexID to be == context->FontTexture, so clear both.
	ImGuiIO& io = ImGui::GetIO();
	IM_ASSERT(context->FontTexture == io.Fonts->TexID);
	context->FontTexture->Release();
	context->FontTexture = NULL;
	io.Fonts->TexID = NULL;
}

IMGUI_IMPL_API void ImGui_ImplDX9_InvalidateDeviceObjects(ImGui_ImplDX9_Context* context)
{
    if (!context->pd3dDevice)
        return;
    if (context->pVB)
    {
        context->pVB->Release();
        context->pVB = NULL;
    }
    if (context->pIB)
    {
        context->pIB->Release();
        context->pIB = NULL;
    }
	ImGui_ImplDX9_InvalidateFontsTexture(context);
}

IMGUI_IMPL_API void ImGui_ImplDX9_NewFrame(ImGui_ImplDX9_Context* context)
{
    if (!context->FontTexture)
		ImGui_ImplDX9_CreateFontsTexture(context);
}

IMGUI_IMPL_API LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFile(LPDIRECT3DDEVICE9 device, LPCTSTR path)
{
	LPDIRECT3DTEXTURE9 tex = NULL;
	if (D3DXCreateTextureFromFile(device, path, &tex) != D3D_OK)
		return NULL;
	return tex;
}

IMGUI_IMPL_API LPDIRECT3DTEXTURE9 ImGui_ImplDX9_CreateTextureFromFileInMemory(LPDIRECT3DDEVICE9 device, LPCVOID src, UINT size)
{
	LPDIRECT3DTEXTURE9 tex = NULL;
	if (D3DXCreateTextureFromFileInMemory(device, src, size, &tex) != D3D_OK)
		return NULL;
	return tex;
}

IMGUI_IMPL_API void ImGui_ImplDX9_ReleaseTexture(LPDIRECT3DTEXTURE9 tex)
{
	if (tex)
		tex->Release();
}
