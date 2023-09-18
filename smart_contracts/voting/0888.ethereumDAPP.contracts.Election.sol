pragma solidity >=0.5.0;

contract Election {
    // Model a Candidate
    struct Candidate {  //Any variable without the prefix _ is called a state variable which means it is accessible in the smart contract deployed to blockchain
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts (ganache accounts) that have voted
    mapping(address => bool) public voters;   // key is of type address because it represents the address of the account that is going to vote
    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;   //since we declare candidates public we will have a getter funciton for free
    // Store Candidates Count                        //When we add a candidate to the mapping we are chainging the state of the contract => 
    //                                                // we are writing to the blockchain (interacting with the data layer of the blockchain)
    uint public candidatesCount;                    //we need to use this state variable  to count the number of candidate because in solidity
//                                                  //we cannot know the length of the mapping candidates because for uint that does not exist
//                                                  //we will have an empty candidate
    // voted event so that the browser can subscribe to this event and reload the page
    event votedEvent (
        uint indexed _candidateId  
    );

    constructor() public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
        addCandidate("Candidate 3");
    }
    // the funtion must be private so that only the smart contract can execute this function Nodes on the blockchain network must not execute the function
    function addCandidate (string memory _name) private {    // name is a local variabe => we use the prefix _
    //This function creates a candidate with the contructor of the struct and adds it to the mapping
        candidatesCount ++;                                 
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote (uint _candidateId) public { // public => can be executed by the acocunts on the blockchain network
        // require that they haven't voted before
        require(!voters[msg.sender]);   // msg.sender variable contains the account who called the vote function
    // require something that is true to continue executing


        // require a valid candidate to vote to 
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;   // we are storing every voter that voted in the voters mapping

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}
