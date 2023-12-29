# Tools-in-XSPEC
Useful tools for data analysis in XSPEC

Use a Gaussian line to search lines in spectra:
Gaussian_line_scan_routine_in_XSPEC.sh

Convert results of 'error' command in XSPEC for multiple spectra of the same source into a table in LATEX language:
convert_error_results_to_latex_table.py

Automatically perform 'error' command in XSPEC for multiple spectra of the same source and save results into various .txt files (number=N_parameters): 
output-error-results-in-several-spectra.sh

Create an XSPEC-version table model from PION in SPEX, see SPEX-to-XSPEC directory:
1. Use the PION model in SPEX to generate spectra with various parameters:
PION-to-SPECTRA.py
2. Collect generated spectra into a table model readable in XSPEC:
gen_table_pion.py 
Cite Parker, Michael L. 2019 when you use them.
