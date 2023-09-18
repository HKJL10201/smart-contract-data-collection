pragma solidity ^0.6.6;

contract VotingPortal
{
    struct Candi
    {
        uint cid;
        string candiname;
        uint vc;
    }

    mapping (uint => Candi) public candis;
    uint public candicount;
    mapping (address => bool) public persontovote;

    constructor() public 
    {
        addingCandi("Kartikeya");
        addingCandi("Rahul");
        addingCandi("Digvijay");
        addingCandi("Shlok");
    }

    function addingCandi(string memory _fname) private 
    {
        candicount++;
        candis[candicount] = Candi(candicount, _fname, 0);
    }

    function votingCandi(uint _candid) public 
    {
        require(!persontovote[msg.sender]);
        require(_candid > 0 && _candid <= candicount);
        persontovote[msg.sender] = true;
        candis[_candid].vc++;
    }
}