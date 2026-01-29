# Autodocs

## Setters (@set)

### `/home/hadean/Desktop/Bin/autodocs.lua:3`
> Parse CLI args with defaults

> strip trailing slash, resolve absolute path via cd

> `US` separates multi-line text within record fields

```lua
local SCAN_DIR = arg[1] or "."
local OUTPUT   = arg[2] or "readme.md"
SCAN_DIR = SCAN_DIR:gsub("/$", "")
local p = io.popen('cd "' .. SCAN_DIR .. '" && pwd')
SCAN_DIR = p:read("*l")
p:close()
```

### `/home/hadean/Desktop/Bin/autodocs.lua:209`
> Initialize per-file state machine variables

> `get_lang` sets language via return value

> records table collects output in-memory

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

## Asserts (@ass)

### `/home/hadean/Desktop/Bin/autodocs.lua:29`
> Test whether a line contains any documentation tag

```lua
local function has_tag(line)
    return line:find("@set", 1, true) or line:find("@ass", 1, true) or
           line:find("@cal", 1, true) or line:find("@rai", 1, true)
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:35`
> Classify a tagged line into SET, ASS, CAL, or RAI

```lua
local function get_tag(line)
    if     line:find("@set", 1, true) then return "SET"
    elseif line:find("@ass", 1, true) then return "ASS"
    elseif line:find("@cal", 1, true) then return "CAL"
    elseif line:find("@rai", 1, true) then return "RAI"
    end
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:84`
> Detect comment style from a source line

> `none` skips early in next defs

```lua
local function detect_style(line)
    local tl = trim_lead(line)
    if     tl:sub(1, 4) == "<!--" then return "html"
    elseif tl:sub(1, 2) == "/*"   then return "cblock"
    elseif tl:sub(1, 2) == "//"   then return "dslash"
    elseif tl:sub(1, 1) == "#"    then return "hash"
    elseif tl:sub(1, 3) == '"""'  then return "dquote"
    elseif tl:sub(1, 3) == "'''"  then return "squote"
    elseif tl:sub(1, 2) == "--"   then return "ddash"
    else   return "none"
    end
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:165`
> Map file extension to fenced code block language

> falling back to shebang detection for extensionless files


### `/home/hadean/Desktop/Bin/autodocs.lua:533`
> Verify tagged files were discovered


### `/home/hadean/Desktop/Bin/autodocs.lua:554`
> Verify extraction produced results


## Callers (@cal)

### `/home/hadean/Desktop/Bin/autodocs.lua:14`
> Strip leading spaces and tabs from a string

```lua
local function trim_lead(s)
    return (s:gsub("^[ \t]+", ""))
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:19`
> Strip trailing spaces and tabs from a string

```lua
local function trim_trail(s)
    return (s:gsub("[ \t]+$", ""))
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:24`
> Trim both ends via trim_lead and trim_trail

```lua
local function trim(s)
    return trim_trail(trim_lead(s))
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:44`
> Extract the subject line count from `@tag:N` syntax

> parsing leading digits after the colon

```lua
local function get_subject_count(text)
    local n = text:match("@set:(%d+)") or text:match("@ass:(%d+)") or
              text:match("@cal:(%d+)") or text:match("@rai:(%d+)")
    return tonumber(n) or 0
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:52`
> Strip `@tag:N` and trailing digits from text

> rejoining prefix with remaining content

```lua
local function strip_tag_num(text, tag)
    local pos = text:find(tag .. ":", 1, true)
    if not pos then return text end
    local prefix = text:sub(1, pos - 1)
    local rest = text:sub(pos + #tag + 1)
    rest = rest:gsub("^%d+", "")
    rest = rest:gsub("^ ", "", 1)
```

### `/home/hadean/Desktop/Bin/autodocs.lua:64`
> Remove `@tag` or `@tag:N` syntax from comment text

> delegates to `strip_tag_num` for `:N` variants

```lua
local function strip_tags(text)
    local tags = {"@set", "@ass", "@cal", "@rai"}
    for _, tag in ipairs(tags) do
        if text:find(tag .. ":%d") then
            return strip_tag_num(text, tag)
        end
        local spos = text:find(tag .. " ", 1, true)
        if spos then
            return text:sub(1, spos - 1) .. text:sub(spos + #tag + 1)
        end
        local bpos = text:find(tag, 1, true)
        if bpos then
            return text:sub(1, bpos - 1) .. text:sub(bpos + #tag)
        end
    end
    return text
end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:99`
> Strip comment delimiters and extract inner text

> for all styles including block continuations


### `/home/hadean/Desktop/Bin/autodocs.lua:206`
> Walk one file as a line-by-line state machine

> extracting tagged comments into records table


### `/home/hadean/Desktop/Bin/autodocs.lua:225`
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
```

### `/home/hadean/Desktop/Bin/autodocs.lua:259`
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
```

### `/home/hadean/Desktop/Bin/autodocs.lua:456`
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

        w(string.format("## %s (%s)\n\n", title, label))

        for _, r in ipairs(entries) do
            w(string.format("### `%s`\n", r.loc))

            -- Render text lines (split on US, skip empty after trim)
            for tline in r.text:gmatch("[^\031]+") do
                local tr = trim(tline)
                if tr ~= "" then
                    w(string.format("> %s\n\n", tr))
                end
            end

            -- Render subject code block
            if r.subj and r.subj ~= "" then
                if r.lang and r.lang ~= "" and r.lang ~= "-" then
                    w(string.format("```%s\n", r.lang))
                else
                    w("```\n")
                end
                -- Split on US, preserving empty segments for blank source lines
                for sline in (r.subj .. "\031"):gmatch("(.-)\031") do
                    w(sline .. "\n")
                end
```

### `/home/hadean/Desktop/Bin/autodocs.lua:511`
> Entry point


### `/home/hadean/Desktop/Bin/autodocs.lua:513`
> Discover files containing documentation tags

> respect .gitignore patterns via --exclude-from when present

```lua
    local gi = ""
    local gf = io.open(SCAN_DIR .. "/.gitignore", "r")
    if gf then
        gf:close()
        gi = "--exclude-from=" .. SCAN_DIR .. "/.gitignore"
```

### `/home/hadean/Desktop/Bin/autodocs.lua:547`
> Process all discovered files into intermediate records

```lua
    for _, fp in ipairs(files) do
        if not fp:match("/" .. out_base_escaped .. "$") then
            process_file(fp)
        end
    end

```

### `/home/hadean/Desktop/Bin/autodocs.lua:565`
> Render documentation and write output file

```lua
    local markdown = render_markdown()
    local f = io.open(OUTPUT, "w")
```

### `/home/hadean/Desktop/Bin/autodocs.lua:573`
> Entry point

```lua
main()
```

## Raisers (@rai)

### `/home/hadean/Desktop/Bin/autodocs.lua:535`
> Handle missing tagged files

> with empty output and stderr warning

```lua
        local f = io.open(OUTPUT, "w")
        f:write("# Autodocs\n\nNo tagged documentation found.\n")
        f:close()
```

### `/home/hadean/Desktop/Bin/autodocs.lua:556`
> Handle extraction failure

> with empty output and stderr warning

```lua
        local f = io.open(OUTPUT, "w")
        f:write("# Autodocs\n\nNo tagged documentation found.\n")
        f:close()
```

