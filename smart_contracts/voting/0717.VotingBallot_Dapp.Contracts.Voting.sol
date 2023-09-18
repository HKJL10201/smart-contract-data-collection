// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
struct Voter {
    string name;
    address voterAdd;
    bool voterRegistered;
    bool voted;
    bool allowed;
}
struct Party {
    string name;
    uint256 noOfVotes;
    bool partyRegistered;
    address partyAdd;
}

contract Voting {
    address public chairperson;
    Voter[] public voters;
    Party[] public parties;

    constructor() {
        chairperson = msg.sender;
    }

    function existParty(address addr) internal view returns (int256) {
        for (uint256 i = 0; i < parties.length; i++) {
            if (parties[i].partyAdd == addr) return int256(i);
        }
        return -1;
    }

    function existVoter(address addr) internal view returns (int256) {
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].voterAdd == addr) return int256(i);
        }
        return -1;
    }

    function registerParty(string memory _name) external {
        require(msg.sender!=chairperson,"Chairperson cannot form party");
        require(existParty(msg.sender) == -1, "Party already registered");
        Party memory party;
        party.name = _name;
        party.partyAdd = msg.sender;
        party.partyRegistered = true;
        parties.push(party);
    }

    function registerVoter(string memory _name) external {
        require(msg.sender!=chairperson,"Chairperson cannot vote");
        require(existVoter(msg.sender) == -1, "Voter already registered");
        Voter memory voter;
        voter.name = _name;
        voter.voterAdd = msg.sender;
        voter.voterRegistered = true;
        voters.push(voter);
    }

    function allow(address addr) external {
        int256 index = existVoter(addr);
        require(
            msg.sender == chairperson,
            "Only chairperson can allow to vote"
        );
        require(index != -1, "Voter not registered");
        voters[uint256(index)].allowed = true;
    }

    function vote(address addr) external {
        int256 index = existVoter(msg.sender);
        int256 i = existParty(addr);
        require(msg.sender!=chairperson,"Chairperson cannot vote");
        require(i != -1, "Party not registered");
        require(index != -1, "Voter not registered");
        require(voters[uint256(index)].allowed == true, "Voter not allowed");
        require(voters[uint256(index)].voted == false, "Voter voted already");
        parties[uint256(i)].noOfVotes++;
        voters[uint(index)].voted=true;
    }
    function decideWinner() external view returns(string memory){        
        require(msg.sender==chairperson,"Only chairperson can decide");
        string memory winner;
        if(parties.length==1) return parties[parties.length-1].name;
        for(uint i=1;i<parties.length;i++){
            if(parties[i].noOfVotes>parties[i-1].noOfVotes) winner=parties[i-1].name;
        }
        return winner;
    }
}
