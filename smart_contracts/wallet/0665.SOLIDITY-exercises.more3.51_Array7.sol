pragma solidity >=0.8.7;

contract ArrayTest {

    string[] myArray = ["flower", "rose", "tulip"];

    function updateEl1() external {
        myArray[1] = "camomile";
    }

    function updateEl2(string memory newValue) external {
        myArray[1] = newValue;
    }

    function updateEl3() external {
        myArray = ["dandellion", "peachflower", "almondflower", "appleflower"];
    }



    function getValues() external view returns(string[] memory) {
        return myArray;
    }

}   