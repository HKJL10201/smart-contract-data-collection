// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
contract WillThrow {
    error NotAllowedError(string);
    function afunction() public pure{
        // require(false, "Error");
        // assert(false);
        revert NotAllowedError("You are not allowed ");
    }
}

contract ErrorHandling{ // we create another contract for testing purpose
event ErrorLogging(string reason); // it creates an evenet for testing the Errors.
event ErrorLogCode(uint code);
event ErrorLogBytes(bytes lowLevelData);
    function catchTheError() public {
        WillThrow will = new WillThrow();
        try will.afunction(){ // we try the function here
           // add the code here if it works
        } catch Error(string memory reason){ // used for require statement
            emit ErrorLogging(reason); 
        } catch Panic (uint errorCode){ // used for assert statement
            emit ErrorLogCode(errorCode);
        } catch(bytes memory lowLevelData){ // if it is neither Error nor Panic then it's a custom error
            emit ErrorLogBytes(lowLevelData);
        }
    }
} 