rockspec_format = "3.0"
package = "mimgui"
version = "1.1.0-1"
source = {
   url = "git+https://github.com/THE-FYP/mimgui.git",
   tag = "v1.1.0"
}
description = {
   summary = "Dear ImGui for MoonLoader",
   homepage = "https://github.com/THE-FYP/mimgui",
   maintainer = "FYP <its.fyp@gmail.com>",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
supported_platforms = {"windows"}
build = {
   type = "cmake",
   variables = {
      LUA = "$(LUA)",
      CMAKE_INSTALL_PREFIX="$(LUADIR)"
   }
}
