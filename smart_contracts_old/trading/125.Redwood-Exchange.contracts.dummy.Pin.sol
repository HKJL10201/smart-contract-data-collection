pragma solidity 0.5.3;

// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol';
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/IERC20.sol';
// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol';

import '../libraries/token/ERC20/ERC20.sol';
import '../libraries/token/ERC20/IERC20.sol';
import '../libraries/token/ERC20/ERC20Detailed.sol';

contract Pin is  IERC20, ERC20, ERC20Detailed{
    constructor() ERC20Detailed('PIN', 'Pine Stablecoin', 18) public {}
    
    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}
