// SPDX-License-Identifier: MIT

// Solidity version here
pragma solidity >=0.5.0 <0.9.0;

import "./Ownable.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Creating contract named lottery

contract Lottery is Ownable, VRFConsumerBase {
    // Manager of application - needs its address
    address public manager;

    // Participants of appication - needs its address
    // should be payable as we need to transfer ether to that address
    address payable[] public participants; 

    // Create an event variable
    event GotWinner(
        address winnerAddress,
        uint winAmount
    );

    // We need to define two variables required for VRFConsumerBase
    // keyHash and fee
    // keyHash - The Chainlink node keyhash. This is used identify which Chainlink node we want to work with.
    // fee - The Chainlink node fee. This represents the fee (gas) the Chainlink will charge us, expressed in LINK tokens.
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public randomValue; // Value returned from chainlink

    // We need the LINK and VRF Coordinator address
    // These values can be found from - 
    // https://docs.chain.link/docs/vrf-contracts/
    // We have used values for the Rinkeby Test network
    constructor() VRFConsumerBase(
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK
    ) {
        // Manager is who deploys the contract
        manager = msg.sender;

        // These are standard values for Rinkeby Test network - fetched from Chainlink
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 100000000000000000; // 0.1 LINK
    }

    // App to support receive ether feature with no data
    receive() external payable {
        // Lottery price is 0.1 ether
        require(msg.value==0.1 ether);

        // Put that participant address inside the participant array
        // As msg.sender is not of type address payable, we need to explicitly cast it to payable
        address payable participantAddress = payable(msg.sender);
        participants.push(participantAddress);
    }

    // Get participants
    function getParticipants() external view returns(address payable[] memory) {
        return participants;
    }

    // Get balance inside the contract account
    // Only owner can call this function
    // It doesn't change state of blockchain hence view
    function getBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    // Call this to get a random winner - request random number from oracle
    function getWinner() public onlyOwner returns (bytes32 requestId) {
        // We require minimum 3 participants to decide a winner 
        require(participants.length>=3);

        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomValue = randomness;
        
        // Index value 
        uint index = randomValue % participants.length;

        address payable winner = participants[index];

        // Transfer total lottery price to winner
        // Keep 0.1 ether to the contract itself for internal oracle contract calls
        uint amount = (participants.length - 1) * 0.1 ether;
        winner.transfer(amount);

        // Winner decided, emit the event
        emit GotWinner(winner, amount);

        // Lottery round over - Reset the participants array now
        participants = new address payable[](0);
    }
}


