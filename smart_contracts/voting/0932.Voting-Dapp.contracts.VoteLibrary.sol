// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library VoteLibrary
{
    struct Vote
    {
        uint id;
        uint time;
        string PartyName;
        string adhaar;
        string constituency;
    }
    struct Party
    {
        string name;
        uint voteCount;
    }
    struct Identity
    {
        string add;
        string adhaarNumber;
        string email;
    }
}