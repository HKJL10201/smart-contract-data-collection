// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "../contracts/voteContract.sol";

contract voteAppTest is VoteApp {

    address[] candidates;
    address _winning_address = msg.sender;

    VoteApp voteContractToTest;
    function beforeAll () public {
        voteContractToTest = new VoteApp();
    }


    function initCandidates() public returns (address[]) {
        for (uint i=0; i<2; i++) {
            candidates.push(_winning_address);
        }
    }

    function checkContribute() public {
        console.log("Running checkWinner");
        voteContractToTest.createVoting(candidates);
        voteContractToTest.contribute(_winning_address);
        Assert.equal(uint256(0), uint256(10000000000000000 wei), "raisedAmount should be equal to 0.01 eth");
    }
}