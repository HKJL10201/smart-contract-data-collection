pragma solidity ^0.4.17;

contract Voting {
    address public owner;
    uint public idWinner;
    bool public idChecker = false;
    uint public index = 0;
    
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    uint[] _id;
    
    mapping( uint => address) public identity;
    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;
//    mapping (uint => Candidate) public winner;
    // Store Candidates Count
    uint public candidatesCount;

    // voted event
    event votedEvent (
        uint indexed _candidateId
    );
    event voteFinished (
        uint id
    );
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    
    
    function checkValidId(uint _id) public {
        if(identity[_id] == msg.sender)
            idChecker = true;
    }

    function Voting () public {
        owner = msg.sender;
        addCandidate("Son Goku");
        addCandidate("Naruto");
        addCandidate("Doreamon");
        addCandidate("Conan");
        addCandidate("Inuyasha");
        addCandidate("KaptainGoku");
    }
    
// Chua su dung
    function addCandidate (string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        _id.push(candidatesCount);
    }
    
    function setIdentity(uint _identity) public {
        index = _identity;
        identity[_identity] = msg.sender;
    }

    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require a valid candidate
        // require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        votedEvent(_candidateId);
         uint voteCountMax = 0;
        //find winner
        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > voteCountMax) {
                voteCountMax = candidates[i].voteCount;
                idWinner = i; 
            }
        }
    }
    
    /*function killVote () onlyOwner returns (uint){
        return idWinner;
    }
    string ipfsHash;

   function setHash(string x) public {
     ipfsHash = x;
   }

   function getHash() public view returns (string x) {
     return ipfsHash;
   }*/
}