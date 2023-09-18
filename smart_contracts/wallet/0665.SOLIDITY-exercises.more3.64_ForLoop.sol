//SPDX-Licence-Identifier: MIT

pragma solidity >=0.8.7;

contract ForLoop {
    uint[] myArray;
    function addArray() external {
        for(uint i=0; i<9; i++) {
            myArray.push(i);
        }
    }
    function getArray() external view returns(uint[] memory) {
        return myArray;
    }

    uint[] myArray2;
    function addArray2() external {
        for(uint i=0; i<9; i++) {
            if(i == 3) {
                continue; 
            } else {
                myArray2.push(i);
            }
        }
    }
    function getArray2() external view returns(uint[] memory) {
        return myArray2;
    }


    uint[] myArray3;
    function addArray3() external {
        for(uint i=0; i<9; i++) {
            if(i == 3) {
                continue;
            } else if(i == 7) {
                break;
            } else {
                myArray3.push(i);
            }
        }
    }
    function getArray3() external view returns(uint[] memory) {
        return myArray3;
    }
}