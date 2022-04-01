pragma solidity ^0.6.0;

contract StakeDelegationObjects {

    struct DelegatorInfo {  /// [Key]: delegator (address)
        uint delegatedAmount;
        uint blockNumber;
    }
    
}
