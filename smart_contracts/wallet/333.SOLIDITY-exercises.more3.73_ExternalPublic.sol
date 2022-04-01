//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract RetunMany {

    function assigned() public pure returns(string memory myWord, uint myNumber, bool myBool) {
        myWord = "Schwan";    
        myNumber = 5;
        myBool = true;
    }

    //IMPORTANT: The function above is "public". If I make it "external" I cannot call it from 
    // the function below.
    function destructureAdvanced2() public pure returns(bool) {
        (,, bool myBool3) = assigned();
        return(myBool3);
    }
}