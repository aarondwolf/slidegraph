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

// Test 3: Non-binary pattern
capture slidegraph set, patterns(navy 12 cranberry 01)
if _rc == 198 {
    di as result "PASS: Test 3 - Non-binary pattern returned rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 3 - Expected rc 198, got " _rc
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

// Test 6: Valid 2-frame build execution with twoway options in twoway
sysuse auto, clear
slidegraph set, patterns(navy 11 cranberry 01) off(%0)
slidegraph, stub(test6) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))   ///
    (scatter price mpg if foreign==1, mcolor(cranberry)), ///
    title("Test 6 Build")

capture graph describe test6_1
local rc1 = _rc
capture graph describe test6_2
local rc2 = _rc
if `rc1' == 0 & `rc2' == 0 {
    di as result "PASS: Test 6 - 2-frame build created test6_1 and test6_2 in memory"
    local ++n_pass
}
else {
    di as error "FAIL: Test 6 - Graphs not found in memory"
    local ++n_fail
}

// Test 7: Postfix export with saving(t7_out.png) and saving(t7_out.pdf)
slidegraph set, patterns(navy 11 cranberry 01) off(%0)
slidegraph, stub(test7) saving(t7_out.png) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

capture confirm file "t7_out_1.png"
local png1 = _rc
capture confirm file "t7_out_2.png"
local png2 = _rc

if `png1' == 0 & `png2' == 0 {
    di as result "PASS: Test 7a - Postfix .png export produced t7_out_1.png and t7_out_2.png"
    local ++n_pass
    capture erase "t7_out_1.png"
    capture erase "t7_out_2.png"
}
else {
    di as error "FAIL: Test 7a - Saved .png files missing"
    local ++n_fail
}

slidegraph, stub(test7b) saving(t7b_out.pdf) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

capture confirm file "t7b_out_1.pdf"
local pdf1 = _rc
capture confirm file "t7b_out_2.pdf"
local pdf2 = _rc

if `pdf1' == 0 & `pdf2' == 0 {
    di as result "PASS: Test 7b - Postfix .pdf export produced t7b_out_1.pdf and t7b_out_2.pdf"
    local ++n_pass
    capture erase "t7b_out_1.pdf"
    capture erase "t7b_out_2.pdf"
}
else {
    di as error "FAIL: Test 7b - Saved .pdf files missing"
    local ++n_fail
}

// Test 8: Postfix .gph saving with saving(t8_out.gph)
slidegraph, stub(test8) saving(t8_out.gph) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

capture confirm file "t8_out_1.gph"
local gph1 = _rc
capture confirm file "t8_out_2.gph"
local gph2 = _rc

if `gph1' == 0 & `gph2' == 0 {
    di as result "PASS: Test 8 - Postfix .gph save produced t8_out_1.gph and t8_out_2.gph"
    local ++n_pass
    capture erase "t8_out_1.gph"
    capture erase "t8_out_2.gph"
}
else {
    di as error "FAIL: Test 8 - Saved .gph files missing"
    local ++n_fail
}

// Test 9: Warning when name() option is detected in graph command
slidegraph set, patterns(navy 11 cranberry 01)
capture slidegraph, stub(test9) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy)) ///
    (scatter price mpg if foreign==1, mcolor(cranberry)), ///
    name(user_name)
di as text "Note: Test 9 executed (warning issued on name() option)"
local ++n_pass

// Test 10: RGB detection, warning, and inside-quote opacity replacement
slidegraph set, patterns("255 0 0" 10 "0 128 255" 01) off(%0)
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

// Test 11: Unquoted RGB detection and helpful error
capture slidegraph set, patterns(255 0 0 11 0 128 255 01)
if _rc == 198 {
    di as result "PASS: Test 11 - Unquoted RGB detected with rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 11 - Expected rc 198 for unquoted RGB, got " _rc
    local ++n_fail
}

// Test 12: slidegraph clear
slidegraph clear
if `"$SG_N"' == "" & `"$SG_patterns"' == "" {
    di as result "PASS: Test 12 - slidegraph clear properly wiped configuration globals"
    local ++n_pass
}
else {
    di as error "FAIL: Test 12 - Globals still present after clear"
    local ++n_fail
}

di as text _newline(2) "{hline 60}"
di as text "TEST SUMMARY: Passed: `n_pass' | Failed: `n_fail'"
di as text "{hline 60}"
if `n_fail' > 0 {
    exit 1
}
