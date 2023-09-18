// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Errors
error Vote__OnlyOwnerCanCallThisFunction();
error Vote__VoterAlreadyRegistered();
error Vote__VoterInformationMissing();
error Vote__CandidateAlreadyRegistered();
error Vote__CandidateInformationMissing();
error Vote__YouAlreadyVoted();
error Vote__YouAreNotARegisteredVoter();
error Vote__CandidateAddressDoesntExist();

contract Vote {
    // voters have to register
    // they can register only once (one address)
    // they will have a special voting number
    // only one candidate/address
    // candidates have to have a number
    // function to vote to a candidate
    // function to choose a winner with most votes

    // State variables
    struct Voter {
        address voterAddress;
        string voterName;
        uint256 voterIdNumber;
        uint256 voterNumber;
        bool voted;
    }

    struct Candidate {
        address candidateAddress;
        string candidateName;
        uint256 candidateNumber;
        uint256 votes;
    }

    address[] private voters;
    address[] private candidates;
    address private owner;
    uint256 private voterCurrentNumber = 1;
    uint256 numberOfVotes;
    uint256 winnerCandidateVotes;
    address winnerCandidateAddress;
    string winnerCandidateName;
    mapping(address => Voter) voterAddressToVoter;
    mapping(address => Candidate) candidateAddressToCandidate;

    // Functions
    constructor() {
        owner = msg.sender;
    }

    function registerVoter(string memory _voterName, uint256 _voterIdNumber) public {
        if (voterAddressToVoter[msg.sender].voterAddress == msg.sender) {
            revert Vote__VoterAlreadyRegistered();
        }
        bytes memory checkString = bytes(_voterName);
        if (checkString.length == 0 || _voterIdNumber == 0) {
            revert Vote__VoterInformationMissing();
        }
        voterAddressToVoter[msg.sender].voterAddress = msg.sender;
        voterAddressToVoter[msg.sender].voterName = _voterName;
        voterAddressToVoter[msg.sender].voterIdNumber = _voterIdNumber;
        voterAddressToVoter[msg.sender].voterNumber = voterCurrentNumber++;
        voterAddressToVoter[msg.sender].voted = false;
        voters.push(msg.sender);
    }

    function registerCandidate(
        address _candidateAddress,
        string memory _candidateName,
        uint256 _candidateNumber
    ) public {
        if (msg.sender != owner) {
            revert Vote__OnlyOwnerCanCallThisFunction();
        }
        if (candidateAddressToCandidate[_candidateAddress].candidateAddress == _candidateAddress) {
            revert Vote__CandidateAlreadyRegistered();
        }
        if (_candidateNumber == 0) {
            revert Vote__CandidateInformationMissing();
        }
        candidateAddressToCandidate[_candidateAddress].candidateAddress = _candidateAddress;
        candidateAddressToCandidate[_candidateAddress].candidateName = _candidateName;
        candidateAddressToCandidate[_candidateAddress].candidateNumber = _candidateNumber;
        candidateAddressToCandidate[_candidateAddress].votes = 0;
        candidates.push(_candidateAddress);
    }

    function voteToCandidate(address _candidateAddress) public {
        if (voterAddressToVoter[msg.sender].voterNumber == 0) {
            revert Vote__YouAreNotARegisteredVoter();
        }
        if (voterAddressToVoter[msg.sender].voted == true) {
            revert Vote__YouAlreadyVoted();
        }
        if (candidateAddressToCandidate[_candidateAddress].candidateAddress != _candidateAddress) {
            revert Vote__CandidateAddressDoesntExist();
        }
        candidateAddressToCandidate[_candidateAddress].votes++;
        voterAddressToVoter[msg.sender].voted = true;
        numberOfVotes++;
    }

    function pickWinnerCandidate() public returns (uint256, address, string memory) {
        if (msg.sender != owner) {
            revert Vote__OnlyOwnerCanCallThisFunction();
        }
        uint256 winnerVotes;
        address winnerAddress;
        string memory winnerName;
        for (uint256 candidatesIndex = 0; candidatesIndex < candidates.length; candidatesIndex++) {
            address candidatesAddress = candidates[candidatesIndex];
            uint256 candidateVotes = candidateAddressToCandidate[candidatesAddress].votes;
            string memory candidateName = candidateAddressToCandidate[candidatesAddress]
                .candidateName;
            if (candidateVotes > winnerVotes) {
                winnerVotes = candidateVotes;
                winnerAddress = candidatesAddress;
                winnerName = candidateName;
            }
        }
        winnerCandidateVotes = winnerVotes;
        winnerCandidateAddress = winnerAddress;
        winnerCandidateName = winnerName;
        return (winnerVotes, winnerAddress, winnerName);
    }

    // Getter functions
    function getCandidate(
        uint256 _candidateIndex
    ) public view returns (address, string memory, uint256, uint256) {
        address candidateAddress = candidates[_candidateIndex];
        string memory candidateName = candidateAddressToCandidate[candidateAddress].candidateName;
        uint256 candidateNumber = candidateAddressToCandidate[candidateAddress].candidateNumber;
        uint256 candidateVotes = candidateAddressToCandidate[candidateAddress].votes;
        return (candidateAddress, candidateName, candidateNumber, candidateVotes);
    }

    function getNumberOfCandidates() public view returns (uint256) {
        return candidates.length;
    }

    function getVoters(uint256 _voterIndex) public view returns (address) {
        return voters[_voterIndex];
    }

    function getNumberOfVoters() public view returns (uint256) {
        return voters.length;
    }

    function getVoterNumber(address _votersAddress) public view returns (uint256) {
        return voterAddressToVoter[_votersAddress].voterNumber;
    }

    function getVoterStatus(address _votersAddress) public view returns (bool) {
        return voterAddressToVoter[_votersAddress].voted;
    }

    function getWinnerCandidate() public view returns (uint256, address, string memory) {
        return (winnerCandidateVotes, winnerCandidateAddress, winnerCandidateName);
    }
}
