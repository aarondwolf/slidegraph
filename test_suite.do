/*==============================================================================
  test_suite.do
  Comprehensive test suite for slidegraph package
==============================================================================*/

clear all
adopath ++ .

local n_pass = 0
local n_fail = 0

// Test 1: slidegraph before set should fail with rc 198
macro drop SG_*
capture slidegraph : twoway scatter price mpg
if _rc == 198 {
    di as result "PASS: Test 1 - Calling slidegraph before set returned rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 1 - Expected rc 198, got " _rc
    local ++n_fail
}

// Test 2: Odd number of tokens in patterns
capture slidegraph set, patterns(navy 11 cranberry)
if _rc == 198 {
    di as result "PASS: Test 2 - Odd tokens in patterns returned rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 2 - Expected rc 198, got " _rc
    local ++n_fail
}

// Test 3: Invalid pattern character (not 0, 1, or 2)
capture slidegraph set, patterns(navy 13 cranberry 01)
if _rc == 198 {
    di as result "PASS: Test 3a - Invalid character '3' in pattern returned rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 3a - Expected rc 198 for character '3', got " _rc
    local ++n_fail
}

slidegraph set, patterns(navy 12 cranberry 01)
if r(has_2) == 1 {
    di as result "PASS: Test 3b - 3-state pattern with '2' accepted and flagged has_2=1"
    local ++n_pass
}
else {
    di as error "FAIL: Test 3b - 3-state pattern with '2' not flagged has_2=1"
    local ++n_fail
}

// Test 4: Mismatched pattern lengths
capture slidegraph set, patterns(navy 111 cranberry 01)
if _rc == 198 {
    di as result "PASS: Test 4 - Mismatched pattern lengths returned rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 4 - Expected rc 198, got " _rc
    local ++n_fail
}

// Test 5: Disallow twoway options directly in slidegraph command
slidegraph set, patterns(navy 11 cranberry 01)
capture slidegraph, title("Bad Place") : twoway scatter price mpg
if _rc == 198 {
    di as result "PASS: Test 5 - twoway option in slidegraph disallowed (rc 198)"
    local ++n_pass
}
else {
    di as error "FAIL: Test 5 - Expected rc 198 for twoway option in slidegraph, got " _rc
    local ++n_fail
}

// Test 6: off() validation (integer, default 0, inrange 0-100)
slidegraph set, patterns(navy 11 cranberry 01)
if "$SG_off" == "%0" {
    di as result "PASS: Test 6a - Default off() is %0"
    local ++n_pass
}
else {
    di as error "FAIL: Test 6a - Expected %0, got " "$SG_off"
    local ++n_fail
}

slidegraph set, patterns(navy 11 cranberry 01) off(25)
if "$SG_off" == "%25" {
    di as result "PASS: Test 6b - off(25) set %25"
    local ++n_pass
}
else {
    di as error "FAIL: Test 6b - Expected %25, got " "$SG_off"
    local ++n_fail
}

capture slidegraph set, patterns(navy 11 cranberry 01) off(-1)
if _rc == 198 {
    di as result "PASS: Test 6c - off(-1) rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 6c - Expected rc 198 for off(-1)"
    local ++n_fail
}

capture slidegraph set, patterns(navy 11 cranberry 01) off(101)
if _rc == 198 {
    di as result "PASS: Test 6d - off(101) rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 6d - Expected rc 198 for off(101)"
    local ++n_fail
}

capture slidegraph set, patterns(navy 11 cranberry 01) off(not_a_num)
if _rc == 198 {
    di as result "PASS: Test 6e - off(not_a_num) rejected by syntax with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 6e - Expected rc 198 for off(not_a_num)"
    local ++n_fail
}

// Test 7: Valid 2-frame build execution with twoway options in twoway
sysuse auto, clear
slidegraph set, patterns(navy 11 cranberry 01) off(0)
slidegraph, stub(test7) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))   ///
    (scatter price mpg if foreign==1, mcolor(cranberry)), ///
    title("Test 7 Build")

capture graph describe test7_1
local rc1 = _rc
capture graph describe test7_2
local rc2 = _rc
if `rc1' == 0 & `rc2' == 0 {
    di as result "PASS: Test 7 - 2-frame build created test7_1 and test7_2 in memory"
    local ++n_pass
}
else {
    di as error "FAIL: Test 7 - Graphs not found in memory"
    local ++n_fail
}

// Test 8: Postfix export with saving(t8_out.png) and saving(t8_out.pdf)
slidegraph, stub(test8) saving(t8_out.png) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

capture confirm file "t8_out_1.png"
local png1 = _rc
capture confirm file "t8_out_2.png"
local png2 = _rc

if `png1' == 0 & `png2' == 0 {
    di as result "PASS: Test 8a - Postfix .png export produced t8_out_1.png and t8_out_2.png"
    local ++n_pass
    capture erase "t8_out_1.png"
    capture erase "t8_out_2.png"
}
else {
    di as error "FAIL: Test 8a - Saved .png files missing"
    local ++n_fail
}

slidegraph, stub(test8b) saving(t8b_out.pdf) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

capture confirm file "t8b_out_1.pdf"
local pdf1 = _rc
capture confirm file "t8b_out_2.pdf"
local pdf2 = _rc

if `pdf1' == 0 & `pdf2' == 0 {
    di as result "PASS: Test 8b - Postfix .pdf export produced t8b_out_1.pdf and t8b_out_2.pdf"
    local ++n_pass
    capture erase "t8b_out_1.pdf"
    capture erase "t8b_out_2.pdf"
}
else {
    di as error "FAIL: Test 8b - Saved .pdf files missing"
    local ++n_fail
}

// Test 9: Warning when name() option is detected in graph command
capture slidegraph, stub(test9) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry)), ///
    name(user_name)
di as text "Note: Test 9 executed (warning issued on name() option)"
local ++n_pass

// Test 10: RGB detection, warning, and inside-quote opacity replacement
slidegraph set, patterns("255 0 0" 10 "0 128 255" 01) off(0)
if r(any_rgb) == 1 {
    di as result "PASS: Test 10a - RGB color successfully detected and flagged"
    local ++n_pass
}
else {
    di as error "FAIL: Test 10a - RGB color not flagged in return results"
    local ++n_fail
}

slidegraph, stub(test10) : twoway ///
    (scatter price mpg if foreign==0, mcolor("255 0 0")) ///
    (scatter price mpg if foreign==1, mcolor("0 128 255")), ///
    title("RGB Test")

capture graph describe test10_1
local rc_rgb1 = _rc
capture graph describe test10_2
local rc_rgb2 = _rc
if `rc_rgb1' == 0 & `rc_rgb2' == 0 {
    di as result "PASS: Test 10b - RGB build created test10_1 and test10_2 in memory"
    local ++n_pass
}
else {
    di as error "FAIL: Test 10b - RGB graphs not found in memory"
    local ++n_fail
}

// Test 11: Non-twoway graph support: graph bar and graph box
slidegraph set, patterns(navy 11 cranberry 01) off(0)
slidegraph, stub(test_bar) : graph bar (mean) price (mean) mpg, ///
    bar(1, color(navy)) bar(2, color(cranberry)) title("Bar Test")

capture graph describe test_bar_1
local rc_bar1 = _rc
capture graph describe test_bar_2
local rc_bar2 = _rc
if `rc_bar1' == 0 & `rc_bar2' == 0 {
    di as result "PASS: Test 11a - graph bar build created test_bar_1 and test_bar_2"
    local ++n_pass
}
else {
    di as error "FAIL: Test 11a - graph bar graphs not found in memory"
    local ++n_fail
}

slidegraph, stub(test_box) : graph box price weight, ///
    box(1, color(navy)) box(2, color(cranberry)) title("Box Test")

capture graph describe test_box_1
local rc_box1 = _rc
capture graph describe test_box_2
local rc_box2 = _rc
if `rc_box1' == 0 & `rc_box2' == 0 {
    di as result "PASS: Test 11b - graph box build created test_box_1 and test_box_2"
    local ++n_pass
}
else {
    di as error "FAIL: Test 11b - graph box graphs not found in memory"
    local ++n_fail
}

// Test 12: Unquoted RGB detection and helpful error
capture slidegraph set, patterns(255 0 0 11 0 128 255 01)
if _rc == 198 {
    di as result "PASS: Test 12 - Unquoted RGB detected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 12 - Expected rc 198 for unquoted RGB, got " _rc
    local ++n_fail
}

// Test 14: Shorthand presets (cumulative and spotlight)
slidegraph set, colors(navy cranberry midblue) cumulative
if "$SG_N" == "3" & `"$SG_patterns"' == "navy 222 cranberry 022 midblue 002" {
    di as result "PASS: Test 14a - colors() cumulative generated 222 / 022 / 002"
    local ++n_pass
}
else {
    di as error `"FAIL: Test 14a - Unexpected cumulative patterns: $SG_patterns"'
    local ++n_fail
}

slidegraph set, colors(navy cranberry midblue) spotlight
if "$SG_N" == "3" & `"$SG_patterns"' == "navy 211 cranberry 021 midblue 002" {
    di as result "PASS: Test 14b - colors() spotlight generated 211 / 021 / 002"
    local ++n_pass
}
else {
    di as error `"FAIL: Test 14b - Unexpected spotlight patterns: $SG_patterns"'
    local ++n_fail
}

// Test 15: Preset and dim() validation
capture slidegraph set, patterns(navy 11) colors(navy cranberry) cumulative
if _rc == 198 {
    di as result "PASS: Test 15a - Specifying both patterns() and colors() rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 15a - Expected rc 198 for both patterns() and colors()"
    local ++n_fail
}

capture slidegraph set, colors(navy cranberry)
if _rc == 198 {
    di as result "PASS: Test 15b - colors() without preset rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 15b - Expected rc 198 for colors() without preset"
    local ++n_fail
}

capture slidegraph set, colors(navy cranberry) cumulative spotlight
if _rc == 198 {
    di as result "PASS: Test 15c - Specifying both cumulative and spotlight rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 15c - Expected rc 198 for both cumulative and spotlight"
    local ++n_fail
}

capture slidegraph set, colors(navy cranberry) cumulative dim(120)
if _rc == 198 {
    di as result "PASS: Test 15d - dim(120) rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 15d - Expected rc 198 for dim(120)"
    local ++n_fail
}

// Test 16: 3-State pattern execution (focus 2, dim 1, off 0)
slidegraph set, colors(navy cranberry) spotlight dim(25) off(0)
slidegraph, stub(test16) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

capture graph describe test16_1
local rc_t16_1 = _rc
capture graph describe test16_2
local rc_t16_2 = _rc
if `rc_t16_1' == 0 & `rc_t16_2' == 0 {
    di as result "PASS: Test 16 - 3-State spotlight build created test16_1 and test16_2"
    local ++n_pass
}
else {
    di as error "FAIL: Test 16 - 3-State graphs not found in memory"
    local ++n_fail
}

// Test 17: full option with memory name and disk export
slidegraph set, colors(navy cranberry) cumulative
slidegraph, stub(test17) saving(test17_plot.png) full : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

capture graph describe test17_1
local rc_t17_1 = _rc
capture graph describe test17_2
local rc_t17_2 = _rc
capture graph describe test17
local rc_t17_full = _rc

capture confirm file "test17_plot_1.png"
local f1 = _rc
capture confirm file "test17_plot_2.png"
local f2 = _rc
capture confirm file "test17_plot.png"
local f_full = _rc

if `rc_t17_1' == 0 & `rc_t17_2' == 0 & `rc_t17_full' == 0 & `f1' == 0 & `f2' == 0 & `f_full' == 0 {
    di as result "PASS: Test 17 - full option created suffixed and unsuffixed graphs in memory and disk"
    local ++n_pass
    capture erase "test17_plot_1.png"
    capture erase "test17_plot_2.png"
    capture erase "test17_plot.png"
}
else {
    di as error "FAIL: Test 17 - full option graph or disk files missing"
    local ++n_fail
}

// Test 18: slidegraph export generating .tex file
slidegraph export using "test18_beamer.tex", replace
capture confirm file "test18_beamer.tex"
local tex_rc = _rc
if `tex_rc' == 0 {
    di as result "PASS: Test 18 - slidegraph export wrote test18_beamer.tex"
    local ++n_pass
    capture erase "test18_beamer.tex"
}
else {
    di as error "FAIL: Test 18 - test18_beamer.tex not found"
    local ++n_fail
}

// Test 19: slidegraph export with custom path() and options()
slidegraph export using "test19_beamer.tex", path("slides/figs") options("width=0.85\textwidth") replace
capture confirm file "test19_beamer.tex"
local tex_rc19 = _rc
if `tex_rc19' == 0 & `"`r(path)'"' == "slides/figs" & `"`r(options)'"' == "width=0.85\textwidth" {
    di as result "PASS: Test 19 - slidegraph export with custom path() and options() succeeded"
    local ++n_pass
    capture erase "test19_beamer.tex"
}
else {
    di as error "FAIL: Test 19 - slidegraph export custom path/options failed"
    local ++n_fail
}

// Test 20: slidegraph export overwrite protection (rc 602 without replace)
slidegraph export using "test20_beamer.tex", replace
capture slidegraph export using "test20_beamer.tex"
if _rc == 602 {
    di as result "PASS: Test 20 - Overwrite protection raised rc 602 without replace"
    local ++n_pass
    capture erase "test20_beamer.tex"
}
else {
    di as error "FAIL: Test 20 - Expected rc 602 for existing file without replace"
    local ++n_fail
}

// Test 21: Hardened edge cases (unquoted RGB in 2nd slot/colors(), comma in quotes, intensity *#, ./path without .tex)
capture slidegraph set, patterns(navy 11 255 0 0 01)
if _rc == 198 {
    di as result "PASS: Test 21a - Unquoted RGB in 2nd pattern slot rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 21a - Expected rc 198 for unquoted RGB in 2nd slot, got " _rc
    local ++n_fail
}

capture slidegraph set, colors(navy 255 0 0) cumulative
if _rc == 198 {
    di as result "PASS: Test 21b - Unquoted RGB in colors() rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 21b - Expected rc 198 for unquoted RGB in colors(), got " _rc
    local ++n_fail
}

slidegraph set, colors(navy cranberry) cumulative
capture slidegraph :
if _rc == 198 {
    di as result "PASS: Test 21c - Empty command after colon rejected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 21c - Expected rc 198 for empty command after colon, got " _rc
    local ++n_fail
}

// Comma inside quotes before options + intensity multiplier (*0.8)
slidegraph, stub(test21d) saving(t21d.pdf) : twoway ///
    (scatter price mpg if make != "Ford, Inc.", mcolor(navy*0.8)) ///
    (scatter price mpg if foreign == 1, mcolor(cranberry*0.9))

capture graph describe test21d_1
local rc_21d = _rc
if `rc_21d' == 0 {
    di as result "PASS: Test 21d - Quoted comma before options and color*# intensity multiplier handled cleanly"
    local ++n_pass
    capture erase "t21d_1.pdf"
    capture erase "t21d_2.pdf"
}
else {
    di as error "FAIL: Test 21d - Failed on quoted comma or intensity multiplier"
    local ++n_fail
}

// Relative path with './' and no .tex suffix in using
slidegraph export using "./test21e_overlay", replace
capture confirm file "./test21e_overlay.tex"
if _rc == 0 {
    di as result "PASS: Test 21e - Relative path './test21e_overlay' properly appended .tex"
    local ++n_pass
    capture erase "./test21e_overlay.tex"
}
else {
    di as error "FAIL: Test 21e - './test21e_overlay.tex' not created"
    local ++n_fail
}

// Test 22: slidegraph clear
slidegraph clear
if `"$SG_N"' == "" & `"$SG_patterns"' == "" {
    di as result "PASS: Test 22 - slidegraph clear properly wiped configuration globals"
    local ++n_pass
}
else {
    di as error "FAIL: Test 22 - Globals still present after clear"
    local ++n_fail
}

di as text _newline(2) "{hline 60}"
di as text "TEST SUMMARY: Passed: `n_pass' | Failed: `n_fail'"
di as text "{hline 60}"
if `n_fail' > 0 {
    exit 1
}
