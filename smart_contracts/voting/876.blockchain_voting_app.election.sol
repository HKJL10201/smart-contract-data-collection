pragma solidity 0.4.21;

contract Election{
    
    struct Candidate{
        string name;
        string link;
        uint voteCount;
    }
    
    struct Voter{
        bool authorized;
        bool Voted;
        uint vote;
        uint pin;
        uint totalwrongtries;
    }
    
    address public owner;
    string public electionname;
    
    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint public totalvotes;
    
    modifier Owneronly(){
        require(msg.sender == owner);
        _;
    }
    
    
    function Election(string _name) public {
        owner = msg.sender;
        electionname = _name;
    }
    
    function Addcandidate(string _name, string _link) Owneronly public {
        candidates.push(Candidate(_name,_link, 0));
    }
    
    function getNumCandidate() public view returns(uint){
        return candidates.length; 
    }
    
    function Authorize(address _person, uint pin) Owneronly public{
        voters[_person].authorized = true;
        voters[_person].pin = pin;
        voters[_person].totalwrongtries = 0;
        }
    
    function vote( uint _voteIndex, uint pin) public {
        require(!voters[msg.sender].Voted);
        require(voters[msg.sender].authorized);
        
        if(voters[msg.sender].pin == pin && voters[msg.sender].totalwrongtries < 6){
        candidates[_voteIndex].voteCount += 1;
        voters[msg.sender].Voted = true;
        totalvotes += 1;
        }else{
            voters[msg.sender].totalwrongtries +=1;
        }
        
    }
    
    function showTheError() public view returns(string){
         if(voters[msg.sender].Voted)
        return "already voted";
        else if(!voters[msg.sender].authorized)
        return "Not authorized";
        else 
        return "You may vote";
    }
    
    
    function end() Owneronly public{
        selfdestruct(owner);
    }
}














