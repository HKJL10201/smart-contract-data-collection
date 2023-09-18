pragma solidity ^0.4.20;

contract Voting{

    Candidate[] candidates;
    address[] whitelist;
    mapping(address => Voter) voters;
    uint maxVotes = 0; //the maximum number of votes for an canadidate
    address pollOwner;
    bool active;

    struct Candidate{
        uint id;
        bytes32 name;
        uint numberOfVotes;
    }

    struct Voter{
        bool hasVoted;
        uint vote;
    }

    /*Takes the array of candidates and creates a Candidate object for each canadidate in the array
        sets id, name and numberOfVotes for each candidate
        pushes the object to the array of canadidate objects
        sets the owner of the poll*/
    function Voting(bytes32[] myCandidates) public {
        
        pollOwner = msg.sender;
        active = true;
        whitelist.push(msg.sender);
        
        for(uint i = 0; i < myCandidates.length; i++){
            candidates.push(Candidate({
                id : i,
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
        require(voters[msg.sender].hasVoted == false);
        _;
    }
    
    /* checks if the poll is still active meaning voters can still vote */
    modifier isActive(){
        require(active == true);
        _;
    }

    /* Checks if the canadidate that the voter wishes to vote for actually exists or not*/
    modifier candidateExists(uint _candidate){
        bool result;
        for(uint i = 0; i < candidates.length; i++){
            if(_candidate == candidates[i].id){
                result = true;
            }else{
                result = false;
            }
        }
        require(result);
        _;
    }
    
    /* checks if the address that wants to vote is in the whitelist */
    modifier isAllowed(){
        bool allowed;
        
        for(uint i; i > whitelist.length; i++){
            if(msg.sender == whitelist[i]){
                allowed = true;
            }
        }
        
        require(allowed == true);
        _;
    }

    /* Creates a voter object for a vote coming from a new address
    changes voted status of the voter and sets the id of the candidate it has voted for
    increments the number of votes for said candidate by 1
    changes maxVotes value if it is required */
    function vote(uint _candidate) isActive() isAllowed() canVote() public payable{
        voters[msg.sender] = Voter({
            hasVoted : true,
            vote : _candidate
        });
        uint n = candidates[_candidate].numberOfVotes + 1;
        candidates[_candidate].numberOfVotes = n;
        if(n > maxVotes){
            maxVotes = n;
        }

    }

     /* returns the total number of votes for a canadidate*/
    function totalVotesFor(uint _candidate) private view returns(uint){
        return candidates[_candidate].numberOfVotes;
    }

    /*compares the total votes for each candidate and returns the candidate name with the largest number of votes*/
    function winner() private view returns(string){
        bytes32 winning;
        for(uint i = 0; i < candidates.length; i++){
            if(candidates[i].numberOfVotes == maxVotes){
                winning = candidates[i].name;
            }
        }
        return str(winning);
    }

    /* returns a list of winners as it is possible for multiple candidates to have the same number of votes
    each candidate name is separate by a comma for easy reading and parsing later */
    function winners() private view returns(string){
        string memory winning;
        for(uint i = 0; i < candidates.length; i++){
            if(candidates[i].numberOfVotes == maxVotes){
                winning = concat(winning, str(candidates[i].name));
                winning = concat(winning, ", ");
            }
        }
        return winning;
    }

    /* returns the maximum number of votes for any candidate*/
    function getMaxVotes() private view returns(uint){
        return maxVotes;
    }
    
    /* stops anyone from voting and returns the winners of the poll
        this can only be done by the owner of the poll/contracts */
    function endsVote() isOwner() public returns(string){
        active = false;
        return winners();
    }

    /* returns what candidate an address has voted for if the address has voted
    otherwise returns that the address has not voted for anything yet
    keeps voting public but anonymous as no one knows who the address belongs to*/
    function votedFor(address _voter) isAllowed() public view returns(string){
        if(voters[_voter].hasVoted == false){
            return "You have not voted yet";
        }else{
            uint v = voters[_voter].vote;
            bytes32 s = candidates[v].name;
            return str(s);
        }
    }
    
    /* adds an address to the whitelist which allows the address to vote
        can only be done by the owner of the contract/poll */
    function addToWhitelist(address _address) isOwner() public{
        whitelist.push(_address);
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