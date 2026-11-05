*! version 1.2.0  05nov2026
*! slidegraph: Automated stepped/layered graph generation for presentations
*! Author: Aaron Wolf (aaron.wolf@u.northwestern.edu)
*! Program architecture: slidegraph set & slidegraph

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
            di as text "  {bf:slidegraph set}, patterns(color1 pat1 color2 pat2 ...) [off(%0)]"
            di as text "  {bf:slidegraph} [, stub(string) saving(string)] : {it:twoway_cmd}"
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
    syntax , patterns(string asis) [off(integer 0)]

    // Validate off is an integer between 0 and 100
    if !inrange(`off', 0, 100) {
        di as error "off() must be an integer between 0 and 100"
        exit 198
    }

    local off_mod "%`off'"

    // Count tokens
    local ntokens : word count `patterns'
    if `ntokens' == 0 {
        di as error "option patterns() required"
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

        // Validate that pattern consists strictly of 0 and 1
        forvalues k = 1/`plen' {
            local ch = substr("`pat'", `k', 1)
            if "`ch'" != "0" & "`ch'" != "1" {
                di as error "invalid character '`ch'' in pattern '`pat'' for color '`color''; patterns must contain only 0 and 1"
                exit 198
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
    global SG_npairs   `npairs'
    global SG_any_rgb  `any_rgb'

    // Return values in r()
    return scalar N       = `N'
    return scalar npairs  = `npairs'
    return scalar any_rgb = `any_rgb'
    return scalar off_val = `off'
    return local patterns `"`patterns'"'
    return local off      `"`off_mod'"'

    di as text "slidegraph configuration set: `npairs' pattern(s) across `N' frame(s), off modifier: " as result "`off_mod'"
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

    // Parse options before the colon (strictly slidegraph options: stub, saving)
    local 0 `"`before'"'
    syntax [, stub(string) saving(string)]

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

    // Loop through each frame i = 1 to N
    forvalues i = 1/`N' {
        local cur_cmd `"`cmd'"'

        // Apply visibility modifications for frame i
        forvalues p = 1/`npairs' {
            local color `"${SG_color_`p'}"'
            local pat   `"${SG_pat_`p'}"'

            local bit = substr("`pat'", `i', 1)
            if "`bit'" == "0" {
                // Dim/hide color using Mata helper (handles named & RGB colors)
                mata: _sg_replace_color(st_local("cur_cmd"), st_local("color"), st_local("off"), "cur_cmd")
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

    return scalar N = `N'
    return local stub "`stub'"
    return local off `"$SG_off"'
    if `"`saving'"' != "" {
        return local saving `"`saving'"'
    }
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
        di as text "Use {bf:slidegraph set, patterns(...)} to set up a configuration."
    }
    else {
        di as text "Active slidegraph configuration:"
        di as text "  Frames (N)   : " as result "$SG_N"
        di as text "  Patterns     : " as result `"$SG_patterns"'
        di as text "  Off modifier : " as result `"$SG_off"'
        if "$SG_any_rgb" == "1" {
            di as text "  RGB detected : " as result "yes (inside-quote modifier applied)"
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
end
