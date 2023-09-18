//SPDX-License-Identifier: GPL-3.int20
pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;
contract election{
     address public admin; // address of Administrator of voting process 
    bool votingison=true; // flag to tell voting is on or not
    struct candidate{
        string name;
        uint age; // Age of candidate should be 18 or above 
        uint numberofvotes;
        string district;
        string qualification;
    }
     struct voter{
        uint candyid; 
        bool donevoting; // Already voted?
        
    }
    
    candidate[] public candy;
    mapping(address=> voter) public voters;
    // Function to add candidates information in respective arrays
    constructor (string[] memory names, uint[] memory howold, string[] memory candydist, string[] memory qualify){
         admin=msg.sender;        
         for(uint o=0;names.length>o; o++){
        require(howold[o]>17, "Legal age in India to stand for elections is 18");
        candy.push(candidate({name: names[o], age: howold[o],numberofvotes: 0,district: candydist[o],qualification: qualify[o]}));
    }
    }
    function declareresults() public view returns (string memory){
        require(!votingison && (msg.sender==admin));
        uint maxvotes;
        uint indexofwinner;
        for(uint i=0; i<candy.length; i++){
            if(maxvotes<candy[i].numberofvotes){
                maxvotes=candy[i].numberofvotes;
                indexofwinner=i;
            }
        }
        return candy[indexofwinner].name;
    }
    

    
    function castvote(uint mycandidate) public{
        require(votingison);
        voter storage current= voters[msg.sender];
        require(!current.donevoting);
        current.candyid= mycandidate;
        candy[mycandidate].numberofvotes++;
        current.donevoting=true;
    }
     // function for admin to close voting process
    function endvoting() public{
        require((msg.sender==admin) && votingison);
        votingison=false;
    }
     function districtofcandidate(uint idofcandy) public view returns (string memory){
         return candy[idofcandy].district;
     }
     
     function qualificationofcandidate(uint idofcandy) public view returns (string memory){
         return candy[idofcandy].qualification;
     } 
     function nameofcandidate(uint idofcandy) public view returns (string memory){
         return candy[idofcandy].name;
     }
     function ageofcandidate(uint idofcandy) public view returns (uint){
         return candy[idofcandy].age;
     }
     function numberofcandies() public view returns (uint){
     return candy.length;}
    
}