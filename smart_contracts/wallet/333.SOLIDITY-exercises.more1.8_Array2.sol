pragma solidity >=0.8.7;

contract Array2 {
    uint[6] public data;
    
    function defineAndGetArray() public returns(uint[6] memory) {
        data = [22, 36, 85, 2, 1, 7];
        data[2] = 5;
        return (data);
    }
}