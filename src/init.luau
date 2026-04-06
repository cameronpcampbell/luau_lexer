--!strict

local lexuau = require("./lexuau/src")

local function table_merge(tbleA: any, tbleB: any)
    for key, value in tbleB do
        if type(value) == "table" and type(tbleA[key]) == "table" then
            table_merge(tbleA[key], value)

        else
            tbleA[key] = value
        end
    end

    return tbleA
end

local
    luau_lexer, multiline_string_lexer,
    interpolated_string_lexer, interpolated_string_expression_lexer

-- Add a `sublexers` field to `LexerConfig` to allow
-- lexers to be more easily combined.
local expressions_config: lexuau.LexerConfig = {
    subpatterns = {
        hex_prefix = "0[xX]",
        hex_digits = "[0-9a-fA-F][0-9a-fA-F_]*",
        hex = "(?&hex_prefix)(?&hex_digits)",

        bin_prefix = "0[bB]",
        bin_digits = "[01][01_]*",
        bin = "(?&bin_prefix)(?&bin_digits)",

        digits = "\\d[\\d_]*",
        integer = "(?&digits)\\.?[\\d_]*|\\.\\d[\\d_]*",
        exponent = "[eE][+-]?(?&digits)",
        decimal = "(?&integer)(?&exponent)?",
    },

    patterns = {
        string = "\"[^\"]*\"|'[^']*'",

        number = "(?&hex)|(?&bin)|(?&decimal)",

        multiline_string_start = {
            pattern = "\\[\\[",
            callback = function(value, lexer)
                return value, lexer:morph(multiline_string_lexer :: lexuau.Lexer)
            end
        },

        interpolated_string_start = {
            pattern = "`",
            callback = function(value, lexer)
                return value, lexer:morph(interpolated_string_lexer :: lexuau.Lexer)
            end
        }
    }
}

luau_lexer = lexuau.new(table_merge({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        local_keyword = "local",
        ident = "[A-Za-z_][A-Za-z0-9_]*",
        eq = "="
    }
}, expressions_config))

multiline_string_lexer = lexuau.new({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        multiline_string_close = {
            pattern = "\\]\\]",
            callback = function(value, lexer)
                return value, lexer:morph(luau_lexer :: lexuau.Lexer)
            end
        }
    }
})

interpolated_string_lexer = lexuau.new({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        text_block = "[^{`]+",
        interpolated_string_expression_start = {
            pattern = "{",
            callback = function(value, lexer)
                return value, lexer:morph(interpolated_string_expression_lexer :: lexuau.Lexer)
            end
        },
        interpolated_string_end = {
            pattern = "`",
            callback = function(value, lexer)
                return value, lexer:morph(luau_lexer :: lexuau.Lexer)
            end
        }
    }
})

interpolated_string_expression_lexer = lexuau.new(table_merge({
    skip = "\\s+",
    subpatterns = {},
    patterns = {
        interpolated_string_expression_end = {
            pattern = "}",
            callback = function(value, lexer)
                return value, lexer:morph(interpolated_string_lexer :: lexuau.Lexer)
            end
        }
    }
}, expressions_config))

local lexed = luau_lexer.lex([=[
    local foo = `hello {0b1010} world`
    local bar = "kthxbai"
]=])

for value, kind in lexed do
    print(value, kind)
end
