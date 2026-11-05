*! version 1.0.0  05nov2026
*! slidegraph: Automated stepped/layered graph generation for presentations
*! Author: Aaron
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
            di as text "  {bf:slidegraph} [, stub(string) saving(string) export(string) {it:graph_options}] : {it:twoway_cmd}"
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
    syntax , patterns(string) [off(string)]

    // Default off-modifier
    if `"`off'"' == "" {
        local off "%0"
    }
    else if substr(`"`off'"', 1, 1) != "%" {
        local off "%`off'"
    }

    // Count tokens
    local ntokens : word count `patterns'
    if `ntokens' == 0 {
        di as error "option patterns() required"
        exit 198
    }
    if mod(`ntokens', 2) != 0 {
        di as error "patterns() must contain an even number of tokens: <color_token> <binary_pattern> pairs"
        exit 198
    }

    local npairs = `ntokens' / 2
    local N = 0

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
    }

    // Store configuration in global macros for state persistence
    global SG_patterns `"`patterns'"'
    global SG_N        `N'
    global SG_off      `"`off'"'
    global SG_npairs   `npairs'

    // Return values in r()
    return scalar N = `N'
    return scalar npairs = `npairs'
    return local patterns `"`patterns'"'
    return local off `"`off'"'

    di as text "slidegraph configuration set: `npairs' pattern(s) across `N' frame(s), off modifier: " as result "`off'"
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph run (default execution)
// -----------------------------------------------------------------------------
program define slidegraph_run, rclass
    version 15.0

    // Check if configuration exists
    if "$SG_N" == "" | "$SG_patterns" == "" {
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

    // Parse options before the colon
    local 0 `"`before'"'
    syntax [, saving(string) stub(string) export(string) *]

    if `"`stub'"' == "" {
        local stub "slide"
    }

    // Split raw twoway command into body and top-level options
    mata: _slidegraph_split_cmd(st_local("cmd"), "cmd_body", "cmd_opts")

    local N      = $SG_N
    local npairs = $SG_npairs
    local off    `"$SG_off"'

    // Loop through each frame i = 1 to N
    forvalues i = 1/`N' {
        local cur_body `"`cmd_body'"'

        // Apply visibility modifications for frame i
        forvalues p = 1/`npairs' {
            local c_idx = 2 * `p' - 1
            local pat_idx = 2 * `p'
            local color : word `c_idx' of $SG_patterns
            local pat   : word `pat_idx' of $SG_patterns

            local bit = substr("`pat'", `i', 1)
            if "`bit'" == "0" {
                // Dim/hide color using word-boundary replacement
                local cur_body = ustrregexra(`"`cur_body'"', "\b" + "`color'" + "\b", "`color'" + "`off'")
            }
        }

        // Frame name in memory
        local graphname "`stub'_`i'"
        local frame_opts `"name(`graphname', replace)"'

        // File saving option if requested
        if `"`saving'"' != "" {
            tokenize `"`saving'"', parse(",")
            local s_name `"`1'"'
            local s_sub  `"`2'`3'"'
            if `"`s_sub'"' == "" {
                local s_sub ", replace"
            }
            local frame_opts `"`frame_opts' saving("`s_name'_`i'"`s_sub')"'
        }

        // Append graph options from twoway command and slidegraph prefix
        if `"`cmd_opts'"' != "" {
            local frame_opts `"`frame_opts' `cmd_opts'"'
        }
        if `"`options'"' != "" {
            local frame_opts `"`frame_opts' `options'"'
        }

        // Execute the modified command for frame i
        di as text _col(2) "{hline 64}"
        di as text "slidegraph frame `i'/`N' ({bf:`graphname'}):"
        di as result `"  `cur_body', `frame_opts'"'
        `cur_body', `frame_opts'

        // Optional export
        if `"`export'"' != "" {
            graph export "`stub'_`i'.`export'", replace
            di as text `"  Saved image: `stub'_`i'.`export'"'
        }
    }

    return scalar N = `N'
    return local stub "`stub'"
    return local off `"$SG_off"'
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph clear
// -----------------------------------------------------------------------------
program define slidegraph_clear
    version 15.0
    macro drop SG_patterns SG_N SG_off SG_npairs
    di as text "slidegraph configuration cleared"
end

// -----------------------------------------------------------------------------
// Subcommand: slidegraph query
// -----------------------------------------------------------------------------
program define slidegraph_query
    version 15.0
    if "$SG_N" == "" {
        di as text "No slidegraph configuration is currently active."
        di as text "Use {bf:slidegraph set, patterns(...)} to set up a configuration."
    }
    else {
        di as text "Active slidegraph configuration:"
        di as text "  Frames (N)   : {res}$SG_N}"
        di as text "  Patterns     : {res}$SG_patterns}"
        di as text "  Off modifier : {res}$SG_off}"
    }
end

// -----------------------------------------------------------------------------
// Mata Helper: Split graph command into body and top-level options
// -----------------------------------------------------------------------------
mata:
mata set matastrict on
void _slidegraph_split_cmd(string scalar raw, string scalar local_body, string scalar local_opts)
{
    real scalar i, n, depth, comma_pos
    string scalar ch

    n = strlen(raw)
    depth = 0
    comma_pos = 0

    // Find the first comma at paren depth == 0
    for (i = 1; i <= n; i++) {
        ch = bsubstr(raw, i, 1)
        if (ch == "(") depth++
        else if (ch == ")") depth--
        else if (ch == "," & depth == 0) {
            comma_pos = i
            break
        }
    }

    if (comma_pos > 0) {
        st_local(local_body, bsubstr(raw, 1, comma_pos - 1))
        st_local(local_opts, bsubstr(raw, comma_pos + 1, n - comma_pos))
    }
    else {
        st_local(local_body, raw)
        st_local(local_opts, "")
    }
}
end
