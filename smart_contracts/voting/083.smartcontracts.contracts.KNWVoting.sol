pragma solidity ^0.5.15;

import "./libraries/SafeMath.sol";

interface KNWTokenContract {
    function balanceOfID(address _address, uint256 _id) external view returns (uint256 balance);
    function freeBalanceOfID(address _address, uint256 _id) external view returns (uint256 freeBalance);
    function lockTokens(address _address, uint256 _id, uint256 _amount) external returns (bool success);
    function unlockTokens(address _address, uint256 _id, uint256 _amount) external returns (bool success);
    function mint(address _address, uint256 _id, uint256 _amount) external returns (bool success);
    function burn(address _address, uint256 _id, uint256 _amount) external returns (bool success);
}

/**
 * @title Knowledge-extractable voting
 *
 * @dev Implementation of the knowledge-extractable voting contract. It handles votes on yay/nay topics
 * and uses KNW tokens to further assign weight to the individuals opinion based on his/her knowledge
 * token balance.
 */
contract KNWVoting {
    using SafeMath for uint;

    struct KNWVote {
        bytes32 repository;             // Initiating ditContract
        uint256 knowledgeID;            // Knowledge ID that will be used
        uint256 commitEndDate;          // End-Timestamp of the commit phase
        uint256 openEndDate;            // End-Timestamp of the reveal phase
        uint256 neededMajority;         // Percent needed in order to pass
        uint256 winningPercentage;      // After the vote: percentage of the winning side
        uint256 votesFor;               // Votes in favor of the proposal
        uint256 votesAgainst;           // Votes against the proposal
        uint256 votesUnrevealed;        // Votes that haven't been revealed yet
        uint256 participantsFor;        // Participants who votes for the proposal 
        uint256 participantsAgainst;    // Participants who votes against the proposal 
        uint256 participantsUnrevealed; // Participants who haven't revealed their yet
        bool isResolved;                // Inidicating whether the vote has been resolved (finished) yet
        mapping(address => Participant) participant;
    }

    struct Stake {
        uint256 proposersStake;     // Stake of the proposer that will be the limit of the voters stakes
        uint256 proposersReward;    // Calculated end-reward of the proposer
        uint256 returnPool;         // Pool of ETH that will be returned to the voting participants
        uint256 rewardPool;         // Pool of ETH that will be rewarded to the voting participants on the winning side
    } 

    struct Participant {
        bool didCommitVote;     // Inidicates whether a participant has commited a vote
        bool didOpenVote;       // Inidicates whether a participant has revealed his vote
        bool isProposer;        // Inidicates whether a participant is the proposer of this vote
        uint256 usedKNW;        // Count of KNW that a participant uses in this vote
        uint256 percentOfKNW;   // Percent of KNW that a user is currently using
        uint256 numberOfVotes;  // Count of votes that a participant has in this vote
        uint256 voteHash;       // The hashed vote of a participant
    }

    // repositories that are interacting with this contract are stored in this struct
    // with their corresponding settings
    struct ditRepositorySettings {
        uint256 majority;
    }

    // addresses of the dit Coordinator contract(s)
    mapping(address => bool) public ditCoordinatorContracts;

    // maps the addresses of contracts that are allowed to call this contracts functions
    mapping (bytes32 => ditRepositorySettings) ditRepositories;

    // address of the dit Manager
    address public manager;

    // addresses of the last and next contract versions
    address public lastKNWVoting;
    address public nextKNWVoting;

    // address of the KNWToken Contract
    address public KNWTokenAddress;

    // KNWToken Contract
    KNWTokenContract token;

    // used methods for minting and burning (currently standard)
    uint256 constant public MINTING_METHOD = 0;
    uint256 constant public BURNING_METHOD = 0;

    // nonce of the current vote
    uint256 public currentVoteID;

    // nonce of the first vote that is being handles by this contract
    uint256 public startingVoteID;

    // maps a voteID to the vote struct
    mapping(uint256 => KNWVote) public votes;

    // maps a voteID to its stake struct
    mapping(uint256 => Stake) public stakesOfVote; 

    constructor(address _KNWTokenAddress, address _lastKNWVoting) public {
        require(_KNWTokenAddress != address(0), "KNWToken address can't be empty");
        KNWTokenAddress = _KNWTokenAddress;
        token = KNWTokenContract(KNWTokenAddress);

        if(_lastKNWVoting != address(0)) {
            lastKNWVoting = _lastKNWVoting;
            KNWVoting lastContract = KNWVoting(lastKNWVoting);
            currentVoteID = lastContract.currentVoteID();
        } else {
            currentVoteID = 0;
        }
        startingVoteID = currentVoteID;

        manager = msg.sender;
    }

    function upgradeContract(address _address) external returns (bool success) {
        require(msg.sender == manager);
        require(_address != address(0));
        nextKNWVoting = _address;
        return true;
    }

    function replaceManager(address _newManager) external returns (bool success) {
        require(msg.sender == manager);
        require(_newManager != address(0));
        manager = _newManager;
        return true;
    }

    // Adding an address of a new ditCoordinator contract
    function addDitCoordinator(address _newDitCoordinatorAddress) external returns (bool success) {
        require(msg.sender == manager, "Only the manager can call this");
        require(_newDitCoordinatorAddress != address(0), "ditCoordinator address can only be added if it's not empty");
        ditCoordinatorContracts[_newDitCoordinatorAddress] = true;
        return true;
    }

    // Adding a new ditRepositories address that will be allowed to use this contract    
    function addNewRepository(bytes32 _newRepository, uint256 _majority) external calledByDitCoordinator(msg.sender) returns (bool success) {
        ditRepositories[_newRepository].majority = _majority;
        return true;
    }

    // Starts a new vote
    function startVote(bytes32 _repository, address _address, uint256 _knowledgeID, uint256 _voteDuration, uint256 _proposersStake, uint256 _numberOfKNW) external calledByDitCoordinator(msg.sender) returns (uint256 voteID) {
        currentVoteID = currentVoteID.add(1);

        // Creating a new vote
        votes[currentVoteID] = KNWVote({
            repository: _repository,
            knowledgeID: _knowledgeID,
            commitEndDate: block.timestamp.add(_voteDuration),
            openEndDate: block.timestamp.add(_voteDuration).add(_voteDuration),
            neededMajority: ditRepositories[_repository].majority,
            votesFor: 0,
            votesAgainst: 0,
            votesUnrevealed: 0,
            winningPercentage: 0,
            participantsFor: 0,
            participantsAgainst: 0,
            participantsUnrevealed: 0,
            isResolved: false
        });

        stakesOfVote[currentVoteID] = Stake({
            proposersStake: _proposersStake,
            proposersReward: 0,
            returnPool: 0,
            rewardPool: 0
        });
        
        uint256 freeBalance = token.freeBalanceOfID(_address, _knowledgeID);

        // Locking and storing the amount of KNW that the proposer has for this label
        require(token.lockTokens(_address, _knowledgeID, _numberOfKNW));
        votes[currentVoteID].participant[_address].usedKNW = _numberOfKNW;
        votes[currentVoteID].participant[_address].isProposer = true;

        if (freeBalance == _numberOfKNW) {
             votes[currentVoteID].participant[_address].percentOfKNW = 100;
        } else if(freeBalance > 0) {
            votes[currentVoteID].participant[_address].percentOfKNW = (_numberOfKNW.mul(100)).div(freeBalance);
        }
        
        require(votes[currentVoteID].participant[_address].percentOfKNW >= 1, "Can't start a vote without using any KNW");
        
        return currentVoteID;
    }

    // Commits a vote using hash of choice and secret salt to conceal vote until reveal
    function commitVote(uint256 _voteID, address _address, bytes32 _secretHash, uint256 _numberOfKNW) external calledByDitCoordinator(msg.sender) returns (uint256 numberOfVotes) {
        require(_voteID != 0, "voteID can't be zero");
        require(commitPeriodActive(_voteID), "Commit period has to be active");
        require(!didCommit(_address, _voteID), "Can't commit more than one vote");

        // Preventing participants from committing a secretHash of 0
        require(_secretHash != 0, "Can't vote with a zero hash");

        // msg.value of the callers vote transaction was checked in the calling ditContract
        numberOfVotes = stakesOfVote[_voteID].proposersStake;
        
        uint256 freeBalance = token.freeBalanceOfID(_address, votes[currentVoteID].knowledgeID);

        // Returns the amount of free KNWTokens that are now used and locked for this vote
        require(token.lockTokens(_address, votes[_voteID].knowledgeID, _numberOfKNW));
        votes[_voteID].participant[_address].usedKNW = _numberOfKNW;
        if (freeBalance == _numberOfKNW) {
             votes[_voteID].participant[_address].percentOfKNW = 100;
        } else if(freeBalance > 0) {
            votes[_voteID].participant[_address].percentOfKNW = (_numberOfKNW.mul(100)).div(freeBalance);
        }
        
        require(votes[currentVoteID].participant[_address].percentOfKNW >= 1, "Can't vote without using any KNW");

        // Calculation of vote weight due to KNW influence
        // Vote_Weight = Vote_Weight  + (Vote_Weight * KNW_Balance)
        // Note: If KNW_Balance is > 1 the square-root of usedKNW will be used
        // If KNW_Balance is <= 1 the untouched KNW_Balance will be used
        uint256 sqrtOfKNW = (_numberOfKNW.div(10**12)).sqrt();
        if(sqrtOfKNW >= _numberOfKNW.div(10**15)) {
            sqrtOfKNW = _numberOfKNW.div(10**15);
        }
        numberOfVotes = numberOfVotes.add((sqrtOfKNW.mul(numberOfVotes)).div(10**3));

        votes[_voteID].participant[_address].numberOfVotes = numberOfVotes;
        votes[_voteID].participant[_address].voteHash = uint256(_secretHash);
        votes[_voteID].participant[_address].didCommitVote = true;

        // Adding the number of tokens and votes to the count of unrevealed tokens and votes
        votes[_voteID].votesUnrevealed = votes[_voteID].votesUnrevealed.add(numberOfVotes);
        votes[_voteID].participantsUnrevealed = votes[_voteID].participantsUnrevealed.add(1);
        
        return numberOfVotes;
    }

    // Reveals the vote with the option and the salt used to generate the voteHash
    function openVote(uint256 _voteID, address _address, uint256 _voteOption, uint256 _salt) external calledByDitCoordinator(msg.sender) returns (bool success) {
        require(openPeriodActive(_voteID), "Reveal period has to be active");
        require(votes[_voteID].participant[_address].didCommitVote, "Participant has to have a vote commited");
        require(!votes[_voteID].participant[_address].didOpenVote, "Can't reveal a vote more than once");

        // Comparing the commited hash with the one that is calculated from option and salt
        require(keccak256(abi.encodePacked(_voteOption, _salt)) == bytes32(votes[_voteID].participant[_address].voteHash), "Choice and Salt have to be the same as in the votehash");

        uint256 numberOfVotes = votes[_voteID].participant[_address].numberOfVotes;

        // remove the participants tokens from the unrevealed tokens
        votes[_voteID].votesUnrevealed = votes[_voteID].votesUnrevealed.sub(numberOfVotes);
        votes[_voteID].participantsUnrevealed = votes[_voteID].participantsUnrevealed.sub(1);
        
        // add the tokens to the according counter
        if (_voteOption == 1) {
            votes[_voteID].votesFor = votes[_voteID].votesFor.add(numberOfVotes);
            votes[_voteID].participantsFor = votes[_voteID].participantsFor.add(1);
        } else {
            votes[_voteID].votesAgainst = votes[_voteID].votesAgainst.add(numberOfVotes);
            votes[_voteID].participantsAgainst = votes[_voteID].participantsAgainst.add(1);
        }

        votes[_voteID].participant[_address].didOpenVote = true;
        
        return true;
    }

    // Resolves a vote and calculates the outcome
    function endVote(uint256 _voteID) external calledByDitCoordinator(msg.sender) returns (bool votePassed) {
        require(voteEnded(_voteID), "Poll has to have ended");

        uint256 totalVotes = votes[_voteID].votesFor.add(votes[_voteID].votesAgainst);
        uint256 participants = votes[_voteID].participantsAgainst.add(votes[_voteID].participantsFor).add(votes[_voteID].participantsUnrevealed);
        
        // In case of no participants we define the reward directly to prevent division by zero (participants)
        if(participants == 0) {
            stakesOfVote[_voteID].proposersReward = stakesOfVote[_voteID].proposersStake;
            votes[_voteID].winningPercentage = 0;
            votes[_voteID].isResolved = true;
            return false;
        }

        // The return pool is the amount of ETH that will be returned to the participants
        stakesOfVote[_voteID].returnPool = participants.mul(stakesOfVote[_voteID].proposersStake.sub((stakesOfVote[_voteID].proposersStake.div(participants))));

        uint256 opposingVoters = 0;
        votePassed = isPassed(_voteID);

        if(votePassed) {
            // If the vote passed, the netStake of the opposing and unrevealed voters will be added to the reward pool
            votes[_voteID].winningPercentage = votes[_voteID].votesFor.mul(100).div(totalVotes);
            opposingVoters = votes[_voteID].participantsAgainst.add(votes[_voteID].participantsUnrevealed);
            stakesOfVote[_voteID].proposersReward = stakesOfVote[_voteID].proposersStake;
        } else {
            if(votes[_voteID].votesFor != votes[_voteID].votesAgainst) {
                // If the vote didn't pass, the netStake of the opposing and unrevealed voters will be added to the reward pool
                votes[_voteID].winningPercentage = votes[_voteID].votesAgainst.mul(100).div(totalVotes);
                opposingVoters = votes[_voteID].participantsFor.add(votes[_voteID].participantsUnrevealed);
                
                // Adding the proposers stake to the reward pool
                stakesOfVote[_voteID].rewardPool = stakesOfVote[_voteID].proposersStake;
            } else {
                // If the vote ended in a draw, the netStake of the unrevealed voters will be added to the reward pool
                votes[_voteID].winningPercentage = 50;                 
                opposingVoters = votes[_voteID].participantsUnrevealed;
                stakesOfVote[_voteID].proposersReward = stakesOfVote[_voteID].proposersStake;
            }
        }
        
        if(stakesOfVote[_voteID].returnPool > 0) {
            stakesOfVote[_voteID].rewardPool = stakesOfVote[_voteID].rewardPool.add((opposingVoters.mul((stakesOfVote[_voteID].proposersStake.sub((stakesOfVote[_voteID].returnPool.div(participants)))))));
        }
        
        votes[_voteID].isResolved = true;
        
        // In case of a passed vote or a draw, the proposer will also get a share of the reward
        if(stakesOfVote[_voteID].proposersReward > 0) {
            uint256 winnersReward = stakesOfVote[_voteID].rewardPool.div(((participants.sub(opposingVoters)).add(1)));
            stakesOfVote[_voteID].proposersReward = stakesOfVote[_voteID].proposersReward.add(winnersReward);
            stakesOfVote[_voteID].rewardPool = stakesOfVote[_voteID].rewardPool.sub(winnersReward);
        }
        
        return votePassed;
    }

    // Calculates the return (and possible reward) for a single participant
    function calculateStakeReturn(uint256 _voteID, bool _votedForRightOption, bool _refund) internal view returns (uint256) {
        uint256 participants = votes[_voteID].participantsAgainst.add(votes[_voteID].participantsFor).add(votes[_voteID].participantsUnrevealed);
        uint256 totalReturn = 0;

        // "refund" is the case when a vote ends in a draw (or noone participates)
        if(!_refund) {
            uint256 basicReturn = stakesOfVote[_voteID].returnPool.div(participants);
            totalReturn = basicReturn;
            if(_votedForRightOption) {
                uint256 likeMindedVoters = 0;
                if(isPassed(_voteID)) {
                    likeMindedVoters = votes[_voteID].participantsFor;
                } else {
                    likeMindedVoters = votes[_voteID].participantsAgainst;
                }
                
                // splitting the total amount between the like-minded voters to calculate the return/reward for the caller
                totalReturn = (totalReturn.add(getNetStake(_voteID))).add((stakesOfVote[_voteID].rewardPool.div(likeMindedVoters))); 
            }
        } else {
            // if the vote ended in a draw (or noone participated)
            totalReturn = stakesOfVote[_voteID].proposersStake;
            if(votes[_voteID].participantsUnrevealed > 0 && votes[_voteID].participantsUnrevealed < participants) {
                // adding the netStake of unrevealed votes to the reward
                totalReturn = stakesOfVote[_voteID].proposersStake.add((votes[_voteID].participantsUnrevealed.mul(stakesOfVote[_voteID].proposersStake)).div((participants.sub(votes[_voteID].participantsUnrevealed))));
            }
        }

        return totalReturn;
    }
    
    // Allowing participants who voted according to what the right decision was to claim their "reward" after the vote ended
    function finalizeVote(uint256 _voteID, uint256 _voteOption, address _address) external calledByDitCoordinator(msg.sender) returns (uint256 reward, bool winningSide, uint256 numberOfKNW) {
        KNWVote storage vote = votes[_voteID];
        // vote needs to be resolved and only participants who revealed their vote
        require(vote.isResolved, "Poll has to be resolved");

        if(vote.participant[_address].usedKNW > 0) {
            require(token.unlockTokens(_address, vote.knowledgeID, vote.participant[_address].usedKNW));
        }
    
        bool votePassed = isPassed(_voteID);
        bool votedRight = (_voteOption == (votePassed ? 1 : 0));

        if(vote.participant[_address].isProposer) {
            // the proposer is a special participant that is handled separately
            if(votePassed) {
                numberOfKNW = mintKNW(_address, vote.knowledgeID, vote.winningPercentage, vote.participant[_address].percentOfKNW);
            } else if(stakesOfVote[_voteID].proposersReward == 0) {
                // proposers reward is only zero if he lost the vote on the proposal, otherwise it was a draw
                numberOfKNW = burnKNW(_address, vote.knowledgeID, vote.participant[_address].usedKNW, vote.winningPercentage);
            }
            votedRight = votePassed;
            reward = stakesOfVote[_voteID].proposersReward;
        } else if(didOpen(_address, _voteID)) {
            // If vote ended 50:50
            if(!votePassed && vote.votesFor == vote.votesAgainst) {
                // participants get refunded and unrevealed tokens will be distributed evenly
                reward = calculateStakeReturn(_voteID, votedRight, true);
            // If vote ended regularly
            } else {
                // calculcate the reward (their tokens plus (if they voted right) their share of the tokens of the losing side)
                reward = calculateStakeReturn(_voteID, votedRight, false);
                // participants who voted for the winning option 
                if(votedRight) {
                    numberOfKNW = mintKNW(_address, vote.knowledgeID, vote.winningPercentage, vote.participant[_address].percentOfKNW);
                // participants who votes for the losing option
                } else {
                    numberOfKNW = burnKNW(_address, vote.knowledgeID, vote.participant[_address].usedKNW, vote.winningPercentage);
                }
            }
        // participants who didn't reveal but participated are assumed to have voted for the losing option
        } else if (!didOpen(_address, _voteID) && didCommit(_address, _voteID)){
            reward = calculateStakeReturn(_voteID, false, false);
            numberOfKNW = burnKNW(_address, vote.knowledgeID, vote.participant[_address].usedKNW, vote.winningPercentage);
        // participants who didn't participate at all
        } else {
            revert("Not a participant of the vote");
        }

        return (reward, votedRight, numberOfKNW);
    }

    function mintKNW(address _address, uint256 _knowledgeID, uint256 _winningPercentage, uint256 _percentOfKNW) internal returns (uint256 numberOfKNW) {
        uint256 tokenAmount = 0;
        if(MINTING_METHOD == 0) {
            // Regular minting:
            // For votes ending near 100% about 1 KNW will be minted
            // For votes ending near 50% about 0,0002 KNW will be minted 
            tokenAmount = _winningPercentage.sub(50).mul(20000000000000000);
        }

        if(tokenAmount > 0) {
            tokenAmount = (tokenAmount.mul(_percentOfKNW)).div(100);
            require(token.mint(_address, _knowledgeID, tokenAmount));
        }

        return tokenAmount;
    }

    function burnKNW(address _address, uint256 _knowledgeID, uint256 _stakedTokens, uint256 _winningPercentage) internal returns (uint256 numberOfKNW) {
        uint256 tokenAmount = 0;
        // uint256 burnedTokens = _stakedTokens;
        if(_stakedTokens > 0) {
            if(BURNING_METHOD == 0) {
                // Method 1: square-root based
                uint256 deductedKnwBalance = ((_stakedTokens.div(10**12)).sqrt()).mul(10**15);
                if(deductedKnwBalance < _stakedTokens) {
                    tokenAmount = _stakedTokens.sub(deductedKnwBalance);
                } else {
                    // For balances < 1 (10^18) the sqaure-root would be bigger than the balance due to the nature of square-roots.
                    // So for balances <= 1 half of the balance will be burned
                    tokenAmount = _stakedTokens.div(2);
                }
            } else if(BURNING_METHOD == 1) {
                // Method 2: each time the token balance will be divded by 2
                tokenAmount = _stakedTokens.div(2);
            } else if(BURNING_METHOD == 2) {
                // Method 3: 
                // For votes ending near 100% nearly 100% of the balance will be burned
                // For votes ending near 50% nearly 0% of the balance will be burned 
                uint256 burningPercentage = (_winningPercentage.mul(2)).sub(100);
                tokenAmount = (_stakedTokens.mul(burningPercentage)).div(100);
            }
        }

        if(tokenAmount > 0) {
            require(token.burn(_address, _knowledgeID, tokenAmount));
        }

        return tokenAmount;
    }

    // Determines if vote has passed
    function isPassed(uint256 _voteID) public view returns (bool passed) {
        require(voteEnded(_voteID), "Poll has to have ended");

        KNWVote memory vote = votes[_voteID];
        return (100 * vote.votesFor) > (vote.neededMajority * (vote.votesFor + vote.votesAgainst));
    }
    
    // Determines if a vote is resolved
    function isResolved(uint256 _voteID) public view returns (bool resolved) {
        return votes[_voteID].isResolved;
    }

    // Voting-Helper functions
    // Determines if vote is over
    function voteEnded(uint256 _voteID) public view returns (bool ended) {
        require(voteExists(_voteID), "Poll has to exist");

        return isExpired(votes[_voteID].openEndDate);
    }

    // Checks if an expiration date has been reached
    function isExpired(uint256 _terminationDate) public view returns (bool expired) {
        return (block.timestamp > _terminationDate);
    }

    // Checks if the commit period is still active for the specified vote
    function commitPeriodActive(uint256 _voteID) public view returns (bool active) {
        require(voteExists(_voteID), "Poll has to exist");

        return !isExpired(votes[_voteID].commitEndDate);
    }

    // Checks if the reveal period is still active for the specified vote
    function openPeriodActive(uint256 _voteID) public view returns (bool active) {
        require(voteExists(_voteID), "Poll has to exist");

        return !isExpired(votes[_voteID].openEndDate) && !commitPeriodActive(_voteID);
    }

    // Checks if participant has committed for specified vote
    function didCommit(address _address, uint256 _voteID) public view returns (bool committed) {
        require(voteExists(_voteID), "Poll has to exist");

        return votes[_voteID].participant[_address].didCommitVote;
    }

    // Checks if participant has revealed for specified vote
    function didOpen(address _address, uint256 _voteID) public view returns (bool revealed) {
        require(voteExists(_voteID), "Poll has to exist");

        return votes[_voteID].participant[_address].didOpenVote;
    }

    // Checks if a vote exists
    function voteExists(uint256 _voteID) public view returns (bool exists) {
        return (_voteID != 0 && _voteID <= currentVoteID);
    }

    // Returns the gross amount of ETH that a participant currently has to stake for a vote
    function getGrossStake(uint256 _voteID) public view returns (uint256 grossStake) {
        return stakesOfVote[_voteID].proposersStake;
    }

    // Returns the net amount of ETH that a participant currently has to stake for a vote
    function getNetStake(uint256 _voteID) public view returns (uint256 netStake) {
        uint256 participants = votes[_voteID].participantsAgainst.add(votes[_voteID].participantsFor).add(votes[_voteID].participantsUnrevealed);
        if(participants > 0) {
            return stakesOfVote[_voteID].proposersStake.div(participants);
        }
        return stakesOfVote[_voteID].proposersStake;

    }

    // Returns the number of KNW tokens that a participant used for a vote
    function getUsedKNW(address _address, uint256 _voteID) public view returns (uint256 usedKNW) {
        return votes[_voteID].participant[_address].usedKNW;
    }

    // Returns the number of votes that a participant has in a vote
    function getAmountOfVotes(address _address, uint256 _voteID) public view returns (uint256 numberOfVotes) {
        return votes[_voteID].participant[_address].numberOfVotes;
    }
    
    // Modifier: function can only be called by a listed dit contract
    modifier calledByDitCoordinator (address _address) {
        require(ditCoordinatorContracts[_address], "Only a ditCoordinator is allow to call this");
        _;
    }
}