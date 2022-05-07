Compiler = Object:extend()

function Compiler:new(parser)
    self:restart(parser)
end

function Compiler:restart(parser)
    self.ast = parser:parse()
    self.indentdepth = 0
end

function Compiler:unindent()
    self.indentdepth = self.indentdepth - 1
end

function Compiler:indent()
    self.indentdepth = self.indentdepth + 1
end

function Compiler:getIndent()
    return self.indentdepth > 0 and string.rep("\t", self.indentdepth) or ""
end

-- there is no need for this
function Compiler:compileProgram()
    return self:compileStatements(self.ast.program.statements)
end

function Compiler:compileStatements(sts)
    local statements = ""
    for _, statement in pairs(sts) do
        statements = statements .. self:compileStatement(statement) .. "\n"
    end
    return statements 
end

function Compiler:assertArgLen(op, len)
    if op.exprs ~= len then
        error("CompilerError: Wrong number of arguments for " .. op.name .. ": " .. #op.exprs .. " instead of " .. len)
    end
end

function Compiler:compileStatement(statement)
    if statement.name == "fn" then return self:compileFunction(statement) end

    local op = statement.operation
    local expr1 = statement.exprs[1] and self:compileExpr(statement.exprs[1]) or nil
    local expr2 = statement.exprs[2] and self:compileExpr(statement.exprs[2]) or nil

    -- Assignment
    if op.type == Token.EQUAL then return self:compileAssignment(statement)  
    elseif op.value == "let" then return "local " .. self:compileAssignment(statement)

    -- Arithmetic
    elseif op.type == Token.PLUS
        or op.type == Token.MINUS 
        or op.type == Token.DIV
        or op.type == Token.TIMES
        or op.type == Token.LESS
        or op.type == Token.LEQ then
        return self:compileVarargs(statement.exprs, op.value)
    
    -- Logical operators
    elseif op.value == "and" or op.value == "or" then return self:compileVarargs(statement.exprs, op.value)
    elseif op.value == "not" then
        if #statement.exprs == 1 then return "not "..self:compileExpr(statement.exprs[1])
        else self:assertArgLen(statement, 2) end
        
    elseif op.value == "do" then return self:compileDo(statement)
    elseif op.value == "fn" then return self:compileFunction(statement)
    
    -- Comparison
    elseif op.value == "is" then
        return expr1 .. " == " .. expr2
    
    -- Pairs
    elseif op.value == "cons" then return "{car = "..expr1..", cdr = "..expr2.."}"
    elseif op.value == "car" or op.value == "cdr" then return expr1.."."..op.value
    elseif op.value == "setcar" or op.value == "setcdr" then
        -- NOTE: Behavior can be replicated using (= ((car|cdr) pair) val)
        return expr1 .. "." .. op.value:sub(4, 7) .. " = ".. expr2
    
    -- Control statements
    elseif op.value == "if" then return self:compileIf(statement)
    elseif op.value == "while" then return self:compileWhile(statement)
    
    -- Other
    elseif op.value == "list" then return self:compileExprs(statement.exprs)
    -- In any other case, assume it's a function call
    else return statement.operation.value .. "("..self:compileExprs(statement.exprs)..")" end

    -- Just in case
    error("CompilerError: unrecognized operation: "..op.value)
end

function Compiler:compileAssignment(statement)
    local lhs = self:compileExpr(statement.exprs[1])
    local rhs = self:compileExpr(statement.exprs[2])
    return lhs .. " = " .. rhs
end

function Compiler:compileExprs(exps)
    local exprs = ""
    for i=1, #exps do
        exprs = exprs .. self:compileExpr(exps[i])
        if i ~= #exps then exprs = exprs .. ", " end
    end
    return exprs
end

function Compiler:compileExpr(expr)
    -- No need to process a primitive.
    if expr.type == Token.INT
    or expr.type == Token.FLOAT
    or expr.type == Token.STRING
    or expr.type == Token.ID then
        return expr.value
    end

    -- For booleans however, there is absolutely no false.
    if expr.type == Token.TRUE
    or expr.type == Token.NIL then
        return expr.type == Token.TRUE and "true" or "nil"
    end

    if expr.operation or expr.name == "fn" or expr.name == "mac" then return self:compileStatement(expr) end
    error("CompilerError: unrecognized expression")
end

function Compiler:compileVarargs(exprs, delimiter, join)
    local st = ""
    for k,expr in pairs(exprs) do
        st = st .. self:compileExpr(expr)
        local toconcat = " "..delimiter.." "
        if join then toconcat = delimiter end
        if next(exprs,k) then st = st .. toconcat end
    end
    return st
end

function Compiler:compileDo(statement)
    local ret = "(function()\n"
    self:indent()
    for i=1, #statement.exprs do
        local expr = statement.exprs[i]
        local toconcat = self:compileExpr(expr) .. "\n"
        if i == #statement.exprs then
            if not toconcat:find("=") then toconcat = "return " .. toconcat end
        end
        ret = ret .. self:getIndent() .. toconcat
    end
    self:unindent()
    ret = ret .. "end)()"
    return ret
end

function Compiler:compileFunction(statement)
    local ret = "function("
    ret = ret .. self:compileVarargs(statement.params, ", ", true)
    ret = ret .. ")"
    if statement.statement then
        ret = ret .. " return "
        ret = ret .. self:compileStatement(statement.statement)
    end
    ret = ret .. " end"
    return ret
end

function Compiler:compileIf(statement)
    local ret = "(function()\n"
    self:indent()
    ret = ret .. self:getIndent() .. "if "
    local currentExpr = 1
    local haselsecase = #statement.exprs%2 ~= 0

    ret = ret .. self:compileExpr(statement.exprs[currentExpr]) .. " then return "
    currentExpr = currentExpr + 1
    ret = ret .. self:compileExpr(statement.exprs[currentExpr]) .. (#statement.exprs > 2 and "\n" or " ")
    currentExpr = currentExpr + 1

    if #statement.exprs > 2 then
        while currentExpr <= #statement.exprs - (haselsecase and 1 or 0) do
            --if not statement.exprs[currentExpr+1] then print("Breaking") break end
            local toconcat = ""
            toconcat = toconcat .. self:getIndent() .. "elseif " .. self:compileExpr(statement.exprs[currentExpr]) .. " then "
            currentExpr = currentExpr + 1
            toconcat = toconcat .. "return " .. self:compileExpr(statement.exprs[currentExpr]) .. " "
            currentExpr = currentExpr + 1
            ret = ret .. toconcat
        end
    end
    
    if haselsecase then ret = ret .. "\nelse return " .. self:compileExpr(statement.exprs[currentExpr]) .. " end\n"
    else ret = ret .. "end\n" end
    self:unindent()
    ret = ret .. self:getIndent() .. "end)()\n"
    return ret
end

function Compiler:compileWhile(statement)
    local ret = "while "
    local currentExpr = 1
    ret = ret .. self:compileExpr(statement.exprs[currentExpr]) .. " do\n"
    self:indent()
    currentExpr = currentExpr + 1
    while currentExpr <= #statement.exprs do
        ret = ret .. self:getIndent() .. self:compileExpr(statement.exprs[currentExpr]) .. "\n"
        currentExpr = currentExpr + 1
    end
    self:unindent()
    ret = ret .. self:getIndent() .. "end\n"  
    return ret
end

function Compiler:compile()
    return self:compileProgram()
end

return Compiler