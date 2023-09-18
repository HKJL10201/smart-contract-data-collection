// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
import './RewardToken.sol';
import './Tether.sol';

contract DecentralBank {

    address public _owner;                                                               // Intialize owner
    string public _name = 'Decentral Bank';                                              // Name of the bank
    Tether public _Tether;                                                               // Local variable to store Tether contract address as a Tether datatype
    RewardToken public _RewardToken;                                                     // Local variable to store RewardToken contract address as a RewardToken datatype

    //address of account staking
    address[] public _stakers;

    mapping(address => uint256) public _stakingBalance;                                  // Stores staking balance of respected accounts
    mapping(address => bool) public _hasStaked;                                          // Stores true for the respected accounts if the account has staked previously, false otherwise
    mapping(address => bool) public _isStaking;                                          // Stores true for the respected accounts if the account is currently staking, false otherwise

    // Initialize an instance of the DecentralBank contract.
    // While passing the contract address of Tether and RewardToken
    constructor(RewardToken _rewardToken, Tether _tether) {
        _owner = msg.sender;                                                             // Intialize the msg.sender as the owner
        _Tether = _tether;                                                               // Intialize the Tether contract address to local variable
        _RewardToken = _rewardToken;                                                     // Intialize the RewardToken contract address to local variable
    }

    // Function to stake tokens
    function _stakeTokens(uint256 _stakingAmount) public {

        // require staking amount to be greater than zero
        require(_stakingAmount > 0, 'Cannot stake 0 token');                            
 
        // Transfer tether tokens to this contract address for staking
        _Tether._thirdPartyTransfer(msg.sender, address(this), _stakingAmount);    

        _stakingBalance[msg.sender] = _stakingBalance[msg.sender] + _stakingAmount;     // Updates staking balance

        // Checks if the user account has previously staked or not     
        if(! _hasStaked[msg.sender]) {
            _stakers.push(msg.sender);                                                   // If the user has not staked then add him to the list of stakers
        }

        _isStaking[msg.sender] = true;                                                   // Set true for user isStaking
        _hasStaked[msg.sender] = true;                                                   // Set true for user hasStaked
        
    }

    // Function to unstake tokens
    function _unstakeTokens() public {

        uint256 _balance = _stakingBalance[msg.sender];                                  // Stores the token amount of user account to _balance
        require(_balance > 0, 'Cannot unstake 0 token');                                 // Token for unstaking cannot be 0
        // Calls transfer function from Tether contract and
        // Transfer the tokens to unstake
        _Tether._transfer(msg.sender, _balance);                                        
        _stakingBalance[msg.sender] = 0;                                                 // Set the staking balance of user to 0
        _isStaking[msg.sender] = false;                                                  // Set false for user isStaking
    }

    // Function to issue reward tokens to the user account
    function _issueRewardTokens() public {

        // Only owner can issue reward tokens to the user account
        require(msg.sender == _owner, 'Only owner can issue reward tokens');

        for(uint256 i=0; i < _stakers.length; i++) {
            address _recipient = _stakers[i];                                            // Access the stakers array and store each member to recipient one at a time
            uint256 _rewardToken = _stakingBalance[_recipient] / 9;                      // Calculate the reward token
            
            require(_rewardToken > 0, 'Reward Token cannot be 0');                       // Reward Token cannot be 0 when issue
            _RewardToken._transfer(_recipient, _rewardToken);                            // Calls transfer function from RewardToken contract and
        }                                                                                // Issue reward tokens to the recipient
    } 
}
