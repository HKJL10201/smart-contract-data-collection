pragma solidity ^0.6.0;

import { StakeDelegationObjects } from "./StakeDelegationObjects.sol";

contract StakeDelegationStorages is StakeDelegationObjects {
    mapping (address => DelegatorInfo) delegatorInfos;   /// [Key]: delegator (address)
    
}
