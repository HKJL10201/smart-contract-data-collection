pragma solidity >=0.8.7;

contract Crud {
    struct UserStruct {
        uint id;
        string name;
    }
    UserStruct[] public myArray;
    uint public indexId = 1;
    // the indexId must be 1. If not our id will start from 0.
    // And if it starts from 0, it can collide with non-existing records.
    // because non-existing records, will also have indexId 0.

    function createUser(string memory newName) public {
        myArray.push(UserStruct(indexId, newName));
        indexId++;
    }
    function getAllArray() public view returns(UserStruct[] memory) {
        return myArray;
    }

    function getElement(uint number1) public view returns(UserStruct memory) {
        for(uint i=0; i<myArray.length; i++) {
            if(i == number1) {
                return myArray[number1];
            }
        }
    }

    function loop(uint number4) internal view returns(UserStruct) {
        for(uint i=0; i<myArray.length; i++) {
            if(i == number4) {
                return i;
            }
        }
    }

    function updateElement(uint number2, string memory freshName) public {
        uint i = loop(number2);
        myArray[i].name = freshName;

    }

    function deleteElement(uint number3) public {
        for(uint i=0; i<myArray.length; i++) {
            if(i == number3) {
                delete myArray[i];
            }
        }
        revert("user does not exist");
    }





}