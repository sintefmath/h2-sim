Hydrogen storage in depleted gas reservoirs
===========================================

Compositional flow with bacterial effects · ``h2-biochem``

The biochemistry module extends MRST compositional flow with microbial
populations, reaction pathways, and aqueous tracer transport. This model
family supports studying injected hydrogen mixed with residual reservoir
gases. The introductory notebook uses a simplified one-dimensional setup.

What the models include
-----------------------

* Soreide–Whitson gas–liquid partitioning.
* Methanogenesis and acetogenesis in the selected introductory notebook.
* Sulfate reduction in the corresponding multi-reaction setups.
* Optional molecular diffusion, dispersion, bacterial diffusion, chemotaxis,
  carbonate feedback, and bioclogging where supported by the setup.

The component mixture depends on the example. The multi-reaction setups
include water, hydrogen, carbon dioxide, methane, hydrogen sulfide, and acetate.

Start without PHREEQC
---------------------

.. code-block:: matlab

   startupH2sim
   simple1DBacterialExampleMetacet

This MRST-only example introduces grid construction, wells, microbial
populations, and compositional transport. It requires neither IPhreeqcCOM
nor Parallel Computing Toolbox.

.. button-ref:: nblinks/simple1DBacterialExampleMetacet
   :color: primary

   Open the bacterial-flow notebook →

Equation ownership
------------------

With ``phreeqcTimestepCoupling=false``, microbial source terms are owned by
MRST. The optional PHREEQC workflows change how chemistry is closed and,
for the compositional backend, which solver owns microbial kinetics.
See :doc:`phreeqc` before switching backends.

Inspect ``state.nbact`` for modeled microbial populations and the appropriate
component/tracer fields for transport. Consumption means hydrogen removed by
microbial reactions; it is distinct from unrecovered gas during withdrawal.
