{smcl}
{* *! version 1.0.0  05nov2026}{...}
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
{cmd:slidegraph} [{cmd:,} {it:options}] {cmd::} {it:twoway_graph_command}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main (slidegraph)}
{synopt :{opt stub(name)}}graph name prefix in memory; default is {cmd:slide}{p_end}
{synopt :{opt saving(filename [, replace])}}save individual graph frames as {it:filename_i.gph}{p_end}
{synopt :{opt export(fmt)}}automatically export each frame to image format {it:fmt} (e.g., {cmd:png}, {cmd:pdf}){p_end}
{synopt :{it:graph_options}}any standard {help twoway_options:twoway graph options} applied to each frame{p_end}

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


{marker options}{...}
{title:Options}

{phang}
{opt patterns(string)} specifies the series visibility sequence using paired color tokens and binary strings.
For example, {cmd:patterns(navy 11 cranberry 01)} defines a 2-frame build where the {cmd:navy} series is
visible in both frames ({cmd:11}) and the {cmd:cranberry} series is hidden in frame 1 and appears in frame 2 ({cmd:01}).
All binary patterns must contain only {cmd:0} and {cmd:1} and must have identical length {it:N} (the total frame count).

{phang}
{opt off(string)} specifies the opacity modifier applied when a bit is {cmd:0}. The default is {cmd:%0} (fully transparent).
Alternatively, a dimming modifier such as {cmd:%5} or {cmd:%10} can be supplied to de-emphasize inactive series rather than
hiding them completely.

{phang}
{opt stub(name)} sets the memory name prefix for the generated graphs ({it:stub_1}, {it:stub_2}, ..., {it:stub_N}).
The default is {cmd:slide} ({cmd:slide_1}, {cmd:slide_2}, ...).

{phang}
{opt saving(filename [, replace])} specifies that each frame {it:i} should be saved to disk as a Stata graph file
({it:filename_i.gph}).

{phang}
{opt export(fmt)} automatically exports each rendered slide to {it:stub_i.fmt} (e.g., {cmd:export(png)} or {cmd:export(pdf)}).


{marker examples}{...}
{title:Examples}

{pstd}Load example data:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}1. Two-frame build introducing foreign cars in frame 2:{p_end}
{phang2}{cmd:. slidegraph set, patterns(navy 11 cranberry 01) off(%0)}{p_end}
{phang2}{cmd:. slidegraph, title("Price vs MPG by Foreign Status") : twoway (scatter price mpg if foreign==0, mcolor(navy)) (scatter price mpg if foreign==1, mcolor(cranberry))}{p_end}

{pstd}2. Four-frame build with points, lines, and custom stub name:{p_end}
{phang2}{cmd:. slidegraph set, patterns(navy 1111 cranberry 0111 midblue 0011 orange 0001) off(%0)}{p_end}
{phang2}{cmd:. slidegraph, stub(build4) title("Price vs MPG with Fits") : twoway (scatter price mpg if foreign==0, mcolor(navy)) (scatter price mpg if foreign==1, mcolor(cranberry)) (lfit price mpg if foreign==0, lcolor(midblue)) (lfit price mpg if foreign==1, lcolor(orange))}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:slidegraph set} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}total number of frames{p_end}
{synopt:{cmd:r(npairs)}}number of color/pattern pairs{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(patterns)}}raw patterns string{p_end}
{synopt:{cmd:r(off)}}off modifier{p_end}

{pstd}
Configuration is also persisted in global macros ({cmd:$SG_patterns}, {cmd:$SG_N}, {cmd:$SG_off}, {cmd:$SG_npairs})
so it remains available across subsequent commands.
{p2colreset}{...}
