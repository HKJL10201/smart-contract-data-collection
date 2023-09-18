pragma solidity ^0.8.18;

contract SimpleVoting {
    address private owner;

    string[] candidates = ["Joe", "Trump"];
    mapping(string => uint256) voteCount;
    bool votingOpen = true;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can call this function."
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function vote(string calldata _vote) public {
        if (votingOpen) {
            if (valueExists(candidates, _vote)) {
                voteCount[_vote]++;
            }
        }
    }

    function getVoteCount(string calldata candidate)
        public
        view
        returns (uint256)
    {
        return voteCount[candidate];
    }

    function closeVoting() public onlyOwner {
        votingOpen = false;
    }

    function openVoting() public onlyOwner {
        votingOpen = true;
    }

    function valueExists(string[] memory candidateList, string memory _vote)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < candidateList.length; i++) {
            if (keccak256(bytes(candidateList[i])) == keccak256(bytes(_vote))) {
                return true;
            }
        }
        return false;
    }
}
