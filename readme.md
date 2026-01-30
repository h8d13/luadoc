# Autodocs

## Checks (@chk)

### <a id="chk-1"></a>1. ~/Desktop/Bin/autodocs.lua:2
`-s` outputs extra stats


### <a id="chk-1-1"></a>1.1 ~/Desktop/Bin/autodocs.lua:90
Test whether a line contains any documentation tag

> early `@` check short-circuits lines with no tags

```lua
local function has_tag(line)
    if not find(line, "@", 1, true) then return nil end
    return find(line, "@def", 1, true) or find(line, "@chk", 1, true) or
           find(line, "@run", 1, true) or find(line, "@err", 1, true)
end
```

### <a id="chk-1-2"></a>1.2 ~/Desktop/Bin/autodocs.lua:98
Classify a tagged line into `DEF`, `CHK`, `RUN`, or `ERR`

```lua
local function get_tag(line)
    if     find(line, "@def", 1, true) then return "DEF"
    elseif find(line, "@chk", 1, true) then return "CHK"
    elseif find(line, "@run", 1, true) then return "RUN"
    elseif find(line, "@err", 1, true) then return "ERR"
    end
end
```

### <a id="chk-1-3"></a>1.3 ~/Desktop/Bin/autodocs.lua:107
Extract the subject line count from `@tag:N` syntax

> using pattern capture after the colon

```lua
local function get_subject_count(text)
    local n = match(text, "@def:(%d+)") or match(text, "@chk:(%d+)") or
              match(text, "@run:(%d+)") or match(text, "@err:(%d+)")
    return tonumber(n) or 0
end
```

### <a id="chk-1-4"></a>1.4 ~/Desktop/Bin/autodocs.lua:137
Extract `!x` admonition suffix from tag syntax

```lua
local function get_admonition(text)
    local code = match(text, "@%a+:?%d*!(%a)")
    if code then return ADMONITIONS[code] end
end
```

### <a id="chk-1-5"></a>1.5 ~/Desktop/Bin/autodocs.lua:168
Detect comment style via byte-level prefix check

> skips leading whitespace without allocating a trimmed copy

```lua
local function detect_style(line)
    local i = 1
    while byte(line, i) == 32 or byte(line, i) == 9 do i = i + 1 end
    local b = byte(line, i)
    if not b then return "none" end
    if b == 60 then -- '<'
        if sub(line, i, i + 3) == "<!--" then return "html" end
    elseif b == 47 then -- '/'
        local b2 = byte(line, i + 1)
        if b2 == 42 then return "cblock" end
        if b2 == 47 then return "dslash" end
    elseif b == 35 then return "hash"
    elseif b == 34 then -- '"'
        if sub(line, i, i + 2) == '"""' then return "dquote" end
    elseif b == 39 then -- "'"
        if sub(line, i, i + 2) == "'''" then return "squote" end
    elseif b == 45 then -- '-'
        if byte(line, i + 1) == 45 then return "ddash" end
    end
    return "none"
end
```

### <a id="chk-1-6"></a>1.6 ~/Desktop/Bin/autodocs.lua:195
*↳ [Runners 1.5](#run-1-5)*

shell type comments


### <a id="chk-1-7"></a>1.7 ~/Desktop/Bin/autodocs.lua:199
*↳ [Runners 1.5](#run-1-5)*

double-slash comments


### <a id="chk-1-8"></a>1.8 ~/Desktop/Bin/autodocs.lua:204
*↳ [Runners 1.5](#run-1-5)*

double-dash comments


### <a id="chk-1-9"></a>1.9 ~/Desktop/Bin/autodocs.lua:209
*↳ [Runners 1.5](#run-1-5)*

C-style block opening


### <a id="chk-1-10"></a>1.10 ~/Desktop/Bin/autodocs.lua:216
*↳ [Runners 1.5](#run-1-5)*

HTML comment opening


### <a id="chk-1-11"></a>1.11 ~/Desktop/Bin/autodocs.lua:223
*↳ [Runners 1.5](#run-1-5)*

block comment continuation lines


### <a id="chk-1-12"></a>1.12 ~/Desktop/Bin/autodocs.lua:234
*↳ [Runners 1.5](#run-1-5)*

html closing


### <a id="chk-1-13"></a>1.13 ~/Desktop/Bin/autodocs.lua:240
*↳ [Runners 1.5](#run-1-5)*

triple-quote docstring styles


### <a id="chk-1-14"></a>1.14 ~/Desktop/Bin/autodocs.lua:253
*↳ [Runners 1.5](#run-1-5)*

docstring continuation lines

> no opening delimiter to strip; checks both `"""` and `'''` closers


### <a id="chk-1-15"></a>1.15 ~/Desktop/Bin/autodocs.lua:287
Classify file language via extension or shebang

> accepts `first_line` to avoid reopening the file

```lua
local function get_lang(filepath, first_line)
    local ext = match(filepath, "%.([^%.]+)$")
    if ext and ext_map[ext] then return ext_map[ext] end
    if first_line and sub(first_line, 1, 3) == "#!/" then
        for _, pair in ipairs(shebang_map) do
            if find(first_line, pair[1], 1, true) then
                return pair[2]
            end
        end
    end
    return ""
end
```

### <a id="chk-1-16"></a>1.16 ~/Desktop/Bin/autodocs.lua:432
*↳ [Runners 1.8](#run-1-8)*

Scan untagged block comment for tags


### <a id="chk-1-17"></a>1.17 ~/Desktop/Bin/autodocs.lua:451
*↳ [Runners 1.8](#run-1-8)*

Scan untagged HTML comment for tags


### <a id="chk-1-18"></a>1.18 ~/Desktop/Bin/autodocs.lua:484
*↳ [Runners 1.8](#run-1-8)*

Scan untagged docstring for tags


### <a id="chk-1-19"></a>1.19 ~/Desktop/Bin/autodocs.lua:509
*↳ [Runners 1.8](#run-1-8)*

Detect comment style of current line


### <a id="chk-1-20"></a>1.20 ~/Desktop/Bin/autodocs.lua:551
*↳ [Runners 1.8](#run-1-8)*

Untagged block comment start - scan for tags


### <a id="chk-1-21"></a>1.21 ~/Desktop/Bin/autodocs.lua:677
*↳ [Runners 1.16](#run-1-16)*

Verify tagged files were discovered


### <a id="chk-1-22"></a>1.22 ~/Desktop/Bin/autodocs.lua:698
*↳ [Runners 1.16](#run-1-16)*

Verify extraction produced results


### <a id="chk-1-23"></a>1.23 ~/Desktop/Bin/autodocs.lua:744
*↳ [Runners 1.16](#run-1-16)*

Render and compare against existing output

> skip write if content is unchanged

```lua
    local markdown = render_markdown(grouped)
    local ef = open(OUTPUT, "r")
    if ef then
        local existing = ef:read("*a")
        ef:close()
        if existing == markdown then
            io.stderr:write(fmt("autodocs: %s unchanged\n", OUTPUT))
            return
        end
    end
```

## Defines (@def)

### <a id="def-1"></a>1. ~/Desktop/Bin/autodocs.lua:10
> [!IMPORTANT]
> Defines a setter with 1 line of subject

And a important callout

9 lines are inluded as the subject

after the end of comment block

`!n` NOTE

`!t` TIP

`!w` WARN

`!c` CAUTION

```lua
print('luadoc is awesome')
    -- Check  -> Early checks
    ---- guard the entry, bail early if preconditions fail
    -- Define -> Gives instructions to
    ---- define the state/config the rest depends on
    -- Run    -> Use the instructions
    ---- do the actual work using those definitions
    -- Error  -> Handle what went wrong
    ---- handle errors with more definitions
```

### <a id="def-1-1"></a>1.1 ~/Desktop/Bin/autodocs.lua:32
Localize `string.*`, `table.*`, and `io.*` functions

> bypasses metatable and global lookups in the hot loop

```lua
local find   = string.find
local sub    = string.sub
local byte   = string.byte
local match  = string.match
local gmatch = string.gmatch
local gsub   = string.gsub
local fmt    = string.format
local concat = table.concat
local open   = io.open
```

### <a id="def-1-2"></a>1.2 ~/Desktop/Bin/autodocs.lua:44
> [!NOTE]
> Shell-escape a string for safe interpolation into `io.popen`

prevents breakage from paths containing `"`, `$()`, or backticks

```lua
local function shell_quote(s)
    return "'" .. gsub(s, "'", "'\\''") .. "'"
end
```

### <a id="def-1-3"></a>1.3 ~/Desktop/Bin/autodocs.lua:50
Parse CLI args with defaults

> strip trailing slash, resolve absolute path via `/proc/self/environ`

> `US` separates multi-line text within record fields

```lua
local TITLE    = "Autodocs"
local SCAN_DIR = arg[1] or "."
local OUTPUT   = arg[2] or "readme.md"
local STATS    = arg[3] == "-s"
SCAN_DIR = gsub(SCAN_DIR, "/$", "")
if sub(SCAN_DIR, 1, 1) ~= "/" then
    local ef = open("/proc/self/environ", "rb")
    local cwd = ef and match(ef:read("*a"), "PWD=([^%z]+)")
    if ef then ef:close() end
    SCAN_DIR = (SCAN_DIR == ".") and cwd or cwd .. "/" .. SCAN_DIR
end
```

### <a id="def-1-4"></a>1.4 ~/Desktop/Bin/autodocs.lua:127
Hoisted `TAGS` table avoids per-call allocation in `strip_tags`

```lua
local TAGS = {"@def", "@chk", "@run", "@err"}
```

### <a id="def-1-5"></a>1.5 ~/Desktop/Bin/autodocs.lua:130
Map `!x` suffixes to admonition types

```lua
local ADMONITIONS = {n="NOTE", t="TIP", i="IMPORTANT", w="WARNING", c="CAUTION"}
```

### <a id="def-1-6"></a>1.6 ~/Desktop/Bin/autodocs.lua:133
Map tag prefixes to anchor slugs and section titles

```lua
local TAG_SEC   = {CHK="chk", DEF="def", RUN="run", ERR="err"}
local TAG_TITLE = {CHK="Checks", DEF="Defines", RUN="Runners", ERR="Errors"}
```

### <a id="def-1-7"></a>1.7 ~/Desktop/Bin/autodocs.lua:267
Map file extension to fenced code block language

```lua
local ext_map = {
    sh="sh", bash="sh", py="python",
    js="javascript", mjs="javascript", cjs="javascript",
    ts="typescript", mts="typescript", cts="typescript",
    jsx="jsx", tsx="tsx", rb="ruby", go="go", rs="rust",
    c="c", h="c", cpp="cpp", hpp="cpp", cc="cpp", cxx="cpp",
    java="java", cs="csharp", swift="swift", kt="kotlin", kts="kotlin",
    lua="lua", sql="sql", html="html", htm="html", css="css", xml="xml",
    yaml="yaml", yml="yaml", toml="toml", json="json",
    php="php", pl="perl", pm="perl", zig="zig",
    hs="haskell", ex="elixir", exs="elixir", erl="erlang",
}
```

### <a id="def-1-8"></a>1.8 ~/Desktop/Bin/autodocs.lua:281
Map shebang interpreters to fenced code block language

```lua
local shebang_map = {
    {"python", "python"}, {"node", "javascript"}, {"ruby", "ruby"},
    {"perl", "perl"}, {"lua", "lua"}, {"php", "php"}, {"sh", "sh"},
}
```

### <a id="def-1-9"></a>1.9 ~/Desktop/Bin/autodocs.lua:302
Global state for collected records and line count

```lua
local records = {}
local total_input = 0
```

### <a id="def-1-10"></a>1.10 ~/Desktop/Bin/autodocs.lua:309
*↳ [Runners 1.6](#run-1-6)*

> [!NOTE]
> Bulk-read file first so `get_lang` reuses the buffer

avoids a second `open`+`read` just for shebang detection

```lua
    local f = open(filepath, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
```

### <a id="def-1-11"></a>1.11 ~/Desktop/Bin/autodocs.lua:316
*↳ [Runners 1.6](#run-1-6)*

Initialize per-file state machine variables

> `get_lang` receives first line to avoid reopening the file

```lua
    local first   = match(content, "^([^\n]*)")
    local rel     = HOME and sub(filepath, 1, #HOME) == HOME and "~" .. sub(filepath, #HOME + 1) or filepath
    local lang    = get_lang(filepath, first)
    local ln      = 0
    local state   = ""
    local tag     = ""
    local start   = ""
    local text    = ""
    local nsubj   = 0
    local cap_want = 0
    local capture = 0
    local subj    = ""
    local adm     = nil
    local pending = nil
    local tag_indent = 0
```

## Runners (@run)

### <a id="run-1"></a>1. ~/Desktop/Bin/autodocs.lua:67
Strip leading spaces and tabs via byte scan

> returns original string when no trimming needed

```lua
local function trim_lead(s)
    local i = 1
    while byte(s, i) == 32 or byte(s, i) == 9 do i = i + 1 end
    if i == 1 then return s end
    return sub(s, i)
end
```

### <a id="run-1-1"></a>1.1 ~/Desktop/Bin/autodocs.lua:76
Strip trailing spaces and tabs via byte scan

> returns original string when no trimming needed

```lua
local function trim_trail(s)
    local i = #s
    while i > 0 and (byte(s, i) == 32 or byte(s, i) == 9) do i = i - 1 end
    if i == #s then return s end
    return sub(s, 1, i)
end
```

### <a id="run-1-2"></a>1.2 ~/Desktop/Bin/autodocs.lua:85
Trim both ends via `trim_lead` and `trim_trail`

```lua
local function trim(s)
    return trim_trail(trim_lead(s))
end
```

### <a id="run-1-3"></a>1.3 ~/Desktop/Bin/autodocs.lua:115
Strip `@tag:N` and trailing digits from text

> rejoining prefix with remaining content

```lua
local function strip_tag_num(text, tag)
    local pos = find(text, tag .. ":", 1, true)
    if not pos then return text end
    local prefix = sub(text, 1, pos - 1)
    local rest = sub(text, pos + #tag + 1)
    rest = gsub(rest, "^%d+!?%a?", "")
    rest = gsub(rest, "^ ", "", 1)
    return prefix .. rest
end
```

### <a id="run-1-4"></a>1.4 ~/Desktop/Bin/autodocs.lua:143
Remove `@tag`, `@tag:N`, or `@tag!x` syntax from comment text

> delegates to `strip_tag_num` for `:N` and `:N!x` variants

```lua
local function strip_tags(text)
    for _, tag in ipairs(TAGS) do
        if find(text, tag .. ":%d") then
            return strip_tag_num(text, tag)
        end
        local epos = find(text, tag .. "!%a")
        if epos then
            local rest = sub(text, epos + #tag + 2)
            rest = gsub(rest, "^ ", "", 1)
            return sub(text, 1, epos - 1) .. rest
        end
        local spos = find(text, tag .. " ", 1, true)
        if spos then
            return sub(text, 1, spos - 1) .. sub(text, spos + #tag + 1)
        end
        local bpos = find(text, tag, 1, true)
        if bpos then
            return sub(text, 1, bpos - 1) .. sub(text, bpos + #tag)
        end
    end
    return text
end
```

### <a id="run-1-5"></a>1.5 ~/Desktop/Bin/autodocs.lua:192
Strip comment delimiters and extract inner text

> for all styles including block continuations


### <a id="run-1-6"></a>1.6 ~/Desktop/Bin/autodocs.lua:306
Walk one file as a line-by-line state machine

> extracting tagged comments into `records` table


### <a id="run-1-7"></a>1.7 ~/Desktop/Bin/autodocs.lua:334
*↳ [Runners 1.6](#run-1-6)*

> [!NOTE]
> Emit a documentation record or defer for subject capture

`lang` is passed through as-is, empty string means no fence label

```lua
    local function emit()
        if tag ~= "" and text ~= "" then
            local tr = trim(text)
            if tr ~= "" then
                if nsubj > 0 then
                    pending = {
                        tag  = tag,
                        file = rel,
                        loc  = rel .. ":" .. start,
                        text = tr,
                        lang = lang,
                        adm  = adm,
                        indent = tag_indent,
                    }
                    cap_want = nsubj
                    subj = ""
                else
                    records[#records + 1] = {
                        tag  = tag,
                        file = rel,
                        loc  = rel .. ":" .. start,
                        text = tr,
                        lang = lang,
                        subj = "",
                        adm  = adm,
                        indent = tag_indent,
                    }
                end
            end
        end
        state = ""
        tag   = ""
        start = ""
        text  = ""
        nsubj = 0
        adm   = nil
    end
```

### <a id="run-1-8"></a>1.8 ~/Desktop/Bin/autodocs.lua:374
*↳ [Runners 1.6](#run-1-6)*

Flush deferred record with captured `subj` lines

```lua
    local function flush_pending()
        if pending then
            pending.subj = subj
            records[#records + 1] = pending
            pending = nil
            subj    = ""
            capture = 0
        end
    end
```

### <a id="run-1-9"></a>1.9 ~/Desktop/Bin/autodocs.lua:394
*↳ [Runners 1.8](#run-1-8)*

Subject line capture mode


### <a id="run-1-10"></a>1.10 ~/Desktop/Bin/autodocs.lua:406
*↳ [Runners 1.8](#run-1-8)*

Accumulate C-style block comment with tag


### <a id="run-1-11"></a>1.11 ~/Desktop/Bin/autodocs.lua:419
*↳ [Runners 1.8](#run-1-8)*

Accumulate HTML comment with tag


### <a id="run-1-12"></a>1.12 ~/Desktop/Bin/autodocs.lua:470
*↳ [Runners 1.8](#run-1-8)*

Accumulate docstring with tag


### <a id="run-1-13"></a>1.13 ~/Desktop/Bin/autodocs.lua:512
*↳ [Runners 1.8](#run-1-8)*

Continue or close existing single-line comment block


### <a id="run-1-14"></a>1.14 ~/Desktop/Bin/autodocs.lua:527
*↳ [Runners 1.8](#run-1-8)*

Dispatch new tagged comment by style


### <a id="run-1-15"></a>1.15 ~/Desktop/Bin/autodocs.lua:564
*↳ [Runners 1.8](#run-1-8)*

Begin subject capture if waiting and hit a code line


### <a id="run-1-16"></a>1.16 ~/Desktop/Bin/autodocs.lua:582
Render `records` into grouped markdown

> with blockquotes for text and fenced code blocks for subjects

```lua
local function render_markdown(grouped)
    local out = {}
    local function w(s) out[#out + 1] = s end

    w(fmt("# %s\n\n", TITLE))

    local function render_section(entries, prefix)
        if #entries == 0 then return end

        w(fmt("## %s (@%s)\n\n", TAG_TITLE[prefix], TAG_SEC[prefix]))

        for _, r in ipairs(entries) do
            w(fmt('### <a id="%s"></a>%s %s\n', r.anchor, r.idx, r.loc))
            if r.parent and r.parent.anchor then
                w(fmt("*↳ [%s %s](#%s)*\n\n", r.parent.sec_title, r.parent.idx, r.parent.anchor))
            end

            -- Render text lines: admonition or first-plain/rest-blockquote
            if r.adm then
                local first_text = true
                for tline in gmatch(r.text, "[^\031]+") do
                    local tr = trim(tline)
                    if tr ~= "" then
                        if first_text then
                            w(fmt("> [!%s]\n> %s\n\n", r.adm, tr))
                            first_text = false
                        else
                            w(tr .. "\n\n")
                        end
                    end
                end
            else
                local first_text = true
                for tline in gmatch(r.text, "[^\031]+") do
                    local tr = trim(tline)
                    if tr ~= "" then
                        if first_text then
                            w(tr .. "\n\n")
                            first_text = false
                        else
                            w(fmt("> %s\n\n", tr))
                        end
                    end
                end
            end

            -- Render subject code block
            if r.subj and r.subj ~= "" then
                if r.lang and r.lang ~= "" then
                    w(fmt("```%s\n", r.lang))
                else
                    w("```\n")
                end
                -- Split on US, preserving empty segments for blank source lines
                for sline in gmatch(r.subj .. "\031", "(.-)\031") do
                    w(sline .. "\n")
                end
                w("```\n")
            end
            w("\n")
        end
    end

    render_section(grouped.CHK, "CHK")
    render_section(grouped.DEF, "DEF")
    render_section(grouped.RUN, "RUN")
    render_section(grouped.ERR, "ERR")

    return concat(out)
end

-- @run Main function
local function main()
    -- @run:17 Discover files containing documentation tags
    -- respect `.gitignore` patterns via `grep --exclude-from`
    local gi = ""
```

### <a id="run-1-17"></a>1.17 ~/Desktop/Bin/autodocs.lua:691
*↳ [Runners 1.16](#run-1-16)*

Process all discovered files into intermediate `records`

```lua
    for _, fp in ipairs(files) do
        if not match(fp, "/" .. out_base_escaped .. "$") then
            process_file(fp)
        end
    end
```

### <a id="run-1-18"></a>1.18 ~/Desktop/Bin/autodocs.lua:709
*↳ [Runners 1.16](#run-1-16)*

Resolve parents, assign indices, group by tag (single pass)


### <a id="run-1-19"></a>1.19 ~/Desktop/Bin/autodocs.lua:757
*↳ [Runners 1.16](#run-1-16)*

Write output and report ratio

> wraps across two lines so `:N` count must include the continuation

```lua
    local f = open(OUTPUT, "w")
    f:write(markdown)
    f:close()
    local ol = select(2, gsub(markdown, "\n", "")) + 1
    io.stderr:write(fmt("autodocs: wrote %s (%d/%d = %d%%)\n",
        OUTPUT, ol, total_input, total_input > 0 and math.floor(ol * 100 / total_input) or 0))
```

### <a id="run-1-20"></a>1.20 ~/Desktop/Bin/autodocs.lua:766
*↳ [Runners 1.16](#run-1-16)*

Run `stats.awk` on the output if `-s` flag is set

```lua
    if STATS then
        local script_dir = match(arg[0], "^(.*/)") or "./"
        local stats_awk = script_dir .. "stats.awk"
        local sf = open(stats_awk, "r")
        if sf then
            sf:close()
            os.execute(fmt("awk -f %s %s >&2", shell_quote(stats_awk), shell_quote(OUTPUT)))
        end
    end
```

### <a id="run-1-21"></a>1.21 ~/Desktop/Bin/autodocs.lua:778
Entry point

```lua
main()
```

## Errors (@err)

### <a id="err-1"></a>1. ~/Desktop/Bin/autodocs.lua:679
*↳ [Checks 1.21](#chk-1-21)*

Handle missing tagged files

> with empty output and `stderr` warning

```lua
        local f = open(OUTPUT, "w")
        f:write(fmt("# %s\n\nNo tagged documentation found.\n", TITLE))
        f:close()
        io.stderr:write(fmt("autodocs: no tags found under %s\n", SCAN_DIR))
        return
```

### <a id="err-1-1"></a>1.1 ~/Desktop/Bin/autodocs.lua:700
*↳ [Checks 1.22](#chk-1-22)*

Handle extraction failure

> with empty output and `stderr` warning

```lua
        local f = open(OUTPUT, "w")
        f:write(fmt("# %s\n\nNo tagged documentation found.\n", TITLE))
        f:close()
        io.stderr:write(fmt("autodocs: tags found but no extractable docs under %s\n", SCAN_DIR))
        return
```

