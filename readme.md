# Autodocs

## Setters (@set)

### `/home/hadean/Desktop/Bin/autodocs:4`
> Configure scan directory and output path

> from CLI arguments with field delimiters

```sh
SCAN_DIR="${1:-.}"
OUTPUT="${2:-readme.md}"
SCAN_DIR="${SCAN_DIR%/}"
SCAN_DIR=$(cd "$SCAN_DIR" && pwd)
TAB=$(printf '\t')
US=$(printf '\037')
```

### `/home/hadean/Desktop/Bin/autodocs:241`
> Initialize file path and state machine variables

> for tracking comment blocks and subject capture

```sh
    _pf_path="$1"
    _pf_rel="$_pf_path"
    _get_lang "$_pf_path"
    _pf_lang="$_gl"
    _pf_ln=0
    _pf_in=""
    _pf_tag=""
    _pf_start=""
    _pf_text=""
    _pf_nsubj=0
    _pf_cap_want=0
    _pf_capture=0
    _pf_subj=""
    _pf_pending=""
```

## Asserts (@ass)

### `/home/hadean/Desktop/Bin/autodocs:563`
> Verify tagged files were discovered


### `/home/hadean/Desktop/Bin/autodocs:582`
> Verify extraction produced results


## Callers (@cal)

### `/home/hadean/Desktop/Bin/autodocs:41`
> Test whether a line contains any documentation tag

```sh
has_tag() {
    case "$1" in
        *'@set'*|*'@ass'*|*'@cal'*|*'@rai'*) return 0 ;;
        *) return 1 ;;
    esac
}
```

### `/home/hadean/Desktop/Bin/autodocs:49`
> Classify a tagged line into SET, ASS, CAL, or RAI

```sh
get_tag() {
    case "$1" in
        *'@set'*) _gt='SET' ;;
        *'@ass'*) _gt='ASS' ;;
        *'@cal'*) _gt='CAL' ;;
        *'@rai'*) _gt='RAI' ;;
    esac
}
```

### `/home/hadean/Desktop/Bin/autodocs:59`
> Extract the subject line count from @tag:N syntax

> parsing leading digits after the colon into _gsc

```sh
get_subject_count() {
    _gsc=0
    case "$1" in
        *'@set:'[0-9]*) _gsc_r="${1#*@set:}" ;;
        *'@ass:'[0-9]*) _gsc_r="${1#*@ass:}" ;;
        *'@cal:'[0-9]*) _gsc_r="${1#*@cal:}" ;;
        *'@rai:'[0-9]*) _gsc_r="${1#*@rai:}" ;;
        *) return ;;
    esac
    _gsc=""
    while :; do
        case "$_gsc_r" in
            [0-9]*) _gsc="${_gsc}${_gsc_r%"${_gsc_r#?}"}"; _gsc_r="${_gsc_r#?}" ;;
            *) break ;;
        esac
    done
    [ -z "$_gsc" ] && _gsc=0 || :
}
```

### `/home/hadean/Desktop/Bin/autodocs:88`
> Remove @tag or @tag:N syntax from comment text

```sh
strip_tags() {
    case "$1" in
        *'@set:'[0-9]*) _strip_tag_num "$1" "@set" ;;
        *'@set '*)      _st="${1%%@set *}${1#*@set }" ;;
        *'@set'*)       _st="${1%%@set*}${1#*@set}" ;;
        *'@ass:'[0-9]*) _strip_tag_num "$1" "@ass" ;;
        *'@ass '*)      _st="${1%%@ass *}${1#*@ass }" ;;
        *'@ass'*)       _st="${1%%@ass*}${1#*@ass}" ;;
        *'@cal:'[0-9]*) _strip_tag_num "$1" "@cal" ;;
        *'@cal '*)      _st="${1%%@cal *}${1#*@cal }" ;;
        *'@cal'*)       _st="${1%%@cal*}${1#*@cal}" ;;
        *'@rai:'[0-9]*) _strip_tag_num "$1" "@rai" ;;
        *'@rai '*)      _st="${1%%@rai *}${1#*@rai }" ;;
        *'@rai'*)       _st="${1%%@rai*}${1#*@rai}" ;;
        *)              _st="$1" ;;
    esac
}
```

### `/home/hadean/Desktop/Bin/autodocs:107`
> Detect comment style from a source line

> supporting hash, dslash, cblock, html, dquote, squote, ddash

```sh
detect_style() {
    _trim_lead "$1"
    case "$_tl" in
        '<!--'*)    _ds='html'   ;;
        '/*'*)      _ds='cblock' ;;
        '//'*)      _ds='dslash' ;;
        '#'*)       _ds='hash'   ;;
        '"""'*)     _ds='dquote' ;;
        "'''"*)     _ds='squote' ;;
        '--'*)      _ds='ddash'  ;;
        *)          _ds='none'   ;;
    esac
}
```

### `/home/hadean/Desktop/Bin/autodocs:123`
> Strip comment delimiters and extract inner text

> for all styles including block continuations


### `/home/hadean/Desktop/Bin/autodocs:189`
> Map file extension to fenced code block language

> falling back to shebang detection for extensionless files


### `/home/hadean/Desktop/Bin/autodocs:238`
> Walk one file as a line-by-line state machine

> extracting tagged comments into tab-delimited records


### `/home/hadean/Desktop/Bin/autodocs:258`
> Emit a documentation record or defer for subject capture


### `/home/hadean/Desktop/Bin/autodocs:281`
> Flush deferred record with captured subject lines


### `/home/hadean/Desktop/Bin/autodocs:515`
> Render intermediate records into grouped markdown

> with blockquotes for text and fenced code blocks for subjects


### `/home/hadean/Desktop/Bin/autodocs:558`
> Discover files containing documentation tags

```sh
    _m_files=$(grep -rl -I \
        -e '@set' -e '@ass' -e '@cal' -e '@rai' \
        "$SCAN_DIR" 2>/dev/null) || true
```

### `/home/hadean/Desktop/Bin/autodocs:574`
> Process all discovered files into intermediate records

```sh
    _m_intermediate=$(
        printf '%s\n' "$_m_files" | while IFS="" read -r _m_fp; do
            case "$_m_fp" in */"$_m_out_base") continue ;; esac
            process_file "$_m_fp"
        done
    )
```

### `/home/hadean/Desktop/Bin/autodocs:591`
> Render documentation and write output file

```sh
    render_markdown "$_m_intermediate" > "$OUTPUT"
    printf 'autodocs: wrote %s\n' "$OUTPUT" >&2
```

### `/home/hadean/Desktop/Bin/autodocs:596`
> Entry point

```sh
main
```

## Raisers (@rai)

### `/home/hadean/Desktop/Bin/autodocs:565`
> Handle missing tagged files

> with empty output and stderr warning

```sh
        printf '# Autodocs\n\nNo tagged documentation found.\n' > "$OUTPUT"
        printf 'autodocs: no tags found under %s\n' "$SCAN_DIR" >&2
        return 0
```

### `/home/hadean/Desktop/Bin/autodocs:584`
> Handle extraction failure

> with empty output and stderr warning

```sh
        printf '# Autodocs\n\nNo tagged documentation found.\n' > "$OUTPUT"
        printf 'autodocs: tags found but no extractable docs under %s\n' "$SCAN_DIR" >&2
        return 0
```

