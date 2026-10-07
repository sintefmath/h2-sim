.. raw:: html

   <div class="home-hero">
    <div class="hero-copy">
     <p class="eyebrow">OPEN TOOLS FOR UNDERGROUND HYDROGEN STORAGE</p>
     <h1>From storage physics<br>to reactive flow.</h1>
     <p class="hero-description">Explore hydrogen–brine flow, microbial activity, and chemistry coupling with MATLAB and MRST.</p>
     <div class="hero-actions"><a class="primary-button" href="installation.html">Get started ↗</a><a class="secondary-button" href="examples.html">Explore notebooks →</a></div>
    </div>
    <figure class="hero-figure"><img src="_static/reservoir.svg" alt="Conceptual porous reservoir: hydrogen injection, a gas plume, and local microbial reactions." width="520" height="420"><figcaption>Understand the physics. Inspect the equations.</figcaption></figure>
   </div>

Choose your model
=================

H2sim extends the MATLAB Reservoir Simulation Toolbox with models and
property tools for hydrogen storage. Begin with the physics you need,
then use a short example to understand the setup and output.

.. grid:: 1 1 3 3
   :gutter: 3
   :class-container: feature-grid

   .. grid-item-card:: 01 · Saline aquifers
      :link: store
      :link-type: doc

      **Black-oil models · h2-store**

      Hydrogen–brine displacement, fluid properties, and solubility tables.

   .. grid-item-card:: 02 · Depleted gas reservoirs
      :link: biochem
      :link-type: doc

      **Compositional flow with bacterial effects · h2-biochem**

      Microbial growth and reaction pathways coupled to compositional transport.

   .. grid-item-card:: 03 · PHREEQC coupling
      :link: phreeqc
      :link-type: doc

      **Local chemistry · two workflows**

      Compositional kinetic coupling or multirate aqueous equilibrium.

Start small. Build understanding.
=================================

.. grid:: 1 1 2 2
   :gutter: 3

   .. grid-item-card:: Installation that fits your setup
      :link: dependencies
      :link-type: doc

      Required dependencies, optional PHREEQC, and serial execution without
      Parallel Computing Toolbox.

      +++
      Check dependencies →

   .. grid-item-card:: Guided MATLAB notebooks
      :link: examples
      :link-type: doc

      A compact black-oil model, microbial flow, and short chemistry examples.

      +++
      Browse examples →

.. admonition:: A serial path for every selected example
   :class: platform-note

   Parallel Computing Toolbox is optional. PHREEQC COM examples require
   Windows MATLAB and a registered IPhreeqcCOM server; MRST-only examples do not.

.. toctree::
   :hidden:
   :caption: Getting started

   installation
   dependencies
   quickstart

.. toctree::
   :hidden:
   :caption: Models

   store
   biochem
   phreeqc

.. toctree::
   :hidden:
   :caption: Learn and explore

   thermodynamics
   examples

.. toctree::
   :hidden:
   :caption: Reference

   reference
   bibliography
   funding
