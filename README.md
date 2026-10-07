# H2sim

MATLAB and MRST tools for underground hydrogen storage.

[Documentation](https://xavierr.github.io/h2-sim/) · [Installation](https://xavierr.github.io/h2-sim/installation.html) · [Examples](https://xavierr.github.io/h2-sim/examples.html)

```sh
git clone --recurse-submodules https://github.com/xavierr/h2-sim.git
```

In MATLAB, from the repository root:

```matlab
startupH2sim
result = exampleBlackOilH2Storage1D;
```

- **h2-store:** hydrogen storage in saline aquifers using black-oil models and fluid-property tools.
- **h2-biochem:** hydrogen storage in depleted gas reservoirs using compositional flow with bacterial effects.
- **PHREEQC coupling:** compositional local kinetics and multirate aqueous equilibrium.

Parallel Computing Toolbox is optional; serial execution is the default. PHREEQC COM backends require Windows MATLAB and a registered IPhreeqcCOM server. The bundled database resolves with `which('h2_biogeochemistry.dat')` after startup.

Build the documentation with:

```sh
python -m pip install -r doc/requirements.txt
python -m sphinx -W --keep-going -b html doc build/docs
```

Documentation builds render notebooks without executing MATLAB. Generated simulations, profiler outputs, and local build files do not belong in source commits.
