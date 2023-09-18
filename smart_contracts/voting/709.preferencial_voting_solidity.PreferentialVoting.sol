// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreferentialVoting is Ownable {
    enum VOTING_STATE {
        NOT_STARTED,
        OPEN,
        FINISHED
    }

    struct Voter {
        bool already_voted;
        bool authorized;
        string government_id;
        uint256[] candidate_order;
    }

    struct Candidate {
        string name;
        uint256 satisfaction_points;
    }

    Candidate[] candidates;

    VOTING_STATE public voting_state;

    mapping(address => Voter) voters;

    constructor(string[] memory candidate_names) {
        require(candidate_names.length > 0);

        for (uint i = 0; i < candidate_names.length; i++) {
            candidates.push(
                Candidate({name: candidate_names[i], satisfaction_points: 0})
            );
        }
    }

    function start_voting() public onlyOwner {
        require(voting_state != VOTING_STATE.OPEN, "voting already started");
        voting_state = VOTING_STATE.OPEN;
    }

    function authorize_address_to_vote(
        address authorized_address,
        string memory government_id
    ) public onlyOwner {
        require(voting_state == VOTING_STATE.OPEN, "voting is not open");
        require(
            voters[authorized_address].authorized == false,
            "already authorized"
        );
        uint256[] memory empty_array;
        voters[authorized_address] = Voter({
            already_voted: false,
            authorized: true,
            government_id: government_id,
            candidate_order: empty_array
        });
    }

    function give_voting_points(uint256[] memory candidate_order) internal {
        for (
            uint256 vote_index = 0;
            vote_index < candidate_order.length;
            vote_index++
        ) {
            Candidate storage current_candidate = candidates[
                candidate_order[vote_index]
            ];
            current_candidate.satisfaction_points += vote_index;
        }
    }

    function vote(uint256[] memory candidate_order) public {
        // to be clear, the least prefered candidate is the 1st in the array
        // example [ "least enjoyed candidate", "i dont mind this one", "my favourite"]
        require(voting_state == VOTING_STATE.OPEN, "voting is not open");
        require(candidate_order.length == candidates.length);
        Voter storage current_voter = voters[msg.sender];
        require(current_voter.authorized, "unauthorized to vote");
        require(current_voter.already_voted == false, "already voted");
        for (
            uint256 vote_index = 0;
            vote_index < candidate_order.length;
            vote_index++
        ) {
            require(
                candidate_order[vote_index] < candidates.length,
                "input values do not match the number of candidates"
            );
        }
        current_voter.candidate_order = candidate_order;
        current_voter.already_voted = true;
        give_voting_points(candidate_order);
    }

    function check_my_vote() public view returns (uint256[] memory) {
        require(voters[msg.sender].already_voted, "you have not voted yet");
        return voters[msg.sender].candidate_order;
    }

    function close_voting() public onlyOwner {
        require(voting_state == VOTING_STATE.OPEN, "voting is not open");
        voting_state = VOTING_STATE.FINISHED;
    }

    function get_candidate_names() public view returns (string[] memory) {
        string[] memory candidate_names = new string[](candidates.length);
        for (
            uint256 candidate_index = 0;
            candidate_index < candidates.length;
            candidate_index++
        ) {
            candidate_names[candidate_index] = (
                candidates[candidate_index].name
            );
        }
        return candidate_names;
    }

    function get_results() public view returns (Candidate[] memory) {
        require(
            voting_state == VOTING_STATE.FINISHED,
            "voting is not finished"
        );
        return candidates;
    }
}
