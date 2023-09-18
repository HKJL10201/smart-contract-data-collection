// SPDX-License-Identifier: MIT

pragma solidity > 0.5.0;

contract voteKaro{
    //address private owner
    bool public person = false;
    uint public counter = 0;

    modifier canVote(bool person) {
        require(person == false);
        _;
    }
    function Vote() public canVote(person) {
        counter++;
    }

}