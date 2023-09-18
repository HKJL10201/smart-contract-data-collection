pragma solidity >=0.4.21 <=0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GenericERC20 is ERC20 {
    string public name = "GenereicERC20";
    string public symbol = "GERC20";
    uint256 public decimals = 2;
    address private _owner;

    constructor() public {
        _owner = msg.sender;
    }
    
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
    
    function transfer(address sender, address recipient, uint256 amount) public {
        _transfer(sender, recipient, amount);
    }
}