pragma solidity 0.5.1;
contract Voting {
    
    
    // Canidates have id and count (number votes)
    struct Candidate {
        uint8 id;
        uint8 count;
    }
    
    
    //***********************************************
    //****************** variables ******************
    //***********************************************
    
    
    // List of candidates
    Candidate[] candidates;
    
    // State of voting
    bool closed = false;
    
    // Address of contract admin
    address admin;
    
    // Id of the winner contract
    uint8 winner;
    
    // Mapping to save address that have voted
    mapping (address => bool) voted;
    
    
    //***********************************************
    //****************** events *********************
    //***********************************************
    
    /**
     * You can ignore the events for this Exercise 
     * They are used in the DApp (Question 5)
     * For more information refer to: https://solidity.readthedocs.io/en/v0.5.1/contracts.html#events
     */
    event Vote(address indexed _voter,uint8 indexed _candidateId ,uint8 _newVotesCount);
    
    event Closed(uint8 _winner);
    
    
    //***********************************************
    //****************** modifiers ******************
    //***********************************************
    
    /**
     * @dev Reverts if msg.sender is not admin
     */
    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }
    
    
    /**
     * @dev Reverts if voting is closed
     */
    modifier onlyIfOpen() {
        require(!closed);
        _;
    }
    
    
    /**
     * @dev Reverts if voting if voting is not closed
     */
    modifier onlyIfClosed() {
        require(closed);
        _;
    }

    //*************************************************
    //****************** Constructor ******************
    //*************************************************


    /**
     * @dev Constructor, sets admin and candidates
     * @param candidateIds List of canidates ids
     */
    constructor(uint8[] memory candidateIds) public {
        for (uint8 i = 0; i < candidateIds.length; i++) {
            candidates.push(Candidate({
                id: candidateIds[i],
                count: 0
            }));
        }
        admin = msg.sender;
    }
    
    
    /**
     * @dev Vote for a candidate
     * @param candidateId Id of the candidate to vote for
     */
    function vote(uint8 candidateId) public onlyIfOpen() {
        require(!voted[msg.sender]);
        
        for (uint8 i = 0; i < candidates.length; i++) {
            if (candidates[i].id == candidateId) {
                candidates[i].count++;
                emit Vote( msg.sender, candidateId,candidates[i].count);
                break;
            }
        }
        
        voted[msg.sender] = true;
    }
    
    /**
     * @dev close voting and set the candidate
     * with most votes as winner
     */
    function closeVoting() public onlyOwner() onlyIfOpen(){
        
        closed = true;
        uint max = 0;
        for (uint8 i = 0; i < candidates.length; i++) {
            if (candidates[i].count > max) {
                max = candidates[i].count;
                winner = candidates[i].id;
            }
        }
        
        emit Closed(winner);
    }
    
    /**
     * @return List of candidates ids
     */
    function getCandidates() public view returns(uint8[] memory) {
        uint8[] memory canidateIds = new uint8[](candidates.length);
        for (uint8 i = 0; i < candidates.length; i++)
            canidateIds[i] = candidates[i].id;
        return canidateIds;
    }
    
    /**
     * @param candidateId id of the candidate
     * @return number of votes candidate received
     */
    function getVotesNum(uint8 candidateId) public view returns(uint8) {
        for (uint8 i = 0; i < candidates.length; i++) {
            if (candidates[i].id == candidateId) {
                return candidates[i].count;
            }
        }
        require(false);
    }
    
    /**
     * @return the winner candidate if voting is closed
     */
    function getWinner() public onlyIfClosed() view returns(uint8) {
        return winner;
    }
}