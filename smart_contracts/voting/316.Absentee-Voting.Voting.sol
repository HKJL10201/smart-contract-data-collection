pragma solidity ^0.6.0;
contract ERC1155{
    function burn(address account, uint256 id, uint256 amount) external virtual {
    }
    function balanceOf(address account, uint256 id) public view virtual returns (uint256){
        
    }
}
contract Voting{
    struct Candidate{
        bytes District;
        uint8 CandidateId;
        string Name;
        uint8 Age;
        string FromParty;
        
    }
    uint public expireTime;
    mapping(address=>Candidate)public _candidate;
    mapping(bytes=>mapping(uint8=>uint))private getVotes;
    //mapping(address=>bytes)public region;
    ERC1155 public ballot;
    constructor(address erc1155addr,uint time)public{
        ballot=ERC1155(erc1155addr);
        expireTime=time;
    }
    /*
    function addVoter(address voterAddr){
        
    }*/
    function addCandidate(address candidateAddr,bytes memory dist,uint8 Cid,string memory name,uint8 age,string memory party)public returns(bool){
        Candidate storage __candidate=_candidate[candidateAddr];
        __candidate.District=dist;
        __candidate.CandidateId=Cid;
        __candidate.Name=name;
        __candidate.Age=age;
        __candidate.FromParty=party;
        return true;
    }
    function vote(uint8 id,bytes memory dist,uint8 cid)public returns(bool){
        require(now<expireTime);
        require(ballot.balanceOf(msg.sender,id)==1);
        ballot.burn(msg.sender,id,1);
        getVotes[dist][cid]+=1;
        return true;
    }
    function VoteBalance(bytes memory dist,uint8 cid)public view returns(uint){
        require(now>expireTime);
        return getVotes[dist][cid];
    }
}
