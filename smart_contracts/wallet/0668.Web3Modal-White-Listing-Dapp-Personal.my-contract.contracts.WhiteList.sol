// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WhiteList {
    uint256 public numberOfWhiteListedAddresses; //public so i can access it in the UI to check if i should call addAd..
    uint256 public maxNumOfWhiteListedAddresses;
    mapping(address => bool) public whiteListedAddresses;
    address[] allWhiteListedAddresses;
    address owner;

    constructor(uint256 _maxNumOfWhiteListedAddresses) {
        maxNumOfWhiteListedAddresses = _maxNumOfWhiteListedAddresses;
        owner = msg.sender;
    }

    function addAddressToWhiteList() public {
        require(numberOfWhiteListedAddresses < maxNumOfWhiteListedAddresses, "Limit reached, cant add address to whitelist");
        require(!whiteListedAddresses[msg.sender], "Address is already whitelisted");
        whiteListedAddresses[msg.sender] = true;
        allWhiteListedAddresses.push(msg.sender);
        numberOfWhiteListedAddresses++;
    }

    function getAllWhiteListedAddress() public onlyOwner view returns(address[] memory) {
        return allWhiteListedAddresses;
    }

    function getNumberOfWhiteListedAddresses() public view returns(uint){
        return allWhiteListedAddresses.length;
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getMsgSender() external view returns(address){
        return msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the Owner can do this");
        _;
    }
}