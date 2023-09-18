// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// Import contracts
import "../Structure/DataStructure.sol";
import "../Access/PrivacyAccess.sol";
import "./IPoll.sol";

/**
* TODO: 1 Limit length of question. 2 Limit length of options array. 3 Limit length
* of each option. 4 Function to pay a compensation of gwei, say 60-80%, from this
* contract to voter once the voting function is done
* 5 Accept donations to contract, but avoid
* any withdrawal, even from the deployer of the contract
*
*/
contract Poll is DataStructure, IPoll {
    address private _owner;
    address private _factory;
    PrivacyAccess _accessor;

    // Store metadata of poll
    PollBody private _data;
    // Store metadata of each option
    Option[] private _optionData;

    // Store vote date of voter
    mapping(address => uint) private _votingDate;
    // Store option of voter
    mapping(address => uint) private _voterOption;

    // msg.sender is not the original caller, it can be a contract. From is the address original caller
    constructor (address from, address factory, string memory question, string[] memory options, uint openDate, uint liveDays, bool _isPrivate) {
        _owner = from;
        _accessor = new PrivacyAccess(from);
        // Build poll and option data
        require(bytes(question).length > 1, "Question is empty");
        require(options.length > 1, "Number of options cannot be less than 1");
        require(liveDays > 0, "Live time cannot be lower than 1 day");
        
        _factory = factory;
        _data.question = question;
        uint currentTimestamp = block.timestamp;
        if (openDate > currentTimestamp + 1 days) {
            _data.openDate = openDate;
        } else {
            _data.openDate = currentTimestamp;
        }
        _data.closeDate = _data.openDate + liveDays * 1 days;

        for (uint i=0; i<options.length; i++) {
            //require(bytes(options[i]).length <= generalLimits.optionLength);
            _optionData.push(Option({option: options[i], nVotes: 0}));
        }

        if (_isPrivate) {
            _accessor.togglePrivacy(from);
        }
    }
    /**
     * @notice Returns address of owner
     * @dev msg.sender is not the address of the function caller, but
     * the address of the Contract. Substitute msg.sender for input address
     */
    modifier canVote(address from, uint optionIndex) {
        require(!_accessor.isPrivate() || _accessor.hasAccess(from), "The poll is private");
        require(_votingDate[from] == 0, "Voter cannot vote again");
        require(optionIndex < _optionData.length, "Option is out of bounds");
        _;
    }

    modifier validOption(uint optionIndex) {
        require(optionIndex < _optionData.length, "Option is out of bounds");
        _;
    }
    modifier isLive() {
        require(_data.closeDate > block.timestamp, "Poll ended");
        _;
    }
    modifier pollOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    // ++ Getter functions ++ 
    /**
     * @notice Returns address of owner
     * @dev Address of whom deployed smart contract
     */
    function getOwner() external virtual override view returns (address) {
        return _owner;
    }
    /**
     * @notice Returns _question of poll
     * @dev 
     */
    function getQuestion() external virtual override view returns (string memory) {
        return _data.question;
    }
    /**
     * @notice Returns total votes
     * @dev 
     */
    function getTotalVotes() external virtual override view returns (uint) {
        return _data.nTotalVotes;
    }
    /**
     * @notice Returns ALL options data
     * @dev 
     */
    function getOptions() external virtual override view returns (string[] memory, uint[] memory) {
        uint length = _optionData.length;
        string[] memory options = new string[](length);
        uint[] memory votes = new uint[](length);
        for (uint i=0; i<length;i++) {
            options[i] = _optionData[i].option;
            votes[i] = _optionData[i].nVotes;
        }
        return (options, votes);
    }
    function getIsPrivate() external virtual override view returns (bool) {
        return _accessor.isPrivate();
    }
    /**
     * @notice Returns creation date
     * @dev 
     */
    function getOpenDate() external virtual override view returns (uint) {
        return _data.openDate;
    }
    /**
     * @notice Returns close date
     * @dev 
     */
    function getCloseDate() external virtual override view returns (uint) {
        return _data.closeDate;
    }
    /**
     * @notice is Poll still live?
     * @dev 
     */
    function getIsLive() external virtual override view returns (bool) {
        uint currentTime = block.timestamp;
        return (_data.openDate <= currentTime) && (currentTime < _data.closeDate);
    }
    /**
     * @notice Returns number of live days
     * @dev 
     */
    function getLiveTime() external virtual override view returns (uint) {
        require(block.timestamp < _data.closeDate, "Poll is not live");
        return _data.closeDate - block.timestamp;
    }
    /**
     * @notice Returns whether voter already voted the poll
     * @dev 
     */
    function hasVoted(address voter) external virtual override view returns (bool) {
        return _votingDate[voter] != 0;
    }
    /**
     * @notice Returns if address has access to poll
     * @dev 
     */
    function getAccess(address from) public virtual override view returns (bool) {
        return _accessor.hasAccess(from);
    }

    // ++ Sett functions ++
    /**
     * @notice Add access to voter to private poll
     */
    function addAccess(address from, address to) external virtual override isLive() {
        _accessor.addAccess(from, to);
    }
    /**
     * @notice Remove access from voter to private poll
     */
    function removeAccess(address from, address to) external virtual override isLive()  {
        _accessor.removeAccess(from, to);
    }
    /**
     * @notice Change privacy
     */
    function togglePrivacy(address from) external virtual override {
        _accessor.togglePrivacy(from);
    }
    /**
     * @notice Vote option of poll
     */
    function setVote(address from, uint optionIndex) external virtual override isLive() canVote(from, optionIndex) returns (bool) {
        _optionData[optionIndex].nVotes += 1;
        // Set voting date to current block timestamp
        _votingDate[from] = block.timestamp;
        _voterOption[from] = optionIndex;
        _data.nTotalVotes += 1;
        return true;
    }
    /**
     * @notice Add or decreace poll live in days
     */
    function changeLive(uint timeDays, bool increase) external virtual override isLive() pollOwner() {
        uint newDate;
        if (increase) {
            newDate = _data.closeDate + timeDays * 1 days;
        } else {
            newDate = _data.closeDate - timeDays * 1 days;
            require(newDate > block.timestamp, "New date cannot be lower than current one");
        }
        _data.closeDate = newDate;
    }
}
