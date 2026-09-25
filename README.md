# hEART 2026 poster reproducibility code

This repository contains the R code used to generate figures for a poster presented at the hEART transport conference in Paris in October 2026.

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
| [`R/linear_growth_demo_plot.r`](R/linear_growth_demo_plot.r) | Demonstrates linear growth of destination availability with distance | None | `output/uniform.png` |
| [`R/disc_demo_plot.R`](R/disc_demo_plot.R) | Illustrates paired points and distance-weighted connections inside a disc | None | `output/disc_plot.png` |
| [`R/boundary_interference_demo_plot.R`](R/boundary_interference_demo_plot.R) | Shows how a study-area boundary changes destination availability | None | `output/boundary_interference.png` |
| [`R/p_g_f_curves.R`](R/p_g_f_curves.R) | Plots spatial weight, impedance, and their product | None | `output/pgf_graph.png` |
| [`R/simulation_experiment.R`](R/simulation_experiment.R) | Tests WMDC recovery in simulated disc-shaped study areas | None | `output/heatmap.png` |
| [`R/nts_histogram.R`](R/nts_histogram.R) | Plots the National Travel Survey home-to-work travel-time distribution | National Travel Survey | `output/impedance_histogram.png` |
| [`R/nts_calibration.R`](R/nts_calibration.R) | Calibrates impedance functions and maps Leeds accessibility | NTS, census geography, workplace data, and OS-MRN | `output/impedance_functions_graph.png`, `output/accessibility_plot.png` |

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
Rscript R/disc_demo_plot.R
Rscript R/boundary_interference_demo_plot.R
Rscript R/p_g_f_curves.R
Rscript R/simulation_experiment.R
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

If you use this package in your research, the following citations are appreciated:

**Poster presented at hEART 2026:**

 Roberts, H. S., Calastri, C., Batley, R. 2026. _Using marginal impedance distributions to calibrate impedance functions for accessibility measurement_ \[Poster\]. European Association for Research in Transportation (hEART), 2026, Paris.

## License

MIT License. See LICENSE file for details.

## Author

Harry Roberts ([H.S.Roberts@leeds.ac.uk](mailto:H.S.Roberts@leeds.ac.uk))

Institute for Transport Studies, University of Leeds