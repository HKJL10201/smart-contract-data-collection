//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;
contract Election {
    struct Proposal {
        string name;  
        uint voteCount; 
    }
    address public chairperson;
    Proposal[]   proposals;
    uint  deadline;
    address[]  Voterlist;
    
    constructor() public {
        chairperson = msg.sender;
    }
    function createCandidate(string[] memory proposalNames,uint _deadline) public {
        require(msg.sender==chairperson);
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
        deadline=block.timestamp+_deadline;
    }
    function vote(uint proposal) external {
        for (uint i = 0; i < Voterlist.length; i++) {
            require(Voterlist[i]!=msg.sender,"All ready voted");
            }
        require(block.timestamp<deadline,"Deadline Passed");
        proposals[proposal].voteCount += 1;
        Voterlist.push(msg.sender);
    }
    function getProposals() public view returns (Proposal[] memory) {
    return proposals;
    }

   function clear() public{
       require(msg.sender==chairperson);
       delete  proposals;
       delete  deadline;
       delete Voterlist;
    }

}
//Gorrli = 0x9923aB9F67A8869A9aE772Fa5F0fadb9A7935590