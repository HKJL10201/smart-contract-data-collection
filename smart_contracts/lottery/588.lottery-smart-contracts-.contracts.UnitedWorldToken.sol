// SPDX-License-Identifier: LICENSED
pragma solidity >=0.5.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";


contract UnitedWorldToken is ERC20Burnable {


    address public admin;
    constructor(
        uint256 initialSupply
    ) public ERC20("UnitedWorldToken", "UWT") {
        admin = msg.sender;
        _mint(msg.sender, initialSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == admin, "only admin");
        _;
    }
    
     function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}



