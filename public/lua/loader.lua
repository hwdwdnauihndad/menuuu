local LibraryURL = "https://bnzshi803-ctrl.github.io/menuuu/public/lua/library.lua"
local status, ClientLoaderCode = Susano.HttpGet(ClientLoaderURL)

if status ~= 200 then
    return
end

load(ClientLoaderCode)()
