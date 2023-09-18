// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12; //support arrays of strings
import "@openzeppelin/contracts/utils/Strings.sol";


contract PartyConvention {

    /*

            ConventionRoles
    GUEST:                  can see the results of Votings
    MEMBER:                 can create motions, can initially support motions, can run in elections
    ALTERNATEDELEGATE:     can hold votingRights, can transfer votingRights, can requestVotingRightsBack, can vote
    DELEGATE:               gets votingRight after being added, can reclaim his/her original voting right
    ADMIN:                  can add/modify/delete participants, can create/start elections, can close Votings

    Every role includes the rights of lesser roles.

            VotingTypes
    MOTION:                MOTION Votings can receive "yes"/"no"/"abstain" votes. Per voting right one can choose either "yes", "no", or "abstain".
    ELECTION:              For elections of persons to party offices    
   
    */

    enum ConventionRole{GUEST, MEMBER, ALTERNATEDELEGATE, DELEGATE, ADMIN} 
    enum VotingStage{PREPARED, OPEN, CLOSED}
    enum VotingType{MOTION, ELECTION }
    
    uint public votingRightsCounter = 0;
    mapping(address => Participant) public participants;
    address[] public participantsArray;
    Voting[] public votings;

//##################################################################################################################
//########################################### All Objects/Classes/Structs ##########################################
   
    struct Participant {
        ConventionRole role;
        address votingRight1from;
        address votingRight2from;
    }
    struct Option{                       //a Voting consists of options. The name of an option can be e.g. "yes", "no", "abstain", "candidate 1", candidate 2", etc.
        string text;
        uint voteCount;
    }
    struct Voting{
        uint id;
        string text;                     //text is what will be voted on. Eg. "Who should be elected as new chairperson?", "are you in favor of Voting xyz?"
        VotingType vtype;
        VotingStage stage;
        Option[]   options;
        address[]  voters; 
        address[]  initialSupporters;    //10 DELEGATEs or 30 Members are needed as supporters for a MOTION to be called to a vote
    }



//##################################################################################################################
//########################################### Constructor ##########################################################


    constructor(){
        Participant memory creator;
        creator.role=ConventionRole.ADMIN;
        creator.votingRight1from=msg.sender;
        participants[msg.sender] = creator;
        participantsArray.push(msg.sender);
        votingRightsCounter++;
    }
    
    
  

//##################################################################################################################
//############################## Internal Helper Functions #########################################################


    function compareString(string memory str1, string memory str2) public pure returns (bool) { //this function was found at https://www.educative.io/answers/how-to-compare-two-strings-in-solidity
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function append( string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) { //this function is oriented at https://ethereum.stackexchange.com/questions/729/how-to-concatenate-strings-in-solidity
    return string(abi.encodePacked(a, b, c, d,e));
    }

    function noOpenVotings() internal view returns (bool){
        for (uint i=0; i<votings.length;i++ ){
            if (votings[i].stage == VotingStage.OPEN){
                return false;
            }
        }
        return true;
    }

    function notContainedInArrayAddr(address[] memory arr_, address el_) pure internal returns (bool){
        for (uint i=0; i<arr_.length;i++ ){
            if (arr_[i] == el_){
                return false;
            }
        }
        return true;
    }

        function notContainedInArrayOption(Option[] memory arr_, string memory el_) pure internal returns (bool){
        for (uint i=0; i<arr_.length;i++ ){
            if (compareString(arr_[i].text , el_)){
                return false;
            }
        }
        return true;
    }

    function transfer(address fromwhom_, address towhom_, uint which_) internal{
        require(which_==1 || which_==2);

           if(participants[towhom_].votingRight1from == address(0)){
            participants[towhom_].votingRight1from = fromwhom_;
        } else{
            participants[towhom_].votingRight2from = fromwhom_;
        }
        if(which_==1){
            participants[fromwhom_].votingRight1from = address(0);
        }
        else{
            participants[fromwhom_].votingRight2from = address(0);

        }
    }

        function enoughSupporters(uint id_) view internal returns (bool){
        uint  DELEGATEs = 0;
        uint  members = 0;

        for (uint i=0; i<votings[id_].initialSupporters.length;i++ ){
            if (participants[votings[id_].initialSupporters[i]].role >= ConventionRole.DELEGATE){
               DELEGATEs++;
            }
            members++;
        }
        return DELEGATEs>=3 || members >=5;

    }


//##################################################################################################################
//####################################### Public Functions #########################################################

//ADMIN Level

    function addParticipant(ConventionRole role_, address addr_ )external{
        require(participants[msg.sender].role == ConventionRole.ADMIN, 
        "Only admins can add new convention participants."); 

        require(participants[addr_].votingRight1from==address(0) 
        && participants[addr_].votingRight2from==address(0), 
        "The Participant was already added and holds voting rights." );

        require(noOpenVotings(), 
        "Can not add new participants while voting is going on.");

        Participant memory newParticipant;
        newParticipant.role = role_;
        if (role_ >= ConventionRole.DELEGATE){
            newParticipant.votingRight1from =addr_;
            votingRightsCounter++;
        }
        participants[addr_]  = newParticipant;
        participantsArray.push(addr_);
    }

    function closeVoting(uint id_) external{
        require(participants[msg.sender].role == ConventionRole.ADMIN, "Only admins can close Votings."); 
        require(votings[id_].stage==VotingStage.OPEN, "Only open Votings can be closed.");
        votings[id_].stage = VotingStage.CLOSED;
    }

    function startElection(uint id_) external{
        require(participants[msg.sender].role == ConventionRole.ADMIN, "Only admins can start elections."); 
        require(votings[id_].stage==VotingStage.PREPARED, "Only prepared Votings can be started.");
        votings[id_].stage = VotingStage.OPEN;
    }


    function createElection(string memory txt_) external returns (uint){
        require(participants[msg.sender].role == ConventionRole.ADMIN, "Only admins can create elections."); 
        uint votingCounter = votings.length;
        Voting storage v=  votings.push();
        v.id = votingCounter;
        v.text = txt_;
        v.vtype = VotingType.ELECTION;
        v.stage = VotingStage.PREPARED;
        Option storage o1 = v.options.push();
        o1.text = "abstain";
        o1.voteCount = 0;
        return v.id;
    }


//DELEGATE Level


    function reclaimVote() external returns(bool){
        require(participants[msg.sender].role >=ConventionRole.DELEGATE, 
        "Only DELEGATEs can reclaim their original voting right.");

        require(participants[msg.sender].votingRight1from == address(0) 
        || participants[msg.sender].votingRight2from == address(0), 
        "Reclaimer already holds 2 active voting rights");

        require(participants[msg.sender].votingRight1from != msg.sender 
        && participants[msg.sender].votingRight2from != msg.sender, 
        "Reclaimer already holds his/her original voting right");
        
        for (uint i=0; i< participantsArray.length;i++){
            if(participants[participantsArray[i]].votingRight1from==msg.sender){
                transfer(participantsArray[i],msg.sender,1);
                return true;
            }
            if(participants[participantsArray[i]].votingRight2from==msg.sender){
                transfer(participantsArray[i],msg.sender,2);
                return true;
        }   }
        return false;
    }

//(ALTERNATE)DELEGATE Level

    function vote(uint Votingid_, uint optionid_) external{
        require(participants[msg.sender].role 
            >=ConventionRole.ALTERNATEDELEGATE, 
        "Only (ALTERNATE)DELEGATEs can cast votes.");

        require(votings[Votingid_].stage == VotingStage.OPEN, 
        "Voting is not open for voting.");

        require(participants[msg.sender].votingRight1from!=address(0) 
        || participants[msg.sender].votingRight2from!=address(0), 
        "No active voting rights held by sender");

        require(participants[msg.sender].votingRight1from!=address(0) 
        && notContainedInArrayAddr(votings[Votingid_].voters, 
                    participants[msg.sender].votingRight1from) 
        || participants[msg.sender].votingRight2from!=address(0) 
        && notContainedInArrayAddr(votings[Votingid_].voters, 
                    participants[msg.sender].votingRight2from), 
        "Vote(s) were already cast");

        if(participants[msg.sender].votingRight1from!=address(0) 
        && notContainedInArrayAddr(votings[Votingid_].voters, 
                    participants[msg.sender].votingRight1from)){
            votings[Votingid_].voters.push(
                participants[msg.sender].votingRight1from);
            votings[Votingid_].options[optionid_].voteCount++;
        }

        if(participants[msg.sender].votingRight2from!=address(0) 
        && notContainedInArrayAddr(votings[Votingid_].voters, 
                    participants[msg.sender].votingRight2from)){
            votings[Votingid_].voters.push(
                participants[msg.sender].votingRight2from);
            votings[Votingid_].options[optionid_].voteCount++;
        }

        if(votings[Votingid_].voters.length >= votingRightsCounter){ 
            votings[Votingid_].stage=VotingStage.CLOSED; 
    }  }

    function transferVotingRight1(address towhom_) external{
        require(participants[msg.sender].role >=ConventionRole.ALTERNATEDELEGATE, "Only (ALTERNATE)DELEGATEs can transfer voting rights.");
        require(participants[towhom_].role >=ConventionRole.ALTERNATEDELEGATE, "Only (ALTERNATE)DELEGATEs can receive voting rights.");

        require(participants[msg.sender].votingRight1from != address(0), "Message sender does not hold any voting right 1.");
        require(participants[towhom_].votingRight1from == address(0) || participants[towhom_].votingRight2from == address(0), "Receiving (ALTERNATE)DELEGATE has already 2 active voting rights");

        require(noOpenVotings(), "Can not transfer votes during open voting processes");

        transfer(msg.sender,towhom_, 1);
       
    }
    
    function transferVotingRight2(address towhom_) external{
        require(participants[msg.sender].role >=ConventionRole.ALTERNATEDELEGATE, "Only (ALTERNATE)DELEGATEs can transfer voting rights.");
        require(participants[towhom_].role >=ConventionRole.ALTERNATEDELEGATE, "Only (ALTERNATE)DELEGATEs can receive voting rights.");

        require(participants[msg.sender].votingRight2from != address(0), "Message sender does not hold any voting right 1.");
        require(participants[towhom_].votingRight1from == address(0) || participants[towhom_].votingRight2from == address(0), "Receiving (ALTERNATE)DELEGATE has already 2 active voting rights");

        require(noOpenVotings(), "Can not transfer votes during open voting processes");

        transfer(msg.sender,towhom_, 2);
       
    }

//MEMBER Level

    function createMotion(string memory txt_) external returns (uint){
        require(participants[msg.sender].role >=ConventionRole.MEMBER, "Only party members can create a MOTION Voting.");
        require(noOpenVotings(), "Can not create new Votings while voting is going on.");
        uint votingCounter = votings.length;
        Voting storage m =  votings.push();
        m.id = votingCounter;
        m.text = txt_;
        m.vtype = VotingType.MOTION;
        m.stage = VotingStage.PREPARED;

        Option storage o1 = m.options.push();
        o1.text = "abstain";
        o1.voteCount = 0;

        Option storage o2 = m.options.push();
        o2.text = "yes";
        o2.voteCount = 0;

        Option storage o3 = m.options.push();
        o3.text = "no";
        o3.voteCount = 0;

        m.initialSupporters.push(msg.sender);
      
        return m.id;
    }

    function runInElection(uint electionID_, string memory name) external {
        require(participants[msg.sender].role >=ConventionRole.MEMBER, "Only party members can run for office.");
        require(votings[electionID_].stage==VotingStage.PREPARED, "One can only run for a not yet started election.");
        require(notContainedInArrayOption(votings[electionID_].options,name), "A member can only run once for the same office."); 

        Option storage o1 = votings[electionID_].options.push();
        o1.text = name;
        o1.voteCount = 0;

    }

    function supportMotion(uint id_) external{
        require(participants[msg.sender].role >=ConventionRole.MEMBER, "Only party members can initially support a MOTION .");
        require(votings[id_].stage==VotingStage.PREPARED, "Only prepared motions can be supported.");

        require(notContainedInArrayAddr(votings[id_].initialSupporters,msg.sender), "A member can only once support a MOTION initially."); //Note: a transferred voting Right does not transfer the right to initially support a Voting
        votings[id_].initialSupporters.push(msg.sender); //The sender is added as a new supporter
        if (enoughSupporters(id_)){
            votings[id_].stage=VotingStage.OPEN; // If one of the thressholds is reached for the Motion, the voting regarding the Motion can start.
        }
    }


   
//GUEST Level

    function seeResults(uint Votingid_) view external returns(string memory result){
        require(votings[Votingid_].stage == VotingStage.CLOSED, "Voting is not closed yet.");
        result = "";
        for (uint i =0; i < votings[Votingid_].options.length;i++){
            string memory count = Strings.toString(votings[Votingid_].options[i].voteCount);
            result = append(result, votings[Votingid_].options[i].text, ":",count,"." );
        }
        return result;

    }


}