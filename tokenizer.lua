local Tokenizer = Object:extend()

function Tokenizer:new(sourceCode)
    self:restart(sourceCode)
end

function Tokenizer:advance()
    self.pos = self.pos + 1
    self.currentChar = self.pos < #self.code + 1 and self.code:sub(self.pos,self.pos) or nil
end

function Tokenizer:peek()    
    local peekAt = self.pos + 1
    return peekAt < #self.code + 1 and self.code:sub(peekAt, peekAt) or nil
end

function Tokenizer:skipWhitespace()
    while self.currentChar and self.currentChar:match('%s') do
        self:advance()
    end
end

function Tokenizer:skipComment()
    while self.currentChar and self.currentChar ~= '\n' do
        self:advance()
    end
    self:advance()
end

function Tokenizer:minus()
    if self:peek():match("%d") then return self:number() end
    self:advance()
    return Token(Token.MINUS, "-")
end

function Tokenizer:number()
    local startIdx = self.pos
    if self.currentChar == "-" then self:advance() end
    while self.currentChar and self.currentChar:match('%d') do
        self:advance()
    end
    if self.currentChar == '.' then
        self:advance()
        while self.currentChar and self.currentChar:match('%d') do self:advance() end
        return Token(Token.FLOAT,self.code:sub(startIdx,self.pos-1))
    end
    return Token(Token.INT,self.code:sub(startIdx,self.pos-1))
end

function Tokenizer:string(strChar)
    local startIdx = self.pos
    self:advance()
    if not self.currentChar then error("TokenizerError: Unterminated string") end
    while self.currentChar and self.currentChar ~= strChar do
        self:advance()
        -- Got to the end of the program without finding the end of the string
        if not self.currentChar then error("TokenizerError: Unterminated string") end
    end
    self:advance()
    return Token(Token.STRING,'\"'..self.code:sub(startIdx+1,self.pos-2)..'\"')
end

function Tokenizer:id()
    local startIdx = self.pos
    while self.currentChar and self.currentChar:match('%w') do
        self:advance()
    end
    local id = self.code:sub(startIdx,self.pos-1)
    local tokenType = Token.ID
    if id == 'nil' then tokenType = Token.NIL
    elseif id == 't' then tokenType = Token.TRUE end
    for i=1, #Token.KEYWORDS do
        if Token.KEYWORDS[i] == id then
            tokenType = Token.KEYWORD
        end
    end
    return Token(tokenType, id)
end

function Tokenizer:less_or_leq()
    self:advance()
    if self.currentChar == '=' then
        self:advance()
        return Token(Token.LEQ, "<=")
    end
    return Token(Token.LESS, "<")
end

function Tokenizer:getNextToken()
    self:skipWhitespace()
    if self.currentChar == nil then return Token(Token.EOF) end

    -- the less than character is a special case
    -- because it can be either a less than or a less than or equal to
    if self.currentChar == "<" then return self:less_or_leq() end

    if self.currentChar == '"' then return self:string(self.currentChar) end
    if self.currentChar == ";" then
        self:skipComment()
        return self:getNextToken()
    end

    if self.currentChar == "'" then return error("TokenizerError: Shorthand for the quote function is not yet supported") end

    if self.currentChar:match('%a') or self.currentChar:find("_") == 1 then return self:id() end
    if self.currentChar:match('%d') or self.currentChar == "." then return self:number() end
    if self.currentChar == "-" then return self:minus() end

    for k,v in pairs(Token.ONE_CHAR_TOKENS) do
        if self.currentChar == k then
            self:advance()
            return Token(v,k)
        end
    end

    error("TokenizerError: Couldn't tokenize character: '" .. self.currentChar.."' at position: " .. self.pos)
end

function Tokenizer:tokenize()
    local tokens = {}
    while true do
        local token = self:getNextToken()
        table.insert(tokens,token)
        if token.type == Token.EOF then return tokens end
    end
end

-- i know this is the exact same as just making a new tokenizer
-- but this is to save memory by reusing the tokenizer
function Tokenizer:restart(sourceCode)
    self.code = sourceCode
    self.pos = 1
    self.currentChar = self.code:sub(self.pos,self.pos)
end

return Tokenizer