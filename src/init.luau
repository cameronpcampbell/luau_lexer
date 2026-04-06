--!strict

local lexuau = require("./lexuau/src")

local
    luau_lexer, multiline_string_lexer,
    interpolated_string_lexer, interpolated_string_expression_lexer

luau_lexer = lexuau.new({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        local_keyword = "local",
        ident = "[A-Za-z_][A-Za-z0-9_]*",
        eq = "=",
        string = "\"[^\"]*\"|'[^']*'",
        multiline_string_start = {
            pattern = "\\[\\[",
            callback = function(value, lexer)
                return value, lexer:morph(multiline_string_lexer :: lexuau.Lexer<any>)
            end
        },
        interpolated_string_start = {
            pattern = "`",
            callback = function(value, lexer)
                return value, lexer:morph(interpolated_string_lexer :: lexuau.Lexer<any>)
            end
        }
    }
})

multiline_string_lexer = lexuau.new({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        multiline_string_close = {
            pattern = "\\]\\]",
            callback = function(value, lexer)
                return value, lexer:morph(luau_lexer :: lexuau.Lexer<any>)
            end
        }
    }
})

interpolated_string_lexer = lexuau.new({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        interpolated_string_expression_start = {
            pattern = "{",
            callback = function(value, lexer)
                return value, lexer:morph(interpolated_string_expression_lexer :: lexuau.Lexer<any>)
            end
        }
    }
})

interpolated_string_expression_lexer = lexuau.new({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        interpolated_string_expression_end = {
            pattern = "}",
            callback = function(value, lexer)
                return value, lexer:morph(interpolated_string_lexer :: lexuau.Lexer<any>)
            end
        }
    }
})

local lexed = luau_lexer.lex([=[
    local foo = `hello {} world`
]=])

for value, kind in lexed do
    print(value, kind)
end
