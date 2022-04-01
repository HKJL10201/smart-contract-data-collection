pragma solidity >=0.4.21 <0.7.0;

library VoteLibrary
{
    struct Vote
    {
        uint id;
        uint time;
        string date;
        string PartyName;
        string code;
    }
    struct Party
    {
        string name;
        uint voteCount;
    }
    struct Identity
    {
        string votername;
        string matriculeCardNumber;
        string email;
    }
}
