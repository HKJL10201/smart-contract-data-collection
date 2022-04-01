pragma solidity >=0.4.25 <0.7.0;

contract Election {
    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;

    // Store Candidates
    // Fetch Candidate
    mapping(uint => Candidate) public candidates;

    // Store Candidates Count
    uint public candidatesCount;

    // Voted event
    event votedEvent (
        uint indexed _candidateId
    );

    // Voters map
    mapping(address => bool) public votersRegister;

    // Admins map
    mapping(address => bool) private adminsRegister;

    constructor () public {
        addCandidate("Donald Trump"); // 1
        addCandidate("Joe Biden"); // 2

        adminsRegister[address(0x96D83Dfd656729E7bcaF0D85152e503057E0FAFB)] = true;
        
        votersRegister[address(0x4513d84388ec07C12124FEBD4C634f46CD872844)] = true;
        votersRegister[address(0xE3A169e94e4AC9706e2e4Ff75142241eD5D69378)] = true;
        votersRegister[address(0xfcAa1107664f05faEB9CFeb35893Bc75b035983A)] = true;
    }

    function addCandidate (string memory _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function registerVoters (address _address) public {
        require(adminsRegister[msg.sender]);
        votersRegister[_address] = true;
    }

    function vote (uint _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender]);

        // require that voter is registered
        require(votersRegister[address(msg.sender)]);

        // require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount ++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }

    function isAllowedToVote(address id) public returns(bool) {
        if(!votersRegister[msg.sender]) { 
            return false;
        } else {
            return true; 
        }
    }
}
