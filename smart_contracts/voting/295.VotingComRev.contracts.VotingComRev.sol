// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract VoteComRev {
    enum Stage { Initial, Voting, Revealing, Finished }
    uint32 constant MINIMUM_DURATION = 1 days;

    uint64 immutable votingDeadline;
    address immutable owner;
    uint64 immutable minimumQuorum;
    address public winner;
    address[] candidates;

    mapping(address => bytes32) private _commits;
    mapping(address => uint256) public votesCount;
    mapping(address => bool) public isCandidate;

    uint64 private _commitsCount;
    uint64 private _revealCount;

    Stage stage = Stage.Initial;

    constructor(uint64 votingDeadline_, uint8 minimumQuorum_) {
        require(
            votingDeadline_ >= block.timestamp + MINIMUM_DURATION, "Wrong deadline");

        owner = msg.sender;
        votingDeadline = votingDeadline_;
        minimumQuorum = minimumQuorum_;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner!");
        _;
    }

    modifier onlyStage(Stage stage_) {
        require(stage == stage_, "Wrong stage!");
        _;
    }

    function addCandidate(address candidate_)
        external onlyOwner onlyStage(Stage.Initial) {
            require(candidate_ != address(0), "Zero address!");
            require(!isCandidate[candidate_], "Is already candidate!");

            candidates.push(candidate_);
            isCandidate[candidate_] = true;
    }

    function nextStage() external onlyOwner {
        incrementStage();
    }

    function incrementStage() internal {
        uint current = uint(stage);

        if (current == 1
            && block.timestamp < votingDeadline
            && _commitsCount < minimumQuorum) {
                revert("Can't end voting!");
        } 

        if (current == 2 && _revealCount < minimumQuorum) {
            revert("Can't end revealing!");
        }

        stage = Stage(++current);
    }



    function vote(bytes32 hiddenVote_)
        external onlyStage(Stage.Voting) {
            require(_commits[msg.sender] != 0, "Cannot vote again!");

            _commits[msg.sender] = hiddenVote_;
            _commitsCount++;
    }

    function reveal(address candidate_, string calldata secret_)
        external onlyStage(Stage.Revealing) {
            require(_commits[msg.sender] != 0, "Not voted!");
            require(isCandidate[candidate_], "Is not candidate!");

            require(
                _commits[msg.sender] == keccak256(
                    abi.encodePacked(candidate_, msg.sender, secret_)
                    ), "Wrong reveal or secret!"
            );

            delete _commits[msg.sender];
            
            votesCount[candidate_] += 1;
            _revealCount++;
    }

    function determineWinner() external onlyStage(Stage.Revealing) {
        address _winner;

        for(uint i; i < candidates.length; i++) {
            if(votesCount[candidates[i]] > votesCount[_winner]) {
                _winner = candidates[i];
            }
        }

        incrementStage();
        winner = _winner;
    }


}