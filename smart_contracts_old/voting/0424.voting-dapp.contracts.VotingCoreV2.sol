// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

contract VotingCoreV2 {
    struct Choice {
        bytes32 ref;
        bytes id;
    }

    struct Voter {
        bytes32 key;
        bool allowed;
        bool voted;
    }

    struct Candidate {
        bytes id;
        bytes32 name;
        bytes32 party;
        bytes32 imgUrl;
        uint32 count;
    }

    address owner;

    Candidate[] public candidates;

    mapping(bytes32 => Voter) public voters;
    mapping(bytes32 => Choice[]) public choices;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function setCandidates(
        bytes[] memory ids,
        bytes32[] memory names,
        bytes32[] memory parties,
        bytes32[] memory imgUrls
    ) public onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            candidates.push(Candidate({
            id : ids[i],
            name: names[i],
            party: parties[i],
            imgUrl: imgUrls[i],
            count : 0
            }));
        }
    }

    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function addVoter(bytes32 key) public onlyOwner {
        voters[key] = Voter({key: key, allowed: true, voted: false});
    }

    function registerChoices(bytes32 key, bytes32[] memory refs) public {
        require(voters[key].allowed, "!allowed");
        for (uint i = 0; i < candidates.length; i++) {
            choices[key].push(Choice({ref: refs[i], id: candidates[i].id}));
        }
    }

    function getChoices(bytes32 key) public view returns (Choice[] memory) {
        return choices[key];
    }

    // temp impl
    function vote(bytes32 key, bytes32 choice) public {
        Voter storage voter = voters[key];
        require(!voter.voted, "duplicate vote");
        Choice[] storage _choices = choices[key];
        bytes storage id;
        for(uint i = 0; i < _choices.length; i++) {
            if(_choices[i].ref == choice) {
                id = _choices[i].id;
                break;
            }
        }
        for(uint i = 0; i < candidates.length; i++) {
            if (
                sha256(candidates[i].id) == sha256(id)
            ) {
                candidates[i].count += 1;
                break;
            }
        }
        voter.voted = true;
    }
}