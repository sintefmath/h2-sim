Quick start
===========

After :doc:`installation`, choose one of the three model families.
All examples below use serial execution.

Hydrogen storage in saline aquifers
-----------------------------------

.. code-block:: matlab

   startupH2sim
   result = exampleBlackOilH2Storage1D;
   lastState = result.states{end};
   gasSaturation = lastState.s(:, 2);

The tutorial uses a horizontal column, a fixed-pressure outlet, and an H₂
injector. It is immiscible: dissolution and vaporization are disabled.
See :doc:`store` for the black-oil interpretation and :doc:`thermodynamics`
for the property tools.

Hydrogen storage in depleted gas reservoirs
-------------------------------------------

.. code-block:: matlab

   simple1DBacterialExampleMetacet

Open the compositional notebook in :doc:`examples` to inspect the setup,
well controls, microbial populations, and transport plots.

Short PHREEQC mineral comparison
--------------------------------

On Windows with IPhreeqcCOM configured:

.. code-block:: matlab

   comparison = exampleCompositionalBacterial1DPhreeqcMinerals( ...
       'gridCells', 4, 'maximumFlowSteps', 2);
   pH = comparison(2).states{end}.phreeqcPH;

Redraw the completed states without solving again:

.. code-block:: matlab

   plotPhreeqcMineralComparison(comparison, ...
       'outputDirectory', fullfile(pwd, 'build', 'my-figures'));

These cases use different kinetic owners. Read :doc:`phreeqc` before
interpreting a backend comparison as a sensitivity to mineral chemistry.
