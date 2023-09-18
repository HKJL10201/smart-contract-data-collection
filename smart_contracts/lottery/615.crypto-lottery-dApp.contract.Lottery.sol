// 0x34f1aBAA77df86DD53C5F9Ab3d0EC2A81D4775e6 contract address on sepolia testnet

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery{
    
    address public manager;                // Mananger Privelages - To reset minimum Value of lottery
    address payable[3] public participants;
    uint public playersAdded = 0;
    uint public minValue = 0.1 ether;

    event DeclareWinner(address winnerAddress,uint winnerIndex, uint winningAmount);

    constructor(){
        manager = msg.sender; // The deploying address will be set as a manager
    }

    modifier onlyManager(){
        require(msg.sender == manager);
        _;
    }

    // To receive participants ether
    receive() external payable {
        require(msg.value == minValue);
        participants[playersAdded] = payable(msg.sender);
        playersAdded++;

        if(playersAdded == 3){
            selectWinner();
            // To start another round of lottery
            playersAdded = 0;

        }
    }

    // To reset min value to participate
    function resetMinValue(uint _minValue) external onlyManager {
        minValue = _minValue;
    }

    // To get Contract balance
    function getBalance() public view onlyManager returns(uint) {
        return address(this).balance;
    }

    // To generate random number
    function generateRandomIndex() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, playersAdded))) % 3;
    }

    // Sending ether to winner's address
    function selectWinner() internal {
        uint randomIndex = generateRandomIndex();
        address payable winner = participants[randomIndex];
        emit DeclareWinner(winner, randomIndex, minValue*participants.length);
        winner.transfer(address(this).balance);
    }

}
