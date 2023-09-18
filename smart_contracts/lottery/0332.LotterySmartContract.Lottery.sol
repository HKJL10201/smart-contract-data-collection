//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    address payable public Owner;
    address payable[] public players;

    bytes32 internal keyHash; // identifies which Chainlink oracle to use
    uint internal fee;        // fee to get random number
    uint public randomResult;

//make sure your metamask connected with Goerli test network before deploy the contract;
//and after deployment sent Link balance to the contract address for generating the random number;
    constructor() 
     VRFConsumerBase(
            0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D, // VRF coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK token address
        ){
        keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
        fee = 0.1 * 10 ** 18;    // 0.1 LINK
        Owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == Owner,"only the Owner can call this function");
        _;
    }

//this is for generate the varified random number
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
        payWinner();
    }

//this function is for participate in the lottery
    function Enter() payable public {
        require(msg.value == 1 ether,"need one ether to participate in this lottery");
        players.push(payable(msg.sender));
    }

//this function is for pick a player who is the winner
    function pickWinner() payable public onlyOwner {
        getRandomNumber();
    }

//this function is for transfer the money to the winner and the fees to the owner
    function payWinner() payable public onlyOwner {
        uint index = randomResult % players.length;
        players[index].transfer(address(this).balance - 0.1 ether * players.length);
        Owner.transfer(address(this).balance);
//reset the state of the contract
        players = new address payable[](0);
    }

//if you want to use this function to generate random number you can go with that
    // function getRandomNumber() public view returns(uint) {
    //     return uint(keccak256(abi.encodePacked(Owner,block.timestamp)));
    // }
}