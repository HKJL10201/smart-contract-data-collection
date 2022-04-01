pragma solidity  ^0.5.0;
pragma experimental ABIEncoderV2;

contract Election
{
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    event votedEvent
    (
        uint indexed id
    );
    uint candidate_count;
    struct Candidate
    {
        uint id;
        string name;
        string party;
        uint vote_count;
    }
    constructor() public
    {
        addCandidate("Moody","BJP");
        addCandidate("Pappu","INC");
    }
    function addCandidate(string memory name,string memory party) private
    {
        candidates[candidate_count]=Candidate(candidate_count,name,party,0);
        candidate_count++;
    }
    function vote(uint id) public
    {
        require(!voters[msg.sender]);
        require(candidate_count > id && id>=0);
        candidates[id].vote_count +=1 ;
        voters[msg.sender]=true;
        emit votedEvent(id);
    }
    function test() pure public returns (string memory)
    {
        return "connected to network";
    }
    
    function getCandidates() view public returns (Candidate[] memory)
    {
        Candidate[] memory ret_candidates=new Candidate[](candidate_count);
        for(uint i = 0; i <candidate_count; i++) {
            ret_candidates[i] =candidates[i];
        }
        return ret_candidates;
    }
    
    function hasVoted(string memory wallet) view public returns (string memory)
    {
        address add=parseAddr(wallet);
        string memory ret;
        if(voters[add])
        {
            ret="True";
        }
        else
        {
            ret="False";
        }
        return ret;
    }
    
    
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
}
    
}
