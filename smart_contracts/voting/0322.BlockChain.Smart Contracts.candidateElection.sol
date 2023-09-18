pragma solidity >= 0.7.0 < 0.9.0;

contract Ballot {
    struct vote {
        address voterAddress;
        uint256 choice;
    }

    struct voter {
        string voterName;
        bool voted;
    }

    struct Proposal {
        bytes32 name; // Name of each Proposal
        uint256 voteCount; // Number of accumulated votes
    }

    Proposal[] public proposals;
    uint256 public proposalSize = 0;
    // uint256 private countResult = 0;
    bytes32 public finalResult;
    uint256 public totalVoter = 0;
    uint256 public totalVote = 0;
    address public ballotOfficialAddress;
    string public ballotOfficialName;
    // string public proposal;

    mapping(uint256 => vote) private votes;
    mapping(address => voter) public voterRegister;

    enum State {
        Created,
        Voting,
        Ended
    }
    // declaring a variable of type enum
    State public state;

    //creates a new ballot contract
    constructor(string memory _ballotOfficialName, bytes32[] memory _proposalNames)
        public
    {
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;
        // proposal = _proposal;
        state = State.Created;
        for(uint i = 0 ; i < _proposalNames.length ; i++){
            proposals.push(Proposal({
                name : _proposalNames[i],
                voteCount : 0
            }));
        }
        proposalSize = _proposalNames.length;

        
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyOfficial() {
        require(msg.sender == ballotOfficialAddress);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    event voterAdded(address voter);
    event voteStarted();
    event voteEnded(bytes32 finalResult);
    event voteDone(address voter);

    //add voter
    function addVoter(address _voterAddress, string memory _voterName)
        public
        inState(State.Created)
        onlyOfficial
    {
        voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        voterRegister[_voterAddress] = v;
        totalVoter++;
        emit voterAdded(_voterAddress);
    }

    //declare voting starts now
    function startVote() public inState(State.Created) onlyOfficial {
        state = State.Voting;
        emit voteStarted();
    }

    //voters vote by indicating their choice (true/false)
    function doVote(uint _choice)
        public
        inState(State.Voting)
        returns (bool voted)
    {
        bool found = false;
        if(_choice < 1 ||  _choice > proposals.length){
            return found;
        }

        if (
            bytes(voterRegister[msg.sender].voterName).length != 0 &&
            !voterRegister[msg.sender].voted
        ) {
            voterRegister[msg.sender].voted = true;
            vote memory v;
            v.voterAddress = msg.sender;
            v.choice = _choice;
            // if (_choice) {
            //     countResult++; //counting on the go
            // }
            proposals[_choice-1].voteCount++;
            votes[totalVote] = v;
            totalVote++;
            found = true;
        }
        emit voteDone(msg.sender);
        return found;
    }

    //end votes
    function endVote() public inState(State.Voting) onlyOfficial {
        state = State.Ended;
        finalResult = winningName();
        // finalResult = countResult; //move result from private countResult to public finalResult
        emit voteEnded(finalResult);
    }

    function winningProposal() public view returns (uint256 winningProposal_){
        uint256 winningVoteCount = 0;
        for(uint i = 0 ; i < proposals.length ; i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i + 1;
            }
        }

        uint cnt = 0;
        for(uint i = 0 ; i < proposals.length ; i++){
                uint temp = proposals[i].voteCount;
                if(temp == winningVoteCount) cnt++;
        }

        if(cnt > 1) { winningProposal_ = 0; }
    }

    function winningName() public view returns (bytes32 winningName_){
        if(winningProposal() == 0)
        {
            winningName_= 0x4e6f2057696e6e65720000000000000000000000000000000000000000000000;
        }else winningName_ = proposals[winningProposal() - 1].name;
    }

}
