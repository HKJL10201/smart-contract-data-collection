pragma solidity >=0.8.7;

// This contract will get the highest number of an array
contract GetHighestNumber {
    uint[3] public myArray = [42, 20, 36];
    //Dont put uint save inside the function because, I want to assign
    //each  true cycle value to the save.
    uint public save = 0;

    function getHighest() public returns(uint) {
        for (uint256 index = 0; index < myArray.length; index++) {
            if (myArray[index] >= save) {
                save = myArray[index];
            } else {
                save;
            }
        }
        return save;
    }
    // return statement must be after for statement because 
    // because if i put it inside for statement, I will have 3 loop results
    // But I want just one, not three
}