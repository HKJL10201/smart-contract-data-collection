// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

contract VotingCore {
    struct Voter {
        bool voted;
        bool isAllowed;
        uint candidateId;
    }

    struct Candidate {
        bytes32 name;
        bytes32 party;
        bytes32 imgUrl;
        uint32 count;
    }

    address public owner;

    Candidate[] public candidates;

    mapping(address => Voter) public voters;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function setCandidates(
        bytes32[] memory names,
        bytes32[] memory parties,
        bytes32[] memory imgUrls
    ) public onlyOwner {
        for (uint i = 0; i < names.length; i++) {
            candidates.push(Candidate({
                name : names[i],
                party : parties[i],
                imgUrl : imgUrls[i],
                count : 0
            }));
        }
    }

    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function whitelistAddress(address voterAddress) public onlyOwner {
        Voter storage voter = voters[voterAddress];
        require(!voter.voted, "Address already voted!");
        require(!voter.isAllowed, "Address already whitelisted!");

        voter.isAllowed = true;
    }

    function getIsAddressAllowed(address voterAddress) public view returns (bool) {
        return voters[voterAddress].isAllowed;
    }

    function vote(uint id) public {
        Voter storage voter = voters[msg.sender];
        require(voter.isAllowed, "Not allowed!");
        require(!voter.voted, "Address already voted!");
        voter.voted = true;
        voter.candidateId = id;

        candidates[id].count += 1;
    }

    function getWinner() public view returns (
        bytes32, bytes32, bytes32, uint32
    ) {
        Candidate memory c = candidates[_getWinnerId()];
        return (c.name, c.party, c.imgUrl, c.count);
    }

    function _getWinnerId() internal view returns (uint) {
        uint currCount = 0;
        uint id;
        for (uint i = 0; i < candidates.length; i++) {
            if(candidates[i].count > currCount) {
                currCount = candidates[i].count;
                id = i;
            }
        }
        return id;
    }
}
