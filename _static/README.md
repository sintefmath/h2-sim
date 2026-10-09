# Website assets

- `h2sim-logo.svg`, `h2sim-icon.svg`, `reservoir.svg`, and `workflows.svg` are H2sim website artwork.
- `home-storage.png`, `home-microbial.png`, and `home-chemistry.png` are AI-generated conceptual illustrations. They are not simulation results.
- `mrst-logo.png` is the official MRST/SINTEF banner, retrieved from the [MRST website](https://www.sintef.no/projectweb/mrst/). Its exact source is recorded in `mrst-logo-source.txt`. The logo links back to MRST and identifies the underlying toolbox.
- `elyes-ahmed-hydrogemm.jpg` is Elyes Ahmed’s portrait from the [official HydroGEMM 2026 invited-speaker page](https://hydrogemm-2026.sciencesconf.org/resource/page/id/1), reused for his event announcement.
- `examples/` contains selected plots from saved example outputs. The corresponding public MATLAB plotting functions and notebooks describe the observables and normalization.

- `phreeqc-icon.png` is a PNG conversion of the PHREEQC application icon from [the upstream USGS source](https://github.com/usgs-coupled/phreeqc3/blob/master/src/phreex.ico). It identifies PHREEQC and links to its official USGS software page.

- `examples/multirate_full_cycle_*.png` are redrawn from the complete 250-day saved multirate and compositional PHREEQC diagnostics in `doc/data/multirate/`. Run `tools/plot_multirate_results.py` to regenerate them; checkpoint checksums and audit limitations are recorded with the data.
