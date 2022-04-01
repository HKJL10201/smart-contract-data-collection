pragma solidity >=0.4.21 <0.6.0;
contract Election {
    /*
    1. smoke testing
    //Constructor will run whenever we deploy our smart contract
    //a variable without an _ before it is called state variable
    //it is accessible inside a contract and represents data
    //that belongs to entire contract
    //solidity gives a getter function for this public variable without we writing it
    //_variable implies ist's a local variable

    string public candidate;

    constructor() public{
        candidate = "Candidate_1";
    }
*/
    
  //  2: list candidates:
  //  Model a candidate
  struct Candidate {
      uint id;
      string name;
      uint voteCount;
  }
   constructor() public{
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    // store a candidate
    //mapping in solidity is like a hashtable with key-value pairs. mapping(key=>value)
    //in solidity, there is no way to get the size of hash table
    //or to iterate the mapping. if there is an invalid id as key, blank is returned, thus we cannot
    //know how big is the mapping. 
    // fetch candidates
    mapping(uint=>Candidate) public candidates; // solidity gives a getter function
    // store candidates count
    uint public candidatesCount;
    //voted event
    // event votedEvent(
    //     uint indexed _candidateId
    // );
    //store accounts that have voted
    mapping(address=>bool) public voters;
    
    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public {
        //require that they haven't voted before
        require(!voters[msg.sender]);
        //require a valid candidate
        require(_candidateId>0 && _candidateId<=candidatesCount);
        //record that votes has voted
        /*
        solidity allows us to send the metadata and one of the data is about who is 
        sending that information, the account key of that person
        msg is part of the metadata
        we use msg.sender to get the details to keep track of account who is voting.
        */
        //from is msg.sender
        //any gas required in require won't be refunded if execution or transaction fails
        voters[msg.sender] = true;
        //update candidate vote count
        candidates[_candidateId].voteCount ++;
        // emit votedEvent(_candidateId);
    }
}