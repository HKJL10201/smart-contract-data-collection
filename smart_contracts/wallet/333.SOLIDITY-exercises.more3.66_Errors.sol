//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract Errors {

    function testRequire(uint _n) external pure returns(uint) {
        require(_n < 100, "number should be less than 100");
        return _n;
    }
    // revert and require are more used in function context.
    // They are checking a condition which is important for the function.
    // The condition is not that important for the whole blockchain.
    // I am not sure about the gas. Is it all gas refunded? or only the gas left?
    
    // Revert allow to write deeper code than require. Because it allows if
    // statement. So, I can write many reverts inside each other.
    function testRevert(uint _n) external pure returns(uint) {
        if(_n <100) {
            return _n;
        } else {
            revert("number should be less than 100");
        }
    }
    // assert is used to check an IMPORTANT STABLE CONDITION before executing code
    uint myNumber = 123;
    function testAssert(uint _n) external view returns(uint) {
        assert(_n != myNumber);
        return _n;
    }

    //Custom Error Message: it should be used with revert()
    //This is a cheap way if your error string is long in revert and require. 
    //You can store error string inside the custom error variable.
    // And although function reads from "error" which is outside the function,
    // the string value of the function is inside the function. For that reason,
    // we can tag it as "pure" 
    error myError(string myString);
    function testCustom(uint _n) external pure returns(uint) {
        if(_n > 10) {
            revert myError("now I can write long long error messages");
        } else {
            return _n;
        }
    }


}