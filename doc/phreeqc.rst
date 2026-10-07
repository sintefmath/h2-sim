PHREEQC coupling
================

Two supported chemistry workflows share MRST flow and EOS gas–liquid
partitioning, but assign microbial kinetics differently.

.. image:: _static/workflows.svg
   :alt: Compositional PHREEQC assigns local kinetics to PHREEQC; multirate PHREEQC retains MRST kinetics and calls aqueous equilibrium after reaction substeps.
   :width: 100%

.. list-table:: Workflow ownership
   :header-rows: 1
   :widths: 25 25 25 25

   * - Workflow
     - Flow / transport
     - Microbial kinetics
     - Equilibrium chemistry
   * - Compositional PHREEQC
     - MRST
     - Cell-local PHREEQC kinetics
     - PHREEQC after a flow timestep
   * - Multirate PHREEQC
     - Coarse MRST flow step
     - MRST local reaction substeps
     - Aqueous-only PHREEQC after each reaction substep

Compositional kinetic coupling
------------------------------

Set ``phreeqcBackend='sequential-compositional-phreeqc'`` and enable timestep
coupling. PHREEQC integrates MET, ACE, and SRB kinetic amounts locally. MRST's
implicit microbial source terms are disabled to prevent double counting.
Aqueous tracers remain transported in MRST.

.. code-block:: matlab

   comparison = exampleCompositionalBacterial1DPhreeqcMinerals( ...
       'gridCells', 4, 'maximumFlowSteps', 2);

Batches reduce COM overhead. The default batch size is 50; use
``sequentialCompositionalPhreeqcBatchSize=1`` for individual cell calls.
Inactive-cell skipping records an explicit execution mask; a skipped identity
update is not an independently evaluated chemistry audit.

.. button-ref:: notebooks/mineral_comparison
   :color: primary

   Open the mineral-chemistry notebook →

Multirate aqueous equilibrium
-----------------------------

The multirate model follows each coarse flow step with bounded local MRST
microbial reaction substeps. PHREEQC equilibrates aqueous/mineral chemistry
after each substep and refreshes the kinetic feedback. Its input contains
no PHREEQC ``RATES`` or ``KINETICS`` blocks.

.. code-block:: matlab

   summary = exampleSequentialBiochemistryPhreeqc1D( ...
       'maximumFlowSteps', 2, 'plotResults', true, ...
       'phreeqcReflashParallel', false);

``reactionSubstepMaxDt`` controls the local reaction cadence. Pressure
flashes run serially by default; Parallel Computing Toolbox is optional.
The separate ``simulateSequentialH2BiochemPhreeqc`` runner is an outer Picard
scheme, distinct from this coarse-flow multirate example.

.. button-ref:: notebooks/multirate_reactions
   :color: primary

   Open the multirate notebook →

Conservation diagnostics
------------------------

The compositional backend records per-cell elemental inventories and warns
when configured tolerances are exceeded. Inspect ``phreeqcElementBalancePass``
and ``phreeqcElementBalanceEvaluatedCells``.

The current equilibrium-only implementation has its elemental audit disabled;
its post-equilibrium EOS component-inventory audit remains active. A passing
EOS audit alone does not establish elemental conservation across the chemistry
handoff. Backend comparisons may also change kinetic parameters and ownership;
a difference is not automatically a mineral or pH effect.

Profiling tools
---------------

.. code-block:: matlab

   results = profilePhreeqcWorkflows('backends', {'compositional'}, ...
       'collectProfiles', false, 'trials', 3);

Paired states and timings are saved under ``build/phreeqc-performance``.
Compare states and diagnostics before interpreting runtime improvements.
