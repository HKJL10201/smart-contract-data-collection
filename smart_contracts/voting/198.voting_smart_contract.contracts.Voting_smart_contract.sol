pragma solidity 0.5.16;

contract Voting_smart_contract {

    struct candidate {
        string candidate_name;
        uint vote_count;
    }

    struct voter {
        uint voted;
        uint modulus;
        uint public_key;
    }

    mapping(uint => candidate) public candidates;
    mapping(uint => voter) public voters;

    uint public candidate_count;
    uint public voter_count;

    uint contract_modulus;
    uint contract_private_key;

    constructor() public {
        contract_modulus = 91;
        contract_private_key = 11; //public key = 59
        voter_count = 2;
        candidate_count = 4;
        addCandidateToBallot("Biden");
        addCandidateToBallot("Trump");
        addEligibleVoter(143, 23); //priv key = 47
        addEligibleVoter(85, 19); //priv key = 27
    }

    function addCandidateToBallot (string memory candidate_name) private {
        uint initial_vote_count = 0;
        candidates[candidate_count] = candidate(candidate_name, initial_vote_count);
        candidate_count++;
    }

    function addEligibleVoter(uint modulus, uint public_key) private {
        uint initial_voted = 0;
        voters[voter_count] = voter(initial_voted, modulus, public_key);
        voter_count++;
    }

    function vote(uint voter_id, uint candidate_id, uint voter_id_signature, uint candidate_id_signature) public
    {
      uint decrypted_voter_id = (voter_id**contract_private_key)%contract_modulus;
      uint decrypted_voter_signature = (voter_id_signature**voters[decrypted_voter_id].public_key)%voters[decrypted_voter_id].modulus;
      uint decrypted_candidate_id = (candidate_id**contract_private_key)%contract_modulus;
      uint decrypted_candidate_signature = (candidate_id_signature**voters[decrypted_voter_id].public_key)%voters[decrypted_voter_id].modulus;
      require(voter_id == decrypted_voter_signature, "Not a valid voter signature.");
      require(candidate_id == decrypted_candidate_signature, "Not a valid voter signature.");
      require(decrypted_voter_id < voter_count && decrypted_voter_id > 1, "Not a valid voter ID.");
      require(voters[decrypted_voter_id].voted == 0, "Voter has already voted.");
      voters[decrypted_voter_id].voted = 1;
      candidates[decrypted_candidate_id].vote_count++;
    }
}
