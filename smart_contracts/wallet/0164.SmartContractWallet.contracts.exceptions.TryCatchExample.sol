//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// This example uses a lower pragma version for the purposes of the example, but it 
// is always a good idea to have input validation in place.
contract TryCatchExample {
    error NotAllowedError(string);

    function aFunction() public pure {
        //require(false, "An exception was thrown."); // Will generate "Error"
        //assert(false);  // Will generate "Panic".
        revert NotAllowedError("Error not allowed.");
    }
}

contract ErrorHandling {
    event ErrorLogging(string reason);
    event ErrorLoggingCode(uint code);
    event ErrorLoggingLowLevel(bytes lowLevelError);

    function catchError() public {
        TryCatchExample e = new TryCatchExample();
        try e.aFunction() {
            // add code if it works.
        } catch Error(string memory reason) {
            emit ErrorLogging(reason);
        } catch Panic(uint errorCode) {
            emit ErrorLoggingCode(errorCode);
        } catch(bytes memory lowLevelError) {
            emit ErrorLoggingLowLevel(lowLevelError);
        }
    }
}