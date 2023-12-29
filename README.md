# Tools-in-XSPEC
Useful tools for data analysis in XSPEC

Use a Gaussian line to search lines in spectra:

- Gaussian_line_scan_routine_in_XSPEC.sh

Use photoionization absorption/emission model to search outflow solutions over multiple spectra:

- XSPEC_absorption/emission_grid.sh

Cite Xu, Y. et al. 2023 when you use them.

Convert results of 'error' command in XSPEC for multiple spectra of the same source into a table in LATEX language:

- convert_error_results_to_latex_table.py

Automatically perform 'error' command in XSPEC for multiple spectra of the same source and save results into various txt files (number=N_parameters): 

- output-error-results-in-several-spectra.sh

Create an XSPEC-version table model from PION/XABS in SPEX, see SPEX-to-XSPEC directory:

- 1. Use the PION/XABS model in SPEX to generate spectra with various parameters:
PION/XABS-to-SPECTRA.py
- 2. Collect generated spectra into a table model readable in XSPEC:
gen_table_pion/xabs.py

Cite Parker, Michael L. et al. 2019 when you use them.


