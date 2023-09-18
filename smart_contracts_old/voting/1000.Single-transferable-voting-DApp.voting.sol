
/**
 * @file voting.sol
 * @author Oskari Kivinen
 * @date created 25th Apr 2019
 */

pragma solidity ^0.5.0;

contract voting {
    
    struct vote{
        address voter;
        uint voteNumber;
    }
    
    struct voter{
        string votersName;
        bool givenVote;
    }
    
    struct candidate{
        string candidatesName;
        uint candidateNumber;
    }
    
    // Votes counts are used to close the vote and keep track of the necessary amount of votes
    uint public votesCount;
    uint public dismissedVotes;
    uint public approvedVotes;
    
    uint public votersCount; 
    uint private droop;
    candidate public voteWinner;
    string public winnerName;

    address public chairman;
    string public chairmanName;
    string public votingSubject;
    uint public nCands;
    uint[] public actives;
    uint[] public disabledCands;
    
    mapping(uint => vote) private votes;
    mapping(uint => uint) private ranks;
    mapping(address => voter) public voters;
    mapping(uint => candidate) public candidates;
    mapping(uint => bool) public votingNumbers;
    mapping(uint => uint[]) private amountRanks;
    
    // State defines the states for the contract
    enum State { addParameters, ongoing, ending}
        State public state;
    
    // Constructor is executed at deployment
    constructor(string memory _chairmanName, string memory _votingSubject) public {
        chairman = msg.sender;
        chairmanName = _chairmanName;
        votingSubject = _votingSubject;
        state = State.addParameters;
    }
    
    // Modifiers are used to make sure functions are called only at certain situations

    modifier isInState(State _state){
        require (state == _state);
        _;
    }
    
    modifier chairmanBoss(){
        require(msg.sender == chairman);
        _;
    }
    
    modifier amountOfRanks(uint[] memory _ranks){
        require(_ranks.length <= nCands);
        _;
    }
    
    modifier closing(){
        require(msg.sender == chairman || votesCount == votersCount);
        _;
    }
    
    // Events are emitted when they occur

    event voteIsOngoing();
    event newVoter(address voter);
    event newCandidate(uint candidateNumber);
    event voteGiven(address voter);
    event voteIsEnded(string voteWinner);
    
    // Adds a candidate and assigns a voting number for them

    function addCandidate(string memory _candidatesName)
        public
        isInState(State.addParameters)
        chairmanBoss
    {
        nCands++;
        candidate memory cand;
        cand.candidatesName = _candidatesName;
        cand.candidateNumber = nCands;
        candidates[nCands] = cand;
        votingNumbers[nCands] = true;
        ranks[nCands] = 0;
        actives.push(nCands);
        emit newCandidate(nCands);
    }
    
    // Adds a voter with a right to cast one vote

    function addVoter(string memory _votersName, address _voter)
        public
        isInState(State.addParameters)
        chairmanBoss
    {
        voter memory member;
        member.votersName = _votersName;
        member.givenVote = false;
        voters[_voter] = member;
        votersCount++;
        emit newVoter(_voter);
    }
    
    // Change the state

    function beginVoting()
        public
        isInState(State.addParameters)
        chairmanBoss
    {
        state = State.ongoing;
        emit voteIsOngoing();
    }
    
    // Casts a vote. Changes the candidates ranks situation

    function giveVote(uint256[] memory _ranks) 
        public
        isInState(State.ongoing)
        amountOfRanks(_ranks)
        returns (bool)
    {
        bool success = false;
        
        if (bytes(voters[msg.sender].votersName).length != 0 
        && !voters[msg.sender].givenVote){
            voters[msg.sender].givenVote = true;
            success = true;
            // If a voter has given numbers that are not corresponding to any candidates, 
            // they have cast their vote but it is dismissed and not calculated to Droop quota
            for (uint i=0; i < _ranks.length; i++){
                if (!votingNumbers[_ranks[i]]){
                    dismissedVotes++;
                    break;
                }
            } 
            // Approved vote leads to the change of the first preference candidate
            if ((votesCount-dismissedVotes) == approvedVotes){
                approvedVotes++;
                vote memory v;
                v.voter = msg.sender;
                v.voteNumber = approvedVotes;
                votes[approvedVotes-1] = v;
                amountRanks[approvedVotes-1] = _ranks;
                ranks[_ranks[0]] = ranks[_ranks[0]] + 1;
            }
            votesCount++;
            emit voteGiven(msg.sender);
            if (votesCount == votersCount){
                closeVote();
            }
        }
        return success;
    }

    // Changes the state and calculates the winner of the election

    function closeVote()
        public
        closing
    {
        state = State.ending;
        droop = approvedVotes/2+1;
        bool clear = false;
        uint round = 1;
        while (clear==false){
            bool disabled = false;
            uint lowest = 0;
            for (uint i = 0; i < actives.length; i++){
                // If we have already a candidate with enough votes, no need to loop more
                if (ranks[actives[i]]>=droop){
                    clear=true;
                    voteWinner = candidates[actives[i]];
                    winnerName = voteWinner.candidatesName;
                    break;
                }
                // Keep track of who has the lowest amount of votes
                if (ranks[actives[i]]<ranks[actives[lowest]]){
                    lowest = i;
                }
            }
            if (clear){
                break;
            }
            // Candidate with the lowest amount of votes gets disabled for further loops
            disabledCands.push(actives[lowest]);
            for (uint j=0; j < approvedVotes; j++){
                for (uint k=0; k < round; k++){
                    // Only votes which are disabled will be distributed further
                    if (disabledCands[k] == amountRanks[j][k]){
                        disabled = true;    
                    } else { 
                        disabled = false;
                        break;
                    }
                }
                // Distribute the ranks of disabled candidates' votes
                if (disabled){
                    ranks[amountRanks[j][round]] = ranks[amountRanks[j][round]] + 1;
                }
            }
            // Reset the disabled candidates ranks and change the actives list correspondingly
            ranks[actives[lowest]]=0;
            for (uint i = lowest; i<actives.length-1; i++){
                actives[i] = actives[i+1];
            }
            delete actives[actives.length-1];
            actives.length--;
            round++;
            // To make sure there are no infinite loops, the while loop stops if there are as many rounds as there are candidates
            if (round == nCands){
                clear = true;
            }
        }
        // Voting ends and the winner will be announced
        emit voteIsEnded(voteWinner.candidatesName);
    }
}