pragma solidity >=0.4.22 <0.6.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SirinVoting {

     struct SRNVoter {
        bool voted;
        bool vote;
        address voterAddress;
    }

    //////////////////////////////////////////////////////////
    // Members
    //////////////////////////////////////////////////////////

    mapping(address => SRNVoter) public voters;
    string public question = "Do you want to get free FINNEY device from SIRINLABS";
    uint8 public totalVoters;

    IERC20 public token;
    uint256 public startTime;
    uint256 public endTime;

    //////////////////////////////////////////////////////////
    // Event
    //////////////////////////////////////////////////////////

    event votedYesEvent(address voter);
    event votedNoEvent(address voter);

    //////////////////////////////////////////////////////////
    // constructor
    //////////////////////////////////////////////////////////

    constructor(uint256 _startTime, uint256 _endTime, address _token) public {
        //require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        token = IERC20(_token);
    }

    //////////////////////////////////////////////////////////
    // public functions
    //////////////////////////////////////////////////////////

    function voteYes() public {
        vote(true);
    }

    function voteNo() public {
        vote(false);
    }

    // @return true if voting event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // @return true if voting event has started
    function hasStarted() public view returns (bool) {
        return now > startTime;
    }

    //////////////////////////////////////////////////////////
    // private functions
    //////////////////////////////////////////////////////////

    function vote(bool voteResult) private {

        SRNVoter storage sender = voters[msg.sender]; // assigns reference
        require(!sender.voted);
        require(token.balanceOf(msg.sender) > 0);
        require(now >= startTime && now <= endTime);

        sender.voted = true;
        sender.vote = voteResult;
        sender.voterAddress = msg.sender;

        voters[msg.sender] = sender;
        totalVoters++;

        if(voteResult) {
            emit votedYesEvent(msg.sender);
        } else {
            emit votedNoEvent(msg.sender);
        }
    }
}
