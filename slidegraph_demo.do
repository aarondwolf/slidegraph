/*==============================================================================
  slidegraph_demo.do
  Demonstration of the slidegraph package for stepped presentation builds
==============================================================================*/

// Clear environment and ensure local directory is in adopath
clear all
adopath ++ .

// Load auto dataset
sysuse auto, clear

// =============================================================================
// Demonstration 1: 2-Slide Build (Domestic -> Foreign)
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 1: 2-Slide Build"
di as text "{hline 70}"

// Step 1: Configure slide build
// navy (Domestic) is visible in frames 1 and 2 (pattern: 11)
// cranberry (Foreign) is hidden in frame 1 and visible in frame 2 (pattern: 01)
// off(%0) sets 0% opacity (completely invisible) when hidden
slidegraph set, patterns(navy 11 cranberry 01) off(%0)

// Step 2: Execute graph sequence
// Notice: twoway options like title() are placed directly in twoway after the colon
slidegraph : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry)),   ///
    title("Price vs MPG by Foreign Status")

// Verify graphs in memory
graph dir slide*


// =============================================================================
// Demonstration 2: 4-Slide Scalable Build with saving(demo_build.png)
// =============================================================================
di as text _newline(2) "{hline 70}"
di as text "DEMONSTRATION 2: 4-Slide Scalable Build with Postfix Export"
di as text "{hline 70}"

// Step 1: Configure 4-frame build with 4 distinct series
//   Frame 1: Domestic points only
//   Frame 2: Domestic + Foreign points
//   Frame 3: Domestic + Foreign points + Domestic trend
//   Frame 4: Domestic + Foreign points + Domestic trend + Foreign trend
slidegraph set, patterns(navy 1111 cranberry 0111 midblue 0011 orange 0001) off(%0)

// Step 2: Execute graph with custom stub and automatic PNG export via saving()
// saving(demo_build.png) automatically detects .png and calls graph export for each frame
slidegraph, stub(build4) saving(demo_build.png) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy) msymbol(circle))                       ///
    (scatter price mpg if foreign==1, mcolor(cranberry) msymbol(diamond))                 ///
    (lfit price mpg if foreign==0,    lcolor(midblue) lwidth(medthick))                   ///
    (lfit price mpg if foreign==1,    lcolor(orange) lwidth(medthick) lpattern(dash)),    ///
    title("Evolution of Price vs MPG with Fits")                                          ///
    subtitle("Demonstrating 4-frame stepped progression")                                 ///
    legend(order(1 "Domestic" 2 "Foreign" 3 "Domestic Fit" 4 "Foreign Fit") rows(1))

// Verify 4-frame graphs in memory
graph dir build4*

// Clean up demo exported PNG files (ignored by git, but clean environment)
forvalues i = 1/4 {
    capture erase "demo_build_`i'.png"
}

di as text _newline(2) "{hline 70}"
di as text "Demonstration completed successfully!"
di as text "{hline 70}"
