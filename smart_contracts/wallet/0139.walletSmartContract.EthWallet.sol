// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract EtherWallet {
    address payable public owner;
    mapping(address => uint256) _deposits;

    event Deposit(address indexed sender, uint256 amount);

    constructor() payable {
        owner = payable(msg.sender);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() public payable {
        require(msg.value > 0, "Minimum deposit amount must be more than 0!");
        _deposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external returns (bool) {
        require(msg.sender == owner, "Caller must be the owner!");
        require(
            address(this).balance >= _amount,
            "Not enough funds in contract"
        );
        payable(msg.sender).transfer(_amount);
        return true;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
