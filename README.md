# Tools-in-XSPEC
Useful tools for data analysis in XSPEC

Create an XSPEC-version table model from PION/XABS in SPEX, see SPEX-to-XSPEC directory:

1. Use the PION/XABS model in SPEX to generate spectra with various parameters:
- PION/XABS-to-SPECTRA.py
2. Collect generated spectra into a table model readable in XSPEC:
- gen_table_pion/xabs.py
- The general versions that do not need pre-calculated SEDs and the ionization balances are in the SPEX-to-XSPEC/general-version/ directory. Be cautious: a cut-off power-law component, instead of a specific SED, is used as an approximation.

Cite Parker, Michael L. et al. 2019 when you use them.



Use a Gaussian line to search lines in spectra:

- Gaussian_line_scan_routine_in_XSPEC.sh

Use photoionization absorption/emission model to search outflow solutions over multiple spectra:

- XSPEC_absorption/emission_grid.sh (here the emission uses a general-version of PION with Omeg=1)

Cite Xu, Yerong et al. 2023 when you use them.


Perform cross-correlation-based Monte Carlo simulations to estimate line significance (including look-elsewhere effects) in spectra:

- see /cross-correlation-based Monte Carlo simulations/line-search/ directory and follow use scripts in the order (currently only one spectrum is considered)

Cite Xu, Yerong et al. 2022 when you use them.

Perform cross-correlation-based Monte Carlo simulations to estimate the significance of plasma detection (including look-elsewhere effects):

- see /cross-correlation-based Monte Carlo simulations/XABS-search/ directory and follow use scripts in the order (currently only one spectrum and absorption model is considered)

Cite Xu, Yerong et al. 2022 when you use them.



Convert results of 'error' command in XSPEC for multiple spectra of the same source into a table in LATEX language:

- convert_error_results_to_latex_table.py

Automatically perform 'error' command in XSPEC for multiple spectra of the same source and save results into various txt files (number=N_parameters): 

- output-error-results-in-several-spectra.sh
