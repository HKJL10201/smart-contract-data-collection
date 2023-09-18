pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.4.17;
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract LotteryV2 {
    using SafeMath for uint;

    address public manager;
    address public feeMangeContract;
    address[] public currentRoundPlayers;
    uint256 public currentRound;
    _Winner[] public allTimeWinners;
    
    uint256 public feePercent; // 10%

    // All time users (address -> round -> entry blance for round in Wei)
    mapping(address => mapping(uint256 => _UserPools)) public entryBalances;
    
    // Structs
    struct _UserPools {
        string tokenName;
        uint256 lotteryRound;
        uint256 amount;
    }
    
     struct _Winner {
        address userAccount;
        string tokenName;
        uint256 lotteryRound;
        uint256 payout;
        uint256 fees;
        uint256 communityPayout;
    }
    
    function Lottery(address _feeAcount, uint256 _feePercent) public {
        manager = msg.sender;
        currentRound = 1;
    
        feeMangeContract = _feeAcount;
        feePercent = _feePercent;
    }
    
    function enter() public  payable {
        // .01 ether = 1000000000000000000 wei
        require(msg.value > .01 ether);
        
        // add user to current round
        currentRoundPlayers.push(msg.sender); 
        
        // Add user to pool
        _UserPools memory _userPools = _UserPools("ETH", currentRound, msg.value);
        entryBalances[msg.sender][currentRound] = _userPools;
    }
    
    function pseudoRandom() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, currentRoundPlayers));
    }
    
    function pickWinner() public restricted {
        // pick a winner
        uint index = pseudoRandom() % currentRoundPlayers.length;
        
        // pay fee to fee account
        uint feesAmount = this.balance.mul(feePercent).div(100);
        uint payout = this.balance.sub(feesAmount);
        currentRoundPlayers[index].transfer(payout);
        
        // worker payout
        uint communityPayout = feesAmount.mul(50).div(100);
        uint workerPayout = feesAmount.sub(communityPayout);
        feeMangeContract.transfer(workerPayout);
        
        // community playout(50% of fees)
        uint communitysplit = communityPayout.div(currentRoundPlayers.length);
        for(uint i=0; i<= currentRoundPlayers.length; i++){
            address player = currentRoundPlayers[i];
            player.transfer(communitysplit);
        }
        
        // get contract ready for next round
        _Winner memory _winner = _Winner(currentRoundPlayers[index], "ETH", currentRound, payout, feesAmount, communityPayout);
        allTimeWinners.push(_winner);
        currentRoundPlayers = new address[](0);
        currentRound ++;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return currentRoundPlayers;
    }
}