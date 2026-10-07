Installation
============

Clone H2sim with its pinned dependencies, then initialize it from MATLAB.
See :doc:`dependencies` for required and optional components.

Clone the repository
--------------------

.. code-block:: shell

   git clone --recurse-submodules https://github.com/xavierr/h2-sim.git
   cd h2-sim

For a checkout cloned without submodules:

.. code-block:: shell

   git submodule update --init --recursive

Initialize MATLAB
-----------------

In the repository root:

.. code-block:: matlab

   startupH2sim

Use MATLAB R2021a or newer for the core examples. Startup adds H2sim modules
and initializes dependencies. Do not add the complete MRST tree with ``genpath``.

Check a small model
-------------------

.. code-block:: matlab

   result = exampleBlackOilH2Storage1D;

This compact black-oil injection example needs neither PHREEQC nor Parallel
Computing Toolbox. Continue with :doc:`quickstart` or :doc:`examples`.

Optional PHREEQC setup
----------------------

Install and register IPhreeqcCOM from the
`USGS PHREEQC distribution <https://www.usgs.gov/software/phreeqc-version-3>`_
on Windows. Test the COM interface and the bundled database:

.. code-block:: matlab

   db = which('h2_biogeochemistry.dat');
   assert(~isempty(db), 'Initialize H2sim first.');
   iph = actxserver('IPhreeqcCOM.Object');
   status = iph.LoadDatabase(db);
   assert(status == 0);
   delete(iph);

Configure ``phreeqcComProgId`` if your COM installation uses a different
identifier. ``phreeqcDatabaseFile`` must resolve to an absolute database path.

The optional WSL wrapper launches Windows MATLAB:

.. code-block:: shell

   bash run_matlab_h2sim.sh "disp(version);"

Set ``MATLAB_BIN`` to the executable's WSL path if necessary. The wrapper
uses a Windows MATLAB installation and its normal licensing requirements.

Update a checkout
-----------------

.. code-block:: shell

   git pull
   git submodule update --init --recursive

Re-run ``startupH2sim`` after updating.

Build the website locally
-------------------------

.. code-block:: shell

   python -m pip install -r doc/requirements.txt
   python -m sphinx -W --keep-going -b html doc build/docs

The docs render saved notebook content and example figures without executing
MATLAB. Open ``build/docs/index.html`` or serve that directory locally.
