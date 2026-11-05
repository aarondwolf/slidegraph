# slidegraph

Automate stepped, layered figures for slide presentations (such as LaTeX Beamer or PowerPoint builds) in Stata using opacity modulation.

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
- Hidden series receive an opacity modifier of `%0` (e.g., `navy%0` or `cranberry%0`).
- Dimmed / de-emphasized series receive partial opacity (e.g., `%5` or `%10`).
- Visible series retain full opacity.

Because all series are evaluated in every frame, Stata locks in fixed axis limits, consistent tick intervals, and an identical legend bounding box throughout the entire animation sequence.

---

## Two-Command Architecture

### 1. `slidegraph set`
Configures the visibility sequence across frames and validates the pattern matrix.

```stata
slidegraph set, patterns(color1 pat1 color2 pat2 ...) [off(string)]
```

- **`patterns(string)`**: Space-separated list of `<color_token> <binary_pattern>` pairs.
  - Every pattern must consist strictly of `0` (hidden/dimmed) and `1` (visible) characters.
  - Every pattern must have the exact same length $N$ (the total frame count).
- **`off(string)`**: Opacity modifier applied to `0` bits. Defaults to `"%0"`. You can also specify partial dimming (e.g., `off(%10)`).

### 2. `slidegraph`
Executes the stored multi-frame sequence. Users provide standard `twoway` commands after the colon (`:`) with all native graph options.

```stata
slidegraph [, stub(name) saving(filename)] : <twoway graph command>
```

- **No twoway options in `slidegraph`**: Users specify all graph options (e.g., `title(...)`, `subtitle(...)`, `legend(...)`) directly within their `twoway` command after the colon.
- **`stub(name)`**: Prefix for memory graph names (`stub_1`, `stub_2`, ..., `stub_N`). Defaults to `slide` (`slide_1`, `slide_2`, ...).
  - *Conflict Detection*: If a `name()` option is detected in the graph command, a warning is displayed alerting the user to potential naming conflicts.
- **`saving(filename)`**: Unified saving and exporting option that automatically inspects the file postfix/extension:
  - `.pdf`, `.png`, `.svg`, `.eps`, `.tif` $\to$ automatically calls `graph export "filename_i.ext", name(stub_i) replace`.
  - `.gph` (or omitting an extension) $\to$ automatically calls `graph save stub_i "filename_i.gph", replace`.

---

## Quickstart & Demonstrations

Run the included demonstration script `slidegraph_demo.do`:

### Demonstration 1: 2-Slide Build
```stata
sysuse auto, clear

// Domestic points visible in frames 1 and 2; Foreign points appear in frame 2
slidegraph set, patterns(navy 11 cranberry 01) off(%0)

// All twoway options (e.g., title) are passed directly to twoway
slidegraph : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry)),   ///
    title("Price vs MPG by Foreign Status")
```

### Demonstration 2: 4-Slide Scalable Build with Postfix Export
```stata
// Stepwise reveal: Domestic -> Foreign -> Domestic Trend -> Foreign Trend
slidegraph set, patterns(navy 1111 cranberry 0111 midblue 0011 orange 0001) off(%0)

// saving(build.png) auto-detects .png and exports build_1.png to build_4.png
slidegraph, stub(build) saving(build.png) : twoway                                        ///
    (scatter price mpg if foreign==0, mcolor(navy) msymbol(circle))                       ///
    (scatter price mpg if foreign==1, mcolor(cranberry) msymbol(diamond))                 ///
    (lfit price mpg if foreign==0,    lcolor(midblue) lwidth(medthick))                   ///
    (lfit price mpg if foreign==1,    lcolor(orange) lwidth(medthick) lpattern(dash)),    ///
    title("Evolution of Price vs MPG with Fits")                                          ///
    subtitle("Demonstrating 4-frame stepped progression")                                 ///
    legend(order(1 "Domestic" 2 "Foreign" 3 "Domestic Fit" 4 "Foreign Fit") rows(1))
```

---

## State Persistence Note

Stata wipes standard `r()` results whenever a new command runs. `slidegraph set` persists configuration in global macros (`$SG_patterns`, `$SG_N`, `$SG_off`, `$SG_npairs`) so that `slidegraph` can be run repeatedly without having to re-declare configuration every time.

To inspect active configuration:
```stata
slidegraph
// or
slidegraph query
```

To clear active configuration:
```stata
slidegraph clear
```

---

## Testing

Run the included test suite in Stata:
```stata
do test_suite.do
```
Tests verify parameter validation, restriction of twoway options in `slidegraph`, warning detection for `name()`, postfix export for `.png`/`.pdf`, `.gph` graph saving, memory retention, and cleanup.
