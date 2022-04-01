pragma solidity >=0.8.7;

contract HelloWorld {
    string public message = "Hello World people!!!";

    function getMessage() public view returns(string memory){
        return message;
    }

    function setMessage(string memory _message) public {
        message = _message;
    }
}
