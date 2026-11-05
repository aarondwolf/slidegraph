{smcl}
{* *! version 1.2.0  05nov2026}{...}
{viewerjumpto "Syntax" "slidegraph##syntax"}{...}
{viewerjumpto "Description" "slidegraph##description"}{...}
{viewerjumpto "Options" "slidegraph##options"}{...}
{viewerjumpto "Remarks" "slidegraph##remarks"}{...}
{viewerjumpto "Examples" "slidegraph##examples"}{...}
{viewerjumpto "Stored results" "slidegraph##results"}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{bf:slidegraph} {hline 2}}Automated stepped and layered graphs for presentation slides{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}
Configure slide layers:

{p 8 16 2}
{cmd:slidegraph set}{cmd:,} {cmdab:pat:terns(}{it:color1 pat1 color2 pat2 ...}{cmd:)} [{cmd:off(}{it:string}{cmd:)}]

{p 4 8 2}
Execute multi-frame build:

{p 8 16 2}
{cmd:slidegraph} [{cmd:,} {cmd:stub(}{it:name}{cmd:)} {cmd:saving(}{it:filename}{cmd:)}] {cmd::} {it:twoway_graph_command}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main (slidegraph)}
{synopt :{opt stub(name)}}graph name prefix in memory; default is {cmd:slide}{p_end}
{synopt :{opt saving(filename)}}save or export individual frames using automatic extension detection (e.g., {cmd:.pdf}, {cmd:.png}, {cmd:.gph}){p_end}

{syntab:Configuration (slidegraph set)}
{synopt :{opt pat:terns(string)}}space-delimited list of {it:color_token binary_pattern} pairs (required){p_end}
{synopt :{opt off(string)}}opacity modifier appended to hidden series; default is {cmd:%0}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:slidegraph} automates the creation of layered, stepped sequence graphs for presentation slides
(such as LaTeX Beamer or PowerPoint builds).

{pstd}
In traditional slide builds, omitting data series from early frames causes Stata to recalculate axis
ranges, change legend bounding boxes, and shift margins across frames. {cmd:slidegraph} solves this
problem by plotting all series in every single frame and modulating visibility using Stata's native opacity
modifiers (e.g., turning {cmd:navy} into {cmd:navy%0} when hidden, or {cmd:navy%5} when dimmed).
As a result, axes, ticks, labels, and legends remain 100% stationary throughout the build sequence.

{pstd}
All {help twoway_options:twoway options} (e.g., {cmd:title()}, {cmd:legend()}, {cmd:aspect()}) are specified
directly within the {it:twoway_graph_command} after the colon. {cmd:slidegraph} manages frame sequencing,
color opacity substitution, distinct memory naming, and automatic file export.


{marker options}{...}
{title:Options}

{phang}
{opt stub(name)} sets the memory name prefix for the generated graphs ({it:stub_1}, {it:stub_2}, ..., {it:stub_N}).
The default is {cmd:slide} ({cmd:slide_1}, {cmd:slide_2}, ...).
{it:Note:} Avoid specifying {cmd:name()} inside the {it:twoway_graph_command}, as {cmd:slidegraph} injects its own
frame names based on {opt stub()}. If a {cmd:name()} option is detected in the graph command, a warning is displayed.

{phang}
{opt saving(filename)} automatically saves or exports each rendered slide with the frame index inserted before the file extension
({it:filename_1.ext}, {it:filename_2.ext}, ..., {it:filename_N.ext}).
The action is determined automatically by inspecting the file postfix:
{break}
- {cmd:.pdf}, {cmd:.png}, {cmd:.svg}, {cmd:.eps}, {cmd:.tif}: automatically calls {cmd:graph export}.
{break}
- {cmd:.gph} (or omitting an extension): automatically calls {cmd:graph save}.

{phang}
{opt patterns(string)} specifies the series visibility sequence using paired color tokens and binary strings.
Both named color styles (e.g., {cmd:navy}, {cmd:cranberry}) and custom RGB values (e.g., {cmd:"255 0 0"}) are supported.
RGB color triples must be enclosed in quotes (e.g., {cmd:patterns("255 0 0" 11 "0 128 255" 01)}).
When an RGB color is detected, {cmd:slidegraph} automatically places the opacity modifier inside the quotes (e.g., {cmd:"255 0 0 %0"}),
as required by Stata's syntax, and issues a warning that RGB formatting may be sensitive to spacing.
All binary patterns must contain only {cmd:0} and {cmd:1} and must have identical length {it:N} (the total frame count).

{phang}
{opt off(string)} specifies the opacity modifier applied when a bit is {cmd:0}. The default is {cmd:%0} (fully transparent).
Alternatively, a dimming modifier such as {cmd:%5} or {cmd:%10} can be supplied to de-emphasize inactive series rather than
hiding them completely.


{marker examples}{...}
{title:Examples}

{pstd}Load example data:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}1. Two-frame build with titles directly in twoway:{p_end}
{phang2}{cmd:. slidegraph set, patterns(navy 11 cranberry 01) off(%0)}{p_end}
{phang2}{cmd:. slidegraph : twoway (scatter price mpg if foreign==0, mcolor(navy)) (scatter price mpg if foreign==1, mcolor(cranberry)), title("Price vs MPG by Foreign Status")}{p_end}

{pstd}2. Four-frame build with custom stub and automatic PDF export:{p_end}
{phang2}{cmd:. slidegraph set, patterns(navy 1111 cranberry 0111 midblue 0011 orange 0001) off(%0)}{p_end}
{phang2}{cmd:. slidegraph, stub(build4) saving(build.pdf) : twoway (scatter price mpg if foreign==0, mcolor(navy)) (scatter price mpg if foreign==1, mcolor(cranberry)) (lfit price mpg if foreign==0, lcolor(midblue)) (lfit price mpg if foreign==1, lcolor(orange)), title("Price vs MPG with Fits")}{p_end}

{pstd}3. Custom RGB colors build:{p_end}
{phang2}{cmd:. slidegraph set, patterns("230 60 60" 11 "40 120 220" 01) off(%0)}{p_end}
{phang2}{cmd:. slidegraph, stub(rgb_demo) : twoway (scatter price mpg if foreign==0, mcolor("230 60 60")) (scatter price mpg if foreign==1, mcolor("40 120 220")), title("Price vs MPG with RGB")}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:slidegraph set} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}total number of frames{p_end}
{synopt:{cmd:r(npairs)}}number of color/pattern pairs{p_end}
{synopt:{cmd:r(any_rgb)}}1 if custom RGB colors detected, 0 otherwise{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(patterns)}}raw patterns string{p_end}
{synopt:{cmd:r(off)}}off modifier{p_end}

{pstd}
Configuration is persisted in global macros ({cmd:$SG_patterns}, {cmd:$SG_N}, {cmd:$SG_off}, {cmd:$SG_npairs}, {cmd:$SG_any_rgb}, {cmd:$SG_color_*}, {cmd:$SG_pat_*})
so it remains available across subsequent commands.
{p2colreset}{...}
