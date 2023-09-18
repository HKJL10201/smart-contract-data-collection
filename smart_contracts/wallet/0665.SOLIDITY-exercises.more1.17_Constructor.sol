pragma solidity >= 0.8.7;

contract Constructor {
    string public myWord;
    string public myWord2;
 
    constructor() {
        myWord = "Word1: Constructor works";
        myWord2 = "Word2: Solidity is nice";
    }

    function getWord() public view returns(string memory) {
        return myWord2;
    }
}