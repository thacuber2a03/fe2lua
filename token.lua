local Token = Object:extend()

Token.FLOAT   = "FLOAT"
Token.INT     = "INT"
Token.ID      = "ID"
Token.KEYWORD = "KEYWORD"
Token.STRING  = "STRING"
Token.TRUE    = "TRUE"
Token.NIL     = "NIL"

Token.LPAREN  = "LPAREN"
Token.RPAREN  = "RPAREN"
Token.EQUAL   = "EQUAL"
Token.LESS    = "LESS"
Token.LEQ     = "LEQ"
Token.PLUS    = "PLUS"
Token.MINUS   = "MINUS"
Token.TIMES   = "TIMES"
Token.DIV     = "DIV"
Token.EOF     = "EOF"

-- NOTE: not ordered in any particular way
Token.ONE_CHAR_TOKENS = {
    ["("] = Token.LPAREN,
    [")"] = Token.RPAREN,
    ["+"] = Token.PLUS,
    ["-"] = Token.MINUS,
    ["*"] = Token.TIMES,
    ["/"] = Token.DIV,
    ["="] = Token.EQUAL,
    ["t"] = Token.TRUE,
}

-- NOTE: also not ordered in any particular way
Token.KEYWORDS = {
    "print",
    "quote",
    "if",
    "while",
    "let",
    "fn",
    "mac",
    "and",
    "or",
    "not",
    "do",
    "is",
    "atom",
    "list",
    "setcdr",
    "setcar",
    "cdr",
    "car",
    "cons"
}

function Token:new(type_, value)
    self.type = type_
    self.value = value
end

function Token:__tostring()
    if self.value then
        if type(self.value) == "string" then return "Token(" .. self.type .. ", " .. self.value .. ")"
        else return "Token(" .. self.type .. ", " .. self.value .. ")" end
    else return "Token("..self.type..")" end
end

return Token