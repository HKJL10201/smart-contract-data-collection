// "SPDX-License-Identifier: MIT"
pragma solidity ^0.7.4;


contract Ownable {
    address internal _owner;

    event OwnerTransfered(address owner);

    constructor () {
        _owner = msg.sender;
        emit OwnerTransfered(msg.sender);
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
        emit OwnerTransfered(newOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner(address comparableAddress) public view returns (bool) {
        return _owner == comparableAddress;
    }

}