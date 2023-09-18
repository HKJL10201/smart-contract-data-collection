//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LotteryMachine.sol";

contract Casino {
    address private owner;
    uint commission = 1;
    LotteryMachine[] machines;

    constructor() {
        owner = msg.sender;
        createMachine();
    }
    
    receive() external payable {}
    
    fallback() external payable {}
    
    function createMachine() public payable returns(LotteryMachine) {
        LotteryMachine machine = new LotteryMachine(msg.sender);
        machines.push(machine);
        return machine;
    }

    function getMachines() public view returns(LotteryMachine[] memory) {
        return machines;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getCommision() public view returns(uint) {
        return commission;
    }

    function withdrow() public {
        payable(owner).transfer(getBalance());
    }

}