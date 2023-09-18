// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import './ERC20/ERC20.sol';

contract NBKToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    )
        ERC20(_name, _symbol)
    public {
        _mint(msg.sender, _maxSupply*(10**18));
    }
}