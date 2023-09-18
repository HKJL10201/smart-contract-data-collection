// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Voting {
    bool startedVote;
    address official;
    address[] registeredVoter;
    mapping(address => bool) alreadyVoted;
    struct Contestant {
        address contestant;
        string name;
        uint64 voteCount;
    }

    Contestant winner;
    Contestant[] registeredContestant;
    Contestant[] voteContestantList;

    error AtLeastTwoCandidateNeeded();
    error VotingStartedAlready();
    error AlreadyVoted();
    error VotingIsYetToStart();
    error NotAContestant();
    error CannotRegisterAddressZero();

    event CollateVote(Contestant indexed);
    event Voted(address indexed __cont, address indexed voter);
    event RegisterContestant(address indexed __cont, string indexed voter);
    event RegisterVoter(address indexed _voter);
    event StartVote(bool indexed status);
    
    constructor() {
        official = msg.sender;
    }

    modifier onlyOfficial() {
        require(
            official == msg.sender,
            "You are not eligible to perform this!"
        );
        _;
    }

    function startVote() external {
        if (registeredContestant.length < 2) {
            revert AtLeastTwoCandidateNeeded();
        }
        if (startedVote) {
            revert VotingStartedAlready();
        }
        startedVote = true;

        emit StartVote(true);
    }

    function registerVoter() external {
        if (startedVote) {
            revert VotingStartedAlready();
        }
        address _voter = msg.sender;

        if (_voter == address(0)) {
            revert CannotRegisterAddressZero();
        }

        bool status = validRegisteredVoter(_voter);

        if (!status) {
            registeredVoter.push(_voter);
        } else {
            revert("Already registered!");
        }

        emit RegisterVoter(_voter);
    }

    function validRegisteredVoter(address _address)
        private
        view
        returns (bool status)
    {
        for (uint256 i = 0; i < registeredVoter.length; i++) {
            if (_address == registeredVoter[i]) {
                status = true;
            } else {
                status = false;
            }
        }
    }

    function registerContestant(address _contestant, string memory _name)
        external
        onlyOfficial
    {
        if (startedVote) {
            revert VotingStartedAlready();
        }

        bool status = validRegisteredContestant(_contestant);
        if (!status) {
            registeredContestant.push(Contestant(_contestant, _name, 0));
        } else {
            revert("Already registered!");
        }

        emit RegisterContestant(_contestant, _name);
    }

    function validRegisteredContestant(address _address)
        private
        view
        returns (bool status)
    {
        for (uint256 i = 0; i < registeredContestant.length; i++) {
            if (_address == registeredContestant[i].contestant) {
                status = true;
            } else {
                status = false;
            }
        }
    }

    function vote(address _contestant) external {
        if (!startedVote) {
            revert VotingIsYetToStart();
        }

        address _voter = msg.sender;
        bool contestantStatus = validRegisteredContestant(_contestant);
        require(contestantStatus, "This address is not a contestant");
        bool status = validRegisteredVoter(_voter);

        if (alreadyVoted[_voter] == true) {
            revert AlreadyVoted();
        }

        if (status) {
            revert NotAContestant();
        }

        alreadyVoted[_voter] = true;

        for (uint256 i = 0; i < voteContestantList.length; i++) {
            if (voteContestantList[i].contestant == _contestant) {
                // incrementing the vote count here
                voteContestantList[i].voteCount++;
            }
        }

        emit Voted(_contestant, _voter);
    }

    function collateResult() external onlyOfficial {
        Contestant memory __cont;

        uint64 winnerCounter;
        for (uint256 i = 0; i < registeredContestant.length; i++) {
            if (winnerCounter < registeredContestant[i].voteCount) {
                winnerCounter = registeredContestant[i].voteCount;
                __cont = registeredContestant[i];
            }
        }

        winner = __cont;

        emit CollateVote(__cont);
    }

    function returnWinner()
        external
        view
        onlyOfficial
        returns (Contestant memory)
    {
        return winner;
    }

    function returnContestants() external view returns (Contestant[] memory) {
        return registeredContestant;
    }

    function returnVoters() external view returns (address[] memory) {
        return registeredVoter;
    }
}
