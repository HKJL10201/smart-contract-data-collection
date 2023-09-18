//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Voting {
    mapping(address => bool) public membershipStatus;
    address[] public activeMembers;
    string[] public proposalList;

    modifier onlyMember(){
        bool status;
        for(uint i=0; i <activeMembers.length; i++) {
            if(activeMembers[i] == msg.sender) {
                status = true;
            }
        }
        require(status == true, "you are not a member");
        _;
    }



    function becomeMember() external payable {
        require(msg.value >= 1 ether, "pay the membership fee of 1 Matic");
        membershipStatus[msg.sender] = true;
        activeMembers.push(msg.sender);
    }

    function makeProposal(string memory _proposal) external onlyMember {
        proposalList.push(_proposal);
    }
}