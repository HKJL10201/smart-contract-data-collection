pragma solidity ^0.4.17 < 0.6.12; 

//Main contract
contract rcard{
    string public name;
    uint256 public rrn;
    uint64 public batch;
    string public status;
    uint64 maths_mark;
    uint64 chemistry_mark;
    uint64 english_mark;
    uint64 physics_mark;
    uint64 biology_mark;

    //constructor 
    constructor (string newname,uint256 newrrn, uint64 newbatch, uint64 newmaths_mark, uint64 newchemistry_mark,uint64 newenglish_mark,uint64 newphysics_mark, uint64 newbiology_mark) public{
        //Basic details
        name = newname;
        rrn = newrrn;
        batch = newbatch;
    
        //Marks out of 50 for each subject
        maths_mark = newmaths_mark;
        chemistry_mark = newchemistry_mark;
        english_mark = newenglish_mark;
        physics_mark = newphysics_mark;
        biology_mark = newbiology_mark;
    
        uint result = maths_mark + chemistry_mark + english_mark + physics_mark + biology_mark;
    
        //Determine whether the student is pass or fail
        if (result >= 100){
            status = "Pass";
        }
        else {
            status = "Fail";
        }
    }
    //Function to get the current report card details
    function getrcardDetails() public view returns (string, uint256, uint64, string){
        return(name, rrn, batch, status);
    }
}
