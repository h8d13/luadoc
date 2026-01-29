# Autodocs

## Setters (@set)

### `/home/hadean/Desktop/Bin/autodocs.lua:3`
> Localize standard library functions

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

### `/home/hadean/Desktop/Bin/autodocs.lua:15`
> Parse CLI args with defaults

> strip trailing slash, resolve absolute path via io.popen

> `US` separates multi-line text within record fields

```lua
local SCAN_DIR = arg[1] or "."
local OUTPUT   = arg[2] or "readme.md"
SCAN_DIR = gsub(SCAN_DIR, "/$", "")
local p = io.popen('cd "' .. SCAN_DIR .. '" && pwd')
SCAN_DIR = p:read("*l")
p:close()
local US = "\031"
```

### `/home/hadean/Desktop/Bin/autodocs.lua:86`
> Hoisted tag table avoids per-call allocation in strip_tags

```lua
local TAGS = {"@set", "@ass", "@cal", "@rai"}
```

### `/home/hadean/Desktop/Bin/autodocs.lua:243`
> Initialize per-file state machine variables

> `get_lang` returns language, `records` collects output in-memory

```lua
    local rel     = filepath
    local lang    = get_lang(filepath)
    local ln      = 0
    local state   = ""
    local tag     = ""
    local start   = ""
    local text    = ""
    local nsubj   = 0
    local cap_want = 0
    local capture = 0
    local subj    = ""
    local pending = nil
```

### `/home/hadean/Desktop/Bin/autodocs.lua:303`
> Bulk-read file into memory for single-syscall I/O

> then scan for newlines in the hot loop

```lua
    local f = open(filepath, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
```

## Asserts (@ass)

### `/home/hadean/Desktop/Bin/autodocs.lua:49`
> Test whether a line contains any documentation tag

> early `@` check short-circuits lines with no tags

```lua
local function has_tag(line)
    if not find(line, "@", 1, true) then return nil end
    return find(line, "@set", 1, true) or find(line, "@ass", 1, true) or
           find(line, "@cal", 1, true) or find(line, "@rai", 1, true)
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:57`
> Classify a tagged line into SET, ASS, CAL, or RAI

```lua
local function get_tag(line)
    if     find(line, "@set", 1, true) then return "SET"
    elseif find(line, "@ass", 1, true) then return "ASS"
    elseif find(line, "@cal", 1, true) then return "CAL"
    elseif find(line, "@rai", 1, true) then return "RAI"
    end
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:108`
> Detect comment style via byte-level prefix check

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

### `/home/hadean/Desktop/Bin/autodocs.lua:198`
> Map file extension to fenced code block language

> falling back to shebang detection for extensionless files


### `/home/hadean/Desktop/Bin/autodocs.lua:576`
> Verify tagged files were discovered


### `/home/hadean/Desktop/Bin/autodocs.lua:597`
> Verify extraction produced results


## Callers (@cal)

### `/home/hadean/Desktop/Bin/autodocs.lua:26`
> Strip leading spaces and tabs via byte scan

> returns original string when no trimming needed

```lua
local function trim_lead(s)
    local i = 1
    while byte(s, i) == 32 or byte(s, i) == 9 do i = i + 1 end
    if i == 1 then return s end
    return sub(s, i)
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:35`
> Strip trailing spaces and tabs via byte scan

> returns original string when no trimming needed

```lua
local function trim_trail(s)
    local i = #s
    while i > 0 and (byte(s, i) == 32 or byte(s, i) == 9) do i = i - 1 end
    if i == #s then return s end
    return sub(s, 1, i)
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:44`
> Trim both ends via trim_lead and trim_trail

```lua
local function trim(s)
    return trim_trail(trim_lead(s))
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:66`
> Extract the subject line count from `@tag:N` syntax

> using pattern capture after the colon

```lua
local function get_subject_count(text)
    local n = match(text, "@set:(%d+)") or match(text, "@ass:(%d+)") or
              match(text, "@cal:(%d+)") or match(text, "@rai:(%d+)")
    return tonumber(n) or 0
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:74`
> Strip `@tag:N` and trailing digits from text

> rejoining prefix with remaining content

```lua
local function strip_tag_num(text, tag)
    local pos = find(text, tag .. ":", 1, true)
    if not pos then return text end
    local prefix = sub(text, 1, pos - 1)
    local rest = sub(text, pos + #tag + 1)
    rest = gsub(rest, "^%d+", "")
    rest = gsub(rest, "^ ", "", 1)
    return prefix .. rest
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:89`
> Remove `@tag` or `@tag:N` syntax from comment text

> delegates to `strip_tag_num` for `:N` variants

```lua
local function strip_tags(text)
    for _, tag in ipairs(TAGS) do
        if find(text, tag .. ":%d") then
            return strip_tag_num(text, tag)
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

### `/home/hadean/Desktop/Bin/autodocs.lua:132`
> Strip comment delimiters and extract inner text

> for all styles including block continuations


### `/home/hadean/Desktop/Bin/autodocs.lua:240`
> Walk one file as a line-by-line state machine

> extracting tagged comments into records table


### `/home/hadean/Desktop/Bin/autodocs.lua:258`
> Emit a documentation record or defer for subject capture

```lua
    local function emit()
        if tag ~= "" and text ~= "" then
            local tr = trim(text)
            if tr ~= "" then
                if nsubj > 0 then
                    local lang_f = lang
                    if lang_f == "" then lang_f = "-" end
                    pending = {
                        tag  = tag,
                        loc  = rel .. ":" .. start,
                        text = tr,
                        lang = lang_f,
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
                    }
                end
            end
        end
        state = ""
        tag   = ""
        start = ""
        text  = ""
        nsubj = 0
    end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:292`
> Flush deferred record with captured subject lines

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

### `/home/hadean/Desktop/Bin/autodocs.lua:499`
> Render intermediate records into grouped markdown

> with blockquotes for text and fenced code blocks for subjects

```lua
local function render_markdown()
    local out = {}
    local function w(s) out[#out + 1] = s end

    w("# Autodocs\n\n")

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

            -- Render text lines (split on US, skip empty after trim)
            for tline in gmatch(r.text, "[^\031]+") do
                local tr = trim(tline)
                if tr ~= "" then
                    w(fmt("> %s\n\n", tr))
                end
            end

            -- Render subject code block
            if r.subj and r.subj ~= "" then
                if r.lang and r.lang ~= "" and r.lang ~= "-" then
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

### `/home/hadean/Desktop/Bin/autodocs.lua:554`
> Entry point


### `/home/hadean/Desktop/Bin/autodocs.lua:556`
> Discover files containing documentation tags

> respect .gitignore patterns via grep --exclude-from

```lua
    local gi = ""
    local gf = open(SCAN_DIR .. "/.gitignore", "r")
    if gf then
        gf:close()
        gi = "--exclude-from=" .. SCAN_DIR .. "/.gitignore"
    end

    local cmd = fmt(
        'grep -rl -I --exclude-dir=.git %s -e "@set" -e "@ass" -e "@cal" -e "@rai" "%s" 2>/dev/null',
        gi, SCAN_DIR
    )
    local pipe = io.popen(cmd)
    local files = {}
    for line in pipe:lines() do
        files[#files + 1] = line
    end
    pipe:close()
```

### `/home/hadean/Desktop/Bin/autodocs.lua:590`
> Process all discovered files into intermediate records

```lua
    for _, fp in ipairs(files) do
        if not match(fp, "/" .. out_base_escaped .. "$") then
            process_file(fp)
        end
    end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:608`
> Render documentation, write output, and report ratio

```lua
    local markdown = render_markdown()
    local f = open(OUTPUT, "w")
    f:write(markdown)
    f:close()
    local ol = select(2, gsub(markdown, "\n", "")) + 1
    io.stderr:write(fmt("autodocs: wrote %s (%d/%d = %d%%)\n",
```

### `/home/hadean/Desktop/Bin/autodocs.lua:618`
> Entry point

```lua
main()
```

## Raisers (@rai)

### `/home/hadean/Desktop/Bin/autodocs.lua:578`
> Handle missing tagged files

> with empty output and stderr warning

```lua
        local f = open(OUTPUT, "w")
        f:write("# Autodocs\n\nNo tagged documentation found.\n")
        f:close()
```

### `/home/hadean/Desktop/Bin/autodocs.lua:599`
> Handle extraction failure

> with empty output and stderr warning

```lua
        local f = open(OUTPUT, "w")
        f:write("# Autodocs\n\nNo tagged documentation found.\n")
        f:close()
```

