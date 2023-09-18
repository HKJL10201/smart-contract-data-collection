pragma solidity ^0.5.0;

import './Voting.sol';

contract electionFactory {
address snowflake;
mapping(uint256 => bool) public electionIds;

event newElectionCreated(
    address indexed _deployedAddress,uint _id
);
constructor(address _snowflake) public{
    snowflake=_snowflake;
}


function createNewElection(uint256 _electionID,string memory _name,string memory _description,uint _days) public returns(address newContract){
        require(electionIds[_electionID]==false,"election id already exists");
       Voting v = new Voting(snowflake,_name,_description,_days);
       emit newElectionCreated(address(v),_electionID);
       electionIds[_electionID]=true;
        return address(v);
    //returns the new election contract address

}

}