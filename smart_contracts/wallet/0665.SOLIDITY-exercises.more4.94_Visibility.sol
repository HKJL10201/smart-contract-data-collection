//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    uint private num1 = 582;
    uint public num2 = 8585;
    uint internal num3 = 5858;
    // state variables cannot have "external". Only functions can have "external".

    function publicF() public pure returns(string memory) {
        return "greetings from PUBLIC function";
    }

    function externalF() external pure returns(string memory) {
        return "greetings from EXTERNAL function";
    }

    function internalF() internal pure returns(string memory) {
        return "greetings from INTERNAL function";
    }

    function privateF() private pure returns(string memory) {
        return "greetings from PRIVATE function";
    }
}

contract B is A {
    function accessTest() external view returns(uint) {
        return num3;
    }
    /*
    for internal state variable, I had to write above function to access.
    public state variable was already visible "Deployed Contracts" area
    private state variable is not visible because Child cannot inherit it.
    */

    /*
    externalF was already visible in "Deployed Contracts" area.
    publicF was already visible in "Deployed Contracts" area.
    privateF was not visible as child contract cannot inherit it.
    internalF was not visible and I dont know why. I tried some way to make it visible no avail.
    I think the reason is that "deployed contracts" area is an external source and for that 
    reason my internal function is not accessible. But then why internal var was accessible? I dont know,
    probably a difference between variable and function.
    */
}