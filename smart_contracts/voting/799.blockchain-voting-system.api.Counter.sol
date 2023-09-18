pragma solidity ^0.4.20;

contract Counter{
    uint[] numbers;
    mapping (uint => uint) counters;
    
    function Counter(){
        for (uint i=0; i < 5; i++){
            counters[i] = 0;
        }
    }
    
    function count(uint number){
        counters[number]++;
    }

    function getCounting (uint number) constant returns (uint){
        return counters[number];
    }
}
