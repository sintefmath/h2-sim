# Full-cycle PHREEQC workflow diagnostics

Numerical exports from two completed, packed 20-cell, 250-day simulations.
No paper text, field-case results, or MATLAB model objects are included.

- `*_history.csv`: reaction-source consumption percentages, spatial median and range of pH and DIC, at 125 accepted output times.
- `*_chemistry.csv`: all 20 cell values at each output time; DIC is mmol/kg water.
- `provenance.json`: source-checkpoint SHA256, schedule, normalization, and available audit results.

Consumption uses total prescribed cycle injection (nominal ideal-gas conversion), not cumulative injection at each time. Spatial medians are descriptive statistics, not well or mixed-water measurements. Workflows differ in kinetic ownership, biomass representation and splitting; these results do not isolate timestep effects. Elemental conservation is not fully established: the compositional case records audit failures and the multirate elemental audit is disabled.

Redraw with `python tools/plot_multirate_results.py` (NumPy and Matplotlib).
The notebook documents the setup and interpretation.
