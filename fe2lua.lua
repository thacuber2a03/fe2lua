Object    = require 'classic'
Token     = require 'token'
Tokenizer = require 'tokenizer'
Parser    = require 'parser'
Compiler  = require 'compiler'

local fe2lua = {}

function fe2lua.compile(feCode)
    local tokenizer = Tokenizer(feCode)
    local parser = Parser(tokenizer)
    local compiler = Compiler(parser)
    return compiler:compile()
end

function fe2lua.compileFile(feFile, outFile)
    local file = assert(io.open(feFile, "r"))
    local feCode = file:read("*all")
    file:close()
    local luaCode = fe2lua.compile(feCode)
    if outFile then
        local file = assert(io.open(outFile, "w"))
        file:write(luaCode)
        file:close()
    else return luaCode end
end

return fe2lua