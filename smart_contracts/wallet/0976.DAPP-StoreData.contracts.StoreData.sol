pragma solidity ^0.5.0;

contract StoreData{
    string public data;

    function set(string memory _data) public {
        data = _data;
    }

    function get() view public returns(string memory){
        return data;
    }






}
