// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract InteractionPortal {
    uint256 totalWaves;
    uint256 totalFistbumps;
    uint256 totalHighfives;
    uint256 totalHandshakes;
    uint256 totalBows;
    uint256 total;
    uint256 seednum = 50;

    uint256 private seed;

    uint256 ether_balance = msg.sender.balance;

    int256 eth_min_requirement_Wave = 500000000000000000; // 0.5 eth
    int256 eth_min_requirement_Fistbump = 1000000000000000000; // 1 eth
    int256 eth_min_requirement_Highfive = 2000000000000000000; // 2 eth
    int256 eth_min_requirement_Handshake = 5000000000000000000; // 5 eth
    int256 eth_min_requirement_Bow = 10000000000000000000; // 10 eth

    uint waveReq = uint(eth_min_requirement_Wave);
    uint fistbumpReq = uint(eth_min_requirement_Fistbump);
    uint highfiveReq = uint(eth_min_requirement_Highfive);
    uint handshakeReq = uint(eth_min_requirement_Handshake);
    uint bowReq = uint(eth_min_requirement_Bow);
    


    

    /*
     * A little magic, Google what events are in Solidity!
     */
    event NewInteraction(address indexed from, uint256 timestamp, string message, string typeofinteraction);
    
    /*
     * I created a struct here named interacter.
     * A struct is basically a custom datatype where we can customize what we want to hold inside it.
     */
    struct Interaction {
        address interacter; // The address of the user who interacted.
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user interacted.
        string typeofinteraction;// add the interaction that the person had
    }

    /*
     * I declare a variable waves that lets me store an array of structs.
     * This is what lets me hold all the interactions anyone ever sends to me!
     */
    Interaction[] interactions;

    /*
     * This is an address => uint mapping, meaning I can associate an address with a number!
     * In this case, I'll be storing the address with the last time the user waved at us.
     */
    mapping(address => uint256) public lastInteractedWith;

    constructor() payable {
        console.log("Hey, it's just your average smart contract here and depending on your wallets eth, we will interact differently...");
        
        /*
         * Set the initial seed
         */
        seed = (block.timestamp + block.difficulty) % 100;
        
    }
     function dosomething(string memory _message) public {
        ether_balance = msg.sender.balance;
         /*
         * We need to make sure the current timestamp is at least 15-minutes bigger than the last timestamp we stored
         */
        require(
            lastInteractedWith[msg.sender] + 20 minutes < block.timestamp,
            "Wait 20 minutes"
        );

        /*
         * Update the current timestamp we have for the user
         */
        lastInteractedWith[msg.sender] = block.timestamp;

         // 0 means do nothing, 1 means wave, 2 means fist bump, 3 means high five, 4 means handshake, 5 means bow
        string memory theInteraction = "None";
        //right now it looks like eth balance is extremely high for made up addresses
        if(ether_balance > bowReq){
            totalBows += 1;
            theInteraction = "Bow";
            console.log("%s has bowed w/ message: %s", msg.sender, _message); // you can change msg.sender to make it so only certain wallets can send you waves
        } else if (ether_balance > handshakeReq) {
            totalHandshakes += 1;
            theInteraction = "Handshake";
            console.log("%s has given you a hand shake w/ message: %s", msg.sender, _message);
        } else if (ether_balance > highfiveReq){
            totalHighfives += 1;
            theInteraction = "High Five";
            console.log("%s has given you a high five w/ message: %s", msg.sender, _message);
        } else if(ether_balance > fistbumpReq){
            totalFistbumps += 1;
            theInteraction = "Fist Bump";
            console.log("%s has given you a fist bump w/ message: %s", msg.sender, _message);
        } else if (ether_balance > waveReq){
            totalWaves += 1;
            theInteraction = "Wave";
            console.log("%s has waved at you w/ message: %s", msg.sender, _message);
        } else {
            total += 1; 
            console.log("%s has no interaction w/ message: %s", msg.sender, _message);
        }
        /*
         * This is where I actually store the interaction data in the array.
         */
        interactions.push(Interaction(msg.sender, _message, block.timestamp, theInteraction));

        /*
         * Generate a new seed for the next user that sends an interaction
         */
        seed = (block.difficulty + block.timestamp + seed) % 100;
        

        console.log("Random # generated: %d", seed);
        seednum = seed;
        /*
         * Give a 25% chance that the user wins the prize.
         */
        if (seed <= 25) {
            console.log("%s won!", msg.sender);

        

        uint256 prizeAmount = 0.0001 ether;
        require(
            prizeAmount <= address(this).balance,
            "Trying to withdraw more money than the contract has."
        );
        (bool success, ) = (msg.sender).call{value: prizeAmount}("");
        require(success, "Failed to withdraw money from contract.");
        }

        /*
         * I added some fanciness here, Google it and try to figure out what it is!
         * Let me know what you learn in #general-chill-chat
         */
        emit NewInteraction(msg.sender, block.timestamp, _message, theInteraction);
     }

    /*
     * I added a function getAllInteractions which will return the struct array, waves, to us.
     * This will make it easy to retrieve the waves from our website!
     */
    function getAllInteractions() public view returns (Interaction[] memory) {
        return interactions;
    }
    function getSeed() public view returns (uint256){
        return seednum;
    }

    function getEtherBalance() public view returns (uint256){
        return ether_balance;
    }

   /* function getInteraction() public view returns (uint256){
        return myInteraction;
    }*/
    

    function getTotalWaves() public view returns (uint256) {
        if (totalWaves > 0){
            console.log("We have %d total waves!", totalWaves);    
        }
        return totalWaves;
    }
    function getTotalFistbumps() public view returns (uint256) {
        if (totalFistbumps > 0){
            console.log("We have %d total fist bumps!", totalFistbumps);   
        }
        return totalFistbumps;
    }
    function getTotal() public view returns (uint256) {
        if (total > 0){
            console.log("We have %d total people who need eth!", total);
            
        }
        return total;
    }
    function getTotalHighfives() public view returns (uint256) {
        if (totalHighfives > 0){
            console.log("We have %d total high fives!", totalHighfives);
            
        }
        return totalHighfives;
    }
    function getTotalHandshakes() public view returns (uint256) {
        if (totalHandshakes > 0){
            console.log("We have %d total hand shakes!", totalHandshakes);
            
        }
        return totalHandshakes;
    }
    function getTotalBows() public view returns (uint256) {
        if (totalBows > 0){
            console.log("We have %d total Bows!", totalBows);
            
        }
        return totalBows;
    }
}