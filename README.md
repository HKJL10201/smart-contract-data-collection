# Smart Contract Data Collection

Including collected smart contracts, scripts for collecting these contracts, and logs.

## Dataset

- Collected data is stored in `smart_contracts` directory.
- Previously collected data is stored in `smart_contracts_old` directory.

## Scripts

- `smart_contract_reptile.py`: used to collect names and links of repositories from GitHub, and store results in `.log` files for each category.
- `smart_contract_download.py`: used to automatically clone repositories from the collected links, and store in `contracts` directory.
- `sol_selector.py`: used to find all `.sol` files in `contracts` directory, and record the file paths in `sol.log`.
- `smart_contract_copy.py`: used to copy all `.sol` files from `contracts` directory to `smart_contracts` directory.

## Logs

- `.log` files record the names and links of GitHub repositories with specific category.
- `sol.log` records the paths of `.sol` files in downloaded repositories.

## Problems

The search limit of GitHub is 1000, which means that although 1311 voting dapps can be found, GitHub can only display the first 1000 results.
