// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Voting {

    struct Vote {
        string user;
        string side;
    }

    Vote[] store; // Array to store all votes

    event VoteCreated (
        string user,
        string side
    );

    event TotalVotes (
        uint total
    );

    function castVote(string memory  _user, string memory _side ) public {
        store.push( Vote(_user,_side) );
        emit VoteCreated(_user, _side);
    }

    function totalVotes( ) public {
        emit TotalVotes( store.length );
    }
}