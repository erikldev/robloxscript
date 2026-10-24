print("TESTE 1: executor funciona")

local ok, result = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/erikldev/robloxscript/main/main.lua", true)
end)

if ok then
    print("TESTE 1: baixou", #result, "bytes")
    print("Primeiros 100 chars:", result:sub(1, 100))
else
    warn("TESTE 1 FALHOU:", result)
end
