pragma solidity >=0.8.7;

contract Arrays {
    uint[] public ids;

    function setIds(uint id) public {
        ids.push(id);
    }

    //if you want to return a single integer
    function getIds(uint indexNumber) public view returns(uint) {
        return ids[indexNumber];
    }

    // if you want to return whole array
    function getIds2() public view returns(uint[] memory) {
        return ids;
    }

    // if you want to return array length
    function arrayLength() public view returns(uint) {
        return ids.length;
    }
}