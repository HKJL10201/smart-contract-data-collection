pragma solidity >=0.8.7;

contract HelloWorld {
    string public myWord = "Good evening sir";

    function helloWorld() public pure returns(string memory) {
        return "Hello World";
    }
    address public myAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    function setWord(string memory _myWord) public {
        myWord = _myWord;
    }

    function getWord() public view returns(string memory) {
        return myWord;
    }

}