/*==============================================================================
  make_example_graphs.do
  Generates sample slidegraph PDF frames and Beamer overlay snippet
==============================================================================*/
clear all
adopath ++ .
sysuse auto, clear

// 3-frame cumulative build: Domestic -> Foreign -> Fit
slidegraph set, colors(navy cranberry midblue) cumulative

slidegraph, stub(scatter_build) saving(scatter_build.pdf) full : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy) msymbol(circle))      ///
    (scatter price mpg if foreign==1, mcolor(cranberry) msymbol(diamond)) ///
    (lfit price mpg, lcolor(midblue) lwidth(medthick)),                  ///
    title("Automobile Price vs. Fuel Efficiency")                       ///
    legend(order(1 "Domestic" 2 "Foreign" 3 "Overall Linear Fit") rows(1))

// Generate Beamer overlay snippet
slidegraph export using "scatter_build_overlays.tex", replace
