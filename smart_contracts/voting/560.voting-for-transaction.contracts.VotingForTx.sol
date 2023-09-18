// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @title Voting for transaction.
 * @dev Contract that implements mechanism of both voting for transaction between set of voters and
 * making of this transaction in case of having enough votes.
 *
 * Voting mechanism: pre-set voters (addresses) can make a proposal of transaction and then during
 * pre-set strict amount of time all voters can see it and vote for it by calling special function.
 * If somebody does not like the proposal, he/she just should do nothing. Then, if proposal got 
 * enough votes (50% + 1), anyone among voters can make a transaction but only one time. If time passes
 * but there was not enough votes or noone wanted to make a transaction then voting for this proposal
 * is ended and voters can suggest a new one.
 * 
 * All transaction properties (address, name of function, data that will be sent (function arguments),
 * value) are stored inside the contract. 
 * 
 * NOTE on {createProposal}: All arguments (data) that are sent with proposed transaction must be 
 * ABI encoded (!): converted into bytes32 layout (left- or right-padded with zero-bytes to a length
 * of 32 bytes) and concatenated into the one bytes variable. Also, function signature must have strict, 
 * canonical form: name of the function with arguments types in parentheses separated by commas without
 * spaces.
 * 
 * Links to documentation:
 * 1. Args encoding: https://docs.soliditylang.org/en/latest/abi-spec.html#examples
 * 2. Function signature: https://docs.soliditylang.org/en/latest/abi-spec.html#function-selector
 */
contract VotingForTransaction {

    event VotingStarted(address targetAddress, 
                        string functionSignature, 
                        bytes dataToSend, 
                        uint256 valueToSend);

    event TransactionMade(bool success,
                          bytes result,
                          address targetAddress, 
                          string functionSignature, 
                          bytes dataToSend, 
                          uint256 valueToSend, 
                          uint256 proposalTime);

    event FundsReplenished(address giver, uint256 amount);

    // {VoterStatus.IsVoter} means this address is a voter and is against current proposal
    enum VoterStatus { NotVoter, IsVoter, VotesFor }

    address[] voters;
    mapping(address => VoterStatus) voterStatus;

    uint256 timeForVoting;

    address targetAddress;
    string functionSignature;
    bytes dataToSend;
    uint256 valueToSend;
    uint256 proposalTime;

    bool entranceFlag;

    /**
     * @dev Sets voters and time period of voting.
     * @param voters_ is an array of addresses that will become voters.
     * @param timeForVoting_ is period of time in seconds during which it is possible to vote
     * and to make a proposed transaction.
     */
    constructor(address[] memory voters_, uint256 timeForVoting_) {
        uint256 length = voters_.length;
        address currVoter;
        for (uint256 i; i < length;) {
            currVoter = voters_[i];
            // To make sure there is no repeating addresses (this would impact on vote count)
            if (voterStatus[currVoter] != VoterStatus.NotVoter) { ++i; continue; }

            voters.push(currVoter);
            voterStatus[currVoter] = VoterStatus.IsVoter;
            unchecked { ++i; }
        }

        timeForVoting = timeForVoting_;
    }

    /**
     * @dev Throws an error if caller is not a voter.
     */
    modifier onlyForVoters() {
        require(voterStatus[msg.sender] != VoterStatus.NotVoter, "Voting: You are not a voter!");
        _;
    }

    /**
     * @dev Throws an error if time for voting has not ended.
     */
    modifier timePassed() {
        require(block.timestamp >= proposalTime + timeForVoting, "Voting: It is too early!");
        _;
    }

    /**
     * @dev Throws an error if time for voting has ended.
     */
    modifier timeNotPassed() {
        require(block.timestamp < proposalTime + timeForVoting, "Voting: It is too late!");
        _;
    }

    /**
     * @notice Returns an array of voters.
     */
    function seeVoters() external view returns(address[] memory) {
        return voters;
    }

    /**
     * @notice Returns time period for voting (in seconds).
     */
    function seeTimeForVoting() external view returns(uint256) {
        return timeForVoting;
    }
    
    /**
     * @notice Returns properties of transaction that is currently on voting.
     * Requirements: time for voting must not expire.
     */
    function seeCurrentProposal() external view timeNotPassed returns(address, string memory, bytes memory, uint256, uint256) {
        return (targetAddress, functionSignature, dataToSend, valueToSend, proposalTime);
    }

    /**
     * @notice Returns true if (50% + 1) of voters agree on the current proposal and
     * false if not.
     * Requirements: time for voting must not expire.
     */
    function seeAreAgreementsEnough() external view timeNotPassed returns(bool) {
        return _areAgreementsEnough();
    }

    /**
     * @notice Votes for current proposal. Be careful! This cannot be undone. 
     * Requirements: caller must be one of the voters and time for voting must not expire.
     */
    function voteForProposal() external timeNotPassed onlyForVoters {
        voterStatus[msg.sender] = VoterStatus.VotesFor;
    }

    /**
     * @notice Creates a proposal that will be sent on voting.
     * Requirements: caller must be one of the voters and time for voting must expire.
     * 
     * @param targetAddress_ is eth address where transaction should go to.
     * @param functionSignature_ is signature of function that will be called (must have strict,
     * canonical form - it is hashed and pruned to 4 bytes later in function {makeTransaction}).
     * Leave it as an empty string if it is only needed to send ether.
     * @param dataToSend_ is function arguments that will be sent with transaction. They must be
     * ABI encoded (!): converted into bytes32 layout (left- or right-padded with zero-bytes to 
     * a length of 32 bytes) and concatenated to one 'bytes' variable by yourself.
     * Leave it as an empty 'bytes' variable if it is not needed to send args with function.
     * @param valueToSend_ is value (in wei) that will be sent. Leave it equal to zero if it is
     * not needed to send any ether.
     */
    function createProposal(
                            address targetAddress_, 
                            string calldata functionSignature_, 
                            bytes calldata dataToSend_,
                            uint256 valueToSend_
                            ) external 
                            timePassed 
                            onlyForVoters
                            virtual {
        // Clearing votes for previous proposal
        _clearVotes();

        // Set properties of new transaction
        targetAddress = targetAddress_;
        functionSignature = functionSignature_;
        valueToSend = valueToSend_;

        // Set data (arguments of function) if it was sent
        if (bytes(functionSignature_).length == 0) {
            require(dataToSend_.length == 0, "Voting: You cannot send any args with empty function name!");
        }
        require(dataToSend_.length % 32 == 0, "Voting: Wrong data (function args) encoding!");
        dataToSend = dataToSend_;

        // Set time of transaction proposal
        proposalTime = block.timestamp;
        emit VotingStarted(targetAddress_, functionSignature_, dataToSend_, valueToSend_);
    }

    /**
     * @notice Makes the transaction that was sent on voting.
     * Requirements: caller must be one of the voters, time for voting (therefore,
     * making of transaction) must not expire, there must be enough votes for proposal.
     * NOTE: If the proposed transaction is reverted, caller will not have second chance
     * during the same voting - `proposalTime` will be changed and time for voting will
     * pass.
     */
    function makeTransaction() external timeNotPassed onlyForVoters {
        require(_areAgreementsEnough(), "Voting: Not enough votes for current proposal!");

        // Set time of last proposal to almost zero to prevent making same multiple 
        // transactions in a row and doing a reentrancy attack and also to instantly 
        // get ability to make new proposals after current transaction making
        uint256 proposalTime_ = proposalTime;
        proposalTime = 1;

        // Making of transaction
        bool success;
        bytes memory result;
        if (bytes(functionSignature).length == 0) {
            // If there is no function signature (and, therefore, no arguments)
            (success, result) = targetAddress.call{value: valueToSend}("");
        } else {
            // If there is only function signature or signature and arguments both
            (success, result) = targetAddress.call{value: valueToSend}(bytes.concat(abi.encodeWithSignature(functionSignature), dataToSend));
        }
        emit TransactionMade(success, result, targetAddress, functionSignature, dataToSend, valueToSend, proposalTime_);
    }

    /**
     * @notice Receives some ether.
     */
    function replenishFunds() external payable {
        require(msg.value > 0, "Voting: You did not send any Ether!");
        emit FundsReplenished(msg.sender, msg.value);
    }

    /**
     * @dev Returns true if (50% + 1) of voters agree on the current proposal and
     * false if not.
     */
    function _areAgreementsEnough() internal view returns(bool) {
        return _countAgreements() >= (voters.length / 2 + 1);
    }

    /**
     * @dev Returns amount of agreements.
     */
    function _countAgreements() internal view returns(uint256) {
        uint256 agreementsAmount;

        uint256 votersAmount = voters.length;
        for (uint256 i; i < votersAmount;) {
            if (voterStatus[voters[i]] == VoterStatus.VotesFor) {
                unchecked { ++agreementsAmount; }
            }
            unchecked { ++i; }
        }

        return agreementsAmount;
    }

    /**
     * @dev Clear all votes for (expired) proposal.
     */
    function _clearVotes() internal {
        uint256 votersAmount = voters.length;
        for (uint256 i; i < votersAmount;) {
            if (voterStatus[voters[i]] == VoterStatus.VotesFor) {
                voterStatus[voters[i]] = VoterStatus.IsVoter;
            }
            unchecked { ++i; }
        }
    }
}
