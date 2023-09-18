pragma solidity ^0.5.15;

import "./libraries/SafeMath.sol";

interface KNWVotingContract {
    function addNewRepository(bytes32 _newRepository, uint256 _majority) external returns (bool success);
    function startVote(bytes32 _repository, address _address, uint256 _knowledgeID, uint256 _voteDuration, uint256 _proposersStake, uint256 _numberOfKNW) external returns (uint256 voteID);
    function commitVote(uint256 _voteID, address _address, bytes32 _secretHash, uint256 _numberOfKNW) external returns (uint256 amountOfVotes);
    function openVote(uint256 _voteID, address _address, uint256 _voteOption, uint256 _salt) external returns (bool success);
    function endVote(uint256 _voteID) external returns (bool votePassed);
    function finalizeVote(uint256 _voteID, uint256 _voteOption, address _address) external returns (uint256 reward, bool winningSide, uint256 amountOfKNW);
}

interface KNWTokenContract { 
    function amountOfIDs() external view returns (uint256 amount);
} 

/**
 * @title ditCoordinator
 *
 * @dev Implementation of the ditCoordinator contract, managing dit-enabled
 * repositories. This contract is the point of interaction of the user with
 * the ditCraft ecosystem, as the whole voting process is handled from here.
 */
contract ditCoordinator {
    using SafeMath for uint256;
    
    struct ditRepository {
        string name;
        uint256[] knowledgeIDs;
        uint256 currentProposalID;
        uint256 votingMajority;
    }

    struct proposal {
        string description;
        string identifier;
        uint256 KNWVoteID;
        uint256 knowledgeID;
        address proposer;
        bool isFinalized;
        bool proposalAccepted;
        uint256 individualStake;
        uint256 totalStake;
        mapping (address => voterDetails) participantDetails;
    }

    struct voterDetails {
        uint256 numberOfVotes;
        uint256 numberOfKNW;
        uint256 choice;
        bool hasFinalized;
    }

    address public KNWVotingAddress;
    address public KNWTokenAddress;

    address public lastDitCoordinator;
    address public nextDitCoordinator;

    address public manager;

    KNWVotingContract KNWVote;
    KNWTokenContract KNWToken;

    uint256 constant public MIN_VOTE_DURATION = 1*60; // 1 minute
    uint256 constant public MAX_VOTE_DURATION = 1*7*24*60*60; // 1 week

    uint256 constant public MINTING_METHOD = 0;
    uint256 constant public BURNING_METHOD = 0;

    mapping (bytes32 => ditRepository) public repositories;
    mapping (bytes32 => mapping(uint256 => bool)) public allowedKnowledgeIDs;
    mapping (bytes32 => mapping(uint256 => proposal)) public proposalsOfRepository;
    mapping (address => bool) public passedKYC;
    mapping (address => bool) public isKYCValidator;

    event InitializeRepository(bytes32 indexed repository, address indexed who);
    event ProposeCommit(bytes32 indexed repository, uint256 indexed proposal, address indexed who, uint256 knowledgeID, uint256 numberOfKNW);
    event CommitVote(bytes32 indexed repository, uint256 indexed proposal, address indexed who, uint256 knowledgeID, uint256 stake, uint256 numberOfKNW, uint256 numberOfVotes);
    event OpenVote(bytes32 indexed repository, uint256 indexed proposal, address indexed who, uint256 knowledgeID, bool accept, uint256 numberOfVotes);
    event FinalizeVote(bytes32 indexed repository, uint256 indexed proposal, address indexed who, uint256 knowledgeID, bool votedRight, uint256 numberOfKNW);
    event FinalizeProposal(bytes32 indexed repository, uint256 indexed proposal, uint256 knowledgeID, bool accepted);

    constructor(address _KNWTokenAddress, address _KNWVotingAddress, address _lastDitCoordinator) public {
        require(_KNWVotingAddress != address(0) && _KNWTokenAddress != address(0), "KNWVoting and KNWToken address can't be empty");
        KNWVotingAddress = _KNWVotingAddress;
        KNWVote = KNWVotingContract(KNWVotingAddress);
        KNWTokenAddress = _KNWTokenAddress;
        KNWToken = KNWTokenContract(KNWTokenAddress);

        lastDitCoordinator = _lastDitCoordinator;

        isKYCValidator[msg.sender] = true;
        manager = msg.sender;
    }

    function upgradeContract(address _address) external returns (bool) {
        require(msg.sender == manager);
        require(_address != address(0));
        nextDitCoordinator = _address;
        return true;
    }

    function replaceManager(address _newManager) external returns (bool) {
        require(msg.sender == manager);
        require(_newManager != address(0));
        manager = _newManager;
        return true;
    }

    function passKYC(address _address) external onlyKYCValidator(msg.sender) returns (bool) {
        passedKYC[_address] = true;
        return true;
    }

    function revokeKYC(address _address) external onlyKYCValidator(msg.sender) returns (bool) {
        passedKYC[_address] = false;
        return true;
    }

    function addKYCValidator(address _address) external onlyKYCValidator(msg.sender) returns (bool) {
        isKYCValidator[_address] = true;
        return true;
    }

    function removeKYCValidator(address _address) external onlyKYCValidator(msg.sender) returns (bool) {
        isKYCValidator[_address] = false;
        return true;
    }

    /**
     * @dev Creats a new ditCraft-based repository
     * @param _repository The descriptor of the repository (e.g. keccak256("github.com/example_repo"))
     * @param _knowledgeIDs The knowledge IDs of this repository (see KNWToken)
     * @param _votingMajority The majority needed for a vote to succeed 
     * @return True on success
     */
    function initRepository(string calldata _repository, uint256[] calldata _knowledgeIDs, uint256 _votingMajority) external onlyPassedKYC(msg.sender) returns (bool) {
        require(bytes(_repository).length != 0, "Repository descriptor can't be empty");
        bytes32 _hash = keccak256(abi.encodePacked(_repository));

        require(repositories[_hash].votingMajority == 0, "Repository can only be initialized once");
        require(_votingMajority >= 50, "Voting majority has to be >= 50");
        require(_knowledgeIDs.length > 0, "Provide at least one knowledge ID");
        require(nextDitCoordinator == address(0), "There is a newer contract deployed");

        uint256 highestID = KNWToken.amountOfIDs();
        for(uint256 i = 0; i < _knowledgeIDs.length; i++) {
            require(_knowledgeIDs[i] < highestID, "Invalid Knowledge ID");
            allowedKnowledgeIDs[_hash][_knowledgeIDs[i]] = true;
        }
        
        // Storing the new dit-based repository
        repositories[_hash] = ditRepository({
            name: _repository,
            knowledgeIDs: _knowledgeIDs,
            currentProposalID: 0,
            votingMajority: _votingMajority
        });

        KNWVote.addNewRepository(_hash, _votingMajority);
        
        emit InitializeRepository(_hash, msg.sender);
        
        return true;
    }

    function migrateRepository(string calldata _repository) external onlyPassedKYC(msg.sender) returns (bool) {
        require(lastDitCoordinator != address(0));
        ditCoordinator last = ditCoordinator(lastDitCoordinator);

        require(bytes(_repository).length != 0, "Repository descriptor can't be empty");
        bytes32 _hash = keccak256(abi.encodePacked(_repository));

        uint256 _currentProposalID = last.getCurrentProposalID(_hash);
        uint256 _votingMajority = last.getVotingMajority(_hash);
        uint256[] memory _knowledgeIDs = last.getKnowledgeIDs(_hash);
        uint256 highestID = KNWToken.amountOfIDs();

        for(uint256 i = 0; i < _knowledgeIDs.length; i++) {
            require(_knowledgeIDs[i] < highestID, "Invalid Knowledge ID");
            allowedKnowledgeIDs[_hash][_knowledgeIDs[i]] = true;
        }

        repositories[_hash] = ditRepository({
            name: _repository,
            knowledgeIDs: _knowledgeIDs,
            currentProposalID: _currentProposalID,
            votingMajority: _votingMajority
        });
        
        KNWVote.addNewRepository(_hash, _votingMajority);

        return true;
    }

    /**
     * @dev Gets a ditCraft-based repositories ditContract address
     * @param _repository The descriptor of the repository (e.g. keccak256("github.com/example_repo"))
     * @return A boolean that indicates if the operation was successful
     */
    function repositoryIsInitialized(bytes32 _repository) external view returns (bool) {
        return repositories[_repository].votingMajority > 0;
    }

    // Proposing a new commit for the repository
    function proposeCommit(bytes32 _repository, string calldata _description, string calldata _identifier, uint256 _knowledgeID, uint256 _numberOfKNW, uint256 _voteDuration) external payable onlyPassedKYC(msg.sender) returns (uint256 proposalID) {
        require(msg.value > 0, "Value of the transaction can not be zero");
        require(_voteDuration >= MIN_VOTE_DURATION && _voteDuration <= MAX_VOTE_DURATION, "Vote duration invalid");
        require(bytes(_description).length > 0 && bytes(_identifier).length > 0, "Topic and identifier of proposal can't be empty");
        require(nextDitCoordinator == address(0), "There is a newer contract deployed");
        require(allowedKnowledgeIDs[_repository][_knowledgeID], "Knowledge ID is not correct");
        
        uint256 newProposalID =  repositories[_repository].currentProposalID.add(1);
        repositories[_repository].currentProposalID = newProposalID;

        // Creating a new proposal
        proposalsOfRepository[_repository][newProposalID] = proposal({
            description: _description,
            identifier: _identifier,
            KNWVoteID: KNWVote.startVote(_repository, msg.sender, _knowledgeID, _voteDuration, msg.value, _numberOfKNW),
            knowledgeID: _knowledgeID,
            proposer: msg.sender,
            isFinalized: false,
            proposalAccepted: false,
            individualStake: msg.value,
            totalStake: msg.value
        });

        emit ProposeCommit(_repository, repositories[_repository].currentProposalID, msg.sender, _knowledgeID, _numberOfKNW);
        
        return newProposalID;
    }

    // Casting a vote for a proposed commit
    function voteOnProposal(bytes32 _repository, uint256 _proposalID, bytes32 _voteHash, uint256 _numberOfKNW) external payable onlyPassedKYC(msg.sender) returns (bool) {
        require(msg.value == proposalsOfRepository[_repository][_proposalID].individualStake, "Value of the transaction doesn't match the required stake");
        require(msg.sender != proposalsOfRepository[_repository][_proposalID].proposer, "The proposer is not allowed to vote in a proposal");
        
        // Increasing the total stake of this proposal (necessary for security purposes during the payout)
        proposalsOfRepository[_repository][_proposalID].totalStake = proposalsOfRepository[_repository][_proposalID].totalStake.add(msg.value);

        // The vote contract returns the number of votes that the voter has in this vote (including the KNW influence)
        uint256 numberOfVotes = KNWVote.commitVote(proposalsOfRepository[_repository][_proposalID].KNWVoteID, msg.sender, _voteHash, _numberOfKNW);
        require(numberOfVotes > 0, "Voting contract returned an invalid amount of votes");

        proposalsOfRepository[_repository][_proposalID].participantDetails[msg.sender].numberOfVotes = numberOfVotes;

        emit CommitVote(_repository, _proposalID, msg.sender, proposalsOfRepository[_repository][_proposalID].knowledgeID, msg.value, _numberOfKNW, numberOfVotes);

        return true;
    }

    // Revealing a vote for a proposed commit
    function openVoteOnProposal(bytes32 _repository, uint256 _proposalID, uint256 _voteOption, uint256 _voteSalt) external onlyPassedKYC(msg.sender) returns (bool) {
        KNWVote.openVote(proposalsOfRepository[_repository][_proposalID].KNWVoteID, msg.sender, _voteOption, _voteSalt);
        
        // Saving the option of the voter
        proposalsOfRepository[_repository][_proposalID].participantDetails[msg.sender].choice = _voteOption;
        emit OpenVote(_repository, _proposalID, msg.sender, proposalsOfRepository[_repository][_proposalID].knowledgeID, (_voteOption == 1), proposalsOfRepository[_repository][_proposalID].participantDetails[msg.sender].numberOfVotes);

        return true;
    }

    // Resolving a vote
    // Note: the first caller will automatically resolve the proposal
    function finalizeVote(bytes32 _repository, uint256 _proposalID, address payable _address) external onlyPassedKYC(_address) returns (bool) {
        require(!proposalsOfRepository[_repository][_proposalID].participantDetails[_address].hasFinalized, "Each participant can only finalize once");
        require(proposalsOfRepository[_repository][_proposalID].participantDetails[_address].numberOfVotes > 0 || proposalsOfRepository[_repository][_proposalID].proposer == _address, "Only participants of the vote are able to resolve the vote");

        // If the proposal hasn't been resolved this will be done by the first caller
        if(!proposalsOfRepository[_repository][_proposalID].isFinalized) {
            proposalsOfRepository[_repository][_proposalID].proposalAccepted = KNWVote.endVote(proposalsOfRepository[_repository][_proposalID].KNWVoteID);
            proposalsOfRepository[_repository][_proposalID].isFinalized = true;

            emit FinalizeProposal(_repository, _proposalID, proposalsOfRepository[_repository][_proposalID].knowledgeID, proposalsOfRepository[_repository][_proposalID].proposalAccepted);
        }
        
        // The vote contract returns the amount of ETH that the participant will receive
        (uint256 value, bool votedRight, uint256 numberOfKNW) = KNWVote.finalizeVote(proposalsOfRepository[_repository][_proposalID].KNWVoteID, proposalsOfRepository[_repository][_proposalID].participantDetails[_address].choice, _address);
        
        // If the value is greater than zero, it will be transferred to the caller
        if(value > 0) {
            _address.transfer(value);
        }
        
        proposalsOfRepository[_repository][_proposalID].totalStake = proposalsOfRepository[_repository][_proposalID].totalStake.sub(value);
        proposalsOfRepository[_repository][_proposalID].participantDetails[_address].hasFinalized = true;
     
        emit FinalizeVote(_repository, _proposalID, _address, proposalsOfRepository[_repository][_proposalID].knowledgeID, votedRight, numberOfKNW);

        return true;
    }

    function getIndividualStake(bytes32 _repository, uint256 _proposalID) external view returns (uint256 individualStake) {
        return proposalsOfRepository[_repository][_proposalID].individualStake;
    }

    // Returns whether a proposal has passed or not
    function proposalHasPassed(bytes32 _repository, uint256 _proposalID) external view returns (bool hasPassed) {
        require(proposalsOfRepository[_repository][_proposalID].isFinalized, "Proposal hasn't been resolved");
        return proposalsOfRepository[_repository][_proposalID].proposalAccepted;
    }

    function getKnowledgeIDs(bytes32 _repository) external view returns (uint256[] memory knowledgeIDs) {
        return repositories[_repository].knowledgeIDs;
    }

    function getVotingMajority(bytes32 _repository) external view returns (uint256 votingMajority) {
        return repositories[_repository].votingMajority;
    }

    function getCurrentProposalID(bytes32 _repository) external view returns (uint256 currentProposalID) {
        return repositories[_repository].currentProposalID;
    }

    function getKNWVoteIDFromProposalID(bytes32 _repository, uint256 _proposalID) external view returns (uint256 KNWVoteID) {
        return proposalsOfRepository[_repository][_proposalID].KNWVoteID;
    }

    modifier onlyPassedKYC(address _address) {
        require(passedKYC[_address]);
        _;
    }

    modifier onlyKYCValidator(address _address) {
        require(isKYCValidator[_address]);
        _;
    }
}