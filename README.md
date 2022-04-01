# Smart Contract Data Collection

Including collected smart contracts, scripts for collecting these contracts, and logs.

## Dataset

Collected data is stored in `smart_contracts` directory.

## Scripts
- `smart_contract_reptile.py`: used to collect names and links of repositories from GitHub, and store results in `.csv` files for each category.
- `smart_contract_download.py`: used to automatically clone repositories from the collected links, and store in `contracts` directory.
- `sol_selector.py`: used to find all `.sol` files in `contracts` directory, and record the file paths in `sol.log`.
- `smart_contract_copy.py`: used to copy all `.sol` files from `contracts` directory to `smart_contracts` directory.

## Logs
- `.csv` files record the names and links of GitHub repositories with specific category.
- `sol.log` records the paths of `.sol` files in downloaded repositories.
