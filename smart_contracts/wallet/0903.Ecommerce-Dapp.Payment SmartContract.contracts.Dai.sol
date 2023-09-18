// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
contract Dai is ERC20{
    constructor() ERC20('Dai Stablecoin','DAI') public {}
    function faucet(address _to, uint _amount) external {
        _mint(_to,_amount);
    }
}