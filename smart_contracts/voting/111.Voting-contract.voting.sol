//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract voting{
    //@author: BlackAdam
    //This code allows a single poll to be created with 3 options (bad, average, good)
    //@dev: the options can be inreased and cutomize
    //note: the contracts needs to be redployed for another poll(else, you will mess up the initial poll)

    //declare an unassigned address here as owner
    address owner;

    //The id of the poll is declared here
    uint ID = 1;

    //The options are declared, the vote is restricted to this three options
    //@dev: any new options should be added here, in the enums, in the vote functions and totalvote function
    uint good;
    uint average;
    uint bad;

    //voting period is set to 2 minutes
    uint votingPeriod = block.timestamp + 120 seconds;

    //the owner of the contract is set to the person that deploy the contract here
    constructor(){
        owner = msg.sender;
    }

    //this keeps the details of the poll/vote created
    //voteOwnerAddress: the address of the owner of the vote/poll
    //Topic: The topic/goal of your poll/vote
    //_noOfVOte: gives the total number of votes the poll/vote generated
    //rate: this keeps tracks of the enums we declared and the options declared there
    //voteCreated: this allow the users/voters to know if a poll/vote has been created
    struct voteDetails{
        address voteOwnerAddress;
        string Topic;
        uint _noOfVOte;
        rating rate;
        bool voteCreated;
    }

    //these are the option that the voters/user can select from
    //bad: 0, average: 1, good: 2
    //@dev: any new options can be added here and these can also be customized
    enum rating{
        bad,
        average,
        good   
    }

    //this map a uint to a voteDetails
    mapping (uint => voteDetails) _votedetails;

    //this keeps track of people who ve voted before, to prevent an address voting twice
    mapping(address => bool) hasVoted;

    //this checked if an address has voted before or not
    modifier voted(){
        require(hasVoted[msg.sender] == false, "youve voted");
        _;
    }

    //this keep tracks of the voting time
    modifier timeElapsed(){
        require(block.timestamp <= votingPeriod, "Voting has ended");
        _;
    }

    //the vote/poll is created here
    function createVote(string memory _topic) external returns(uint, string memory){
    //this assigned an id to a vote details
        voteDetails storage VD =  _votedetails[ID];
    //the msg.sender is stored as the owner of this poll/vote
        VD.voteOwnerAddress = msg.sender;
    //The topic/goal of the poll/vote is set here
        VD.Topic = _topic;
    //the poll/vote is set to true here and this allow the users to able to vote
        VD.voteCreated = true;
        uint currentId = ID;
        ID++;
        return(currentId, "Created Succesfully");
    }

    //this function allows the user to vote 
    //it checks if a user has voted or not
    //it checks if the voting time has elapsed or not
    function Vote(uint _id, rating _rate) external voted timeElapsed{
    //it checks if the rate/options the user has entered is not bigger than the number of options we have
        require(uint8(_rate) <= 3);
    //i am storing the vote details of each voters
        voteDetails storage VD =  _votedetails[_id];
    //i checked if the vote/poll has been created, to prevent voters from wasting vote
        require(VD.voteCreated == true, "invalid vote");
    //set the voter to true, to prevent multiple voting
        hasVoted[msg.sender] = true;
    //the user/voter rates here
        VD.rate = _rate;
    //i am inreasing the total number of vote here
        VD._noOfVOte +=1; 
    //i am checking the rate the user entered and increasing it by 1
    //@dev: if the options/choices has been increase
    //you need to add an if statement to check for the options also
        if (rating.good == _rate) good +=1 ;
        if (rating.average == _rate) average +=1;
        if (rating.bad == _rate) bad +=1;       
    }
    
    //this function gives the results 0f the vote 
    function totalVote() external view returns(uint, uint, uint){
    //the result is returned here
    //@dev:you need to add the choice/option that you included to be able to see the result
        return(bad, average, good);
    }

    //this gives the details of the votes
    function getVoteDetails(uint _id) external view returns(address, string memory, uint){
        voteDetails storage VD =  _votedetails[_id];
        //i checked if the vote/poll has been created for the id you enetring
        require(VD.voteCreated == true, "invalid vote id");
        //i returned the vote owners address
        //The topic/goal of the vote
        //The total number of vote that the poll/vote has accumulated
        return(VD.voteOwnerAddress, VD.Topic, VD._noOfVOte);
    }


}