// Elections smart contract | Kobi Azarov | Tamir Yakov


pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

contract Elections {
    struct Candidate{
        string name;
        uint voteCount;
    }
    
    struct Voter{
        bool authorized;
        bool voted;
        uint vote;
    }
    
    
    address payable public owner;       //owners contract address
    string public electionName;         
    
  
    
    
    mapping(address =>Voter) public voters;     // mapping hash tables which consist pairs of voter and address
    Candidate[] public candidates;          // Candidates that will be added in the Election
    uint public totalVotes;
    
    
   
    function Election (string memory name) public {
        owner=msg.sender;       // msg.sender will be the person who currently creating  the contract.
        electionName = name;
    }
    
    
    //OWNER ONLY permission for future function To establish a hierarchy in the Elections
    modifier ownerOnly(){
        require(msg.sender==owner);
        _;
    }
    
    
    // Function that adding Candidate for the Election with 2 parameters: Candidates name' and index
    function addCandidate(string memory name) ownerOnly public {
        candidates.push(Candidate(name,0));
    }
    function getNumCandidate() public view returns(uint) {
        return candidates.length;
    }
    
    //functuion that returns current number of votes
    function getTotalVotes() public view returns(uint) {
        return totalVotes;
    }
    
    // function that returns the Candidates Array
    function getCandidates() public view returns(Candidate[] memory) {
        return candidates;
    }
    
    
    
    function getElectionName() public view returns(string memory) {
        return electionName;
    }
    
    // Function that Only Owner of contract Authorizing persons to Vote, with their Adress
    function authorize(address _person) ownerOnly public {
        voters[_person].authorized = true;
    }
    
    function vote(uint _voteIndex) public {
        require(!voters[msg.sender].voted); // Checks if this person already Voted
        require(voters[msg.sender].authorized); // Checks if this person authorized by the Owner
        
        voters[msg.sender].vote=_voteIndex;
        voters[msg.sender].voted=true;
        
        candidates[_voteIndex].voteCount+=1;    //adding 1 to counter of This! Candidates Votes
        totalVotes+=1;  //adding 1 to counter TotalVotes of the Election
        
    }
    
    //function that returns Who win in The Election by checking which candidates-Index have max num of votes
    function whoWin() ownerOnly public view returns(string memory) {
        uint maxVotes=0;
        string memory name;
        
        for(uint i=0;i<candidates.length;i++)
        {
            if(candidates[i].voteCount>maxVotes)
            {
            maxVotes=candidates[i].voteCount;
            name=candidates[i].name;
            }
        }
        return name;
    }
    
    //function that Ending the Elections!
    function end() ownerOnly public {
        selfdestruct(owner);
       
    }
    

    
    
}
