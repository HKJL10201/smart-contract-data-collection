// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.16;

contract Voting{
    // attributes to contestant
    struct Contestant{
        uint8 id;
        string name;
        uint32 voteCount;
    }
    // using mapping to fetch contestant details 
    mapping(uint8 => Contestant) public contestants;
    //users who already casted vote
    mapping(address=> bool) public voters;
    uint8 public contestantsCount;
    constructor() public{
        addContestant("Iron Man");
        addContestant("Captain America");
    }
    function addContestant(string memory _name) private{
        contestantsCount++;
        contestants[contestantsCount] = Contestant(contestantsCount, _name, 0);
    }

    function vote(uint8 _contestantId) public payable{ 
        require(!voters[msg.sender]);
        require(_contestantId>0 && _contestantId<=contestantsCount);
        contestants[_contestantId].voteCount++;  
        voters[msg.sender] = true;
        emit votedEvent(_contestantId);
    }
     event votedEvent (
        uint8 indexed _contestantId
    );
}