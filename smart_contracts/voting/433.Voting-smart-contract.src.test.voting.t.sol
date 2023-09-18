// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../voting.sol";



contract TestVoting is Test{
    Voting voting;
    function setUp() public{
        voting = new Voting();

    }

    function testcreatePoll(string memory name) public {
        

        // voting.createPoll(name, 200000000000000000, 5);
        
        // require(votingPoll[name].maxNoOfCandidates == 5);

        
    }

    

}