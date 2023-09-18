// SPDX-License-Identifier: GPL-3.0
// pack variables
pragma solidity >=0.5.16;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint16 id;
        uint32 voteCount;
        string name;
        string party;
    }
 
    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store and Fetch Candidates
    mapping(uint16 => Candidate) public candidates;
    // Store Candidates Count
    uint16 public candidatesCount;
 
    // voted event
    event votedEvent (
        uint16 indexed _candidateId
    );
 
    constructor () public {
        addCandidate("Ranil Wickremesinghe","United National Party");
        addCandidate("Mahinda Rajapaksha","Sri Lanka Podujana Peramuna");
        addCandidate("Anura Kumara Disanayake","National People's Power");
        addCandidate("Sajith Premadasa","Samagi Jana Balawegaya");
        addCandidate("Maithripala Sirisena","Sri Lanka Freedom Party");
        addCandidate("NOTA","None of the above");
    }
 
    function addCandidate (string memory name,string memory party) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, 0, name,party);
    }
    
    function checkVoter ()  private view returns(bool) {
        if( !voters[msg.sender] == true )
        {
            return true;
        }
        else { 
            return false;
        }
    }
 
    function checkCandidate (uint16 _candidateId)  private view returns(bool) {
        if( _candidateId > 0 && _candidateId <= candidatesCount)
        {
            return true;
        }
        else { 
            return false;
        }
    }
 
    function vote (uint16 _candidateId) public {
        // require that they haven't voted before
        bool status;
        status = checkVoter();
        if( status == true )
        {
        // record that voter has voted
        voters[msg.sender] = true;
        // update candidate vote Count
        candidates[_candidateId].voteCount ++;
        // trigger voted event
        emit votedEvent(_candidateId);
        }
        else { 
        }
        // require a valid candidate
        checkCandidate(_candidateId);
 
    }
}