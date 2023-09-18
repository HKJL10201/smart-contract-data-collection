pragma solidity 0.6.1;

contract votting{
    struct candidate{
        uint id;
        string name;
        uint voted;
    }

    address private owner;
    candidate[] Array;

    event Candidate(uint, string,address);
     
    event Vote(uint,address);
    
    mapping(uint => candidate) candidates;

    mapping(address => bool) voters;


    modifier onlyOwner() {
        require(owner == msg.sender,"you are not owner");
        _;

    }

    constructor() public{
        owner = msg.sender;
    }

    function addCandidate(uint _id,string memory _name) public onlyOwner returns(bool){
        Array.push(candidate(_id,_name,0));
        candidates[_id] = candidate(_id,_name,0);
        emit Candidate(_id,_name,msg.sender);
        return true;
    }

    function getCandidateData(uint _id) public view returns(uint,string memory, uint){
        return (candidates[_id].id, candidates[_id].name, candidates[_id].voted); 
    }


    function vote(uint _candidateId) public returns(bool){
        require(!voters[msg.sender],"you have already voted");
        require(_candidateId == candidates[_candidateId].id,"invalid candidateId");
        
        voters[msg.sender] = true;
        candidates[_candidateId].voted += 1;

        emit Vote(_candidateId,msg.sender);
        return true;
        
    }

    function result() public view returns(string memory){
        for(uint i=0; i< Array.length; i++){
            uint temp = Array[i].id;
            if(candidates[temp].voted > candidates[Array[i+1].id].voted){
                return candidates[temp].name;
            }else if(candidates[temp].voted == candidates[Array[i+1].id].voted){
                return "draw";
            }
        }
        
    }

    

}