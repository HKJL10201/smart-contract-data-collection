pragma solidity ^0.6.0;

contract OneInchDelegationManagerConstants {

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH = keccak256(
        'DelegateByType(address delegatee,uint256 type,uint256 nonce,uint256 expiry)'
    );

    bytes32 public constant DELEGATE_TYPEHASH = keccak256(
        'Delegate(address delegatee,uint256 nonce,uint256 expiry)'
    );

}
