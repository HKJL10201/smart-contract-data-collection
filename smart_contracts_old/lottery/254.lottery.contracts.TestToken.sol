pragma solidity ^0.6.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {

    constructor(string memory name, string memory symbol) public ERC20(name, symbol){}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
