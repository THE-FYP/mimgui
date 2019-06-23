cd  LuaJIT-ImGui
git remote add upstream https://github.com/sonoro1234/LuaJIT-ImGui
git fetch upstream
git checkout master
git merge upstream/master -m "Pull latest LuaJIT-ImGui"
git submodule update --recursive
