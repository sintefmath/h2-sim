# Hydrogen-storage biogeochemistry database

`h2_biogeochemistry.dat` is a renamed, unmodified copy of the modified PHREEQC database distributed with [UGFACT](https://github.com/ahmadrezashojaee/UGFACT), developed by Ahmadreza Shojaee at Heriot-Watt University. It is based on the USGS PHREEQC database and includes the pseudo-elements and aqueous species used by the coupled hydrogen-storage workflows.

- [Exact upstream source](https://github.com/ahmadrezashojaee/UGFACT/blob/1f8847ea1895cef52a6f004f46a81614a1d57989/examples/database/PHREEQC_Modified.DAT)
- Upstream filename: `examples/database/PHREEQC_Modified.DAT`
- UGFACT source revision: `1f8847ea1895cef52a6f004f46a81614a1d57989`
- SHA-256: `285cf917656b73786ce4e2a65d8cd7f55fb8086b5022dc7e56b0bc51d11407c7`
- H2sim changes: filename only; all database contents and original credits are preserved.

After `startupH2sim`, locate the bundled database with `which('h2_biogeochemistry.dat')`. Explicitly configured database paths must use this filename, including paths set through `PHREEQC_DATABASE_FILE`.

Please acknowledge UGFACT, MRST, and USGS PHREEQC when using these tools. UGFACT's accompanying framework publication is [New flow simulation framework for underground hydrogen storage modelling considering microbial and geochemical reactions](https://doi.org/10.1016/j.ijhydene.2025.150453).

The database retains its upstream provenance; the H2sim repository does not imply authorship of its thermodynamic data. Upstream [licensing and credits](https://github.com/ahmadrezashojaee/UGFACT#-licensing--credits) identify PHREEQC as USGS software and MRST as GPLv3 software.
