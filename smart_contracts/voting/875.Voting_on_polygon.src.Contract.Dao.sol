//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract Dao {
    struct Proposal {
        string name;
        string discription;  
        uint voteCount; 
    }
    struct member {
       bool approved;
    }
    address public Manager;
    Proposal[]   proposals;
    address[]  Voterlist;
    address[]  PendingApproval;
    mapping(address=>member) members;
    constructor() {
        Manager = msg.sender;
        members[Manager].approved=true;
    }
    modifier onlyMember() {
        require(members[msg.sender].approved, "You are not a member apply for membership");
        _;
    }
    modifier onlyManager() {
        require(msg.sender==Manager, "You are not a Manager");
        _;
    }
    function createProposal(string memory _proposalName ,string memory _discription) public onlyMember {
        proposals.push(Proposal({
            name: _proposalName,
            discription:_discription,
            voteCount: 0
        }));
    }
    function ApplyMembership(address _member) public {
    for (uint i = 0; i < PendingApproval.length; i++) {
        require(PendingApproval[i]!=msg.sender,"Allready Applied for membership");
    }
        PendingApproval.push(_member);
    }
    function ApproveMembership(address _member) public onlyManager {
        members[_member].approved=true;
        for (uint i = 0; i < PendingApproval.length; i++) {
        if(PendingApproval[i]==_member){
            delete PendingApproval[i];
        }
    }
    }
    function vote(uint proposal) external onlyMember {
        for (uint i = 0; i < Voterlist.length; i++) {
            require(Voterlist[i]!=msg.sender,"All ready voted");
            }
        proposals[proposal].voteCount += 1;
        Voterlist.push(msg.sender);
    }
    function getProposals() public view  returns (Proposal[] memory) {
    return proposals;
    }
    function getPendingApproval()  public view  returns (address[] memory) {
    return PendingApproval;
    }
   function clear() onlyManager public{
       delete  proposals;
       delete Voterlist;
    }

}
//mumbai = 0x775C4c31AbBeaf170257805231E3d37D10908232