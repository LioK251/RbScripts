local scripts = {
    [109928390521457] = "https://raw.githubusercontent.com/LioK251/RbScripts/refs/heads/main/AnimeBreaker.lua",
    [106198175232796] = "https://raw.githubusercontent.com/LioK251/RbScripts/refs/heads/main/animelegacy.lua",
}

local url = scripts[game.PlaceId]
if not url then
    warn("Lazy Hub: Unsupported game")
    return
end

local source = game:HttpGet(url)
local run, compileError = loadstring(source)
assert(run, compileError)
run()
