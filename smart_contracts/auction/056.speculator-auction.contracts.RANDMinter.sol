//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RANDMinter is Ownable {
    mapping(address => bool) private minters;

    constructor() public {
        minters[msg.sender] = true;
    }

    function addMinter(address minter) public onlyOwner {
        minters[minter] = true;
    }

    function removeMinter(address minter) public onlyOwner {
        minters[minter] = false;
    }

    modifier onlyMinter() {
        require(minters[_msgSender()] == true, "Not in Minter Role");
        _;
    }
}
