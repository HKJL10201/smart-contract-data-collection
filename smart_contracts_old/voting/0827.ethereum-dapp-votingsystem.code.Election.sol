pragma solidity >=0.4.0 <0.6.0;
contract Election{
    address public owner;
    string public electionName;    
    bytes32 private randNonce;
    bytes private secretNounce;
    string public latestAuthCode;
    string public errorMessage;
    uint flag=0;
    struct Candidate {
        string name;
        uint256 candidate_id;
        uint voteCount;
    }
    struct Voter{
        string auth_code;
        bool authorized;
        uint candidate_id;
        string email;
        bool voted;
        address voter_address;
    }
    uint[] public winnerCandidates;
    mapping(string => Voter) voters;
    mapping(string => bool) private emailExists;
    mapping(uint => Candidate) candidates;   
    uint public totalVotes=0;
    uint public winnerCandidateVotes = 0;
    uint public totalCandidates=0;   
    modifier ownerOnly(){
        require(msg.sender==owner);
        _;
    }
    constructor(string memory _name) public payable{
        owner=msg.sender;
        electionName=_name;
        secretNounce = abi.encodePacked( block.difficulty, now);
    }
    function addCandidates(string memory _name) ownerOnly public {
        totalCandidates= totalCandidates + 1;
        candidates[totalCandidates] = Candidate({name: _name, candidate_id:  totalCandidates, voteCount:0});
    }
    function errorMess() public view returns (string memory){
        return errorMessage;
    }
    function vote(string memory _auth_code, uint _can_id) public returns (string memory) {
        if(flag==0){
            if(voters[_auth_code].voted == true){
                errorMessage="Already Voted";
              return "Already Voted";  
            }
            else{
                if(voters[_auth_code].authorized == false){
                    errorMessage="Voter Not Authorized";
                    return "Voter Not Authorized";
                }
                else{
                    if(voters[_auth_code].voter_address!=msg.sender){
                        errorMessage="Voting with Wrong Address";
                        return "Voting with Wrong Address";
                    }
                    else{
                        voters[_auth_code].voted = true;
                        voters[_auth_code].candidate_id = _can_id;
                        candidates[_can_id].voteCount = candidates[_can_id].voteCount + 1;
                        if(candidates[_can_id].voteCount > winnerCandidateVotes) {
                            winnerCandidateVotes = candidates[_can_id].voteCount;
                        }
                        totalVotes = totalVotes + 1;
                        errorMessage="Vote Successful";
                        return "Vote Successful";
                    }
                }
            }
        }
        else{
            errorMessage="Election over";
            return "Election over";
        }
    }
    function latestAuth() public view returns(string memory){
        return latestAuthCode;
    }
    function addVoter(string memory _email) public returns (string memory) {
        string memory key = random(_email);
        require(emailExists[key] == false);
        emailExists[key] = true;
        voters[key] = Voter({auth_code:key, authorized:true, candidate_id:0, email:_email, voted:false, voter_address:msg.sender});
        if(voters[key].authorized==true){
            latestAuthCode=key;
            return key;
        }
        else{
            return "Not Authorized";
        }
        
    }
    function random(string memory _email)  private view returns (string memory) {
        return uint2str(uint( keccak256(abi.encodePacked( secretNounce, _email))));
    }
    function populateWinnerList() public {
        for(uint i = 1; i <= totalCandidates; i++) {
            if( candidates[i].voteCount >= winnerCandidateVotes) {
                winnerCandidates.push(i);
            }
        }
    }
    function endElection() ownerOnly public {
        flag=1;
    }
    function Result() public view returns (string memory){
        string memory names;
        for(uint i=1; i<=totalCandidates; i++){
            
            names=string(abi.encodePacked(names,uint2str(candidates[i].candidate_id),"/",candidates[i].name,"/",uint2str(candidates[i].voteCount),"\n"));
        }
        return names;
    }
    function getWinnerName() public view returns (string memory) {
        string memory names;
        for(uint i = 1; i <= totalCandidates; i++) {
            if( candidates[i].voteCount >= winnerCandidateVotes) {
                names = string(abi.encodePacked(names,"\n", candidates[i].name));   
            }
        }
        return names;
    }
    function getWinnerCount() public view returns(uint) {
        return winnerCandidateVotes;
    }
    function getCandidateByID(uint id) public view returns(string memory name) {
        return candidates[id].name;
    }
    function getCandidateList() public view returns(string memory){
        string memory names;
        for(uint i = 1; i <= totalCandidates; i++) {
            names = string(abi.encodePacked(names, candidates[i].name, "\n"));   
        }
        return names;
    }
    function end() ownerOnly public{
        selfdestruct(address(uint160(owner)));
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }        
}