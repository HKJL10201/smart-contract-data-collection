// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract VendingMachine {
    address private owner;
    mapping(address => uint8) public donutsBalance;

    constructor() {
        owner = msg.sender;
        donutsBalance[address(this)] = 100;
    }

    function getRemainingDonuts() external view returns (uint8) {
        return donutsBalance[address(this)];
    }

    function reStock(uint8 amount) external {
        require(msg.sender == owner, "you don't have permission");
        donutsBalance[address(this)] += amount;
    }

    function purchase(uint8 amount) external payable {
        require(msg.value >= amount * 0.0000002 ether, "not enough ether sent");
        require(donutsBalance[address(this)] >= amount, "not enough balance");
        donutsBalance[address(this)] -= amount;
        donutsBalance[msg.sender] += amount;
    }
}
