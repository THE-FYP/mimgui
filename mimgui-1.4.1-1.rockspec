rockspec_format = "3.0"
package = "mimgui"
version = "1.4.1-1"
source = {
   url = "git+https://github.com/THE-FYP/mimgui.git",
   tag = "v1.4.1"
}
description = {
   summary = "Dear ImGui for MoonLoader",
   homepage = "https://github.com/THE-FYP/mimgui",
   license = "MIT",
   maintainer = "FYP <its.fyp@gmail.com>"
}
supported_platforms = {
   "windows"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
build = {
   type = "cmake",
   variables = {
      LUADIR = "$(LUADIR)",
      LUALIBDIR = "$(LIBDIR)",
      LUA = "$(LUA)"
   }
}
