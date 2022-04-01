/*  Example proxy contract implementation.

    Proxy contract copied from Solidity patterns below:
    https://fravoll.github.io/solidity-patterns/proxy_delegate.html
*/

contract Proxy {

    address payable public delegate;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function upgradeDelegate(address payable newDelegateAddress) public {
        require(msg.sender == owner, "Only the owner can change delegateAddress");
        delegate = newDelegateAddress;
    }

    // Fallback function will be called for every unknown or unspecified function identifier used
    function() external payable {
        assembly {
            // Get the first variable from Storage, which is the delegate address
            let _target := sload(0)

            // Copy the calling data into memory
            calldatacopy(0x0, 0x0, calldatasize)

            let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)

            // Copy the actual return result into memory
            returndatacopy(0x0, 0x0, returndatasize)

            // Check if the operation outcome is negative bool,
            // if failed, state changes are reverted
            // if succeeded, the result is returned to the caller of the proxy
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
        }
    }
}