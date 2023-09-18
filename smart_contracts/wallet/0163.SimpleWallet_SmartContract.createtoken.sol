//Creating ERC20 Custom token with the help of OpenZeppelin
//SPDX-License-Identifier:MIT
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
pragma solidity ^0.8.0;
contract mytoken is ERC20{
    constructor(string memory _name,string memory _symbol) ERC20(_name,_symbol){
        //this means the contract will also call the constructor in the OpenZeppelin ERC20 contract 
        _mint(msg.sender,1000*(1e18));
        //calling function present inside the ERC20 contract
    }
}
