pragma solidity ^0.6.0;
import "../node_modules/@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
// https://eips.ethereum.org/EIPS/eip-777
// Example implementation https://github.com/0xjac/ERC777/blob/master/contracts/examples/ReferenceToken.sol
// SPDX-License-Identifier: MIT

contract ERC777Token is ERC777,Ownable{
    constructor(
        
    )
        ERC777("MyERC777", "TF7", new address[](0))
        public
    {

        
    }
    function getMyErc777(address account) public onlyOwner{
        address owner = msg.sender;
        _mint(account,100,"","");
    }
}