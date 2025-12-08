local ClientLoaderURL = "https://raw.githubusercontent.com/bnzshi803-ctrl/menuuu/main/public/lua/client_loader.lua"
local status, ClientLoaderCode = Susano.HttpGet(ClientLoaderURL)

if status ~= 200 then
    return
end

load(ClientLoaderCode)()
