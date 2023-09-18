// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;  

contract SimpleStorage {

 uint256 favouriteNumber;

struct People {
    uint256 favouriteNumber;
    string name;
}
People [] public people;

mapping(string=>uint256) public nameToFavouriteNumber;


//Sets the value of a gobal scope FavouriteNumber
 function store(uint256 _favouriteNumber) public {
     favouriteNumber = _favouriteNumber;
 }


function addPerson(string memory _name, uint256 _favouriteNumber) public {
people.push(People(_favouriteNumber,_name));

//Setting the string to favourite number
nameToFavouriteNumber[_name] = _favouriteNumber;
}
//Publicly display the favouriteNumber
 function retrieve() public view returns(uint256) {
     return favouriteNumber;
 }


}