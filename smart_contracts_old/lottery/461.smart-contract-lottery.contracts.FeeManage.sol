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

contract FeeManage {
    using SafeMath for uint;

    address public manager;
    
    // founder: 5%, marketing: 10%
    address[] public contractAccounts;
    mapping(address => uint) public paySplits;
    

    function FeeManage(address _founderAccount, address _marketingAccount) public {
        manager = msg.sender;
        contractAccounts.push(_founderAccount);
        contractAccounts.push(_marketingAccount);
        
        paySplits[_founderAccount] = 5;
        paySplits[_marketingAccount] = 10;
    }
    
    function monthlyPayout() public restricted {
        contractAccounts[0].transfer(this.balance.mul(paySplits[contractAccounts[0]]).div(100));
        contractAccounts[1].transfer(this.balance.mul(paySplits[contractAccounts[2]]).div(100));
    }
    
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}