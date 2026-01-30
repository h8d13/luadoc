#!/usr/bin/env lua
-- @chk:1
-- `-s` outputs extra stats

--########--
--HLPARSER--
--Examples--
--########--

-- @def:9!i
-- Defines a setter with 1 line of subject
-- And a important callout
-- 9 lines are inluded as the subject 
-- after the end of comment block
-- `!n` NOTE
-- `!t` TIP
-- `!w` WARN
-- `!c` CAUTION
print('luadoc is awesome')
    -- Check  -> Early checks
    ---- guard the entry, bail early if preconditions fail
    -- Define -> Gives instructions to
    ---- define the state/config the rest depends on
    -- Run    -> Use the instructions
    ---- do the actual work using those definitions
    -- Error  -> Handle what went wrong
    ---- handle errors with more definitions

--########--
-- IMPLEMTENTATION

-- @def:9 Localize `string.*`, `table.*`, and `io.*` functions
-- bypasses metatable and global lookups in the hot loop
local find   = string.find
local sub    = string.sub
local byte   = string.byte
local match  = string.match
local gmatch = string.gmatch
local gsub   = string.gsub
local fmt    = string.format
local concat = table.concat
local open   = io.open

-- @def:3!n Shell-escape a string for safe interpolation into `io.popen`
-- prevents breakage from paths containing `"`, `$()`, or backticks
local function shell_quote(s)
    return "'" .. gsub(s, "'", "'\\''") .. "'"
end

-- @def:11 Parse CLI args with defaults
-- strip trailing slash, resolve absolute path via `/proc/self/environ`
-- `US` separates multi-line text within record fields
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
local HOME = match(SCAN_DIR, "^(/[^/]+/[^/]+)")
local US = "\031"

-- @run:6 Strip leading spaces and tabs via byte scan
-- returns original string when no trimming needed
local function trim_lead(s)
    local i = 1
    while byte(s, i) == 32 or byte(s, i) == 9 do i = i + 1 end
    if i == 1 then return s end
    return sub(s, i)
end

-- @run:6 Strip trailing spaces and tabs via byte scan
-- returns original string when no trimming needed
local function trim_trail(s)
    local i = #s
    while i > 0 and (byte(s, i) == 32 or byte(s, i) == 9) do i = i - 1 end
    if i == #s then return s end
    return sub(s, 1, i)
end

-- @run:3 Trim both ends via `trim_lead` and `trim_trail`
local function trim(s)
    return trim_trail(trim_lead(s))
end

-- @chk:5 Test whether a line contains any documentation tag
-- early `@` check short-circuits lines with no tags
local function has_tag(line)
    if not find(line, "@", 1, true) then return nil end
    return find(line, "@def", 1, true) or find(line, "@chk", 1, true) or
           find(line, "@run", 1, true) or find(line, "@err", 1, true)
end

-- @chk:7 Classify a tagged line into `DEF`, `CHK`, `RUN`, or `ERR`
local function get_tag(line)
    if     find(line, "@def", 1, true) then return "DEF"
    elseif find(line, "@chk", 1, true) then return "CHK"
    elseif find(line, "@run", 1, true) then return "RUN"
    elseif find(line, "@err", 1, true) then return "ERR"
    end
end

-- @chk:5 Extract the subject line count from `@tag:N` syntax
-- using pattern capture after the colon
local function get_subject_count(text)
    local n = match(text, "@def:(%d+)") or match(text, "@chk:(%d+)") or
              match(text, "@run:(%d+)") or match(text, "@err:(%d+)")
    return tonumber(n) or 0
end

-- @run:9 Strip `@tag:N` and trailing digits from text
-- rejoining prefix with remaining content
local function strip_tag_num(text, tag)
    local pos = find(text, tag .. ":", 1, true)
    if not pos then return text end
    local prefix = sub(text, 1, pos - 1)
    local rest = sub(text, pos + #tag + 1)
    rest = gsub(rest, "^%d+!?%a?", "")
    rest = gsub(rest, "^ ", "", 1)
    return prefix .. rest
end

-- @def:1 Hoisted `TAGS` table avoids per-call allocation in `strip_tags`
local TAGS = {"@def", "@chk", "@run", "@err"}

-- @def:1 Map `!x` suffixes to admonition types
local ADMONITIONS = {n="NOTE", t="TIP", i="IMPORTANT", w="WARNING", c="CAUTION"}

-- @def:2 Map tag prefixes to anchor slugs and section titles
local TAG_SEC   = {CHK="chk", DEF="def", RUN="run", ERR="err"}
local TAG_TITLE = {CHK="Checks", DEF="Defines", RUN="Runners", ERR="Errors"}

-- @chk:4 Extract `!x` admonition suffix from tag syntax
local function get_admonition(text)
    local code = match(text, "@%a+:?%d*!(%a)")
    if code then return ADMONITIONS[code] end
end

-- @run:22 Remove `@tag`, `@tag:N`, or `@tag!x` syntax from comment text
-- delegates to `strip_tag_num` for `:N` and `:N!x` variants
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

-- @chk:21 Detect comment style via byte-level prefix check
-- skips leading whitespace without allocating a trimmed copy
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

-- @run Strip comment delimiters and extract inner text
-- for all styles including block continuations
local function strip_comment(line, style)
    -- @chk shell type comments
    if style == "hash" then
        local sc = match(line, "#(.*)") or ""
        return trim_lead(sc)
    -- @chk double-slash comments
    elseif style == "dslash" then
        local sc = match(line, "//(.*)") or ""
        return trim_lead(sc)

    -- @chk double-dash comments
    elseif style == "ddash" then
        local sc = match(line, "%-%-(.*)") or ""
        return trim_lead(sc)

    -- @chk C-style block opening
    elseif style == "cblock" then
        local sc = match(line, "/%*(.*)") or ""
        sc = trim_trail(sc)
        if sub(sc, -2) == "*/" then sc = sub(sc, 1, -3) end
        return trim(sc)

    -- @chk HTML comment opening
    elseif style == "html" then
        local sc = match(line, "<!%-%-(.*)") or ""
        sc = trim_trail(sc)
        if sub(sc, -3) == "-->" then sc = sub(sc, 1, -4) end
        return trim(sc)

    -- @chk block comment continuation lines
    elseif style == "cblock_cont" then
        local sc = trim_trail(line)
        if sub(sc, -2) == "*/" then sc = sub(sc, 1, -3) end
        sc = trim_lead(sc)
        if sub(sc, 1, 1) == "*" then
            sc = sub(sc, 2)
            sc = trim_lead(sc)
        end
        return trim_trail(sc)

    -- @chk html closing
    elseif style == "html_cont" then
        local sc = trim_trail(line)
        if sub(sc, -3) == "-->" then sc = sub(sc, 1, -4) end
        return trim(sc)

    -- @chk triple-quote docstring styles
    elseif style == "dquote" then
        local sc = match(line, '"""(.*)') or ""
        sc = trim_trail(sc)
        if sub(sc, -3) == '"""' then sc = sub(sc, 1, -4) end
        return trim(sc)

    elseif style == "squote" then
        local sc = match(line, "'''(.*)") or ""
        sc = trim_trail(sc)
        if sub(sc, -3) == "'''" then sc = sub(sc, 1, -4) end
        return trim(sc)

    -- @chk docstring continuation lines
    -- no opening delimiter to strip; checks both `"""` and `'''` closers
    elseif style == "docstring_cont" then
        local sc = trim_trail(line)
        if sub(sc, -3) == '"""' then
            sc = sub(sc, 1, -4)
        elseif sub(sc, -3) == "'''" then
            sc = sub(sc, 1, -4)
        end
        return trim(sc)
    end
    return line
end

-- @def:12 Map file extension to fenced code block language
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

-- @def:4 Map shebang interpreters to fenced code block language
local shebang_map = {
    {"python", "python"}, {"node", "javascript"}, {"ruby", "ruby"},
    {"perl", "perl"}, {"lua", "lua"}, {"php", "php"}, {"sh", "sh"},
}

-- @chk:12 Classify file language via extension or shebang
-- accepts `first_line` to avoid reopening the file
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

-- @def:2 Global state for collected records and line count
local records = {}
local total_input = 0

-- @run Walk one file as a line-by-line state machine
-- extracting tagged comments into `records` table
local function process_file(filepath)
    -- @def:4!n Bulk-read file first so `get_lang` reuses the buffer
    -- avoids a second `open`+`read` just for shebang detection
    local f = open(filepath, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()

    -- @def:15 Initialize per-file state machine variables
    -- `get_lang` receives first line to avoid reopening the file
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

    -- @run:37!n Emit a documentation record or defer for subject capture
    -- `lang` is passed through as-is, empty string means no fence label
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

    -- @run:9 Flush deferred record with captured `subj` lines
    local function flush_pending()
        if pending then
            pending.subj = subj
            records[#records + 1] = pending
            pending = nil
            subj    = ""
            capture = 0
        end
    end

    local pos = 1
    local clen = #content

    while pos <= clen do
        local nl = find(content, "\n", pos, true) or clen + 1
        local line = sub(content, pos, nl - 1)
        pos = nl + 1
        ln = ln + 1

        -- @run Subject line capture mode
        if capture > 0 then
            if subj ~= "" then
                subj = subj .. US .. line
            else
                subj = line
            end
            capture = capture - 1
            if capture == 0 then flush_pending() end
            goto continue
        end

        -- @run Accumulate C-style block comment with tag
        if state == "cblock" then
            if find(line, "*/", 1, true) then
                local sc = strip_comment(line, "cblock_cont")
                if sc ~= "" then text = text .. US .. sc end
                emit()
            else
                local sc = strip_comment(line, "cblock_cont")
                text = text .. US .. sc
            end
            goto continue
        end

        -- @run Accumulate HTML comment with tag
        if state == "html" then
            if find(line, "-->", 1, true) then
                local sc = strip_comment(line, "html_cont")
                if sc ~= "" then text = text .. US .. sc end
                emit()
            else
                local sc = strip_comment(line, "html_cont")
                text = text .. US .. sc
            end
            goto continue
        end

        -- @chk Scan untagged block comment for tags
        if state == "cblock_scan" then
            if find(line, "*/", 1, true) then
                state = ""
            else
                if has_tag(line) then
                    tag   = get_tag(line)
                    start = tostring(ln)
                    local ti = 1; while byte(line,ti) == 32 or byte(line,ti) == 9 do ti = ti+1 end; tag_indent = ti-1
                    local sc = strip_comment(line, "cblock_cont")
                    nsubj = get_subject_count(sc)
                    adm   = get_admonition(sc)
                    text  = strip_tags(sc)
                    state = "cblock"
                end
            end
            goto continue
        end

        -- @chk Scan untagged HTML comment for tags
        if state == "html_scan" then
            if find(line, "-->", 1, true) then
                state = ""
            else
                if has_tag(line) then
                    tag   = get_tag(line)
                    start = tostring(ln)
                    local ti = 1; while byte(line,ti) == 32 or byte(line,ti) == 9 do ti = ti+1 end; tag_indent = ti-1
                    local sc = strip_comment(line, "html_cont")
                    nsubj = get_subject_count(sc)
                    adm   = get_admonition(sc)
                    text  = strip_tags(sc)
                    state = "html"
                end
            end
            goto continue
        end

        -- @run Accumulate docstring with tag
        if state == "dquote" or state == "squote" then
            local close = (state == "dquote") and '"""' or "'''"
            if find(line, close, 1, true) then
                local sc = strip_comment(line, "docstring_cont")
                if sc ~= "" then text = text .. US .. sc end
                emit()
            else
                local sc = strip_comment(line, "docstring_cont")
                text = text .. US .. sc
            end
            goto continue
        end

        -- @chk Scan untagged docstring for tags
        if state == "dquote_scan" or state == "squote_scan" then
            local close, promote
            if state == "dquote_scan" then
                close = '"""'; promote = "dquote"
            else
                close = "'''"; promote = "squote"
            end
            if find(line, close, 1, true) then
                state = ""
            else
                if has_tag(line) then
                    tag   = get_tag(line)
                    start = tostring(ln)
                    local ti = 1; while byte(line,ti) == 32 or byte(line,ti) == 9 do ti = ti+1 end; tag_indent = ti-1
                    local sc = strip_comment(line, "docstring_cont")
                    nsubj = get_subject_count(sc)
                    adm   = get_admonition(sc)
                    text  = strip_tags(sc)
                    state = promote
                end
            end
            goto continue
        end

        -- @chk Detect comment style of current line
        local style = detect_style(line)

        -- @run Continue or close existing single-line comment block
        if state ~= "" then
            if style == state then
                if has_tag(line) then
                    emit()
                else
                    local sc = strip_comment(line, style)
                    text = text .. US .. sc
                    goto continue
                end
            else
                emit()
            end
        end

        -- @run Dispatch new tagged comment by style
        if has_tag(line) and style ~= "none" then
            tag   = get_tag(line)
            start = tostring(ln)
            local ti = 1; while byte(line,ti) == 32 or byte(line,ti) == 9 do ti = ti+1 end; tag_indent = ti-1
            local sc = strip_comment(line, style)
            nsubj = get_subject_count(sc)
            adm   = get_admonition(sc)
            text  = strip_tags(sc)

            if style == "hash" or style == "dslash" or style == "ddash" then
                state = style
            elseif style == "cblock" then
                if find(line, "*/", 1, true) then emit() else state = "cblock" end
            elseif style == "html" then
                if find(line, "-->", 1, true) then emit() else state = "html" end
            elseif style == "dquote" then
                local rest = match(line, '"""(.*)')
                if rest and find(rest, '"""', 1, true) then emit() else state = "dquote" end
            elseif style == "squote" then
                local rest = match(line, "'''(.*)")
                if rest and find(rest, "'''", 1, true) then emit() else state = "squote" end
            end

        -- @chk Untagged block comment start - scan for tags
        elseif style == "cblock" then
            if not find(line, "*/", 1, true) then state = "cblock_scan" end
        elseif style == "html" then
            if not find(line, "-->", 1, true) then state = "html_scan" end
        elseif style == "dquote" then
            local rest = match(line, '"""(.*)')
            if not (rest and find(rest, '"""', 1, true)) then state = "dquote_scan" end
        elseif style == "squote" then
            local rest = match(line, "'''(.*)")
            if not (rest and find(rest, "'''", 1, true)) then state = "squote_scan" end
        end

        -- @run Begin subject capture if waiting and hit a code line
        if cap_want > 0 and style == "none" then
            capture  = cap_want
            cap_want = 0
            subj     = line
            capture  = capture - 1
            if capture == 0 then flush_pending() end
        end

        ::continue::
    end

    emit()
    if cap_want > 0 then cap_want = 0 end
    flush_pending()
    total_input = total_input + ln
end

-- @run:77 Render `records` into grouped markdown
-- with blockquotes for text and fenced code blocks for subjects
local function render_markdown()
    local out = {}
    local function w(s) out[#out + 1] = s end

    w(fmt("# %s\n\n", TITLE))

    local function render_section(prefix)
        local entries = {}
        for _, r in ipairs(records) do
            if r.tag == prefix then
                entries[#entries + 1] = r
            end
        end
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

    render_section("CHK")
    render_section("DEF")
    render_section("RUN")
    render_section("ERR")

    return concat(out)
end

-- @run Main function
local function main()
    -- @run:17 Discover files containing documentation tags
    -- respect `.gitignore` patterns via `grep --exclude-from`
    local gi = ""
    local gf = open(SCAN_DIR .. "/.gitignore", "r")
    if gf then
        gf:close()
        gi = "--exclude-from=" .. shell_quote(SCAN_DIR .. "/.gitignore")
    end

    local cmd = fmt(
        'grep -rl -I --exclude-dir=.git %s -e "@def" -e "@chk" -e "@run" -e "@err" %s 2>/dev/null',
        gi, shell_quote(SCAN_DIR)
    )
    local pipe = io.popen(cmd)
    local files = {}
    for line in pipe:lines() do
        files[#files + 1] = line
    end
    pipe:close()

    -- @chk Verify tagged files were discovered
    if #files == 0 then
        -- @err:5 Handle missing tagged files
        -- with empty output and `stderr` warning
        local f = open(OUTPUT, "w")
        f:write(fmt("# %s\n\nNo tagged documentation found.\n", TITLE))
        f:close()
        io.stderr:write(fmt("autodocs: no tags found under %s\n", SCAN_DIR))
        return
    end

    local out_base = match(OUTPUT, "([^/]+)$")
    local out_base_escaped = gsub(out_base, "(%W)", "%%%1")

    -- @run:5 Process all discovered files into intermediate `records`
    for _, fp in ipairs(files) do
        if not match(fp, "/" .. out_base_escaped .. "$") then
            process_file(fp)
        end
    end

    -- @chk Verify extraction produced results
    if #records == 0 then
        -- @err:5 Handle extraction failure
        -- with empty output and `stderr` warning
        local f = open(OUTPUT, "w")
        f:write(fmt("# %s\n\nNo tagged documentation found.\n", TITLE))
        f:close()
        io.stderr:write(fmt("autodocs: tags found but no extractable docs under %s\n", SCAN_DIR))
        return
    end

    -- @run Resolve parents, assign indices and anchors (single pass)
    local cf = {CHK="", DEF="", RUN="", ERR=""}
    local mi = {CHK=0, DEF=0, RUN=0, ERR=0}
    local si = {CHK=0, DEF=0, RUN=0, ERR=0}
    for i, r in ipairs(records) do
        if r.indent > 0 then
            for j = i - 1, 1, -1 do
                local rj = records[j]
                if rj.file == r.file and rj.indent < r.indent then
                    r.parent = rj
                    break
                end
            end
        end
        local t = r.tag
        if cf[t] ~= r.file then
            cf[t] = r.file
            mi[t] = mi[t] + 1
            si[t] = 0
            r.idx = fmt("%d.", mi[t])
            r.anchor = fmt("%s-%d", TAG_SEC[t], mi[t])
        else
            si[t] = si[t] + 1
            r.idx = fmt("%d.%d", mi[t], si[t])
            r.anchor = fmt("%s-%d-%d", TAG_SEC[t], mi[t], si[t])
        end
        r.sec_title = TAG_TITLE[t]
    end

    -- @chk:10 Render and compare against existing output
    -- skip write if content is unchanged
    local markdown = render_markdown()
    local ef = open(OUTPUT, "r")
    if ef then
        local existing = ef:read("*a")
        ef:close()
        if existing == markdown then
            io.stderr:write(fmt("autodocs: %s unchanged\n", OUTPUT))
            return
        end
    end

    -- @run:6 Write output and report ratio
    -- wraps across two lines so `:N` count must include the continuation
    local f = open(OUTPUT, "w")
    f:write(markdown)
    f:close()
    local ol = select(2, gsub(markdown, "\n", "")) + 1
    io.stderr:write(fmt("autodocs: wrote %s (%d/%d = %d%%)\n",
        OUTPUT, ol, total_input, total_input > 0 and math.floor(ol * 100 / total_input) or 0))

    -- @run:9 Run `stats.awk` on the output if `-s` flag is set
    if STATS then
        local script_dir = match(arg[0], "^(.*/)") or "./"
        local stats_awk = script_dir .. "stats.awk"
        local sf = open(stats_awk, "r")
        if sf then
            sf:close()
            os.execute(fmt("awk -f %s %s >&2", shell_quote(stats_awk), shell_quote(OUTPUT)))
        end
    end
end

-- @run:1 Entry point
main()

