//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Imports
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Custom Errors

error DecentraVote__UpKeepNotNeeded(
    uint256 campaignState,
    uint256 candidateNumber
);

/// @title DecentraVote
/// @author Nilesh Nath
/// @dev This contract uses chainlink automation to automatically pick the winner
///       of the election , The winner will be the one with the highest vote count !

contract DecentraVote is AutomationCompatibleInterface {
    // Structures

    struct Candidate {
        string candidateName;
        address candidateAddress;
        uint256 voteCount;
        string candidateImage;
        string partyName;
    }

    struct Voter {
        bool isVoted;
        bool isEligible;
        address votedTo;
    }

    struct Winner {
        string candidateName;
        address candidateAddress;
        uint256 voteCount;
        string candidateImage;
        string partyName;
    }

    // States of the Campaign : Users are not allowed to vote when campaign is in close state....

    enum campaignStates {
        OPEN,
        CLOSE
    }

    //State Variables

    Candidate[] private s_candidates;
    mapping(address => Voter) private s_voter;
    uint256 private s_totalVotes;
    string private s_votingName;
    address private immutable i_owner;
    campaignStates private s_campaignState;
    uint256 private highestVote;
    address private s_winner;
    string private s_winnerName;
    Winner public winnerInfo;

    address[] private s_votedAddresses; //  state variable to track the addresses of voters who voted during the previous campaign

    //Chainlink Keepers Variables
    uint256 private immutable i_interval;
    uint256 private initialTime;

    // Events
    event candidateAdded(string indexed name, address indexed candidateAddress);
    event voterRegistered(address indexed voter);
    event voted(address indexed voter, address indexed candidate);
    event gotWinner(address indexed winner, string indexed winnerName);

    // Constructor

    constructor(string memory _name, uint256 interval) {
        s_votingName = _name;
        s_totalVotes = 0;
        i_owner = msg.sender;
        i_interval = interval;
        initialTime = block.timestamp;
        highestVote = 0;
    }

    // Modifiers

    modifier onlyOwner() {
        require(
            msg.sender == i_owner,
            "Sorry ! Only Owner is allowed to access this :("
        );
        _;
    }

    // Main Functions

    //// Add candidates , It stores the credentials of the candidates in a dynamic array

    function addCandidates(
        string memory _name,
        address candidateAddress,
        string memory _candidateImage,
        string memory _partyName
    ) public onlyOwner {
        require(s_campaignState == campaignStates.OPEN, "Campaign is close !");

        s_candidates.push(
            Candidate(_name, candidateAddress, 0, _candidateImage, _partyName)
        );
        emit candidateAdded(_name, candidateAddress);
    }

    function registerVoter(uint256 _age, string memory nationality) public {
        require(_age >= 18, "Age should be greater than 18 !");

        require(
            keccak256(bytes(nationality)) == keccak256(bytes("nepali")) ||
                keccak256(bytes(nationality)) == keccak256(bytes("nepalese")),
            "Sorry, only Nepalese are allowed to vote !"
        );

        require(!s_voter[msg.sender].isVoted, "Already voted!");

        s_voter[msg.sender].isEligible = true;
        emit voterRegistered(msg.sender);
    }

    function vote(address candidate) public {
        require(s_voter[msg.sender].isEligible, "Register before voting!");

        require(!s_voter[msg.sender].isVoted, "Already voted!");

        require(s_campaignState == campaignStates.OPEN, "Campaign is close !");

        s_voter[msg.sender].isVoted = true;
        s_totalVotes += 1;
        s_voter[msg.sender].votedTo = candidate;

        // Add voter's address to the s_votedAddresses array
        s_votedAddresses.push(msg.sender);

        for (uint256 i = 0; i < s_candidates.length; i++) {
            if (s_candidates[i].candidateAddress == candidate) {
                s_candidates[i].voteCount += 1;
            }
        }

        emit voted(msg.sender, candidate);
    }

    function resetVoters() internal onlyOwner {
        for (uint256 i = 0; i < s_votedAddresses.length; i++) {
            address voterAddress = s_votedAddresses[i];
            s_voter[voterAddress].isVoted = false;
            s_voter[voterAddress].isEligible = false;
        }
        delete s_votedAddresses; // Clear the s_votedAddresses array after resetting the voter status
    }

    // Chainlink Keepers Implementation

    /**
     *  Consitions to met :
     *  1.Campaign should be in Open State
     *  2.There are atleast one Candidate
     *  3.Timestamp reached
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (s_campaignState == campaignStates.OPEN);
        bool hasCandidates = (s_candidates.length > 0);
        bool isTime = (block.timestamp - initialTime) > i_interval;
        upkeepNeeded = (isOpen && hasCandidates && isTime);
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert DecentraVote__UpKeepNotNeeded(
                uint256(s_campaignState),
                s_candidates.length
            );
        }

        s_campaignState = campaignStates.CLOSE;

        // Reset highestVote to 0 before determining the new winner
        highestVote = 0;

        for (uint256 i = 0; i < s_candidates.length; i++) {
            if (s_candidates[i].voteCount >= highestVote) {
                highestVote = s_candidates[i].voteCount;

                // Update the winnerInfo struct
                winnerInfo.candidateName = s_candidates[i].candidateName;
                winnerInfo.candidateAddress = s_candidates[i].candidateAddress;
                winnerInfo.voteCount = s_candidates[i].voteCount;
                winnerInfo.candidateImage = s_candidates[i].candidateImage;
                winnerInfo.partyName = s_candidates[i].partyName;
            }
        }

        // Clear the s_candidates array
        delete s_candidates;

        emit gotWinner(s_winner, s_winnerName);
    }

    function openCampaign() public onlyOwner {
        require(
            s_campaignState == campaignStates.CLOSE,
            "Campaign is already Open!"
        );

        s_campaignState = campaignStates.OPEN;

        initialTime = block.timestamp; // Update initialTime to the current timestamp

        // Reset voter status for all participants who voted in the previous campaign
        // Resetting this is necessary to insure one have right to vote again when the campaign is reOpened.
        resetVoters();
    }

    // Getters

    function getEligibility(address voter) public view returns (bool) {
        return s_voter[voter].isEligible;
    }

    function getVotedTo(address voter) public view returns (address) {
        return s_voter[voter].votedTo;
    }

    function getCondidates() public view returns (Candidate[] memory) {
        return s_candidates;
    }

    function getTotalVotes() public view returns (uint256) {
        return s_totalVotes;
    }

    function getCampaignName() public view returns (string memory) {
        return s_votingName;
    }

    function getWinnerCandidate() public view returns (Winner memory) {
        return winnerInfo;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getInitialTime() public view returns (uint256) {
        return initialTime;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getCampaignState() public view returns (campaignStates) {
        return s_campaignState;
    }

    function getHighestVote() public view returns (uint256) {
        return highestVote;
    }
}
