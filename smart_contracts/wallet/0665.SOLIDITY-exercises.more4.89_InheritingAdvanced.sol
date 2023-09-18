//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract A {
    /*In the previous example, we saw how our child contract can modify/customize state variables
    of mother contract. And it was easy. However, to modify functions, we need some extra keywords.*/

    /*This is a mother contract. If we want to our child contract
    to be able to modify/customize THE FUNCTIONS inside mother contract, 
    we need to declare it as "VIRTUAL". So, our second function is "VIRTUAL"*/
    function returnWord() external pure returns(string memory) {
        return "Hello";
    }

    function returnWord2() external pure virtual returns(string memory) {
        return "good evening";
    }
}

contract B is A{
    /*
    Then in our child contract, we need to declare the function that we want to modify as "override".
    To make it more complex, we can declare this as "VIRTUAL" for the third contract.
    function returnWord2() external pure override returns(string memory) {
     return "Krankenhaus";
    }
    */
    function returnWord2() external pure virtual override returns(string memory) {
        return "Krankenhaus";
    }
}

contract C is B {
    function returnWord2() external pure override returns(string memory) {
        return "Schmetterling";
    }
}
