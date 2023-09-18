// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

// CHS
contract Voting{
    // uint256 candidateCount
    uint256 candidateCount;
    // uint256 voterCount
    uint256 voterCount;

    // mapping (uint256 => Candidate) candidateDetails;
    mapping (uint256 => Candidate)  public candidateDetails;
    mapping (address => uint256)    public candidate;
    mapping (address => bool)       public votetest;

    State public state;
    Candidate public winner;
    // candidateDetails mapping을 배열로 넣어서 리스트화
    uint256[] internal candidateList;

    // constructor()
    constructor()
    public
    {
        candidateCount = 0;
        voterCount = 0;
        votetest[msg.sender] = false;

        state = State.Created;
    }

    // VARIABLES
    // struct Voter { address voterAddress; bool hasVoted; }
    struct Voter {
        address voterAddress;
        bool hasVoted;
    }

    // struct Candidate { uint256 candidateId; string name; uint256 voteCount; }
    struct Candidate {
        uint256 candidateId;
        string name;
        string slogan;
        uint256 voteCount;
        address candidateAddress;
        // bool isWinner; // winner = true; looser = false;
    }
    
    // enum State { Created, Voting, Ended }
    enum State { 
        Created,
        Voting,
        Ended
    }
    
    // mapping (address=>bool) hasVoted;
    /* mapping (address => bool) public hasVoted; */

    /* MODIFIERS */
    // modifier onlyCandidater()
    modifier onlyCandidater(){
        require(candidate[msg.sender] < 1);
        _;
    }
    modifier onlyMe(address _candidate){
        require(msg.sender == _candidate);
        _;
    }

    // modifier inState()
    modifier inState(State _state){
        require(state == _state);
        _;
    }

    /* FUNCTIONS */
    // addCandidate()
    function addCandidate(string memory _name, string memory _slogan) 
        public 
        onlyCandidater
        inState(State.Created)
    {
        require(candidateCount < 5);
        Candidate memory newCandidate =
            Candidate({
                candidateId: candidateCount,
                name: _name,
                slogan: _slogan,
                voteCount: 0,
                candidateAddress: msg.sender
            });
        candidateDetails[candidateCount] = newCandidate;
        candidateList.push(candidateCount);
        candidateCount++;
        candidate[msg.sender]++;

        if(candidateCount >= 5){
            startVote();
        }
    }

    function deleteCandidate(uint256 _candidateId) 
        public 
        onlyMe(candidateDetails[_candidateId].candidateAddress)
        inState(State.Created)
    {
        if(candidateDetails[_candidateId].candidateId+1== candidateCount){
            delete candidateDetails[_candidateId];
        } else {
            Candidate memory c = Candidate({
                candidateId: candidateDetails[sizeOfCandidate()-1].candidateId,
                name: candidateDetails[sizeOfCandidate()-1].name,
                slogan: candidateDetails[sizeOfCandidate()-1].slogan,
                voteCount: candidateDetails[sizeOfCandidate()-1].voteCount,
                candidateAddress: candidateDetails[sizeOfCandidate()-1].candidateAddress
            });
            candidateDetails[_candidateId] = c;
            delete candidateDetails[sizeOfCandidate()-1];
        }
        // delete candidateList[_candidateId];
        candidateList.pop();
        candidate[msg.sender]--;
        candidateCount--;
    }

    function startVote()
        private
        inState(State.Created)
    {
        state = State.Voting;
    }

    // getCandidateNumber()
    function getCandidateNumber() public view returns (uint256) {
        return candidateCount;
    }


    // Vote()
    function vote(uint256 candidateId) 
        public 
        inState(State.Voting)
    {
        require(votetest[msg.sender] == false);
        // require(start == true);
        // require(end == false);
        candidateDetails[candidateId].voteCount += 1;
        votetest[msg.sender] = true;
        (uint winnerCandi, bool checkEnd) =  winningVote();
        if(checkEnd){
            winner = endVote(winnerCandi);
        }
    }

    // endVote()
    function sizeOfCandidate() 
        public 
        view 
        returns (uint256)
    {
        return uint256(candidateList.length);
    }

    function winningVote()
        public
        view
        returns(uint _winningVote, bool)
    {
        uint winningVoteCount=5;
        for(uint p = 0; p < sizeOfCandidate(); p++){
            if(candidateDetails[p].voteCount >= winningVoteCount){
                winningVoteCount = candidateDetails[p].voteCount;
                _winningVote = p;
                return (_winningVote, true);
            }
        }
        return (_winningVote, false);
    }

    function endVote(uint _winnerCandi)
        private
        inState(State.Voting)
        returns (Candidate memory _winner)
    {
        state = State.Ended;
        _winner = candidateDetails[_winnerCandi];
        return _winner;
    }
}