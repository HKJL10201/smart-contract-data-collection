pragma solidity >=0.8.7;

contract Modifier {

    string name;
    string surname;
    bool public result = false;

    constructor() {
        name = "Harro"; 
        surname = "Schwan";
    }

    modifier checkWord(string memory _name) {
        require(keccak256(bytes(_name)) == keccak256(bytes(name)), "You have entered wrong word");
        _;
    }

    function getName(string memory _name) public checkWord(_name){
        result = true;
    }

}