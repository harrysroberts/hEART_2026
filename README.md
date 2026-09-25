# hEART 2026 poster reproducible code

This repository contains the R code used to generate figures for a poster presented at the European Association for Research in Transportation (hEART) conference in Paris in October 2026:

> Roberts, H. S., Calastri, C., Batley, R. 2026. _Using marginal impedance distributions to calibrate impedance functions for accessibility measurement_ \[Poster\]. European Association for Research in Transportation (hEART), 2026, Paris.

The paper presents "Weighted Marginal Distribution Calibration" as a method to correct for spatially-induced bias in impedance function calibration, using a weight function to capture this bias. This method has been implemented in the `wmdc` package available separately from the author's GitHub at [harrysroberts/wmdc](https://github.com/harrysroberts/wmdc).

## Start here

1. Install [R](https://cran.r-project.org/) (R 4.3 or newer is recommended).
2. Clone this repository and run all commands from its root directory.
3. Create an `output/` directory:

   ```sh
   mkdir -p output
   ```

4. Read [`data_sources.qmd`](data_sources.qmd) and place the required source data under `input/raw/` using the filenames documented there.
5. Install the packages needed for the figure you want to reproduce.
6. Run a script, for example:

   ```sh
   Rscript R/linear_growth_demo_plot.r
   ```

   The figure will be written to `output/uniform.png`.

The scripts use paths relative to the repository root. Running them from another directory will usually result in a missing-file error.

## Figure scripts

| Script | Purpose | Data required | Output |
| --- | --- | --- | --- |
| [`R/nts_histogram.R`](R/nts_histogram.R) | Plots the National Travel Survey home-to-work travel-time distribution | National Travel Survey | `output/impedance_histogram.png` |
| [`R/linear_growth_demo_plot.r`](R/linear_growth_demo_plot.r) | Demonstrates linear growth of destination availability with distance | None | `output/uniform.png` |
| [`R/p_g_f_curves.R`](R/p_g_f_curves.R) | Plots spatial weight function, impedance function, and the marginal impedance distribution | None | `output/pgf_graph.png` |
| [`R/disc_demo_plot.R`](R/disc_demo_plot.R) | Illustrates simulated paired points inside a disc | None | `output/disc_plot.png` |
| [`R/simulation_experiment.R`](R/simulation_experiment.R) | Simulates a trip distribution using a doubly-constrained gravity model and tests the ability of WMDC to recover the input parameter | None | `output/heatmap.png` |
| [`R/boundary_interference_demo_plot.R`](R/boundary_interference_demo_plot.R) | Illustrates how the boundary of the study area induces a reduction in destination availability at higher impedance levels | None | `output/boundary_interference.png` |
| [`R/nts_calibration.R`](R/nts_calibration.R) | Calibrates an impedance function over English NTS data using WMDC, plots this function against the survival curve and maps the accessibility of Leeds under both the WMDC-calibrated impedance function and using the survival curve as the impedance function| National Travel Survey, census geography, workplace data, and OS-MRN | `output/impedance_functions_graph.png`, `output/accessibility_plot.png` |

## Dependencies

The scripts check for most of their CRAN dependencies when they start. Install the common packages with:

```r
install.packages(c("tidyverse", "ggplot2", "scales", "sf", "patchwork"))
```

The simulation and NTS calibration scripts also use the development packages `wmdc` and `losdos`. The scripts offer to install these from GitHub, or they can be installed explicitly:

```r
install.packages("pak")
pak::pak(c("harrysroberts/wmdc", "harrysroberts/losdos"))
```

`sf` may require system libraries on Linux. Follow the installation guidance for your operating system if package installation fails.

## Reproduction order

The scripts are independent, so there is no required execution order. A quick smoke test uses the five data-free scripts:

```sh
Rscript R/linear_growth_demo_plot.r
Rscript R/p_g_f_curves.R
Rscript R/disc_demo_plot.R
Rscript R/simulation_experiment.R
Rscript R/boundary_interference_demo_plot.R
```

Once the source data is available, run the data-dependent figures:

```sh
Rscript R/nts_histogram.R
Rscript R/nts_calibration.R
```

The scripts write PNG files directly to `output/`. These generated files are ignored by Git and are not part of the source-data archive.

## Data and provenance

The source datasets are not included in this repository. [`data_sources.qmd`](data_sources.qmd) records where to obtain each dataset, the expected local filename, and which script uses it. Some sources have access, licence, or geographic eligibility conditions; check the provider's terms before downloading or sharing them.

The code is intended to be run from a clean checkout with the documented source files. Because the simulation demonstrations use random sampling, their exact output can vary between runs unless a seed is set in the script.

## Project structure

```text
R/                 Figure-generation scripts
input/raw/         Locally downloaded source data (not committed)
output/            Generated figures (not committed)
data_sources.qmd   Data manifest and download links
README.md          Reproduction guide
```

## Citation

If you use this package in your research, the following citation is appreciated:

**Poster presented at hEART 2026:**

Roberts, H. S., Calastri, C., Batley, R. 2026. _Using marginal impedance distributions to calibrate impedance functions for accessibility measurement_ \[Poster\]. European Association for Research in Transportation (hEART), 2026, Paris.

## License

MIT License. See LICENSE file for details.

## Author

Harry Roberts ([H.S.Roberts@leeds.ac.uk](mailto:H.S.Roberts@leeds.ac.uk))

Institute for Transport Studies, University of Leeds
