pragma solidity >=0.7.0 <0.8.0;

contract SimpleStorage {
    string public text;

    function set(string memory _text) public {
        text = _text;
    }

    function get() public view returns (string memory) {
        return text;
    }
}
