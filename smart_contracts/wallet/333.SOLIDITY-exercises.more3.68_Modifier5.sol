//SPDX-Licence-Identifier: GPL-3.0;

pragma solidity >=0.8.7;

contract ModifierTest {

    bool public paused;
    uint public myNumber;

    //My first Modifier
    modifier checkPause(){
        require(!paused, "paused");
        _;
    }

    function startStop(bool _start) external{
        paused = _start;
    } 

    function decNumber() external checkPause{
        myNumber -=10;
    }

    function addNumber() external checkPause{
        myNumber +=30;
    }

    //Here I created another modifier
    modifier smallHundred(uint _n){
        require(_n<100, "number should be smaller than 100");
        _;
    }

    function anotherTest(uint _n) external pure smallHundred(_n) returns(uint){
        return 1000+_n;
    }

    //Here is third Modifier called "Sandwich"
    modifier smallTen(uint _n){
        myNumber +=_n; //First executed
        _;
        myNumber = myNumber*10; //third executed
    }

    function thirdModifier(uint _n) external smallTen(_n) {
        myNumber += 3; // second executed
    }

    //Here is fourth Modifier called "Sandwich"
    modifier sandwich(){
        myNumber += 10;
        _;
        myNumber *= 2;
    }

    function fourthModifier() external sandwich{
        myNumber +=1;
    }
}
