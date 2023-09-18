//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.7;

contract FindAndRemove {

    address[] internal members;

    function becomeMember() external {
        members.push(msg.sender);
    }

    function getAllAddresses() external view returns(address[] memory) {
        return members;
    }

    function findAndRemove() external {
        //find the index number
        uint indexNumber;
        for(uint i=0; i<members.length; i++) {
            if( members[i] == msg.sender ) {
                indexNumber = i;
                break;
            }
        }
        //remove element
        for( uint i = indexNumber; i<members.length - 1; i++) {
            members[i] = members[i+1];
        }
        members.pop();       
    }


  


/*

NON ORDERLY WAY
[a, b, c, x, t]
[a, t, c, x, b]
[a, t, c, x]


ORDERLY WAY
[a, b, c, x, t]
[a, c, c, x, t]
[a, c, x, x, t]
[a, c, x, t, t]
[a, c, x, t]

*/



}