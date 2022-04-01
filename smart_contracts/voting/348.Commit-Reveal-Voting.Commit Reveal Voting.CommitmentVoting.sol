pragma solidity ^0.4.20;

contract CommitmentVoting{

    Candidate[] candidates;
    mapping(address => Voter) voters;
    uint maxVotes = 0; //the maximum number of votes for an canadidate
    address pollOwner;
    bool active;
    //uint commitPhaseLength;
    //uint commitPhaseEndTime;

    struct Candidate{
        bytes32 name;
        uint numberOfVotes;
    }

    struct Voter{
        bool commited;
        bool revealed;
        bytes32 voteHash;
        bytes32 voteRev;
    }

    /*Takes the array of candidates and creates a Candidate object for each canadidate in the array
        sets id, name and numberOfVotes for each candidate
        pushes the object to the array of canadidate objects
        sets the owner of the poll and start & end times of the polling*/
    function CommitmentVoting(bytes32[] myCandidates) public {
        pollOwner = msg.sender;
        active = true;
        //commitPhaseLength = pollingLength;
        //commitPhaseEndTime = now + commitPhaseLength*1 seconds;
        
        for(uint i = 0; i < myCandidates.length; i++){
            candidates.push(Candidate({
                name : myCandidates[i],
                numberOfVotes : 0
            }));
        }
    }
    
    /* checks if the sender is the owner of the poll/contract or not */
    modifier isOwner(){
        require(msg.sender == pollOwner);
        _;
    }

    /* Checks if the sender of the vote has voted before*/
    modifier canVote(){
        require(voters[msg.sender].commited == false);
        _;
    }
    
    /* checks if the poll is still active meaning voters can still vote */
    modifier isActive(){
        require(active == true);
        _;
    }
    
    /* checks if the poll has been ended */
    modifier hasEnded(){
        require(active == false);
        _;
    }
    
    /* checks if the inputted hash matches with the inputted name
        the name inputted is converted into a string before hashing*/
    modifier hashMatch(bytes32 hash, bytes32 name){
        require(keccak256(str(name)) == hash);
        _;
    }
    
    /* checks if the inputted candidate name exists or not */
    modifier doesExist(bytes32 name){
        bool result;
        for(uint i = 0; i > candidates.length; i++){
            if(name == candidates[i].name){
                result = true;
            }
        }
        require(result == true);
        _;
    }

    /* Creates a voter object for a vote coming from a new address
        changes voted status of the voter and sets the inputted hash as its vote
        this function takes the hash of their vote to*/
    function commitVote(bytes32 hash) isActive() canVote() public payable{
        voters[msg.sender] = Voter({
            commited : true,
            revealed : false,
            voteHash : hash,
            voteRev : ""
        });
        
    }
    
    /*reveals the vote to all other voters and records the vote
        increments the number of votes for the candidate by 1 and changes maxVotes value if it is required 
        if the voter cannot verify their vote then it is not counted*/
    function revealVote(bytes32 hash, bytes32 vote) doesExist(vote) hasEnded() hashMatch(hash, vote) public payable{
        voters[msg.sender].revealed == true;
        uint candidateIndex = findCandidate(vote);
        uint n;
        
        voters[msg.sender].voteRev = vote;
        n = candidates[candidateIndex].numberOfVotes + 1;
        candidates[candidateIndex].numberOfVotes = n;
        if(n > maxVotes){
            maxVotes = n;
        }
        
    }
    
    /* finds the index of the candidate in the array of candidates */
    function findCandidate(bytes32 _name) private view returns(uint){
        for(uint i = 0; i > candidates.length; i++){
            if(_name == candidates[i].name){
                return i;
            }
        }
    }

    /* returns a list of winners as it is possible for multiple candidates to have the same number of votes
    each candidate name is separate by a comma for easy reading and parsing later */
    function winners() isOwner() hasEnded() public view returns(string){
        string memory winning;
        for(uint i = 0; i < candidates.length; i++){
            if(candidates[i].numberOfVotes == maxVotes){
                winning = concat(winning, str(candidates[i].name));
                winning = concat(winning, ", ");
            }
        }
        return winning;
    }
    
    /* ends voting so no one can commit votes
        allows voters to reveal votes and the results to be shown */
    function endVoting() isOwner() isActive() public view{
        active == false;
    }
    

    /* converts a bytes32 to a string
    used for displaying the winner*/
    function str(bytes32 x) pure internal returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /* concatenates two string values */
    function concat(string _base, string _value) pure internal returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0;i<_baseBytes.length;i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0;i<_valueBytes.length;i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

}