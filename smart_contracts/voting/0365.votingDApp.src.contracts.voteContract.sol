pragma solidity 0.4.26;

contract voteContract {
    mapping(string => uint256) voteCount;
    mapping(address => bool) hasVoted;
    event voteRecorded(address voter, string partyName);

    constructor() public {}

    function getVoteCountOf(string partyName) public view returns (uint256) {
        return voteCount[partyName];
    }

    function vote(string partyName) public payable {
        require(hasVoted[msg.sender] == false);
        voteCount[partyName] += 1;
        hasVoted[msg.sender] = true;
        emit voteRecorded(msg.sender, partyName);
    }

    function getVoteCounts() public view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](4);
        ret[0] = voteCount["BJP"];
        ret[1] = voteCount["AAP"];
        ret[2] = voteCount["Congress"];
        ret[3] = voteCount["NOTA"];
        return ret;
    }
}
