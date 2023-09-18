/*  @Doc
    This is the assembly implementation of the generalised proxy contract
    Essentially a identity contract. Implementing something similiar to the ERC725 spec

    Legend:
    - @Todo -> Items to work on / Fix
    - @Notes -> Notes to devs, usually to explain some concept or code purpose
    - @Debug -> Symbol to indicate code below or on the left is used for Debug
*/

pragma solidity ^0.5.11;

/* Proxy contract that makes a call to the dapp contract to modify the dapp's state */
contract proxy_execution {
    /* Events used for debugging */
    event debug(string, bytes);
    event debug(string, uint256);

    // owner is the first and only declared variable
    // Remember to offset when using storage and coming out with the storage layout
    address public owner;

    // @Debug Variables used for debugging to view in the Remix UI
    bytes32 public addr; // sstore(1, )
    // address public addr; // sstore(1, )
    bytes32 public txData; // sstore(2, )
    bool public res; // sstore(3, )
    bytes32 public return_value; // sstore(4, )

    /// @dev Fallback function forwards all transactions and returns all received return data.
    // @Todo might remove the modifier and implement check inside function
    // Fallback function that should forward all calls to proxied contract
    function() external payable onlyOwner {
        /* @Debug  */
        emit debug("Length of msg.data in fallback fn:", msg.data.length);
        emit debug("The msg.data passed to the fallback function is:", msg.data);

        /*  What we are trying to implement is different from most smart contract proxies out there
            Because unlike the other proxy contracts where values like delegate/proxied address to call are all fixed/pre-set,
            We want a generalisable contract where everything to do with the transaction is relayed in, instead of it being fixed
            Meaning that all the call data are part of the function arguement list.
        */

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            /*
                Steps:
                    1) Get all the data needed for the call
                    2) Make the call and get the execution status + return values
                    3) Check if the call succeeded
                        a) Revert all state changes if the call faile
                        b) Return the call's return value to the contract caller as return value

                Getting data needed for the call
                    1) Get the address to be called, this is part of the call data
                    2) Get the function signature and input value(s) for the function to be called from the call data, as 1 full hex

                Expected Calldata:
                    - "Address" of contract to call
                    - "Data" the transaction data to pass to the other contract
                        - The standard transaction data we are calling it directly.
                        - The function selector and the function input
            */

            /* Step (1) Extract data needed, from the call data */
            // Copy the calling data into memory
            // calldatasize is the size of call data in bytes
            // Copy calldatasize amount of bytes from position 0 of calldata to position 0 of memory
            calldatacopy(0, 0, calldatasize)

            // Load all data from storage data starting at address 0
            // The data from storage at position 0, is the variable "address public addr"
            // Bitmask to grab the first 20bytes/40Hex/unint160 of data from the first 32bytes/64Hex of calldata memory slot to get the input address
            // let addr := and(mload(0), 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000)
            // This is also valid, by doing the mask on the calldata immediately
            let addr := and(calldataload(0), 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000)
            
            // @Notes On what if the user sends address(0) as the address
            // When the "to" field of a transaction is empty, it means that a new contract should be created with the transaction data
            // The user should not send a null address, because we assume that the address is not null during our parsing
            // Maybe frontend should send a variable at the start, so the first Hex acts as a bool, indicating if address is null, before parsing calldata accordingly.
            // The bool will be used to indicate if the operation is for creating contracts or just making a normal contract call
            // The below check wont actually work, because if user send any data, the thing wont be null, it will just treat the data as the address.
            // require(addr !== address(0), "Cannot create contract liddat")
            
            // @Debug 
            // If the storage data type is "address" type,
            // store it only after shifting it all the way to right to prevent your data from being cut, as sol try to fit it into the type smaller size
            // sstore(1, shr(96, addr))
            // Store directly if the variable is of bytes32 type
            sstore(1, addr)

            // The rest of the data in memory, that is not the address, is the transaction data for the proxied contract
            // let txData := mload(20)
            // Below also works, by directly taking the txData from calldata
            let txData := calldataload(20)
            
            // @Debug Store the transaction data for the proxied contract to see if the parsing was correct
            sstore(2, txData)

            /* Step (2) Making the call and getting the return result */
            // calldatasize is the size of call data in bytes
            // Make a delegate call to the addr address with
            //      input memory from 0 to 0 + calldatasize
            //      providing "gas" amount of gas
            //      the "gas" variable stores the gas amount still available to execution
            //      output area from 0 to 0 + 0
            // Effectively using the code from addr but stay in context of current contract
            // let success := delegatecall(gas, addr, 0, calldatasize, 0, 0)
            // Same operation but make the call/code-execution in that contract's state context
            let success := call(gas, addr, callvalue, 0, calldatasize, 0, 0)
            
            // @Debug Store the call result
            sstore(3, success)

            // returndatasize returns the size of the last return data
            // copy returndatasize bytes from position 0 of returndata to position 0 of mememory
            returndatacopy(0, 0, returndatasize)

            sstore(4, mload(0))

            /* Step (3) Checking return value and ending function */
            // if success == 0, meaning the operation is not successful
            // revert state changes and end execution
            // Return data memory from position 0 to 0 + returndatasize
            if eq(success, 0) { revert(0, returndatasize) }

            // End execution and return data memory from position 0 to 0 + returndatasize
            return(0, returndatasize)
        }
    }
}