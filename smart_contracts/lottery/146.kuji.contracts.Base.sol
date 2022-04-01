// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Base is Ownable {

    bool internal locked;

    event Received(address, uint);

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(address to, uint256 value) public payable onlyOwner noReentrant {
        (bool sent, ) = to.call{value: value}("");
        require(sent, "Failed to send Ether");
    }

}