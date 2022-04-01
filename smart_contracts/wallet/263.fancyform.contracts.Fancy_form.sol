// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fancy_form {
    constructor() payable {}

    function send(address payable _to, uint256 _value) public payable {

        require(
            _value <= address(this).balance,
            "Trying to withdraw more money than the contract has."
        );
        require(_value <= 0.01 ether, "0.01 ether is the maximum limit to send.");
        (bool success, ) = _to.call{value: _value}("");
        require(success, "Failed to send Ether");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
