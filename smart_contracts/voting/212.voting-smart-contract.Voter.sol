pragma solidity ^0.8.4;

contract Voter {
    struct OptionPos {
        uint256 pos;
        bool exists;
    }

    uint256[] public votes;
    string[] public options;
    mapping(address => bool) hasVoted;
    mapping(string => OptionPos) posOfOption;

    constructor(string[] memory _options) {
        options = _options;
        for (uint256 i = 0; i < _options.length; i++) {
            votes.push();
        }

        for (uint256 i = 0; i < options.length; i++) {
            OptionPos memory option = OptionPos(i, true);
            string memory optionName = options[i];
            posOfOption[optionName] = option;
        }
    }

    function addOption(string memory option) public {
        options.push(option);
    }

    function vote(uint256 option) public {
        require(0 <= option && option < options.length, "Invalid option!");
        require(!hasVoted[msg.sender], "Account has already voted!");
        votes[option] = votes[option] + 1;
        hasVoted[msg.sender] = true;
    }

    function vote(string memory optionName) public {
        require(!hasVoted[msg.sender], "Account has already voted!");

        OptionPos memory optionPos = posOfOption[optionName];
        require(optionPos.exists, "Option does not exist!");

        votes[optionPos.pos] = votes[optionPos.pos] + 1;
        hasVoted[msg.sender] = true;
    }

    function getOptions() public view returns (string[] memory) {
        return options;
    }

    function getVotes() public view returns (uint256[] memory) {
        return votes;
    }
}
