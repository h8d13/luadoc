#!/usr/bin/env lua

-- @set:6 Parse CLI args with defaults
-- strip trailing slash, resolve absolute path via cd
-- `US` separates multi-line text within record fields
local SCAN_DIR = arg[1] or "."
local OUTPUT   = arg[2] or "readme.md"
SCAN_DIR = SCAN_DIR:gsub("/$", "")
local p = io.popen('cd "' .. SCAN_DIR .. '" && pwd')
SCAN_DIR = p:read("*l")
p:close()
local US = "\031"

-- @cal:3 Strip leading spaces and tabs from a string
local function trim_lead(s)
    return (s:gsub("^[ \t]+", ""))
end

-- @cal:3 Strip trailing spaces and tabs from a string
local function trim_trail(s)
    return (s:gsub("[ \t]+$", ""))
end

-- @cal:3 Trim both ends via trim_lead and trim_trail
local function trim(s)
    return trim_trail(trim_lead(s))
end

-- @ass:4 Test whether a line contains any documentation tag
local function has_tag(line)
    return line:find("@set", 1, true) or line:find("@ass", 1, true) or
           line:find("@cal", 1, true) or line:find("@rai", 1, true)
end

-- @ass:7 Classify a tagged line into SET, ASS, CAL, or RAI
local function get_tag(line)
    if     line:find("@set", 1, true) then return "SET"
    elseif line:find("@ass", 1, true) then return "ASS"
    elseif line:find("@cal", 1, true) then return "CAL"
    elseif line:find("@rai", 1, true) then return "RAI"
    end
end

-- @cal:5 Extract the subject line count from `@tag:N` syntax
-- parsing leading digits after the colon
local function get_subject_count(text)
    local n = text:match("@set:(%d+)") or text:match("@ass:(%d+)") or
              text:match("@cal:(%d+)") or text:match("@rai:(%d+)")
    return tonumber(n) or 0
end

-- @cal:7 Strip `@tag:N` and trailing digits from text
-- rejoining prefix with remaining content
local function strip_tag_num(text, tag)
    local pos = text:find(tag .. ":", 1, true)
    if not pos then return text end
    local prefix = text:sub(1, pos - 1)
    local rest = text:sub(pos + #tag + 1)
    rest = rest:gsub("^%d+", "")
    rest = rest:gsub("^ ", "", 1)
    return prefix .. rest
end

-- @cal:17 Remove `@tag` or `@tag:N` syntax from comment text
-- delegates to `strip_tag_num` for `:N` variants
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

-- @ass:12 Detect comment style from a source line
-- `none` skips early in next defs
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

-- @cal Strip comment delimiters and extract inner text
-- for all styles including block continuations
local function strip_comment(line, style)
    if style == "hash" then
        local sc = line:match("#(.*)") or ""
        return trim_lead(sc)

    elseif style == "dslash" then
        local sc = line:match("//(.*)") or ""
        return trim_lead(sc)

    elseif style == "ddash" then
        local sc = line:match("%-%-(.*)") or ""
        return trim_lead(sc)

    elseif style == "cblock" then
        local sc = line:match("/%*(.*)") or ""
        sc = trim_trail(sc)
        if sc:sub(-2) == "*/" then sc = sc:sub(1, -3) end
        return trim(sc)

    elseif style == "html" then
        local sc = line:match("<!%-%-(.*)") or ""
        sc = trim_trail(sc)
        if sc:sub(-3) == "-->" then sc = sc:sub(1, -4) end
        return trim(sc)

    elseif style == "cblock_cont" then
        local sc = trim_trail(line)
        if sc:sub(-2) == "*/" then sc = sc:sub(1, -3) end
        sc = trim_lead(sc)
        if sc:sub(1, 1) == "*" then
            sc = sc:sub(2)
            sc = trim_lead(sc)
        end
        return trim_trail(sc)

    elseif style == "html_cont" then
        local sc = trim_trail(line)
        if sc:sub(-3) == "-->" then sc = sc:sub(1, -4) end
        return trim(sc)

    elseif style == "dquote" then
        local sc = line:match('"""(.*)') or ""
        sc = trim_trail(sc)
        if sc:sub(-3) == '"""' then sc = sc:sub(1, -4) end
        return trim(sc)

    elseif style == "squote" then
        local sc = line:match("'''(.*)") or ""
        sc = trim_trail(sc)
        if sc:sub(-3) == "'''" then sc = sc:sub(1, -4) end
        return trim(sc)

    elseif style == "docstring_cont" then
        local sc = trim_trail(line)
        if sc:sub(-3) == '"""' then
            sc = sc:sub(1, -4)
        elseif sc:sub(-3) == "'''" then
            sc = sc:sub(1, -4)
        end
        return trim(sc)
    end
    return line
end

-- @ass Map file extension to fenced code block language
-- falling back to shebang detection for extensionless files
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

local shebang_map = {
    {"python", "python"}, {"node", "javascript"}, {"ruby", "ruby"},
    {"perl", "perl"}, {"lua", "lua"}, {"php", "php"}, {"sh", "sh"},
}

local function get_lang(filepath)
    local ext = filepath:match("%.([^%.]+)$")
    if ext and ext_map[ext] then return ext_map[ext] end
    local f = io.open(filepath, "r")
    if f then
        local first = f:read("*l")
        f:close()
        if first and first:sub(1, 3) == "#!/" then
            for _, pair in ipairs(shebang_map) do
                if first:find(pair[1], 1, true) then
                    return pair[2]
                end
            end
        end
    end
    return ""
end

-- Records collected across all files
local records = {}

-- @cal Walk one file as a line-by-line state machine
-- extracting tagged comments into records table
local function process_file(filepath)
    -- @set:12 Initialize per-file state machine variables
    -- `get_lang` sets language via return value
    -- records table collects output in-memory
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

    -- @cal:21 Emit a documentation record or defer for subject capture
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

    -- @cal:8 Flush deferred record with captured subject lines
    local function flush_pending()
        if pending then
            pending.subj = subj
            records[#records + 1] = pending
            pending = nil
            subj    = ""
            capture = 0
        end
    end

    local f = io.open(filepath, "r")
    if not f then return end

    for line in f:lines() do
        ln = ln + 1

        -- Subject line capture mode
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

        -- Inside a C-style block comment with tag
        if state == "cblock" then
            if line:find("*/", 1, true) then
                local sc = strip_comment(line, "cblock_cont")
                if sc ~= "" then text = text .. US .. sc end
                emit()
            else
                local sc = strip_comment(line, "cblock_cont")
                text = text .. US .. sc
            end
            goto continue
        end

        -- Inside an HTML comment with tag
        if state == "html" then
            if line:find("-->", 1, true) then
                local sc = strip_comment(line, "html_cont")
                if sc ~= "" then text = text .. US .. sc end
                emit()
            else
                local sc = strip_comment(line, "html_cont")
                text = text .. US .. sc
            end
            goto continue
        end

        -- Scanning a block comment for a tag
        if state == "cblock_scan" then
            if line:find("*/", 1, true) then
                state = ""
            else
                if has_tag(line) then
                    tag   = get_tag(line)
                    start = tostring(ln)
                    local sc = strip_comment(line, "cblock_cont")
                    nsubj = get_subject_count(sc)
                    text  = strip_tags(sc)
                    state = "cblock"
                end
            end
            goto continue
        end

        -- Scanning an HTML comment for a tag
        if state == "html_scan" then
            if line:find("-->", 1, true) then
                state = ""
            else
                if has_tag(line) then
                    tag   = get_tag(line)
                    start = tostring(ln)
                    local sc = strip_comment(line, "html_cont")
                    nsubj = get_subject_count(sc)
                    text  = strip_tags(sc)
                    state = "html"
                end
            end
            goto continue
        end

        -- Inside a docstring with tag
        if state == "dquote" or state == "squote" then
            local close = (state == "dquote") and '"""' or "'''"
            if line:find(close, 1, true) then
                local sc = strip_comment(line, "docstring_cont")
                if sc ~= "" then text = text .. US .. sc end
                emit()
            else
                local sc = strip_comment(line, "docstring_cont")
                text = text .. US .. sc
            end
            goto continue
        end

        -- Scanning a docstring for a tag
        if state == "dquote_scan" or state == "squote_scan" then
            local close, promote
            if state == "dquote_scan" then
                close = '"""'; promote = "dquote"
            else
                close = "'''"; promote = "squote"
            end
            if line:find(close, 1, true) then
                state = ""
            else
                if has_tag(line) then
                    tag   = get_tag(line)
                    start = tostring(ln)
                    local sc = strip_comment(line, "docstring_cont")
                    nsubj = get_subject_count(sc)
                    text  = strip_tags(sc)
                    state = promote
                end
            end
            goto continue
        end

        -- Default: detect comment style of current line
        local style = detect_style(line)

        -- Continue existing single-line comment block
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

        -- New tagged comment
        if has_tag(line) and style ~= "none" then
            tag   = get_tag(line)
            start = tostring(ln)
            local sc = strip_comment(line, style)
            nsubj = get_subject_count(sc)
            text  = strip_tags(sc)

            if style == "hash" or style == "dslash" or style == "ddash" then
                state = style
            elseif style == "cblock" then
                if line:find("*/", 1, true) then emit() else state = "cblock" end
            elseif style == "html" then
                if line:find("-->", 1, true) then emit() else state = "html" end
            elseif style == "dquote" then
                local rest = line:match('"""(.*)')
                if rest and rest:find('"""', 1, true) then emit() else state = "dquote" end
            elseif style == "squote" then
                local rest = line:match("'''(.*)")
                if rest and rest:find("'''", 1, true) then emit() else state = "squote" end
            end

        -- Untagged block comment start - scan for tags
        elseif style == "cblock" then
            if not line:find("*/", 1, true) then state = "cblock_scan" end
        elseif style == "html" then
            if not line:find("-->", 1, true) then state = "html_scan" end
        elseif style == "dquote" then
            local rest = line:match('"""(.*)')
            if not (rest and rest:find('"""', 1, true)) then state = "dquote_scan" end
        elseif style == "squote" then
            local rest = line:match("'''(.*)")
            if not (rest and rest:find("'''", 1, true)) then state = "squote_scan" end
        end

        -- Begin subject capture if we're waiting and hit a code line
        if cap_want > 0 and style == "none" then
            capture  = cap_want
            cap_want = 0
            subj     = line
            capture  = capture - 1
            if capture == 0 then flush_pending() end
        end

        ::continue::
    end

    f:close()
    emit()
    if cap_want > 0 then cap_want = 0 end
    flush_pending()
end

-- @cal:39 Render intermediate records into grouped markdown
-- with blockquotes for text and fenced code blocks for subjects
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
                w("```\n")
            end
            w("\n")
        end
    end

    render_section("SET", "Setters", "@set")
    render_section("ASS", "Asserts", "@ass")
    render_section("CAL", "Callers", "@cal")
    render_section("RAI", "Raisers", "@rai")

    return table.concat(out)
end

-- @cal Entry point
local function main()
    -- @cal:5 Discover files containing documentation tags
    -- respect .gitignore patterns via --exclude-from when present
    local gi = ""
    local gf = io.open(SCAN_DIR .. "/.gitignore", "r")
    if gf then
        gf:close()
        gi = "--exclude-from=" .. SCAN_DIR .. "/.gitignore"
    end

    local cmd = string.format(
        'grep -rl -I --exclude-dir=.git %s -e "@set" -e "@ass" -e "@cal" -e "@rai" "%s" 2>/dev/null',
        gi, SCAN_DIR
    )
    local pipe = io.popen(cmd)
    local files = {}
    for line in pipe:lines() do
        files[#files + 1] = line
    end
    pipe:close()

    -- @ass Verify tagged files were discovered
    if #files == 0 then
        -- @rai:3 Handle missing tagged files
        -- with empty output and stderr warning
        local f = io.open(OUTPUT, "w")
        f:write("# Autodocs\n\nNo tagged documentation found.\n")
        f:close()
        io.stderr:write(string.format("autodocs: no tags found under %s\n", SCAN_DIR))
        return
    end

    local out_base = OUTPUT:match("([^/]+)$")
    local out_base_escaped = out_base:gsub("(%W)", "%%%1")

    -- @cal:6 Process all discovered files into intermediate records
    for _, fp in ipairs(files) do
        if not fp:match("/" .. out_base_escaped .. "$") then
            process_file(fp)
        end
    end

    -- @ass Verify extraction produced results
    if #records == 0 then
        -- @rai:3 Handle extraction failure
        -- with empty output and stderr warning
        local f = io.open(OUTPUT, "w")
        f:write("# Autodocs\n\nNo tagged documentation found.\n")
        f:close()
        io.stderr:write(string.format("autodocs: tags found but no extractable docs under %s\n", SCAN_DIR))
        return
    end

    -- @cal:2 Render documentation and write output file
    local markdown = render_markdown()
    local f = io.open(OUTPUT, "w")
    f:write(markdown)
    f:close()
    io.stderr:write(string.format("autodocs: wrote %s\n", OUTPUT))
end

-- @cal:1 Entry point
main()
