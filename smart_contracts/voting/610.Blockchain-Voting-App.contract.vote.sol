// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract vote {
    // This is the contract's body, here you'll specify the logic for this contract.

    // struct for a Candidate
    struct Candidate {
        uint256 id;
        string name;
        string partyName;
        uint256 age;
        string city;
        uint256 votes;
    }

    // storing party votes
    struct Party {
        string partyName;
        uint256 partyVotes;
    }

    Party[] parties;

    // storing current id of the last candidate
    uint256 curr = 0;

    // status of result
    uint256 declared = 0;

    // array for storing the candidates
    Candidate[] candidates;

    // create a function to vote a candidate
    function voteCandidate(uint256 _id) public {
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].id == _id) {
                candidates[i].votes++;

                for (uint256 j = 0; j < parties.length; j++) {
                    if (
                        keccak256(abi.encodePacked(parties[j].partyName)) ==
                        keccak256(abi.encodePacked(candidates[i].partyName))
                    ) {
                        parties[j].partyVotes++;
                        break;
                    }
                }
            }
        }
    }

    // getting votes of parties
    function getPartyVotes() public view returns (Party[] memory) {
        return parties;
    }

    // function to add a candidate
    function addCandidate(
        string memory _name,
        string memory _partyName,
        uint256 _age,
        string memory _city
    ) public {
        Candidate memory newCandidate = Candidate(
            curr + 1,
            _name,
            _partyName,
            _age,
            _city,
            0
        );
        candidates.push(newCandidate);
        curr++;

        uint256 found = 0;
        for (uint256 j = 0; j < parties.length; j++) {
            if (
                keccak256(abi.encodePacked(parties[j].partyName)) ==
                keccak256(abi.encodePacked(_partyName))
            ) {
                found = 1;
                break;
            }
        }

        if (found == 0) {
            Party memory newParty = Party(_partyName, 0);
            parties.push(newParty);
        }
    }

    // function to return all candidates
    function getCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    // to declare result
    function declareResults() public {
        declared = 1;
    }

    // get result status
    function getStatus() public view returns (uint256) {
        return declared;
    }

    // function to get the winner
    function getWinner() public view returns (Candidate memory) {
        uint256 mx = 0;
        Candidate memory winner = candidates[0];

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].votes >= mx) {
                mx = candidates[i].votes;
                winner = candidates[i];
            }
        }

        return winner;
    }
}
