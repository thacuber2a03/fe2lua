local fe2lua = require 'fe2lua'

function pconcat(t, indent)
    indent = indent or ""
    local str = ""
    for k,v in pairs(t) do
        if type(v) == "table" and v.name ~= "Token" then
            -- If the table is empty, append "{}"
            if next(v) == nil then
                str = str .. indent .. k .. "= {}\n"
            else
                if type(k) ~= "number" then str = str .. indent .. k .. " = {\n"
                else str = str .. indent .. "{\n" end
                str = str .. pconcat(v, indent .. "  ")
                str = str .. indent .. (next(t, k) and "},\n" or "}\n")
            end
        else
            if type(k) ~= "number" then str = str .. indent .. k .. " = " .. tostring(v)
            else str = str .. indent .. tostring(v) end
            str = str .. (next(t, k) and ",\n" or "\n")
        end
    end
    return str
end

if #arg == 0 then
    while true do
        io.write(">> ")
        local line = io.read()
        if not line then break end
        if line ~= "" then print(fe2lua.compile(line)) end
    end
else
    fe2lua.compileFile(arg[1], arg[2])
end