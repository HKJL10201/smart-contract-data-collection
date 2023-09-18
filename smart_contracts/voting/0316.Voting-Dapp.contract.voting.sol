//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract voting{
    //@author: BlackAdam
    //This code allows a single poll to be created with 3 options (No, Undecided, Yes)
    //@dev: the options can be inreased and cutomize


    //The id of the poll is declared here
    uint32 public ID = 1;

    //this keeps the details of the poll/vote created
    //voteOwnerAddress: the address of the owner of the vote/poll
    //Topic: The topic/goal of your poll/vote
    //_noOfVOte: gives the total number of votes the poll/vote generated
    //rate: this keeps tracks of the enums we declared and the options declared there
    //voteCreated: this allow the users/voters to know if a poll/vote has been created
    //votingPeriod: this set the duration for the poll/vote that a user create

    struct voteDetails{
        address voteOwnerAddress; //20bytes
        string Topic;
        string Details;
        string bannerURL;
        uint120 _noOfVOte;
        Rating rate;
        uint32 votingPeriod;
        uint32 No; // 4 byte
        uint32 Undecided;
        uint32 Yes; 
    }

    //these are the option that the voters/user can select from
    //No: 0, Undecided: 1, Yes: 2
    /// @dev: any new options can be added here and these can also be customized
    enum Rating{
        No,
        Undecided,
        Yes   
    }

    //this map a uint to a voteDetails
    mapping (uint => voteDetails) _votedetails;

    //this keeps track of people who have voted before, to prevent an address from voting twice
    mapping(address => mapping(uint => bool)) hasVoted;

    modifier exists(uint _id){
        require(_id < ID, "vote does not exist");
        _;
    }

    //the vote/poll is created here
    function createVote(
        string memory _topic, uint duration, string memory bannerLink, string memory _details
        ) 
        external returns(uint, string memory)
    {
        voteDetails storage VD =  _votedetails[ID];
        VD.voteOwnerAddress = msg.sender;
        VD.Topic = _topic;
        VD.Details = _details;
        VD.bannerURL = bannerLink;
        VD.votingPeriod = uint32(block.timestamp + (duration * (1 days)));
        uint currentId = ID;
        ID++;
        return(currentId, "Created Succesfully");
    }

    //this function allows the user to vote 
    function Vote(uint32 _id, uint _rate) external exists(_id){

        require(!hasVoted[msg.sender][_id], "already voted");
        require(_rate <= 2, "invalid Rating");

        voteDetails storage VD =  _votedetails[_id];

        require(block.timestamp <= VD.votingPeriod, "Voting has ended");

        hasVoted[msg.sender][_id] = true;
        VD._noOfVOte++; 

        if (_rate == 0){
            VD.No += 1;
            VD.rate = Rating.No;
        }else if (_rate == 1){
            VD.Undecided += 1;
            VD.rate = Rating.Undecided;
        } else{
            VD.Yes += 1;
            VD.rate = Rating.Yes;
        }        
    }

    //this gives the details of the votes
    function getVoteDetails(uint _id) 
        external view exists(_id)
        returns(address, string memory, string memory, uint, uint32, string memory, uint32, uint32, uint32)
    {
        voteDetails storage VD =  _votedetails[_id];
        return(
            VD.voteOwnerAddress, 
            VD.Topic, VD.Details, 
            VD._noOfVOte, 
            VD.votingPeriod, 
            VD.bannerURL, 
            VD.No, 
            VD.Undecided, 
            VD.Yes
        );
    }

    //this function returns the timeleft for a particular poll
    function timeLeft(uint _id) external view exists(_id) returns(uint32) {
        voteDetails storage VD =  _votedetails[_id];
        return uint32(VD.votingPeriod - block.timestamp);
    }


}