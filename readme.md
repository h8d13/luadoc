# Autodocs

## Setters (@set)

### `/home/hadean/Desktop/Bin/autodocs.lua:8`
> [!IMPORTANT]
> Defines a setter with 1 line of subject

And a important callout

```lua
print('luadoc is awesomne')
```

### `/home/hadean/Desktop/Bin/autodocs.lua:13`
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

### `/home/hadean/Desktop/Bin/autodocs.lua:31`
Parse CLI args with defaults

> strip trailing slash, resolve absolute path via `/proc/self/environ`

> `US` separates multi-line text within record fields

```lua
local TITLE    = "Autodocs"
local SCAN_DIR = arg[1] or "."
local OUTPUT   = arg[2] or "readme.md"
SCAN_DIR = gsub(SCAN_DIR, "/$", "")
if sub(SCAN_DIR, 1, 1) ~= "/" then
    local ef = open("/proc/self/environ", "rb")
    local cwd = ef and match(ef:read("*a"), "PWD=([^%z]+)")
    if ef then ef:close() end
    SCAN_DIR = (SCAN_DIR == ".") and cwd or cwd .. "/" .. SCAN_DIR
end
local US = "\031"
```

### `/home/hadean/Desktop/Bin/autodocs.lua:106`
Hoisted `TAGS` table avoids per-call allocation in `strip_tags`

```lua
local TAGS = {"@set", "@ass", "@cal", "@rai"}
```

### `/home/hadean/Desktop/Bin/autodocs.lua:109`
Map `!x` suffixes to GitHub admonition types

```lua
local ADMONITIONS = {n="NOTE", t="TIP", i="IMPORTANT", w="WARNING", c="CAUTION"}
```

### `/home/hadean/Desktop/Bin/autodocs.lua:274`
> [!NOTE]
> Bulk-read file first so `get_lang` reuses the buffer

avoids a second `open`+`read` just for shebang detection

```lua
    local f = open(filepath, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
```

### `/home/hadean/Desktop/Bin/autodocs.lua:281`
Initialize per-file state machine variables

> `get_lang` receives first line to avoid reopening the file

```lua
    local first   = match(content, "^([^\n]*)")
    local rel     = filepath
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
```

## Asserts (@ass)

### `/home/hadean/Desktop/Bin/autodocs.lua:69`
Test whether a line contains any documentation tag

> early `@` check short-circuits lines with no tags

```lua
local function has_tag(line)
    if not find(line, "@", 1, true) then return nil end
    return find(line, "@set", 1, true) or find(line, "@ass", 1, true) or
           find(line, "@cal", 1, true) or find(line, "@rai", 1, true)
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:77`
Classify a tagged line into `SET`, `ASS`, `CAL`, or `RAI`

```lua
local function get_tag(line)
    if     find(line, "@set", 1, true) then return "SET"
    elseif find(line, "@ass", 1, true) then return "ASS"
    elseif find(line, "@cal", 1, true) then return "CAL"
    elseif find(line, "@rai", 1, true) then return "RAI"
    end
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:143`
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

### `/home/hadean/Desktop/Bin/autodocs.lua:233`
Map file extension to fenced code block language via `ext_map`

> falling back to shebang detection for extensionless files


### `/home/hadean/Desktop/Bin/autodocs.lua:636`
Verify tagged files were discovered


### `/home/hadean/Desktop/Bin/autodocs.lua:657`
Verify extraction produced results


## Callers (@cal)

### `/home/hadean/Desktop/Bin/autodocs.lua:25`
> [!NOTE]
> Shell-escape a string for safe interpolation into `io.popen`

prevents breakage from paths containing `"`, `$()`, or backticks

```lua
local function shell_quote(s)
    return "'" .. gsub(s, "'", "'\\''") .. "'"
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:46`
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

### `/home/hadean/Desktop/Bin/autodocs.lua:55`
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

### `/home/hadean/Desktop/Bin/autodocs.lua:64`
Trim both ends via `trim_lead` and `trim_trail`

```lua
local function trim(s)
    return trim_trail(trim_lead(s))
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:86`
Extract the subject line count from `@tag:N` syntax

> using pattern capture after the colon

```lua
local function get_subject_count(text)
    local n = match(text, "@set:(%d+)") or match(text, "@ass:(%d+)") or
              match(text, "@cal:(%d+)") or match(text, "@rai:(%d+)")
    return tonumber(n) or 0
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:94`
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

### `/home/hadean/Desktop/Bin/autodocs.lua:112`
Extract `!x` admonition suffix from tag syntax

```lua
local function get_admonition(text)
    local code = match(text, "@%a+:?%d*!(%a)")
    if code then return ADMONITIONS[code] end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:118`
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

### `/home/hadean/Desktop/Bin/autodocs.lua:167`
Strip comment delimiters and extract inner text

> for all styles including block continuations


### `/home/hadean/Desktop/Bin/autodocs.lua:271`
Walk one file as a line-by-line state machine

> extracting tagged comments into `records` table


### `/home/hadean/Desktop/Bin/autodocs.lua:298`
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
                        loc  = rel .. ":" .. start,
                        text = tr,
                        lang = lang,
                        adm  = adm,
                    }
                    cap_want = nsubj
                    subj = ""
                else
                    records[#records + 1] = {
                        tag  = tag,
                        loc  = rel .. ":" .. start,
                        text = tr,
                        lang = lang,
                        subj = "",
                        adm  = adm,
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

### `/home/hadean/Desktop/Bin/autodocs.lua:334`
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

### `/home/hadean/Desktop/Bin/autodocs.lua:538`
Render `records` into grouped markdown

> with blockquotes for text and fenced code blocks for subjects

```lua
local function render_markdown()
    local out = {}
    local function w(s) out[#out + 1] = s end

    w(fmt("# %s\n\n", TITLE))

    local function render_section(prefix, title, label)
        local entries = {}
        for _, r in ipairs(records) do
            if r.tag == prefix then
                entries[#entries + 1] = r
            end
        end
        if #entries == 0 then return end

        w(fmt("## %s (%s)\n\n", title, label))

        for _, r in ipairs(entries) do
            w(fmt("### `%s`\n", r.loc))

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

    render_section("SET", "Setters", "@set")
    render_section("ASS", "Asserts", "@ass")
    render_section("CAL", "Callers", "@cal")
    render_section("RAI", "Raisers", "@rai")

    return concat(out)
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:614`
Main function


### `/home/hadean/Desktop/Bin/autodocs.lua:616`
Discover files containing documentation tags

> respect `.gitignore` patterns via `grep --exclude-from`

```lua
    local gi = ""
    local gf = open(SCAN_DIR .. "/.gitignore", "r")
    if gf then
        gf:close()
        gi = "--exclude-from=" .. shell_quote(SCAN_DIR .. "/.gitignore")
    end

    local cmd = fmt(
        'grep -rl -I --exclude-dir=.git %s -e "@set" -e "@ass" -e "@cal" -e "@rai" %s 2>/dev/null',
        gi, shell_quote(SCAN_DIR)
    )
    local pipe = io.popen(cmd)
    local files = {}
    for line in pipe:lines() do
        files[#files + 1] = line
    end
    pipe:close()
```

### `/home/hadean/Desktop/Bin/autodocs.lua:650`
Process all discovered files into intermediate `records`

```lua
    for _, fp in ipairs(files) do
        if not match(fp, "/" .. out_base_escaped .. "$") then
            process_file(fp)
        end
    end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:668`
> [!NOTE]
> Render documentation, write output, and report ratio

wraps across two lines so `:N` count must include the continuation

```lua
    local markdown = render_markdown()
    local f = open(OUTPUT, "w")
    f:write(markdown)
    f:close()
    local ol = select(2, gsub(markdown, "\n", "")) + 1
    io.stderr:write(fmt("autodocs: wrote %s (%d/%d = %d%%)\n",
        OUTPUT, ol, total_input, total_input > 0 and math.floor(ol * 100 / total_input) or 0))
```

### `/home/hadean/Desktop/Bin/autodocs.lua:679`
Entry point

```lua
main()
```

## Raisers (@rai)

### `/home/hadean/Desktop/Bin/autodocs.lua:638`
Handle missing tagged files

> with empty output and `stderr` warning

```lua
        local f = open(OUTPUT, "w")
        f:write(fmt("# %s\n\nNo tagged documentation found.\n", TITLE))
        f:close()
```

### `/home/hadean/Desktop/Bin/autodocs.lua:659`
Handle extraction failure

> with empty output and `stderr` warning

```lua
        local f = open(OUTPUT, "w")
        f:write(fmt("# %s\n\nNo tagged documentation found.\n", TITLE))
        f:close()
```

