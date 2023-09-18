//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Exercise2 {
    //FUNCTION 1 - CREATE AN ARRAY OF EVEN NUMBERS
    uint[] myArray;
    function setEvens() external {
        for(uint i=0; i<20; i++) {
            if(i % 2 == 0) {
                myArray.push(i);
            }
        }
    }
    function getEvens() external view returns(uint[] memory) {
        return myArray;
    }

    enum 
    //THE SAME AS ABOVE, BUT I DONT NEED A SEPARATE VIEW FUNCTION
    function setEvens2() pure external returns(uint[] memory) {
        uint[] memory evens = new uint[](20);
        uint myIndex = 0;
        for(uint i=1; i<=20; i++) {
            if(i % 2 == 0) {
                evens[myIndex] = i;
                myIndex++;
            }
        }
        return evens; 
    }
    
    //FINDING THE BIG NUMBER IN AN ARRAY
    function findBigNum(uint[] memory a) external pure returns(uint) {
        uint bigNumber;
        for(uint i=0; i<a.length; i++){
            a[i]>= bigNumber ? bigNumber = a[i] : bigNumber;
        }
        return bigNumber;
    }

    //FINDINT THE SUM OF AN ARRAY
    function findSum(uint[] memory a) external pure returns(uint) {
        uint totalNumber;
        for(uint i = 0; i<a.length; i++) {
            totalNumber += a[i];
        }
        return totalNumber;
    }

    //FIND THE INDEX NUMBER OF AN ARRAY ELEMENT
    uint[] myArray2 = [8, 4, 55, 66, 99];
    function findIndex(uint a) external view returns(uint) {
        for(uint i = 0; i< myArray2.length; i++) {
            if(myArray2[i]==a) {
                return i;
            }
        }
        revert("value is not in array");
    }

    //ORDER THE ARRAY ELEMENTS FROM SMALL TO BIG
    uint[] arr = [89, 23, 111, 54, 2, 3, 52, 0];
    function orderArray() external {
        for(uint a = 0; a<arr.length-1; a++){
            uint x;
            for(uint i = 0; i<arr.length-1; i++) {
                
                if(arr[i] >= arr[i+1]) {
                    x = arr[i];
                    arr[i] = arr[i+1];
                    arr[i+1] = x;
                } 
            }
        }

    }

    function returnArr() external view returns(uint[] memory) {
        return arr;
    }

    //REMOVE DUPLICATE NUMBERS IN AN ARRAY
    /* I created two for loops, first for loop is saving the number value, the second for loop is comparing this number
    value to the next members of the array. Thats why I am saying "uint i = a+1". If I was going to say "uint i = 0" then
    it would compare the first for loop value to the second for loop value and they would be the same values. And it would delete
    values even if they are not duplicate.
    Then I am removing the duplicate by replacing it with the element at the last place of the array. Then a simple pop()
    I know by this the array order changes, by in case it works and removes duplicates. If I want to protect order, then
    I would have to create a new order.
    [2, 1, 1, 5]    [2, 1, 1, 5]    [2, 1, 1, 5]
       \                \                   \
        \ \  \           \  \                \
    [2, 1, 1, 5]    [2,1, 1, 5]     [2, 1, 1, 5]
    First loop cycle of the First loop: I am comparing 2 to 1, 1, 5
    Second loop cycle of the Second loop: I am comparing 1 to 1,5
    Third loop cycle of the Third loop: I am comparing 1  to 5
    As I made "a<arr2.length-1;" I am not comparing 5 to any number. And loop finishes.
    */
    uint[] arr2 = [20, 15, 10, 2, 15];
    //uint[] arr2 = [2,1,1,5];
    function removeDuplicate() external {
        for(uint a = 0; a<arr2.length-1; a++){
            
            uint x = arr2[a];
            for(uint i = a+1; i<arr2.length; i++) {
                if(x == arr2[i]) {
                    arr2[i] = arr2[arr2.length-1];
                    arr2.pop();
                }


            }


        }
    }
    function returnArr2() external view returns(uint[] memory){
        return arr2;
    }

    //REMOVE SPECIFIC INDEX
    uint[] arr4 = [1, 2, 999, 3, 4];

    function removeIndex(uint index) external {
        uint lastNumber = arr4[arr4.length-1];
        arr4[index] = lastNumber;
        arr4.pop();
    }

    functino removeIndexOrdered(uint index) external {
        for(uint i = index; i<arr4.length-1; i++) {
            arr4[i] = arr4[i+1];
            arr4.pop();
        }
    }

}