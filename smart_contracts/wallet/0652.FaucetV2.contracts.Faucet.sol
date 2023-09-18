// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "./Logger.sol";
import "./IFaucet.sol";

contract Faucet is Owned, Logger, IFaucet {

    uint public numOfFunders;

    mapping(address => bool) private funders;
    mapping(uint => address) private lutFunders;

    modifier limitWithdraw(uint withdrawAmount) {
        require(
            withdrawAmount <= 1000000000000000000,
            "Cannot withdraw more than 1 ether"
        );
        _; // function body is executed next
    }

    function emitLog() public pure override returns(bytes32) {
        return "Hello, World!"; 
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function addFunds() external override payable {
        address funder = msg.sender;
        test3();

        if (!funders[funder]) {
            uint index = numOfFunders++;
            funders[funder] = true;
            lutFunders[index] = funder;
        }
    }

    function admin1() external onlyOwner {
        // some managing stuff that only admin should have access to
    }

    function admin2() external onlyOwner {
        // some managing stuff that only admin should have access to
    }

    function withdraw(uint amount) override external limitWithdraw(amount) {
        payable(msg.sender).transfer(amount);
    }

    function getAllFunders() external view returns (address[] memory) {
        address[] memory _funders = new address[](numOfFunders);
        for (uint8 n = 0; n < numOfFunders; n++) {
            _funders[n] = lutFunders[n];
        }
        return _funders;
    }

    function getFunderAtIndex(uint8 index) external view returns (address) {
        return lutFunders[index];
    }

    // const instance = await Faucet.deployed()
    
    // instance.addFunds({value: "2000000000000000000", from: accounts[0]})
    // instance.addFunds({value: "2000000000000000000", from: accounts[1]})

    // instance.getAllFunders()
    // instance.getFunderAtIndex(0)

    // instance.withdraw("500000000000000000", {from: accounts[1]})
}