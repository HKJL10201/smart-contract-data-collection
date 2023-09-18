pragma solidity ^0.5.11;

/* Proxy contract that makes a call to the dapp contract to modify the it's own state */
contract proxy {
    // Public variables that are set by the call function.
    bool public res;
    bytes public val;
    bytes public encoded_value;

    // Variables modifiable by the code from delegateCall executing in the current memory context
    uint256 public n;
    address public sender;

    function callSetN(address _e, uint256 _n) public {
        // encoded_value = abi.encode(bytes4(keccak256("setN(uint256)")), _n);
        encoded_value = abi.encodePacked(bytes4(keccak256("setN(uint256)")), _n);

        // "dapp" contract's storage is not set, whereas "proxy" contract's storage is modified
        (res, val) = _e.delegatecall(encoded_value);
    }
}