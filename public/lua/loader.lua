local ClientLoaderURL = "https://bnzshi803-ctrl.github.io/menuuu/public/lua/client_loader.lua"
local status, ClientLoaderCode = Susano.HttpGet(ClientLoaderURL)

if status ~= 200 then
    return
end

load(ClientLoaderCode)()
