// SPDX-License-Identifier: MIT
pragma solidity ^0.8.00;


// Code for the Tron contract goes here
contract Tron {
    // Declare variables
    address[] public owners;
    uint public required;
    address public owner;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor function
    constructor (address[] memory _owners, uint _required) public payable {
    owners = _owners;
    required = _required;
    owner = msg.sender;
    totalSupply = 1000000000 * 1e6;
    balanceOf[owner] = totalSupply;
}

    // Transfer function
    function transfer(address _to, uint256 _value) public payable{
        require(required == 1, "One signature is required to execute the transfer.");
        require(balanceOf[msg.sender] >= _value && _value > 0, "Insufficient balance or invalid value.");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    // Approve function
    function approve(address _spender, uint256 _value) public payable returns (bool success) {
        require(required == 1, "One signature is required to execute the approval.");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Payable fallback function
fallback() external payable {
    // The contract is now payable, so you can send value along with the contract deployment transaction or with any other transaction that calls this contract.
}

}