// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./BallotInterface.sol";
import "./utils/Ownable.sol";
import "./utils/Helpers.sol";

contract Ballot is Ownable, BallotInterface, Helper {
    uint256 public electionDuration;
    uint256 public startTime;
    struct Voter {
        uint256 age;
        bool voted;
        bool votable;
    }

    struct Contestant {
        uint256 id;
        string name;
        string party;
        uint256 votesCount;
    }

    mapping(uint256 => Contestant) public contestants;
    uint256 public contestantCount;

    mapping(address => Voter) public voters;
    string public electionName;

    constructor(string memory _electionName, uint256 _electionDuration) {
        electionName = _electionName;
        electionDuration = _electionDuration;
        startTime = block.timestamp;
        addContestant("Gift Opia", "SLN");
        addContestant("Buhari Mohammed", "APC");
        addContestant("Atiku Abubakarr", "PDP");
    }

    function addContestant(string memory _name, string memory _party)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        contestantCount++;
        contestants[contestantCount] = Contestant(
            contestantCount,
            _name,
            _party,
            0
        );
        return true;
    }

    function getContestant(uint256 _id) view public returns(uint256, string memory, string memory) {
        return(contestants[_id].id, contestants[_id].name, contestants[_id].party);
    }

    function authorizeVoter(address person)
        public
        virtual
        override
        onlyOwner
        returns (bool)
    {
        voters[person].votable = true;
        return true;
    }

    function vote(uint256 contestantId, uint256 _age)
        public
        virtual
        override
        Votable(_age)
        returns (bool)
    {
        require(!voters[msg.sender].voted, "You can only vote once!");
        require(voters[msg.sender].votable, "Unauthorized");
        require(contestants[contestantId].id == contestantId, "Contestant doesn't exist");

        voters[msg.sender].voted = true;
        contestants[contestantId].votesCount++;

        emit Vote(contestantId);

        return true;
    }

    function end() public virtual override onlyOwner {
        require(
            startTime + electionDuration > block.timestamp,
            "The election is still ongoing"
        );

        for (uint256 i = 0; i < contestantCount; i++) {
            emit RevealResult(contestants[i].name, contestants[i].votesCount);
        }
    }
}
