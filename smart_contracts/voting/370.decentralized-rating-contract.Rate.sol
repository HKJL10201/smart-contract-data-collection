pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title Raiting contract
 * All parties involved in Datum network can rate each other like on other marketplaces e.g. ebay.
 * The goal is to display in the marketplace the users (Ethereum public address) rating.
 */
contract Rating is Ownable {
    using SafeMath for uint;
    
    // struct for each data item
    struct DataItem {
        bool isItem;
        uint upvotes;
        uint downvotes;
    }
    
    // mapping for votes
    mapping (address => mapping (bytes32 => DataItem)) dataVotes;
    // mapping for voters' vote history
    mapping (address => mapping (bytes32 => bool)) voteHistory;
    // mapping to count total upvotes of a voter
    mapping (address => uint) upvotesForProvider;
    // mapping to count total downvotes of a voter
    mapping (address => uint) downvotesForProvider;
    
    // authorize if msg.sender didn't vote to dataId
    modifier isNewVote(bytes32 dataId) {
        require(voteHistory[msg.sender][dataId] != true);
        _;
    }
    
    constructor () public {
        
    }
    
    // upvote for item (_provider, _dataId)
    function rateUp(address _provider, bytes32 _dataId) public isNewVote(_dataId) {
        // (_provider, _dataId) pair is already exists
        if (dataVotes[_provider][_dataId].isItem == true) {
            dataVotes[_provider][_dataId].upvotes += 1;
        } else {
            dataVotes[_provider][_dataId] = DataItem({
                isItem: true,
                upvotes: 1,
                downvotes: 0
            });
        }
        
        // increase count of upvotes for msg.sender
        upvotesForProvider[_provider] += 1;
        // mark this voter as voted for this dataId
        voteHistory[msg.sender][_dataId] = true;
    }
    
    // downvote for item (_provider, _dataId)
    function rateDown(address _provider, bytes32 _dataId) public isNewVote(_dataId) {
        // (_provider, _dataId) pair is already exists
        if (dataVotes[_provider][_dataId].isItem == true) {
            dataVotes[_provider][_dataId].downvotes += 1;
        } else {
            dataVotes[_provider][_dataId] = DataItem({
                isItem: true,
                upvotes: 0,
                downvotes: 1
            });
        }
        
        // increase count of upvotes for msg.sender
        downvotesForProvider[_provider] += 1;
        // mark this voter as voted for this dataId
        voteHistory[msg.sender][_dataId] = true;
    }
    
    // return total (upvotes, downvotes) of a provider
    function ratingForAddress(address _provider) public constant returns (uint, uint) {
        return (upvotesForProvider[_provider], downvotesForProvider[_provider]);
    }
    
    // return (upvotes, downvotes) of a (provider, item)
    function ratingForAddressWithDataId(address _provider, bytes32 _dataId) public constant returns (uint, uint) {
        if (dataVotes[_provider][_dataId].isItem == true) {
            return (dataVotes[_provider][_dataId].upvotes, dataVotes[_provider][_dataId].downvotes);
        } else {
            return (0, 0);
        }
    }
    
    // clear upvotes and downvotes for (_provider, _dataId);
    function clearRating(address _provider, bytes32 _dataId) public onlyOwner {
        if (dataVotes[_provider][_dataId].isItem == true) {
            upvotesForProvider[_provider] = upvotesForProvider[_provider].sub(dataVotes[_provider][_dataId].upvotes);
            dataVotes[_provider][_dataId].upvotes = 0;
            downvotesForProvider[_provider] = downvotesForProvider[_provider].sub(dataVotes[_provider][_dataId].downvotes);
            dataVotes[_provider][_dataId].downvotes = 0;
        }
    }
} 
 