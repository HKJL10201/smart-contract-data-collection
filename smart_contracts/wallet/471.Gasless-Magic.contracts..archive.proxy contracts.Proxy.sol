pragma solidity ^0.5.0;

/*  @Docs
    Copied over from Gnosis Safe safe-contracts project's Proxies/ directory

    - Master Copy is set in the constructor function
    - The fallback function basically acts as a passthrough to communicate with the master copy
*/

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <stefan@gnosis.pm>
contract Proxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    // address internal masterCopy;
    address public masterCopy;

    event debug(string, bytes);

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            /*  @Notes
                caller:
                    Call sender, excluding the delegateCall
                callvalue:
                    wei sent together with the current call
            */

            // Load all data from storage data starting at address 0
            // The data from storage at position 0, is the variable "address public masterCopy"
            // Use a bitmask to grab the first 20bytes or unint160 of the storage data to get the address value
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // calldatasize() returns size of call data in bytes
            // Copy calldatasize() amount of bytes from position 0 of calldata to position 0 of memory
            calldatacopy(0, 0, calldatasize())

            // calldatasize() returns size of call data in bytes
            // Make a delegate call to the masterCopy address with
            //      input memory from 0 to 0 + calldatasize()
            //      providing "gas" amount of gas
            //      the "gas" variable stores the gas amount still available to execution
            //      output area from 0 to 0 + 0
            // Effectively using the code from masterCopy but stay in context of current contract
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)

            // returndatasize() returns the size of the last return data
            // copy returndatasize() bytes from position 0 of returndata to position 0 of mememory
            returndatacopy(0, 0, returndatasize())

            // if success == 0, meaning the operation is not successful
            // revert state changes and end execution
            // Return data memory from position 0 to 0 + returndatasize()
            if eq(success, 0) { revert(0, returndatasize()) }

            // End execution and return data memory from position 0 to 0 + returndatasize()
            return(0, returndatasize())
        }
    }
}
