//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract RetunMany {
    //1) Here "assigned" type Multiple Return function
    function assigned() public pure returns(string memory myWord, uint myNumber, bool myBool) {
        myWord = "Schwan";    
        myNumber = 5;
        myBool = true;
    }
    //2) Here "Regular" type Multiple Return function
    function returnMany() public pure returns(string memory, uint, bool) {
        return("Azad", 123, true);
    }
    //3) Here "Named" type Multiple Return Function
    function named() public pure returns(string memory myWord, uint myNumber, bool myBool) {
        return("Schekria", 444, true);
    }

    //In these Dest. function, I can get data from any of the above function
    // and store their values inside the local variables

    //IMPORTANT: The functions above are "public". If I make them "external" I cannot call them from 
    // the functions below.

    function destructureBasic() public pure {
        (string memory myWord3, uint myNumber3, bool myBool3) = named();
    }
    //Pay attention to comma there. I am saving only one value(boolean) inside my local variable.
    function destructureIntermediate() public pure {
        (,, bool myBool3) = named();
    }
    function destructureAdvanced1() public pure returns(string memory, uint, bool) {
        (string memory myWord3, uint myNumber3, bool myBool3) = named();
        return(myWord3, myNumber3, myBool3);
    }
    function destructureAdvanced2() public pure returns(bool) {
        (,, bool myBool3) = named();
        return(myBool3);
    }
}