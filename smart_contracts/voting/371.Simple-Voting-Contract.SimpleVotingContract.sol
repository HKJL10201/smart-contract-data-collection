// SPDX-License-Identifier: UNLICENSED  (it is common practice to include an open source license or declare it unlicensed)
pragma solidity ^0.8.7;  // tells the compiler which version to use

contract SimpleVotingContract {

    // store the addresses of voters on the blockchain in these 2 arrays
    address[] votedYes;
    address[] votedNo;

    function voteYes() public {
        votedYes.push(msg.sender);
    }

    function voteNo() public {
        votedNo.push(msg.sender);
    }

    function getYesVotes() public view returns (uint) {
        return votedYes.length;
    }

    function getNoVotes() public view returns (uint) {
        return votedNo.length;
    }
}
