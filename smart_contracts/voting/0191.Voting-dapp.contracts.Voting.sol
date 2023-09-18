// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

error Voting__SendMoreEthToVote();
error Voting__ElectionNotOpen();
error Voting__RegisterationPeriodOver();
error Voting__EndOfElection();
error Voting__UserAlreadyExists();
error Voting__UserDoesntExist();
error Voting__YouHaveAlreadyVoted();
error Voting__ReceivingMoneyFailed();

/**@title A Voting Contract
 * @author Onwuka Rosario
 * @notice this contract is a voting app
 * 
 */

contract Voting{
    //type declarations
    enum ElectionState{
        OPEN,
        BUSY
    }
    struct CandidateDetails{
        uint256 candidateId;
        string name;
        address owner;
        uint256 numVotes;
    }
    struct ElectionDetails{
        string title;
        uint256 period;
    }
    struct VoterDetails{
        address owner;
    }
    mapping(address => VoterDetails) public addresstoVoters;

    ElectionDetails[]elections;
    mapping(string => ElectionDetails) public titleToElection;
    
   
    event CandidateName(string name);
    CandidateDetails[] public candidates;
    mapping(string => CandidateDetails) public numToCandidate;

   

    //variables
    uint256 private s_contractStartTime;
    ElectionState private s_electionState;
    string  votingTitle = "no election has started";
    address owner;
    uint256 votes;
    uint256 highestVotes = 0;
    string winner;
    address immutable i_myAccount = 0xD25E99a739566fee6Aa23Ad287a4384Acb8db089;
    CandidateDetails[] winnerDetails;
    string[] public candidateNames;
    uint256 time;
    uint256 blocktimePeriod;
    uint256 canId;

    

    constructor(){
        s_contractStartTime = block.timestamp;
        s_electionState = ElectionState.OPEN;
        owner = msg.sender;
    }
    /**
    *@dev This is the function a user has to click to start an Election
    *he has to put in certain parameters as the title , period of registeration , time election should end
    *everything in the parameter is added to the struct and arrays for future use
    *vairables are set 
    */
    
    function startElection(string memory _title , uint256 _period)public payable {
      
        require(msg.value > 0, "not enough ETH");

        // require(s_electionState == ElectionState.OPEN , "There is an election in progress");
        
        titleToElection[_title] = ElectionDetails(
            _title,
            _period
        );
        elections.push(ElectionDetails(
            _title,
            _period
        ));


        votingTitle = _title;
        time = _period * 60;
        blocktimePeriod = block.timestamp + time;
        s_electionState = ElectionState.BUSY;

        
    }
    /**
    *@dev This function is the register function for users to be candidates in the election
    *in order for a user to register the following has to be true
    * 1)to make sure the user paid the right amount of ether
    * 2)to make sure there is an election in progress
    * 3)to make sure the period of registration hasnt been exceeded
    * 4)to ensure the users name  had not registered before
    * 5)to ensure the user isnt registering again with another username
    * if all these conditions are positive users get added to an array and struct to store their data
    */
    function register(string memory _name)public payable {
        if(msg.value  < 0.01 ether){
            revert Voting__SendMoreEthToVote();
        }
        //if election is not open
        if(s_electionState != ElectionState.BUSY){
            revert Voting__ElectionNotOpen();
        }
        // if registeration time is already over
        if(block.timestamp >= blocktimePeriod){
            revert Voting__RegisterationPeriodOver();
        }
        //if user name already exists
        for(uint256 i = 0; i < candidates.length ; i++){
            if( keccak256(abi.encodePacked((candidates[i].name))) == keccak256(abi.encodePacked((_name)))){
                revert Voting__UserAlreadyExists();
            }
        }
        //if user address already exists
         for(uint256 i = 0; i < candidates.length ; i++){
            if( candidates[i].owner == msg.sender){
                revert Voting__UserAlreadyExists();
            }
        }

        canId++;
        
        
        numToCandidate[_name]=CandidateDetails(
            canId,
            _name,
            msg.sender,
            votes
        );
        candidates.push(CandidateDetails(
            canId,
            _name,
            msg.sender,
            votes
        ));    
        candidateNames.push(_name);
    }
    /**
    *@dev This function is for users to vote for the candidates that registered for the election
    *the following conditions must be true before one can actually vote
    * 1) the user paid enough eth tho vote
    * 2) there is a proceeeding election
    * after these meet their requirements users vote for the candidates and the votes are updated in the struct and array
    */
    function vote(string memory _name)public payable{
           if(msg.value  < 0.01 ether){
            revert Voting__SendMoreEthToVote();
        }
          //if election is not open
        if(s_electionState != ElectionState.BUSY){
            revert Voting__ElectionNotOpen();
        }
           //if user name doesnt exists
        // for(uint256 i = 0; i < candidates.length ; i++){
        //     if( keccak256(abi.encodePacked((candidates[i].name))) == keccak256(abi.encodePacked((_name)))){
        //         revert Voting__UserDoesntExist();
        //     }
        // }
        //if voter has already voted before
        if(addresstoVoters[msg.sender].owner == msg.sender){
            revert Voting__YouHaveAlreadyVoted();
        }
        numToCandidate[_name].numVotes++;
        //to update value to the array
        for(uint256 i = 0; i<candidates.length; i++){
            if(keccak256(abi.encodePacked((candidates[i].name))) == keccak256(abi.encodePacked((_name)))){
                candidates[i].numVotes++;
            }
        }
        //adding users to voters array
        addresstoVoters[msg.sender]=VoterDetails(
            msg.sender
        );
    }
    /**
    *@dev This function is to check when the election will end..
    * if i do not summoun enough strength to use chainlink upkeep which i hope i do ill use a js function
    * to make sure this runs every second if the election period is over a winner is decided and election resets
    */
        function checkElectionEnd()public{
            if(block.timestamp >= blocktimePeriod){
                decideWinner();
                viewWinner();
            }
        }
    /**
    *@dev this function is to decide a winnner 
    */
       function decideWinner()public {
        for(uint256 i = 0; i<candidates.length; i++){
            if(candidates[i].numVotes > highestVotes ){
                highestVotes = candidates[i].numVotes ;   
            }
        }
        for(uint256 i = 0; i< candidates.length; i++){
            if(candidates[i]. numVotes == highestVotes){
                winner = candidates[i].name;
            }
            
        }
        //reversing all attributes to original since election has ended and there is no current elction on ground
        votingTitle = "no election has started";
        time = 0;
        blocktimePeriod = 0;
        s_electionState = ElectionState.OPEN;
        
        
   
    }
    /**
    *@dev this function is to withdraw all the money in this smart contract to mine😈
    * hope thi sblows so we can make it a real app 
    */
      function withdraw()public{
         //actually withdrawing funds
        (bool callSuccess , ) = payable(i_myAccount).call{value: address(this).balance}("");
        if(callSuccess){
            revert Voting__ReceivingMoneyFailed();
        }
    }

    //getter functions

    //this returns election details
     function getElectionDetails()public view returns(ElectionDetails memory){
        
        return elections[elections.length-1];
    }
    //this returns candidates
     function getCandidates()public view returns(CandidateDetails[] memory){
        return candidates;
    }
    
    
    //this returns the winner of the election
    function viewWinner()public view returns (string memory name){
        return winner;
    }
    function timeview()public view returns (uint256){
        return blocktimePeriod;
    }
    function blocktimestampe()public view returns (uint256){
        return block.timestamp;
    }

}