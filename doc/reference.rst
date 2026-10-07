Code reference
==============

Browse the `source repository <https://github.com/xavierr/h2-sim>`_, or use
MATLAB's ``help`` and ``edit`` commands for local function documentation.

Entry points
------------

.. list-table::
   :header-rows: 1
   :widths: 60 40

   * - Function
     - Purpose
   * - ``startupH2sim``
     - Initialize code and dependencies
   * - ``exampleBlackOilH2Storage1D``
     - Small serial black-oil injection tutorial
   * - ``simple1DBacterialExampleMetacet``
     - MRST compositional microbial example
   * - ``setupH2StorageExampleWithSRB_benchmark``
     - Configure a multi-reaction benchmark
   * - ``exampleCompositionalBacterial1DPhreeqcMinerals``
     - Original MRST and three PHREEQC mineral configurations
   * - ``exampleSequentialBiochemistryPhreeqc1D``
     - Coarse-flow / local-reaction multirate example
   * - ``profilePhreeqcWorkflows``
     - Paired profiling and state comparisons

Output and replotting
---------------------

The three new short examples save their setup and accepted states with MRST
packed simulation output. ``packed_setup.mat`` sits beside the saved states,
well solutions, and timestep reports. Changed inputs select a separate result
directory. Returned results contain the setup and state histories;
``packedProblem`` identifies the black-oil and multirate output locations.
The mineral comparison returns one result per model configuration.

.. code-block:: matlab

   plotPhreeqcMineralComparison(comparison);
   plotSequentialBiochemistryPhreeqc(summary);
   plotPhreeqcBackendComparison(scenarios);

Plotting functions preserve values and export vector PDF and PNG figures.
``outputDirectory=''`` disables export. Dimensionless distance uses actual
domain edges, rather than stretching cell centers to zero and one.

Hydrogen-consumption percentages refer to microbial reaction consumption,
with the injection denominator stated by the figure. They are distinct from
unrecovered gas or a production recovery factor.

Tests
-----

.. code-block:: matlab

   checks = runtests('h2-biochem/tests');
   assertSuccess(checks);

COM integration tests require Windows and a registered IPhreeqcCOM server.
A skipped test does not validate a backend on that platform. The serial
fallback tests cover both available and missing optional toolbox checks.

See :doc:`phreeqc` for the current conservation-audit limitations.
