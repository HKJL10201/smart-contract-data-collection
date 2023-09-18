pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

contract Voting {

    address owner;
    string winner;
    uint minChoices = 3;
    uint totalChoices = 0;
    uint votesToWin = 11;
    string[] choices;
    mapping (address => bool) voters;
    mapping (string => uint) choiceVotes;


    constructor() public {
        owner = msg.sender;
    }

    function addChoice(string memory name) public {
        require(msg.sender == owner, "Only owner can add choices!");
        require(choiceVotes[name] == 0, "Choice alreay added!");
        /* Solidity does not provide any means to check whether a certain key exists in a mapping. By default, every
           possible key exists in the mapping with its value set to the default for that data type. For ints, this is zero.
           This means by default, all possible choice names already exist with a initial vote count of 0. This is why
           when a new choice is added, its vote count is set to 1 as it signifies that this choice is now part of the voting. */
        choiceVotes[name] += 1;
        totalChoices += 1;
        choices.push(name);
    }

    function vote(string memory choice) public {
        require (totalChoices >= minChoices, "Minimum number of choices have not been added!");
        require (choiceVotes[choice] > 0, "Given choice has not been added by the owner!");
        require (voters[msg.sender] == false, "You have already cast your vote!");
        require (bytes(winner).length == 0, "A winner has already emerged!");

        choiceVotes[choice] += 1;
        voters[msg.sender] = true;

        if (choiceVotes[choice] == votesToWin) {
            winner = choice;
        }
    }

    function getWinner() public view returns (string memory) {
        require(bytes(winner).length > 0, "No winner has emerged so far!");
        return winner;
    }

    function getChoiceVotes(string memory choice) public view returns (uint) {
        return choiceVotes[choice] - 1; // Choices have one vote by default
    }

    function getAllChoices() public view returns (string[] memory) {
        return choices;
    }
}