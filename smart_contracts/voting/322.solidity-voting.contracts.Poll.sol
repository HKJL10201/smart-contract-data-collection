// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@gmussi-contracts/gmussi-claimable/contracts/Claimable.sol";
import "./PollingStation.sol";
/**
 * A poll is a contract that stores potential options to vote on, as well as which addresses have voted already.
 * Addresses can vote on the poll until the poll owner closes the contract.
 * Addresses can also put their votes for sale as long as they have not voted yet.
 */
contract Poll is Claimable {
    PollingStation private pollingStation;

    struct Vote {
        bool used;
        bool forSale;
        uint price;
        address payable owner;
    }

    string public name; // name of this poll - is this necessary?

    bytes32[] public options; // options that can be voted on
    uint[] public voteCounts; // number of votes for each option

    mapping(address => Vote) private votes; // stores the votes of everyone

    bool public closed; // stores if the polling is still accepting votes

    /**
     * Event triggered every time a new vote is given in this poll
     */
    event NewVote (bytes32 indexed option, address indexed voteAddr, address indexed user);

    /**
     * Event triggered when a vote is put for sale
     */
    event VoteForSale(address indexed voteAddr, uint indexed price, address indexed user);

    /**
     * Event triggered when a vote is no longer for sale
     */
    event VoteNotForSale(address indexed voteAddr, address indexed user);

    /**
     * Event triggered when a vote is sold 
     */
    event VoteOwnershipChanged(address indexed voteAddr, address indexed seller, address indexed buyer);

    /**
     * Event triggered when the poll is closed
     */
    event PollClosed (address indexed pollAddr);

    /**
     * A poll requires a name and a bytes32 for each option.
     */
    constructor(PollingStation _pollingStation, string memory _name, bytes32[] memory _options) {
        require(_options.length > 0);

        pollingStation = _pollingStation;

        name = _name;
        for (uint i = 0; i < _options.length; i++) {
            options.push(_options[i]);
            voteCounts.push(0);
        }
    }

    /**
     * Stores a vote from the message sender. 
     * Each address can vote only once and only as long as the poll is not closed.
     * Each address can also sell their voting rights for others, which allows the buyer to vote.
     * @param _optionIndex a bytes32 representing the option to vote.
     * @dev Refer to `options` property  
     * @param _voteAddr address of the voter this vote refers to. Message sender must own that right
     */
    function vote(uint _optionIndex, address _voteAddr) public notVoted(_voteAddr) ownsVote(_voteAddr) pollOpen {
        voteCounts[_optionIndex]++;
        votes[_voteAddr].used = true;

        emit NewVote(options[_optionIndex], _voteAddr, msg.sender);
    } 

    /**
     * Puts a vote for sale for a specified price.
     * @param _voteAddr The vote to be put for sale. Msg.owner must own this vote.
     * 
     */
    function sellVote(address _voteAddr, uint price) public notVoted(_voteAddr) ownsVote(_voteAddr) pollOpen {
        require(price > 0, "Price must be higher than 0");

        Vote storage _vote = votes[_voteAddr];
        _vote.price = price;
        _vote.forSale = true;

        emit VoteForSale(_voteAddr, price, msg.sender);
    }

    /**
     * Makes a vote no longer available for sale
     * @param _voteAddr The vote address currently for sale
     */
    function stopSelling(address _voteAddr) public notVoted(_voteAddr) ownsVote(_voteAddr) forSale(_voteAddr) pollOpen {
        Vote storage _vote = votes[_voteAddr];
        _vote.price = 0;
        _vote.forSale = false;

        emit VoteNotForSale(_voteAddr, msg.sender);
    }

    /**
     * Buys a vote for sale. Enough funds must be transferred to this method. 
     * More funds than necessary will be refunded.
     * @dev This method only works if the vote has not been used AND is for sale 
     * @param _voteAddr the address of the seller whose vote is intended to buy
     */
    function buysVote(address payable _voteAddr) public payable notVoted(_voteAddr) forSale(_voteAddr) pollOpen {
        Vote storage _vote = votes[_voteAddr];
        address payable seller = _vote.owner;

        require(msg.value >= _vote.price, "Not enough funds transferred");
        
        uint change = msg.value - _vote.price;

        seller.transfer(_vote.price); // sends the price value to the seller

        if (change > 0) {
            payable(msg.sender).transfer(change); // send the change back to the buyer
        }

        _vote.forSale = false;
        _vote.owner = payable(msg.sender);
        emit VoteOwnershipChanged(_voteAddr, seller, msg.sender);
    }

    /**
     * Delegates a vote to someone else.
     * @param _voteAddr the vote to be delegated, usually same as msg.sender
     * @param _newOwner address of the new owner of this vote
     */
    function delegateVote(address _voteAddr, address payable _newOwner) public notVoted(_voteAddr) ownsVote(_voteAddr) pollOpen {
        votes[_voteAddr].owner = _newOwner;

        emit VoteOwnershipChanged(_voteAddr, msg.sender, _newOwner);
    }

    /**
     * Closes the poll. This action is irreversible and can only be performed once.
     */
    function closePoll() public pollOpen onlyOwner {
        closed = true;

        pollingStation.pollClosed(this);

        emit PollClosed(address(this));
    }

    /**
     * Function modifier that checks if the poll is still opened.
     */
    modifier pollOpen () {
        require(!closed);
        _;
    }

    /**
     * Function modifier that checks if the message sender has already voted in this poll
     */
    modifier notVoted(address _voter) {
        require(!votes[_voter].used);
        _;
    }

    /**
     * Function modifier that checks if the address trying to vote owns that vote 
     */
    modifier ownsVote(address _voter) {
        require((votes[_voter].owner == address(0) && _voter == msg.sender) || votes[_voter].owner == msg.sender);
        _;
    } 

    /**
     * Function modifier that checks if a vote is for sale
     */
    modifier forSale(address _vote) {
        require(votes[_vote].forSale);
        _;
    }

    function getOptions() public view returns (bytes32[] memory) {
        return options;
    }

    function getVoteCount() public view returns(uint[] memory) {
        return voteCounts;
    }

    function getVote(address _voter) public view returns(bool, bool, uint, address) {
        Vote storage _vote = votes[_voter];
        return (_vote.used, _vote.forSale, _vote.price, _vote.owner);
    }
 }