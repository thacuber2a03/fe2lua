Parser = Object:extend()

-- Grammar:
-- program -> statements EOF
-- statements -> statements statement | statement
-- statement -> ifstatement | codedef | (LPAREN (operation exprs?)? RPAREN)
-- ifstatement -> LPAREN KEYWORD(if) expr expr RPAREN | elseifstatement | expr
-- elseifstatement -> expr expr elseifstatement | elsestatement | RPAREN
-- elsestatement -> expr RPAREN
-- codedef -> ((KEYWORD(mac) | KEYWORD(fn)) params statement?))?
-- operation -> DIV | TIMES | MINUS | PLUS | EQUAL | LESS | LEQ et al.
-- params -> LPAREN ID* RPAREN
-- exprs -> expr | exprs expr
-- expr -> (INT | FLOAT | ID | STRING | statement)

function Parser:new(tokenizer)
    self:restart(tokenizer)
end

function Parser:restart(tokenizer)
    self.tokens = tokenizer:tokenize()
    self.pos = 1
    self.token_at = self.tokens[self.pos]
end

function Parser:advance()
    self.pos = self.pos + 1
    self.token_at = self.pos < #self.tokens + 1 and self.tokens[self.pos] or nil
end

function Parser:eat(tokenType)
    if self.token_at.type == tokenType then self:advance()
    else error("ParserError: Expected "..tokenType.." but got "..self.token_at.type) end
end

function Parser:program()
    local program = self:statements()
    self:eat(Token.EOF)
    return {program = program}
end

function Parser:statements()
    local statements = {}
    while self.token_at and self.token_at.type ~= Token.EOF do
        table.insert(statements, self:statement())
    end
    return {statements = statements}
end

function Parser:statement()
    self:eat(Token.LPAREN)
    if self.token_at.value == "mac" or self.token_at.value == "fn" then
        local statement = self:codedef()
        self:eat(Token.RPAREN)
        return statement
    elseif self.token_at.value == "if" then
        local statement = self:ifstatement()
        self:eat(Token.RPAREN)
        return statement
    else
        local operation = self:operation()
        local exprs = self:exprs()
        self:eat(Token.RPAREN)
        return {operation = operation, exprs = exprs}
    end
end

function Parser:ifstatement()
    local ifst = self.token_at
    self:eat(Token.KEYWORD)
    local exprs = {}
    while self.token_at and self.token_at.type ~= Token.RPAREN do
        table.insert(exprs, self:expr())
    end     
    return {operation = ifst, exprs = exprs}
end

function Parser:operation()
    local operation = self.token_at
    if operation.type ~= Token.INT
    and operation.type ~= Token.FLOAT
    and operation.type ~= Token.STRING 
    and operation.type ~= Token.TRUE
    and operation.type ~= Token.NIL then
        self:eat(operation.type)
        return operation
    else error("ParserError: Expected operation but got "..operation.type) end
end

function Parser:exprs()
    local exprs = {}
    while self.token_at and self.token_at.type ~= Token.RPAREN do
        table.insert(exprs, self:expr())
    end
    return exprs
end

function Parser:expr()
    local expr = self.token_at
    if expr.type == Token.INT
    or expr.type == Token.FLOAT
    or expr.type == Token.ID
    or expr.type == Token.STRING 
    or expr.type == Token.TRUE
    or expr.type == Token.NIL then
        self:eat(expr.type)
        return expr
    elseif expr.type == Token.LPAREN then
        return self:statement()
    else error("ParserError: Expected expression but got "..expr.type) end
end

function Parser:codedef()
    local codedef = self.token_at
    local name = (codedef.value == "mac" and "mac") or "fn"
    self:eat(codedef.type)
    local params = self:params()
    local statement
    if self.token_at.type == Token.LPAREN then statement = self:statement() end
    return {name = name, params = params, statement = statement}
end

function Parser:params()
    if self.token_at.type == Token.LPAREN then
        local params = {}
        self:eat(Token.LPAREN)
        while self.token_at and self.token_at.type ~= Token.RPAREN do
            table.insert(params, self.token_at)
            self:eat(Token.ID)
        end
        self:eat(Token.RPAREN)
        return params
    else error("ParserError: parameters are required") end
end

function Parser:parse()
    return self:program()
end

return Parser