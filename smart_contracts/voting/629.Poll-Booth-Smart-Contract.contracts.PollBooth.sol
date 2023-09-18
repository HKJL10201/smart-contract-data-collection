pragma solidity >=0.4.22 <0.9.0;

contract PollBooth {
    mapping(string => uint256) votes;

    struct WinningItem {
        string name;
        uint256 votes;
    }
    WinningItem winningItem;

    function voteFor(string memory name) public {
        votes[name]++;

        if (votes[name] > winningItem.votes) {
            winningItem.name = name;
            winningItem.votes = votes[name];
        }
    }

    function getVotesFor(string memory name) public view returns (uint256) {
        return votes[name];
    }

    function getWinner() public view returns (string memory name, uint256) {
        return (winningItem.name, winningItem.votes);
    }
}
