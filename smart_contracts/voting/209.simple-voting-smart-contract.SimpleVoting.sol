// SPDX-License-Identifier: MIT
// WARNING this contract has not been independently tested or audited
// DO NOT use this contract with funds of real value until officially tested and audited by an independent expert or group

pragma solidity 0.8.11;

import "https://github.com/second-state/simple-staking-smart-contract/blob/main/SimpleStaking.sol"

contract SimpleVoting {
    // SimpleStaking
    SimpleStaking simpleStaking;

    // boolean to prevent reentrancy
    bool internal locked;

    // Library usage
    //using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Contract owner
    address public owner;

    // ERC20 contract address
    //IERC20 public erc20Contract;

    // /// @dev TODO
    // /// @param _erc20_contract_address.
    //constructor(IERC20 _erc20_contract_address) {
    constructor(address _simpleStakingAddress) {
        // Set contract owner
        owner = msg.sender;
        // Set the erc20 contract address which this timelock is deliberately paired to
        //require(address(_erc20_contract_address) != address(0), "_erc20_contract_address address can not be zero");
        //erc20Contract = _erc20_contract_address;
        // Initialize the reentrancy variable to not locked
        locked = false;
        simpleStaking = SimpleStaking(_simpleStakingAddress);
    }

    // Modifier
    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // Modifier
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Message sender must be the contract's owner.");
        _;
    }

    /// @dev TODO
    function testingVotingFunctionality() public view returns(uint256){
        // We only allow users who have staked tokens to partake in voting
        require(simpleStaking.balances(msg.sender) > 0, "Message sender must have tokens staked in order to vote");
        // This shows that we can get any user's balance which locked in the SimpleStaking contract
        // The specific user's balance is essentially their weight (how much their vote is worth; relative to other staking users)
        return simpleStaking.balances(msg.sender);
    }
}
