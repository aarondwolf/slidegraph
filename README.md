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
Executes the stored multi-frame sequence, modifying the graph command for each frame $i = 1, \dots, N$.

```stata
slidegraph [, stub(name) saving(filename [, replace]) export(fmt) *] : <any twoway graph command>
```

- **`stub(name)`**: Prefix for memory graph names (`stub_1`, `stub_2`, ..., `stub_N`). Defaults to `slide` (`slide_1`, `slide_2`, ...).
- **`saving(filename [, replace])`**: Saves each frame to disk as `filename_i.gph`.
- **`export(fmt)`**: Automatically exports each slide to disk in the specified format (e.g., `export(png)` or `export(pdf)`).
- **`*`**: Any standard Stata `twoway` options (e.g., `title(...)`, `subtitle(...)`, `legend(...)`) passed before the colon will be applied to each frame.

---

## Quickstart & Demonstrations

Run the included demonstration script `slidegraph_demo.do`:

### Demonstration 1: 2-Slide Build
```stata
sysuse auto, clear

// Domestic points visible in frames 1 and 2; Foreign points appear in frame 2
slidegraph set, patterns(navy 11 cranberry 01) off(%0)

slidegraph, title("Price vs MPG by Foreign Status") : twoway ///
    (scatter price mpg if foreign==0, mcolor(navy))         ///
    (scatter price mpg if foreign==1, mcolor(cranberry))
```

### Demonstration 2: 4-Slide Scalable Build
```stata
// Stepwise reveal: Domestic -> Foreign -> Domestic Trend -> Foreign Trend
slidegraph set, patterns(navy 1111 cranberry 0111 midblue 0011 orange 0001) off(%0)

slidegraph, stub(build4) title("Evolution of Price vs MPG with Fits") : twoway            ///
    (scatter price mpg if foreign==0, mcolor(navy) msymbol(circle))                       ///
    (scatter price mpg if foreign==1, mcolor(cranberry) msymbol(diamond))                 ///
    (lfit price mpg if foreign==0,    lcolor(midblue) lwidth(medthick))                   ///
    (lfit price mpg if foreign==1,    lcolor(orange) lwidth(medthick) lpattern(dash)),    ///
    legend(order(1 "Domestic" 2 "Foreign" 3 "Domestic Fit" 4 "Foreign Fit") rows(1))
```

---

## State Persistence Note

Stata wipes standard `r()` results whenever a new command runs. To maintain a smooth interactive experience, `slidegraph set` stores parsed configuration in global macros (`$SG_patterns`, `$SG_N`, `$SG_off`, `$SG_npairs`) so that `slidegraph` can be run repeatedly without having to re-declare configuration every time.

To inspect the current configuration:
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
Tests verify parameter validation, syntax errors, frame count matching, opacity modifier formatting, memory graph retention, and file exports.
