pragma solidity >=0.4.22 <0.9.0;

interface BallotInterface {
    function addContestant(string memory _name, string memory _party)
        external
        returns (bool);

    function getContestant(uint256 _id) external returns(uint256, string memory, string memory);

    function authorizeVoter(address person) external returns (bool);

    function vote(uint256 contestantId, uint256 _age) external returns (bool);

    function end() external;

    // Events
    event Vote(uint256 indexed contestantId);
    event RevealResult(
        string indexed contestantName,
        uint256 contestantVotesCount
    );
}
