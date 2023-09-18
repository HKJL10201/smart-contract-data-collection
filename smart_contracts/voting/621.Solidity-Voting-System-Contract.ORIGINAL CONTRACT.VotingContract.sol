// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract VotingContract {
    mapping(address => bool) addressMapping;
    address[] addressStorage;

    uint256 partyOneVotes;
    uint256 partyTwoVotes;
    uint256 partyThreeVotes;

    constructor() {
        partyOneVotes = 0;
        partyTwoVotes = 0;
        partyThreeVotes = 0;
    }

    function addMeToVotedList() public {
        require(!hasAlreadyVoted(), "You Have Already Been Added");
        addressMapping[msg.sender] = true;
        addressStorage.push(msg.sender);
    }

    function registerVote(uint256 num) public {
        require(
            num < 4 && num > 0,
            "the given number is invalid as the number is out of range"
        );
        require(!hasAlreadyVoted());
        addMeToVotedList();
        if (num == 1) {
            partyOneVotes++;
        } else if (num == 2) {
            partyTwoVotes++;
        } else {
            partyThreeVotes++;
        }
    }

    function hasAlreadyVoted() public view returns (bool) {
        // return false;
        return addressMapping[msg.sender];
    }

    function getAddressValues() public view returns (address[] memory) {
        return addressStorage;
    }

    function getParty1Votes() public view returns (uint256) {
        return partyOneVotes;
    }

    function getParty2Votes() public view returns (uint256) {
        return partyTwoVotes;
    }

    function getParty3Votes() public view returns (uint256) {
        return partyThreeVotes;
    }
}
