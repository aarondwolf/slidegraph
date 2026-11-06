# slidegraph

Automate stepped, layered figures for slide presentations (such as LaTeX Beamer or PowerPoint builds) in Stata using opacity modulation.

---

## Installation

Install directly via `net install` from GitHub or a local clone:

```stata
// From GitHub:
net install slidegraph, from("https://raw.githubusercontent.com/aaronwolf/slidegraph/master") replace

// Or from a local directory:
net install slidegraph, from("C:/path/to/slidegraph") replace
```

---

## The Core Concept

When presenting empirical results or model progressions in slide decks, speakers frequently build complex graphs layer by layer:
1. Show baseline data points.
2. Introduce comparison groups.
3. Overlay fitted trendlines or counterfactual predictions.

In standard Stata workflows, plotting subsets of series across different graphs leads to **distracting visual jitter**:
- The $x$- and $y$-axis ranges shift as data bounds change.
- Axis labels and tick marks shift position.
- Legend boxes resize and re-center.
- Margins and plotting area ratios change.

### The `slidegraph` Solution
Instead of conditionally omitting series, `slidegraph` **plots all series in every single frame** and modulates their visibility across sequential frames by appending Stata opacity modifiers:
- **Focus (`2` or `1` in binary mode):** Visible series retain 100% opacity.
- **Dimmed / Ghost Context (`1` in ternary mode):** Previous series remain as de-emphasized background context (`%20` or user-defined `dim()`).
- **Hidden (`0`):** Series receive an opacity modifier of `%0` (or user-defined `off()`).

Because all series are evaluated in every frame, Stata locks in fixed axis limits, consistent tick intervals, and an identical legend bounding box throughout the entire animation sequence.

### Design Philosophy: Why Color-Based Substitution?

Stata's graphing ecosystem spans a wide variety of built-in commands (`twoway`, `graph bar`, `graph box`, `graph dot`, `histogram`) and community-contributed packages (`coefplot`, `marginsplot`, `binscatter`, etc.), each with its own syntax for defining series and plot elements. Attempting to parse plot structures directly would either restrict `slidegraph` to basic `twoway` commands or make it fragile when used with wrapper packages.

Despite their syntactic differences, nearly all Stata graph commands share a common denominator: they accept standard Stata color specifications. By keying frame visibility to color tokens rather than plot syntax, `slidegraph` remains completely command-agnostic—any element whose color you can specify can be sequenced across slides.

#### Limitation & Workarounds: Multiple Layers with the Same Color

Because `slidegraph` identifies layers by their color token, two plot elements that use the exact same color string cannot be toggled independently:

```stata
// Both scatter plots will turn on/off together if both use 'navy'
twoway (scatter y1 x1, mcolor(navy)) (scatter y2 x2, mcolor(navy))
```

If you need two series to appear in the **same visual color** on different frames, you have two simple workarounds:

1. **Use visually identical color aliases:** Stata treats unit intensity multipliers and equivalent RGB triplets as identical on screen, while `slidegraph` sees them as distinct tokens:
   - Layer 1: `mcolor(navy)`
   - Layer 2: `mcolor(navy*1)` (or `mcolor(navy*1.0)`)
   - Layer 3: `mcolor("26 71 111")` (the RGB equivalent of `navy`)
   ```stata
   slidegraph set, colors(navy navy*1 "26 71 111") cumulative
   ```
2. **Copy and tweak the generated commands:** `slidegraph` prints the exact expanded command for every frame to the Stata Results window. In complex cases, you can assign temporary distinct colors to generate the sequence, then copy the echoed commands from the Results window and adjust the colors manually.

---

## Architecture & Subcommands

### 1. `slidegraph set`
Configures the visibility sequence across frames and validates the pattern matrix.

```stata
// Explicit custom patterns:
slidegraph set, patterns(color1 pat1 color2 pat2 ...) [off(integer 0)] [dim(integer 20)]

// Shorthand presets (no manual binary strings required):
slidegraph set, colors(color1 color2 ...) cumulative|spotlight [off(integer 0)] [dim(integer 20)]
```

- **`patterns(string)`**: Space-separated list of `<color_token> <pattern>` pairs.
  - Supports named color styles (`navy`, `cranberry`, `forest_green`) and quoted RGB triples (`"255 0 0"`, `"0 128 255"`).
  - Patterns can be binary (`0`/`1`) or 3-state ternary (`0`=off, `1`=dimmed, `2`=focus).
- **`colors(string)`**: Shorthand list of series colors to sequence automatically:
  - **`cumulative`**: Progressive build where each series turns on at 100% and stays on in all subsequent frames (`222...`, `022...`, `002...`).
  - **`spotlight`**: Narrative focus where active series is highlighted at 100%, previous series are dimmed to `dim()`, and future series remain hidden (`211...`, `021...`, `002...`).
- **`off(integer)`**: Opacity percentage integer applied to `0` bits (`0` to `100`, default `0` $\to$ `%0`).
- **`dim(integer)`**: Opacity percentage integer applied to `1` bits in 3-state patterns (`0` to `100`, default `20` $\to$ `%20`).
- **RGB Color Detection**: If RGB values are detected, `slidegraph` issues a warning and dynamically moves opacity modifiers inside quotes (`"R G B %0"`), ensuring compatibility with Stata's graph engine.

### 2. `slidegraph`
Executes the stored multi-frame sequence. Users provide standard graph commands after the colon (`:`) with all native graph options.

```stata
slidegraph [, stub(name) saving(filename) full] : <graph command>
```

- **Any Stata graph command supported**: Works with `twoway`, `graph bar`, `graph box`, `graph hbar`, `graph dot`, etc.
- **No graph options before colon**: Users specify all graph options (e.g., `title(...)`, `subtitle(...)`, `legend(...)`) directly within their graph command after the colon.
- **`stub(name)`**: Prefix for memory graph names (`stub_1`, `stub_2`, ..., `stub_N`). Defaults to `sg`.
- **`saving(filename)`**: Unified saving and exporting option that automatically inspects the file postfix/extension:
  - `.pdf`, `.png`, `.svg`, `.eps`, `.tif` $\to$ automatically calls `graph export "filename_i.ext", name(stub_i) replace`.
  - `.gph` (or omitting an extension) $\to$ automatically calls `graph save stub_i "filename_i.gph", replace`.
- **`full`**: In addition to generating the frame sequence, also creates and saves an **unsuffixed full figure** (`stub` in memory, `filename.ext` on disk) where all series are at 100% opacity. This enables generating both paper figures and slide animation frames from a single graph command.

### 3. `slidegraph export`
Generates a clean LaTeX Beamer overlay `.tex` file that can be immediately `\input` into a Beamer slide.

```stata
slidegraph export [using filename.tex] [, path(string) saving(filename) options(string) replace]
```

- **`using filename.tex`**: Target `.tex` file (defaults to `saving_stem.tex`).
- **`path(string)`**: Custom relative or absolute path to prepend in LaTeX `\includegraphics` commands (e.g., `path("figures/slides")`). `slidegraph` automatically strips any local Stata directory components from the image filename, solving path mismatches between Stata and LaTeX.
- **`options(string)`**: Arguments passed inside `\includegraphics[...]` (defaults to `width=\linewidth`).
- **Output syntax**: Generates clean, robust `\only<i...>{\includegraphics[...]}{...}}%` overlays with trailing `%` to prevent unwanted line breaks.

---

## Quickstart & Demonstrations

Run the included demonstration script `examples/slidegraph_demo.do` (or see the complete LaTeX Beamer example in `examples/beamer/`):

### 1. Progressive Build with Shorthand `cumulative` Preset
```stata
sysuse auto, clear

// Shorthand setup: 2 frames (Domestic only -> Domestic + Foreign)
slidegraph set, colors(navy cranberry) cumulative

// All twoway options are placed after the colon
slidegraph : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry)),   ///
    title("Price vs MPG by Foreign Status")
```

### 2. 3-State Narrative Spotlight Build (`spotlight` with dimming)
```stata
// Spotlight: Series under discussion is 100% opacity; previously introduced series are dimmed to %25
slidegraph set, colors(navy cranberry midblue) spotlight dim(25)

slidegraph, stub(spot) : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry))     ///
    (lfit price mpg, lcolor(midblue)),                      ///
    title("Price vs MPG: Spotlight Sequence")
```

### 3. Full Paper Figure + Slide Sequence + LaTeX Beamer Export
```stata
slidegraph set, colors(navy cranberry midblue) cumulative

// full option outputs paper_slide.pdf (paper figure) AND paper_slide_1..3.pdf (slide frames)
slidegraph, stub(paper_slide) saving(paper_slide.pdf) full : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))                 ///
    (scatter price mpg if foreign==1, mcolor(cranberry))           ///
    (lfit price mpg, lcolor(midblue)),                             ///
    title("Price vs MPG with Overall Trend")

// Export LaTeX overlay code pointing to presentation figures directory
slidegraph export using "paper_slide_overlays.tex", path("figures/slides") replace
```

In your LaTeX Beamer presentation, simply insert:
```latex
\begin{frame}{Model Progression}
  \centering
  \input{paper_slide_overlays.tex}
\end{frame}
```

### 4. Custom RGB Colors
```stata
// RGB triples must be enclosed in quotes
slidegraph set, patterns("230 60 60" 11 "40 120 220" 01) off(0)

// Opacity modifier is automatically placed inside quotes: "40 120 220 %0"
slidegraph, stub(rgb_demo) : twoway ///
    (scatter price mpg if foreign==0, mcolor("230 60 60"))       ///
    (scatter price mpg if foreign==1, mcolor("40 120 220")),     ///
    title("Price vs MPG with Custom RGB Colors")
```

### 5. Layered Bar Charts and Box Plots
```stata
slidegraph set, colors(navy cranberry) cumulative

// Works with graph bar, graph box, graph hbar, etc.
slidegraph, stub(demo_bar) : graph bar (mean) price (mean) mpg, ///
    bar(1, color(navy)) bar(2, color(cranberry))                ///
    title("Average Price and MPG Comparison")
```

---

## Testing

Run the included automated test suite in Stata:
```stata
do tests/test_suite.do
```
Tests cover syntax validation, presets (`cumulative`, `spotlight`), 3-state dimming, `full` figure generation, postfix export (`.png`, `.pdf`, `.gph`), RGB quote detection, `slidegraph export` LaTeX file generation, and `net install` package validation.
