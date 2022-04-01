pragma solidity >=0.8.7;
  
contract Types { 
    // creating a simple dynamic array and making it public so that you can see it in remix
    uint[] public data; 
    
    uint j = 0;
    /*We created a while loop to populate our array. Now we can check values inside the array
    but first we need press loop button and then we can insert index number to the data input field 
    so that we can see relevant value. */
    function loop() public returns(uint[] memory){
        while(j < 100) {
            j = j + 7;
            data.push(j); 
        }
        return data;

    } 
    /* thought I could just say uint public myNumber = data[2] but no, evm gives error.
    I think it is because when we need to run loop() function so that data[2] can exist.
    As we run contract, contract doesnt call loop by itself, that's why it cant see any value
    here and that's why there is error. So to overcome it, I created this piece of function*/
    uint public myNumber = 0;

    function addNumber() public returns(uint) {
        myNumber = data[3];
        return myNumber;
    }
}