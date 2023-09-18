pragma solidity ^0.4.20;

contract Voting{

    Candidate[] candidates;
    mapping(address => Voter) voters;
    uint maxVotes = 0; //the maximum number of votes for an canadidate

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
        pushes the object to the array of canadidate objects*/
    function Voting(bytes32[] myCandidates) public {
        for(uint i = 0; i < myCandidates.length; i++){
            candidates.push(Candidate({
                id : i,
                name : myCandidates[i],
                numberOfVotes : 0
            }));
        }
    }

    /* Checks if the sender of the vote has voted before*/
    modifier canVote(){
        require(voters[msg.sender].hasVoted == false);
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

    /* Creates a voter object for a vote coming from a new address
    changes voted status of the voter and sets the id of the candidate it has voted for
    increments the number of votes for said candidate by 1
    changes maxVotes value if it is required */
    function vote(uint _candidate) public canVote() payable{
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
    function totalVotesFor(uint _candidate) public view returns(uint){
        return candidates[_candidate].numberOfVotes;
    }

    /*compares the total votes for each candidate and returns the candidate name with the largest number of votes*/
    function winner() public view returns(string){
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
    function winners() public view returns(string){
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
    function getMaxVotes() public view returns(uint){
        return maxVotes;
    }

    /* returns what candidate an address has voted for if the address has voted
    otherwise returns that the address has not voted for anything yet
    keeps voting public but anonymous as no one knows who the address belongs to*/
    function votedFor(address _voter) public view returns(string){
        if(voters[_voter].hasVoted == false){
            return "You have not voted yet";
        }else{
            uint v = voters[_voter].vote;
            bytes32 s = candidates[v].name;
            return str(s);
        }
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
