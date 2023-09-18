// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract GroupFund {
    address public admin;
    //all contributors
    address payable[] public participants_array;
    //participants: to check how much each contributor contributed
    mapping(address => uint256) public participants;
    //all addresses that were voted
    address payable[] public participant_votes_array;
    //participant_votes: to check how much votes each player that was voted has
    mapping(address => uint256) public participant_votes;
    //check if an address has voted already
    mapping(address => bool) public participant_has_voted;
    //array of all addresses that won
    address[] public recordOfWinners;

    uint256 public total_number_votes;
    uint256 public total_amount_raised;
    uint256 public required_amount;
    uint256 public id_round;

    constructor() {
        admin = msg.sender;
        required_amount = 20000000000000;
        id_round = 1;
    }

    //adding voter to participants array and populating map for each individual's contribution
    function contribute() public payable {
        require(
            msg.value >= required_amount,
            "Amount paid is less than the minimum amount"
        );
        if (participants[msg.sender] == 0) {
            participants_array.push(payable(msg.sender));
        }
        participants[msg.sender] += msg.value;
        total_amount_raised += msg.value;
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants_array;
    }

    function obtainVoteResults()
        public
        view
        returns (address payable[] memory)
    {
        return participant_votes_array;
    }

    //voting function, also checks if the latest vote finally generates a winner and restarts all data structures
    function voteTaker(address winnerUser) public payable {
        require(
            participants[msg.sender] != 0,
            "The user who's voting didn't contribute to the group fund."
        );

        require(
            participants[winnerUser] != 0,
            "The user who's being voted didn't contribute to the group fund."
        );
        require(
            participant_has_voted[msg.sender] == false,
            "This participant has already voted."
        );
        if (participant_votes[winnerUser] == 0) {
            participant_votes_array.push(payable(winnerUser));
        }
        participant_votes[winnerUser] += 1;
        total_number_votes += 1;
        participant_has_voted[msg.sender] = true;
        // need for votes to be more than half of participants, and more than two participants required
        if (
            participant_votes[winnerUser] > participants_array.length / 2 &&
            participants_array.length > 2
        ) {
            payable(winnerUser).transfer(total_amount_raised);
            recordOfWinners.push(winnerUser);
            total_amount_raised = 0;
            total_number_votes = 0;
            id_round++;
            // reset the maps and arrays
            for (uint256 i = 0; i < participants_array.length; i++) {
                participants[participants_array[i]] = 0;
                participant_has_voted[participants_array[i]] = false;
            }
            for (uint256 j = 0; j < participant_votes_array.length; j++) {
                participant_votes[participant_votes_array[j]] = 0;
            }
            participants_array = new address payable[](0);
            participant_votes_array = new address payable[](0);
        }
    }
}
