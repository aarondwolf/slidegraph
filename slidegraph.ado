*! version 1.3.0  05nov2026
*! slidegraph: Automated stepped/layered graph generation for presentations
*! Author: Aaron Wolf (aaron.wolf@u.northwestern.edu)
*! Program architecture: slidegraph set, slidegraph, & slidegraph export

program define slidegraph, rclass
    version 15.0

    // Check if arguments are provided
    if `"`0'"' == "" {
        if "$SG_N" != "" {
            slidegraph_query
            exit 0
        }
        else {
            di as text "slidegraph: Automated stepped/layered graph builds for slide presentations"
            di as text "Usage:"
            di as text "  {bf:slidegraph set}, patterns(color1 pat1 ...) [off(0)] [dim(20)]"
            di as text "  {bf:slidegraph set}, colors(color1 color2 ...) {bf:cumulative}|{bf:spotlight} [off(0)] [dim(20)]"
            di as text "  {bf:slidegraph} [, stub(string) saving(string) full] : {it:graph_cmd}"
            di as text "  {bf:slidegraph export} [using file.tex] [, path(string) saving(string) options(string) replace]"
            exit 0
        }
    }

    // Inspect first token
    gettoken subcmd : 0, parse(" ,:")

    if "`subcmd'" == "set" {
        gettoken subcmd rest : 0, parse(" ,:")
        slidegraph_set `rest'
        return add
        exit 0
    }
    else if "`subcmd'" == "export" | "`subcmd'" == "tex" | "`subcmd'" == "beamer" {
        gettoken subcmd rest : 0, parse(" ,:")
        slidegraph_export `rest'
        return add
        exit 0
    }
    else if "`subcmd'" == "clear" | "`subcmd'" == "reset" {
        slidegraph_clear
        exit 0
    }
    else if "`subcmd'" == "query" | "`subcmd'" == "list" | "`subcmd'" == "describe" {
        slidegraph_query
        exit 0
    }
    else {
        // Execute graph sequence
        slidegraph_run `0'
        return add
        exit 0
    }
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph set
// -----------------------------------------------------------------------------
program define slidegraph_set, rclass
    version 15.0
    syntax [, patterns(string asis) colors(string asis) CUMulative SPOTlight off(integer 0) dim(integer 20)]

    // Check patterns vs colors
    if `"`patterns'"' != "" & `"`colors'"' != "" {
        di as error "cannot specify both patterns() and colors()"
        exit 198
    }
    if `"`patterns'"' == "" & `"`colors'"' == "" {
        di as error "must specify either patterns() or colors()"
        exit 198
    }

    // Build preset patterns if colors() was provided
    if `"`colors'"' != "" {
        if "`cumulative'" == "" & "`spotlight'" == "" {
            di as error "must specify either cumulative or spotlight with colors()"
            exit 198
        }
        if "`cumulative'" != "" & "`spotlight'" != "" {
            di as error "cannot specify both cumulative and spotlight"
            exit 198
        }
        local preset = cond("`cumulative'" != "", "cumulative", "spotlight")
        mata: _sg_build_preset_patterns(st_local("colors"), st_local("preset"), "patterns")
    }

    // Validate off and dim are integers between 0 and 100
    if !inrange(`off', 0, 100) {
        di as error "off() must be an integer between 0 and 100"
        exit 198
    }
    if !inrange(`dim', 0, 100) {
        di as error "dim() must be an integer between 0 and 100"
        exit 198
    }

    local off_mod "%`off'"
    local dim_mod "%`dim'"

    // Count tokens
    local ntokens : word count `patterns'
    if `ntokens' == 0 {
        di as error "option patterns() or colors() required"
        exit 198
    }

    // Check for unquoted RGB colors (e.g. 255 0 0 11 ...)
    if `ntokens' >= 4 {
        local w1 : word 1 of `patterns'
        local w2 : word 2 of `patterns'
        local w3 : word 3 of `patterns'
        if real("`w1'") != . & real("`w2'") != . & real("`w3'") != . {
            di as error `"unquoted RGB color detected in patterns(); RGB colors must be enclosed in quotes, e.g. patterns("`w1' `w2' `w3'" <pattern> ...)"'
            exit 198
        }
    }

    if mod(`ntokens', 2) != 0 {
        di as error "patterns() must contain an even number of tokens: <color_token> <binary_pattern> pairs"
        exit 198
    }

    local npairs = `ntokens' / 2
    local N = 0
    local any_rgb = 0
    local has_2 = 0

    // Validate pairs
    forvalues p = 1/`npairs' {
        local c_idx = 2 * `p' - 1
        local pat_idx = 2 * `p'
        local color : word `c_idx' of `patterns'
        local pat   : word `pat_idx' of `patterns'

        local plen = length("`pat'")
        if `plen' == 0 {
            di as error "pattern for color '`color'' cannot be empty"
            exit 198
        }
        if `p' == 1 {
            local N = `plen'
        }
        else if `plen' != `N' {
            di as error "all patterns must have the exact same length (`N'); pattern for '`color'' has length `plen'"
            exit 198
        }

        // Validate that pattern consists strictly of 0, 1, or 2
        forvalues k = 1/`plen' {
            local ch = substr("`pat'", `k', 1)
            if "`ch'" != "0" & "`ch'" != "1" & "`ch'" != "2" {
                di as error "invalid character '`ch'' in pattern '`pat'' for color '`color''; patterns must contain only 0, 1, and 2"
                exit 198
            }
            if "`ch'" == "2" {
                local has_2 = 1
            }
        }

        // Detect if color is RGB
        mata: st_local("is_rgb", strofreal(_sg_is_rgb(st_local("color"), .)))
        if `is_rgb' {
            local any_rgb = 1
            di as text "{p 0 4 2}{bf:warning:} RGB color detected (`color'); using RGB opacity modifiers in Stata requires placing the modifier inside quotes (e.g., " as result `""`color' `off_mod'""' as text "), which can be sensitive to formatting and spacing. Named color styles are recommended, but proceeding anyway.{p_end}"
        }

        // Store pair information
        global SG_color_`p'  `"`color'"'
        global SG_pat_`p'    `"`pat'"'
        global SG_is_rgb_`p' `is_rgb'
    }

    // Store configuration in global macros for state persistence
    global SG_patterns `"`patterns'"'
    global SG_N        `N'
    global SG_off      `"`off_mod'"'
    global SG_dim      `"`dim_mod'"'
    global SG_has_2    `has_2'
    global SG_npairs   `npairs'
    global SG_any_rgb  `any_rgb'

    // Return values in r()
    return scalar N       = `N'
    return scalar npairs  = `npairs'
    return scalar any_rgb = `any_rgb'
    return scalar off_val = `off'
    return scalar dim_val = `dim'
    return scalar has_2   = `has_2'
    return local patterns `"`patterns'"'
    return local off      `"`off_mod'"'
    return local dim      `"`dim_mod'"'

    if `has_2' {
        di as text "slidegraph configuration set: `npairs' pattern(s) across `N' frame(s), dim: " as result "`dim_mod'" as text ", off: " as result "`off_mod'"
    }
    else {
        di as text "slidegraph configuration set: `npairs' pattern(s) across `N' frame(s), off modifier: " as result "`off_mod'"
    }
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph run (default execution)
// -----------------------------------------------------------------------------
program define slidegraph_run, rclass
    version 15.0

    // Check if configuration exists
    if `"$SG_N"' == "" | `"$SG_patterns"' == "" {
        di as error "no slidegraph configuration found; run {bf:slidegraph set} first"
        exit 198
    }

    // Ensure colon syntax is present
    cap _on_colon_parse `0'
    if _rc {
        di as error "syntax error: colon ':' required after slidegraph options"
        exit 198
    }

    local before `"`s(before)'"'
    local cmd    `"`s(after)'"'

    // Parse options before the colon (strictly slidegraph options: stub, saving, full)
    local 0 `"`before'"'
    syntax [, stub(string) saving(string) full]

    if `"`stub'"' == "" {
        local stub "slide"
    }

    // Warn if name() was already specified in the graph command
    if ustrregexm(`"`cmd'"', "\bname\s*\(") {
        di as text "{p 0 4 2}{bf:warning:} 'name()' option detected in graph command; specifying both stub() in slidegraph and name() in the graph command may cause issues{p_end}"
    }

    // Parse saving option if specified
    local save_stem ""
    local save_ext ""
    local save_type ""
    if `"`saving'"' != "" {
        mata: _slidegraph_parse_save(st_local("saving"), "save_stem", "save_ext", "save_type")
    }

    local N      = $SG_N
    local npairs = $SG_npairs
    local off    `"$SG_off"'
    local dim    `"$SG_dim"'

    // Loop through each frame i = 1 to N
    forvalues i = 1/`N' {
        local cur_cmd `"`cmd'"'

        // Apply visibility modifications for frame i
        forvalues p = 1/`npairs' {
            local color `"${SG_color_`p'}"'
            local pat   `"${SG_pat_`p'}"'

            local bit = substr("`pat'", `i', 1)
            if "$SG_has_2" == "1" {
                if "`bit'" == "0" {
                    mata: _sg_replace_color(st_local("cur_cmd"), st_local("color"), st_local("off"), "cur_cmd")
                }
                else if "`bit'" == "1" {
                    mata: _sg_replace_color(st_local("cur_cmd"), st_local("color"), st_local("dim"), "cur_cmd")
                }
                // bit == 2 is focus/on: no replacement needed
            }
            else {
                if "`bit'" == "0" {
                    mata: _sg_replace_color(st_local("cur_cmd"), st_local("color"), st_local("off"), "cur_cmd")
                }
                // bit == 1 is on: no replacement needed
            }
        }

        // Frame name in memory
        local graphname "`stub'_`i'"
        local name_opt `"name(`graphname', replace)"'

        // Inject name() option cleanly into the graph command
        mata: _slidegraph_inject_name(st_local("cur_cmd"), st_local("name_opt"), "exec_cmd")

        // Execute the modified command for frame i
        di as text _col(2) "{hline 64}"
        di as text "slidegraph frame `i'/`N' ({bf:`graphname'}):"
        di as result `"  `exec_cmd'"'
        `exec_cmd'

        // Save or export frame if saving() was requested
        if "`save_type'" == "save" {
            graph save `graphname' `"`save_stem'_`i'`save_ext'"', replace
            di as text `"  Saved graph: `save_stem'_`i'`save_ext'"'
        }
        else if "`save_type'" == "export" {
            graph export `"`save_stem'_`i'`save_ext'"', name(`graphname') replace
            di as text `"  Exported image: `save_stem'_`i'`save_ext'"'
        }
    }

    // If full option requested, generate unsuffixed graph with all series on
    if "`full'" != "" {
        local graphname "`stub'"
        local name_opt `"name(`graphname', replace)"'
        mata: _slidegraph_inject_name(st_local("cmd"), st_local("name_opt"), "exec_cmd")

        di as text _col(2) "{hline 64}"
        di as text "slidegraph full frame ({bf:`graphname'}):"
        di as result `"  `exec_cmd'"'
        `exec_cmd'

        if "`save_type'" == "save" {
            graph save `graphname' `"`save_stem'`save_ext'"', replace
            di as text `"  Saved graph: `save_stem'`save_ext'"'
        }
        else if "`save_type'" == "export" {
            graph export `"`save_stem'`save_ext'"', name(`graphname') replace
            di as text `"  Exported image: `save_stem'`save_ext'"'
        }
    }

    // Store state for slidegraph export / query
    global SG_has_full = ("`full'" != "")
    global SG_saving `"`saving'"'
    global SG_save_stem `"`save_stem'"'
    global SG_save_ext `"`save_ext'"'
    global SG_save_type `"`save_type'"'
    global SG_last_stub `"`stub'"'

    return scalar N = `N'
    return local stub "`stub'"
    return local off `"$SG_off"'
    return local dim `"$SG_dim"'
    if `"`saving'"' != "" {
        return local saving `"`saving'"'
        return local save_stem `"`save_stem'"'
        return local save_ext `"`save_ext'"'
    }
    if "`full'" != "" {
        return local full "1"
    }
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph export (generate LaTeX Beamer overlay snippet)
// -----------------------------------------------------------------------------
program define slidegraph_export, rclass
    version 15.0
    syntax [using/] [, path(string) saving(string) options(string) replace]

    // Verify configuration exists
    if `"$SG_N"' == "" {
        di as error "no slidegraph configuration found; run {bf:slidegraph set} and {bf:slidegraph} first"
        exit 198
    }

    // Determine saving target
    if `"`saving'"' == "" {
        local saving `"$SG_saving"'
    }
    if `"`saving'"' == "" {
        di as error "no saving() filename found; specify saving() in slidegraph export or run slidegraph with saving() first"
        exit 198
    }

    // Parse saving stem and extension
    local save_stem ""
    local save_ext ""
    local save_type ""
    mata: _slidegraph_parse_save(st_local("saving"), "save_stem", "save_ext", "save_type")

    if "`save_ext'" == ".gph" {
        di as text "{p 0 4 2}{bf:note:} saving() has .gph extension; LaTeX typically expects image formats like .pdf, .png, etc.{p_end}"
    }

    local N = $SG_N

    // Format LaTeX image paths using Mata helper
    mata: _slidegraph_format_tex_paths(st_local("save_stem"), st_local("save_ext"), st_local("path"), `N', "tex_img")

    // Determine target .tex file
    if `"`using'"' != "" {
        local target_tex `"`using'"'
        if !strpos(`"`target_tex'"', ".") {
            local target_tex `"`target_tex'.tex"'
        }
    }
    else {
        local target_tex `"`save_stem'.tex"'
    }

    // Check replace
    if "`replace'" == "" {
        capture confirm file `"`target_tex'"'
        if _rc == 0 {
            di as error `"file '`target_tex'' already exists; specify replace option to overwrite"'
            exit 602
        }
    }

    // Default graphicx options
    if `"`options'"' == "" {
        local options "width=\linewidth"
    }

    // Write .tex file
    tempname fh
    file open `fh' using `"`target_tex'"', write text replace
    file write `fh' `"% LaTeX Beamer overlay sequence generated by slidegraph"' _n
    forvalues i = 1/`N' {
        file write `fh' `"\only<`i'>{\includegraphics[`options']{`tex_img_`i''}}%"' _n
    }
    if "$SG_has_full" == "1" {
        file write `fh' `"% Standalone full figure (no overlays):"' _n
        file write `fh' `"% \includegraphics[`options']{`tex_img_full'}"' _n
    }
    file close `fh'

    // Display output in Results window
    di as text _newline _col(2) "{hline 64}"
    di as text "LaTeX Beamer overlay code generated:"
    forvalues i = 1/`N' {
        di as result `"  \only<`i'>{\includegraphics[`options']{`tex_img_`i''}}%"'
    }
    if "$SG_has_full" == "1" {
        di as text "  % Standalone full figure:"
        di as text `"  % \includegraphics[`options']{`tex_img_full'}"'
    }
    di as text _col(2) "{hline 64}"
    di as text `"Overlay file written to: {bf:`target_tex'}"'
    di as text "In your LaTeX presentation, insert:"
    di as result `"  \input{`target_tex'}"'

    return local file `"`target_tex'"'
    return local options `"`options'"'
    return local path `"`path'"'
    return scalar N = `N'
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph clear
// -----------------------------------------------------------------------------
program define slidegraph_clear
    version 15.0
    macro drop SG_*
    di as text "slidegraph configuration cleared"
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph query
// -----------------------------------------------------------------------------
program define slidegraph_query
    version 15.0
    if `"$SG_N"' == "" {
        di as text "No slidegraph configuration is currently active."
        di as text "Use {bf:slidegraph set, patterns(...)} or {bf:slidegraph set, colors(...) cumulative} to set up a configuration."
    }
    else {
        di as text "Active slidegraph configuration:"
        di as text "  Frames (N)   : " as result "$SG_N"
        di as text "  Patterns     : " as result `"$SG_patterns"'
        if "$SG_has_2" == "1" {
            di as text "  Dim modifier : " as result `"$SG_dim"'
        }
        di as text "  Off modifier : " as result `"$SG_off"'
        if "$SG_any_rgb" == "1" {
            di as text "  RGB detected : " as result "yes (inside-quote modifier applied)"
        }
        if "$SG_saving" != "" {
            di as text "  Last saving  : " as result `"$SG_saving"'
        }
    }
end

// -----------------------------------------------------------------------------
// Mata Helpers
// -----------------------------------------------------------------------------
mata:
mata set matastrict on

// Check if string represents an RGB color triple (0-255 0-255 0-255)
real scalar _sg_is_rgb(string scalar color, real vector rgb_vals)
{
    string scalar clean
    real scalar r, g, b

    clean = strtrim(subinstr(color, char(34), ""))
    if (ustrregexm(clean, "^\s*([0-9]{1,3})\s+([0-9]{1,3})\s+([0-9]{1,3})\s*$")) {
        r = strtoreal(ustrregexs(1))
        g = strtoreal(ustrregexs(2))
        b = strtoreal(ustrregexs(3))
        if (r >= 0 & r <= 255 & g >= 0 & g <= 255 & b >= 0 & b <= 255) {
            rgb_vals = (r, g, b)
            return(1)
        }
    }
    return(0)
}

// Replace color token with opacity modifier:
// For RGB: moves opacity modifier inside quotes: "R G B" -> "R G B %0"
// For named style: appends opacity modifier: navy -> navy%0
void _sg_replace_color(string scalar cmd_in, string scalar color, string scalar off, string scalar s_out)
{
    real vector rgb
    string scalar r_str, g_str, b_str, pat, rep, q

    rgb = J(1, 0, .)
    q = char(34)
    if (_sg_is_rgb(color, rgb)) {
        r_str = strofreal(rgb[1])
        g_str = strofreal(rgb[2])
        b_str = strofreal(rgb[3])
        // Match quotes around R G B with flexible spacing and optional intensity multiplier
        pat = q + "(\s*" + r_str + "\s+" + g_str + "\s+" + b_str + "(?:\*[0-9.]+)?\s*)" + q
        rep = q + "$1 " + off + q
        st_local(s_out, ustrregexra(cmd_in, pat, rep))
    }
    else {
        pat = "\b" + color + "\b"
        rep = color + off
        st_local(s_out, ustrregexra(cmd_in, pat, rep))
    }
}

// Inject name(..., replace) into command without syntax error from multiple commas
void _slidegraph_inject_name(string scalar raw, string scalar name_opt, string scalar s_out)
{
    real scalar i, n, depth, has_comma
    string scalar ch, trimmed

    trimmed = strtrim(raw)
    n = strlen(trimmed)
    depth = 0
    has_comma = 0
    for (i = 1; i <= n; i++) {
        ch = bsubstr(trimmed, i, 1)
        if (ch == "(") depth++
        else if (ch == ")") depth--
        else if (ch == "," & depth == 0) {
            has_comma = 1
            break
        }
    }
    if (has_comma) {
        st_local(s_out, trimmed + " " + name_opt)
    }
    else {
        st_local(s_out, trimmed + ", " + name_opt)
    }
}

// Parse saving() argument, detecting file stem and postfix extension
void _slidegraph_parse_save(string scalar arg, string scalar s_stem, string scalar s_ext, string scalar s_type)
{
    string scalar clean, stem, ext, type

    clean = strtrim(subinstr(arg, `"""', ""))
    if (strpos(clean, ",")) {
        clean = strtrim(bsubstr(clean, 1, strpos(clean, ",") - 1))
    }
    ext = pathsuffix(clean)
    stem = pathrmsuffix(clean)

    if (ext == "" | strlower(ext) == ".gph") {
        if (ext == "") ext = ".gph"
        type = "save"
    }
    else {
        type = "export"
    }

    st_local(s_stem, stem)
    st_local(s_ext, strlower(ext))
    st_local(s_type, type)
}

// Build preset patterns from colors() and preset (cumulative or spotlight)
void _sg_build_preset_patterns(string scalar colors_str, string scalar preset, string scalar s_out)
{
    string rowvector cols
    real scalar k, K, f
    string scalar pat, out_str, q

    cols = tokens(colors_str)
    K = length(cols)
    if (K == 0) {
        _error(198, "option colors() cannot be empty")
    }

    q = char(34)
    out_str = ""
    for (k = 1; k <= K; k++) {
        pat = ""
        for (f = 1; f <= K; f++) {
            if (preset == "cumulative") {
                if (f < k) pat = pat + "0"
                else       pat = pat + "2"
            }
            else if (preset == "spotlight") {
                if (f < k)      pat = pat + "0"
                else if (f == k) pat = pat + "2"
                else             pat = pat + "1"
            }
        }
        if (strpos(cols[k], " ")) {
            out_str = out_str + (k > 1 ? " " : "") + q + cols[k] + q + " " + pat
        }
        else {
            out_str = out_str + (k > 1 ? " " : "") + cols[k] + " " + pat
        }
    }
    st_local(s_out, out_str)
}

// Format LaTeX image paths for slidegraph export
void _slidegraph_format_tex_paths(string scalar save_stem, string scalar save_ext, string scalar path_in, real scalar N, string scalar s_macro_prefix)
{
    string scalar bare_name, clean_path, img_base, fwd_stem, dummy_p
    real scalar i

    dummy_p = ""
    bare_name = ""
    fwd_stem = subinstr(save_stem, "\", "/")
    if (path_in != "") {
        clean_path = subinstr(path_in, "\", "/")
        if (bsubstr(clean_path, strlen(clean_path), 1) != "/") {
            clean_path = clean_path + "/"
        }
        pathsplit(fwd_stem, dummy_p, bare_name)
        img_base = clean_path + bare_name
    }
    else {
        img_base = fwd_stem
    }

    for (i = 1; i <= N; i++) {
        st_local(s_macro_prefix + "_" + strofreal(i), img_base + "_" + strofreal(i) + save_ext)
    }
    st_local(s_macro_prefix + "_full", img_base + save_ext)
}
end
