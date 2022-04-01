pragma solidity >=0.4.22 <0.9.0;
 

contract eVoting{
 struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    
    struct Voter{
        //bool authorized;
        bool voted;
        uint vote;
    }
    
    address payable public owner;
    string public electionName;
    uint public noOfCandidates;
    //bool public electionStatus=true;
    enum STATUS{INACTIVE,ACTIVE,ENDED}
    STATUS status=STATUS.INACTIVE;
    
    function electionStatus() public view returns(STATUS){
        return status;
    }
    
    function startElection() public{
        status=STATUS.ACTIVE;
    }

    mapping(address=>Voter) public voters;
    Candidate[] public candidates;
    
    uint public totalVotes;
    
    constructor(string memory _name) public{
        owner=msg.sender;
        electionName=_name;
        addCandidate("rithick");
        addCandidate("roshan");
        addCandidate("roshan bhatt");
    }

     event votedEvent (
        uint indexed _voteIndex
    );
    
    modifier ownerOnly(){
        require(owner==msg.sender);
        _;
    }
    
    function addCandidate(string memory _name)ownerOnly public{
        require(status==STATUS.INACTIVE,"Election has already begun.");
        noOfCandidates++;
        candidates.push(Candidate(noOfCandidates,_name,0));
    }
    
    // function getNumCandidate() public view returns(uint){
    //     return candidates.length;
    // }
    
    // function authorize(address _person) ownerOnly public{
    //     voters[_person].authorized=true;
    // }
    
    function vote(uint _voteIndex) public{
        require(!voters[msg.sender].voted,"Already voted");
        require(status==STATUS.ACTIVE,"Election has not yet started/already ended.");
     
        //require(voters[msg.sender].authorized);
        
        voters[msg.sender].vote=_voteIndex;
        voters[msg.sender].voted=true;
        
        candidates[_voteIndex-1].voteCount+=1;
        totalVotes+=1;
        
        emit votedEvent(_voteIndex);
    }
    function end(address a) public ownerOnly{
        require(status==STATUS.ACTIVE,"Election has not yet begun");
        status=STATUS.ENDED;
        // electionStatus=false;
        // selfdestruct(owner);
    }
}