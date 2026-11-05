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
capture slidegraph, title("Test") : twoway (scatter price mpg)
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

// Test 5: Missing colon in slidegraph
slidegraph set, patterns(navy 11 cranberry 01)
capture slidegraph twoway (scatter price mpg)
if _rc == 198 {
    di as result "PASS: Test 5 - Missing colon returned rc 198"
    local ++n_pass
}
else {
    di as error "FAIL: Test 5 - Expected rc 198, got " _rc
    local ++n_fail
}

// Test 6: Valid 2-frame build execution
sysuse auto, clear
slidegraph set, patterns(navy 11 cranberry 01) off(%0)
slidegraph, stub(test6) title("Test 6 Build") : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))   ///
    (scatter price mpg if foreign==1, mcolor(cranberry))

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

// Test 7: Valid 3-frame build with dimming (%10) and saving()
slidegraph set, patterns(navy 111 cranberry 011 forest_green 001) off(%10)
slidegraph, stub(test7) saving(t7_out, replace) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry))    ///
    (lfit price mpg, lcolor(forest_green))

capture confirm file "t7_out_1.gph"
local f1 = _rc
capture confirm file "t7_out_2.gph"
local f2 = _rc
capture confirm file "t7_out_3.gph"
local f3 = _rc

if `f1' == 0 & `f2' == 0 & `f3' == 0 {
    di as result "PASS: Test 7 - 3-frame saving option produced t7_out_1.gph to t7_out_3.gph"
    local ++n_pass
    erase "t7_out_1.gph"
    erase "t7_out_2.gph"
    erase "t7_out_3.gph"
}
else {
    di as error "FAIL: Test 7 - Saved .gph files missing"
    local ++n_fail
}

// Test 8: slidegraph clear
slidegraph clear
if "$SG_N" == "" & "$SG_patterns" == "" {
    di as result "PASS: Test 8 - slidegraph clear properly wiped configuration globals"
    local ++n_pass
}
else {
    di as error "FAIL: Test 8 - Globals still present after clear"
    local ++n_fail
}

di as text _newline(2) "{hline 60}"
di as text "TEST SUMMARY: Passed: `n_pass' | Failed: `n_fail'"
di as text "{hline 60}"
if `n_fail' > 0 {
    exit 1
}
