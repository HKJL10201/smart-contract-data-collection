pragma solidity ^0.6.3;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
//import '@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol';

contract DaiToken is ERC20{
    constructor() ERC20('DAI', 'Dai Stablecoin') public {}
    function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
}