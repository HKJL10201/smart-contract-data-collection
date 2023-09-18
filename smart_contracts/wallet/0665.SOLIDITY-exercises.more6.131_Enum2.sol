//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

contract EnumExample {


    uint[] myChoices = [0, 1, 2, 3];
    uint public choice1;
    function setLarge1() external {
        choice1 = myChoices[3];
    }

    string[] myChoices2 = ["CHILDREN", "SIZE1", "SIZE2", "SIZE3"];
    string public choice2;
    function setLarge2() external {
        choice2 = myChoices2[3];
    }

    struct MyChoices4 {uint a;}
    MyChoices4 choice4;
    function setLarge4() external {
        choice4 = MyChoices4(3);
    }

    mapping (string => uint) myChoices5;
    function createMapping() external {
        myChoices5["CHILDREN"] = 0;
        myChoices5["SIZE1"] = 1;
    }
    uint choice5;
    function setLarge5() external {
        choice5 = myChoices5["CHILDREN"];
    }


    
    enum MyChoices3 {CHILDREN, SIZE1, SIZE2, SIZE3}
    MyChoices3 public choice3;
    function setLarge3() external {
        choice3 = MyChoices3.SIZE3;
    }

}