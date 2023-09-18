pragma solidity >=0.8.7;

contract Mapping {

    // Here I am createing a mapping
    mapping(address => uint) public myNumbers;

    //This line is for test purposes, doesnt affect function
    address public myAddress = msg.sender;

    // Here I am setting first object of the array
    function setOneObject(uint _anyNumber) public {
        myNumbers[msg.sender] = _anyNumber;
    }

    //Here I am getting the value of the object,  which is 
    // my account and the number value I assigned above
    function getNumber() public view returns(uint) {
        return myNumbers[msg.sender]; 
    }

}