
//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract ReturnIf {

    uint[] myList = [5, 8, 9, 6, 3, 2, 1];
    
    //The function below is peculiar because it returns alternative values by using two "return" instead
    //of using an if statement. 
    function isInList(uint _number) public view returns(bool, uint) {
        for (uint i = 0; i < myList.length; i++){
            if (_number == myList[i]) return (true, i);
        }
        return (false, 0);
    }

    function getList() external view returns(uint[] memory) {
        return myList;
    }


    function addList(uint _newNumber) public {
       (bool _isInsideList, ) = isInList(_newNumber);
       if(!_isInsideList){
           myList.push(_newNumber);
       }
    }

    function removeNumber(uint _number) public {
        (bool _isInsideList, uint i) = isInList(_number);
        if(_isInsideList){
            myList[i] = myList[myList.length - 1];
            myList.pop();
        }
    }
    
}

