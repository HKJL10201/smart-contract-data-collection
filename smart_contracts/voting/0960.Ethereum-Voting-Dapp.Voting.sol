pragma solidity ^0.4.23;

/*
contract developed by vatsamail@gmail.com
Refer zastrin.com
Mahesh Murthy
*/

/* requirements:
 npm install -g --production windows-build-tools
 npm install ganache-cli web3@0.20.1 solc

 code compile at: http://remix.ethereum.org
*/

contract Voting {
    // constructor to initialize the candidates
    bytes32[] public candidates_list;
    mapping (bytes32 => uint8) votes_received; // hash table

    constructor(bytes32[] candidates_names) public {
        candidates_list = candidates_names;
    }

    // function to vote for the candidates
    function vote_for_candidate(bytes32 candidate) public {
        require(check_validity_of_candidate(candidate)); // if the candidate is valid check
        votes_received[candidate] += 1;
    }

    // count the candidates's votes
    function total_votes_for_candidate(bytes32 candidate) view public returns(uint8) { // view makes it asa read only function
        require(check_validity_of_candidate(candidate)); // if the candidate is valid check
        return votes_received[candidate];
    }

    // supplement function to check valid candidate
    function check_validity_of_candidate(bytes32 candidate) view public returns (bool) {
        for (uint i = 0; i < candidates_list.length; i += 1) {
            if (candidate == candidates_list[i]) {
                return true;
            }
        }
        return false;
    }
}
