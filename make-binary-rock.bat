:: flag `--pack-binary-rock` doesn't work well with `make` command (luarocks bug)
call luarocks make --tree=lib CMAKE_GENERATOR_TOOLSET=v141_xp
:: the `pack` command doesn't work as expected with `--tree` flag set (another luarocks bug)
call luarocks pack mimgui
