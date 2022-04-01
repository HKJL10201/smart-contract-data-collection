pragma solidity ^0.5.0;

interface PhoenixIdentityViaInterface {
    function phoenixIdentityCall(address resolver, uint einFrom, uint einTo, uint amount, bytes calldata phoenixIdentityCallBytes)
        external;
    function phoenixIdentityCall(
        address resolver, uint einFrom, address payable to, uint amount, bytes calldata phoenixIdentityCallBytes
    ) external;
    function phoenixIdentityCall(address resolver, uint einTo, uint amount, bytes calldata phoenixIdentityCallBytes) external;
    function phoenixIdentityCall(address resolver, address payable to, uint amount, bytes calldata phoenixIdentityCallBytes)
        external;
}
