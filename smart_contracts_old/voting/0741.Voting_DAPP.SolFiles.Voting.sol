pragma solidity ^0.4.2;
pragma experimental ABIEncoderV2;

contract Users {
    mapping(uint => voter) public voters;
    mapping(uint => owner) public owners;
    mapping(uint => uint) public IndividualVote;
    mapping(uint => Candidate) public CandidateVote;
    uint[] public voterID;
    uint[] public ownerID;
    bool public VoteConfirmation;
    bool public isValidVoter = true;
    bool public isValidOwner = true;
    string[] public Candidates;
    uint public CandidateIndex = 0;
    string[] public names;
    uint[] public votes;
    string public FinalWinner;
    uint public MaxVotes;
    string[] public Names;
    
    struct Candidate{
        string candidateName;
        uint TotalVotes;
    }
    
    struct voter {
        uint voterID;
        string name;
        bytes password;
        uint age;
        address owner;
        string district;
    }

    struct owner{
        uint ownerID;
        string name;
        bytes password;
        uint age;
        address owner;
        string district;
    }
    
    event VoterCreated(
        uint voterID,
        string name,
        bytes password,
        uint age,
        address owner,
        string district
    );

    event OwnerCreated(
        uint ownerID,
        string name,
        bytes password,
        uint age,
        address owner,
        string district
    );
    
    function getCandidateIndex() view public returns(uint) {
        return CandidateIndex;
    }

    function getCandidates() view public returns(string[]) {
        return Candidates;
    }
    
    function getDataVoter() view public returns(bool) {
        return isValidVoter;
    }
    
    function getDataOwner() view public returns(bool){
        return isValidOwner;
    }
    
    function getVotedNames() public view returns(string[]){
        return names;
    }
    
    function getVotes() public view returns(uint[]){
        return votes;
    }
    
    function getWinner() public view returns(string){
        return FinalWinner;
    }
    
    function getMaxVotes() public view returns(uint){
        return MaxVotes;
    }
    
    function AddCandidates(uint _id,string memory candidate) public{
        if(ValidOwnerID(_id)==false){
            if(bytes(candidate).length>1){
            Candidates.push(candidate);
            CandidateVote[CandidateIndex] = Candidate(candidate,0);
            CandidateIndex +=1;
            }
        }
    }
    
    function GetCandidates() public view returns(string[]){
        return Names;
    }
    
    function AvailableCandidates(uint id) public{
        delete Names;
        if(ValidVoterID(id)==false){
            for(uint i=0;i<CandidateIndex+1;i++){
                Names.push(CandidateVote[i].candidateName);
            }
        }
    }
    
    function DisplayAllVotes(uint id) public{
        if(ValidOwnerID(id)==false){
            delete names;
            delete votes;
            for(uint i=0;i<CandidateIndex+1;i++){
                names.push(CandidateVote[i].candidateName);
                votes.push(CandidateVote[i].TotalVotes);
            }
        }
    }
    
    function Winner(uint id) public{
        if(ValidOwnerID(id)==false){
    
        uint max = 0;
        string memory winner;
        for(uint i=0;i<CandidateIndex+1;i++){
        if(CandidateVote[i].TotalVotes>max){
            max = CandidateVote[i].TotalVotes;
            winner = CandidateVote[i].candidateName;
           }
        }
        FinalWinner = winner;
        MaxVotes = max;   
        }
    }
    
    function CreateVoter(uint _id,string memory _name,string memory _password,uint _age,string memory _district) public {
        require(bytes(_name).length > 0);
        require(bytes(_district).length > 0);
        require(_age > 0);
        if(ValidVoterID(_id)==true){
            voterID.push(_id);
            bytes memory b3 = bytes(_password);
            isValidVoter=true;
            IndividualVote[_id]=0;
            voters[_id] = voter(_id,_name,b3,_age,msg.sender,_district);
            emit VoterCreated(_id,_name,b3,_age,msg.sender,_district);
        } else{
            isValidVoter=false;
        }
    }

    function CreateOwner(uint _id ,string memory _name,string _password,uint _age,string memory _district) public {
        require(bytes(_name).length > 0);
        require(bytes(_district).length > 0);
        require(_age > 0);
        if(ValidOwnerID(_id)==true){
            ownerID.push(_id);
            isValidOwner=true;
            bytes memory b3 = bytes(_password);
            owners[_id] = owner(_id,_name,b3,_age,msg.sender,_district);
            emit OwnerCreated(_id,_name,b3,_age,msg.sender,_district);
        } else{
            isValidOwner=false;
        }
    }
    
    function getVoteConfirmation() public view returns(bool){
        return VoteConfirmation;
    }
    function CastVote(uint _id,string memory choice) public{
        if(ValidVoterID(_id)==false){
            if(IndividualVote[_id]==0){
                for(uint i=0;i<CandidateIndex;i++){
                    if(keccak256(abi.encodePacked(CandidateVote[i].candidateName)) == keccak256(abi.encodePacked(choice))){
                        CandidateVote[i].TotalVotes+=1;
                        IndividualVote[_id]=1;
                        VoteConfirmation = true;
                    }
                }
            } else{
            VoteConfirmation = false;
            }
        } else{
            VoteConfirmation = false;
        }
    }
    
    function ValidVoterID(uint _id) view public returns (bool){
        for(uint i=0; i < voterID.length;i++){
            if (voterID[i]==_id) {
                return false;
            }
        }
        return true;
    }
    
    function ValidOwnerID(uint _id) view public returns (bool){
        for(uint i=0; i < ownerID.length;i++){
            if (ownerID[i]==_id) {
                return false;
            }
        }
        return true;
    }
}










