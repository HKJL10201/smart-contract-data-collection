// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
//import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TL is ERC20 {

    /**
    * @dev Constructor of the TL contract
    * Creates some supply for the testing purposes
    */    
    constructor(uint amount) ERC20("TurkishLira", "TL") {
        _mint(msg.sender, amount);
    }

    /**
    * @dev Creates and gives given amount of TL to given address
    * Only used for testing purposes
    */
    function mint(address to, uint amount) public {
        _mint(to, amount);
    }

    /**
    * @dev Transfers given amount of TL from to first given address to second given address
    @ @return bool Whether the transfer was successful
    */
    function send(address from, address to, uint amount) public returns (bool) {
        _transfer(from, to, amount);
        return true;
    }
}