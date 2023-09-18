// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16;

contract Blockchain{
    
    struct Candidate{
        uint8 id;
        string name;
        uint32 voteCount;
    }
    
    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
    // Store Candidates Count
    uint8 public candidatesCount; //is it to calculate
    
     // voted event
    event votedEvent (
        uint32 indexed _candidateId
    );

    constructor () public {  //bu public versiyon hatasından dolayı oldu 
        candidatesCount=0;
        addCandidate("ETH");
        addCandidate("BTC");
        
    }
    
    function addCandidate (string memory _name) public {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint8 _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
    
}