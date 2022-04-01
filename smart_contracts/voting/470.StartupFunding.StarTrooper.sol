pragma solidity ^0.4.18;

contract StarTroopChallenge {

    //Declaring Variables


    enum challengeStatus {Initiated,Registration,Voting,Closed} //This variable allow us to determine in which phase is our challange

    challengeStatus public status;
    address owner; // Owner of the contract


    struct idea { //structure to handle Ideas information
        address submitter;     // Addres of the submitter of the idea;
        uint targetEther;   // This value will define the required ether that the startup is aiming to reach;
        string whitePaperUrl;  // This string will hold the white paper URL;
        //bytes20 hashCommit;  // As the github commit is mapped based on the sha1 hashing with 40 hex decimal chars we can convert this into a 20 bytes based input to lower memory usage;
        string hashCommit;     // As the github commit is mapped based on the sha1 hashing with 40 hex decimal chars we can convert this into a 20 bytes based input to lower memory usage;
        uint128 voteCount;      //Vote count that will be filled during voting part;
        }


    struct Challange {  // This struct will hold the challenge data

        address challengeSubmiter;   //Address of owner of challange

        //Metadata related with the challenge
        string challengeName;          //Name of the challenge that is running;
        string challengeDescription;   //Description of the challenge that is running
        uint deadlineRegistration;  //Deadline date of the challenge that is running
        bool typeRegistration;         //Define type of registration deadline limit; 0 - nº Participants/ 1- nº Blocks
        uint deadlineVotation;      //Define nº days of deadline Votation

    }
    mapping (uint128=> Challange) public challangeList; // This mapping allow us to keep track of different challanges that have been made and to check values
    mapping (uint => idea) ideaList; //In order to mapp all the submited ideas we create an array addressed by an ID

    ///Votting Variables
    struct Votes{ //This structure will empower the counting of votes and guarantee that an address can't vote twice on the same idea
        uint voteNumber;
        mapping (address=>bool) votedAddress;
        mapping (uint=>address) SequencialVoter; //Enables to validate in the end the address on voteList and to multiply them by the heigh factor;

    }

    mapping (uint=> Votes) votesPerIdea;  //This pointer relates the ideaNumber with the details of the votes to it;
    uint[] nonZeroVotes;                 //Array to keep track of non zero votes; This can reduce workload of validation on the end
    ///Related to investment Mappings;
    mapping (address=>uint) investmentStack; //This pointer tracks the investment of each address;
    mapping(uint=>address) investorDetails; //This pointer tracks the Investor Address


    ////////


    //Counter to allow for sequencial numeration

    uint128 numberChallenges;
    uint128 ideaNumber;
    uint investorNumber;
    uint128 counterNotNulls;
    uint voteValue; //Counter Value;
    //////////////
    //Signal events declations
    event lastIdeaAdded(uint id);
    event LogFailure(string);
    event ChallengeNameRunning(string name);
    event ChallengeNumber(uint number);
    //////////////
    //Modifiers Declarations

    modifier requesterOnly(address _account)        {
        require(msg.sender == _account,"Sender not authorized."); //Generic restriction to stop usage if necessary (eg: only onwer or only challenge submitter)
        _;}

    modifier statusTypeOnly(uint _statusRequirment){
        require(uint(status) == _statusRequirment,"Function only available on this challenge status."); //Generic restriction to stop usage based on the challenge status
        // Status= 0 -> Initiated
        // Status= 1 -> Registration
        // Status= 2 -> Voting
        // Status= 3 -> Closed
        _;}

    modifier DeadlineNOTReached(){
        require(now<challangeList[numberChallenges].deadlineVotation,"Voting deadline Already Reached."); //Generic restriction to stop usage when deadline votation reached
        _;}

     modifier DeadlineReached(){
        require(now>challangeList[numberChallenges].deadlineVotation,"Voting deadline Already Reached."); //Generic restriction to stop usage when deadline votation reached
        _;}


    modifier checkZero(uint _ValueToCompareZero){  //This generic restriction targets to stop conditions where values are zero. Example: Check if an investor is listed in the investor list or to check if the msg have balance to pass;
        require(_ValueToCompareZero>0); //
        _;}
        //////////////


    //Constructor to define the owner of the contract and ensure some super user tools to it;
    function StarTroopChallenge() public{
        owner=msg.sender;
        status =challengeStatus.Initiated;
        numberChallenges=0;
        }



    //Function to start StarTroopChallenge
    function StartChallenge (string _nameChallange, string _descriptionChallenge, bool _typeRegistration, uint _registrationNumber, uint _votingNumber) public statusTypeOnly(0) {
        //new challange is initiated; This function will only be available during finished challenges(including started one);
        require( _registrationNumber>0 &&  _votingNumber>0); //checks if the deadlines provided are not in the future. If one is equal to 0 stops execution because one date is not in the future

       emit ChallengeNumber(numberChallenges);
       // Counter Number are reloaded to 0 so it can be reused;
        ideaNumber=0;
        investorNumber=0;


        challangeList[numberChallenges]=Challange(msg.sender,_nameChallange,_descriptionChallenge,_registrationNumber,_typeRegistration,_votingNumber);
               //define Type of registration scenario

        emit ChallengeNameRunning(_nameChallange);

        if(_typeRegistration==true) {
        //false means that the deadline on registration process will be defined by participants; No edition required
        //True means that deadline will be defined in blockNumber
            challangeList[numberChallenges].deadlineRegistration=block.number+_registrationNumber;
            }

         status =challengeStatus.Registration; //status will pass to state of registration

        }

    //////////////////////////////////////////////////
    //Idea registration related functions (status =1)

     function submittingIdea(uint128 _requiredEther,string _whitePapperUrl,string _hashCommit) public statusTypeOnly(1) {

         //////
         //This validations will check if the deadlines (Blocks or participants) have been achieved;
        if(challangeList[numberChallenges].typeRegistration==false && ideaNumber==challangeList[numberChallenges].deadlineRegistration){
            emit LogFailure("Number Ideas already Reached");
        throw;
         }
          //
         if(challangeList[numberChallenges].typeRegistration==true && block.number>challangeList[numberChallenges].deadlineRegistration){
            emit LogFailure("Registration period reached deadline");
        throw;
            }

        /////
        //As the validations have been made and are ok one can register this idea if its eligible;
        //Vote counter is defined to 0;
        ideaList[ideaNumber]=idea(msg.sender,_requiredEther,_whitePapperUrl,_hashCommit,0);
        ideaNumber=ideaNumber+1;
     }

    //Voting Scheme related functions (Status=2)

    //enable voters to addInvestment into its pool to reforce the position
    function addInvestment() public payable checkZero(msg.value) DeadlineNOTReached statusTypeOnly(2){
        //The checks done to this function are: Check if the msg comes with balance/ Check if we are on the voting phase/ Check if deadline of voting phase is not reached
        //
        if(investmentStack[msg.sender]==0){ //Checks if the Investor doesn't exit
          //user doesn't exist;
          //Ether register is saved in wei;
          investmentStack[msg.sender]=investmentStack[msg.sender]+msg.value;
          investorDetails[investorNumber]=msg.sender;
          investorNumber=investorNumber+1;
        } else{
          investmentStack[msg.sender]=investmentStack[msg.sender]+msg.value;

        }




    }

    //enable voters to vote an idea
    function voting(uint _ideaID) public checkZero(investmentStack[msg.sender]) DeadlineNOTReached statusTypeOnly(2){ //Triple validation - Is Voting Part // The deadline was not reach yet // CheckZero to see if the investor exists;

        if (_ideaID>ideaNumber-1){
           emit LogFailure("Submited Vote for nonexistent idea;");
        throw;}

        if(votesPerIdea[_ideaID].voteNumber==0){ //This condition Initializates the voting structure for its firts time
          //Fills the Voting details
          Votes memory VoteInstance; //creates an instance so we can incializate the votesPerIdea
          votesPerIdea[_ideaID]=VoteInstance;
          votesPerIdea[_ideaID].votedAddress[msg.sender]=true; //Disable voting for this account;
          votesPerIdea[_ideaID].SequencialVoter[0]=msg.sender; //Starts list of voting address of the idea
          votesPerIdea[_ideaID].voteNumber=1;                  //As this is the initial instance it will receive a vote
        }

        if(votesPerIdea[_ideaID].votedAddress[msg.sender]==false){ //This condition aims to prevent double voting;
          //Fills the Voting details
          votesPerIdea[_ideaID].votedAddress[msg.sender]=true;
          votesPerIdea[_ideaID].SequencialVoter[votesPerIdea[_ideaID].voteNumber]=msg.sender;
          votesPerIdea[_ideaID].voteNumber=votesPerIdea[_ideaID].voteNumber+1;
        }
    }


    //Final action functions
    function closeChallange() public payable DeadlineReached statusTypeOnly(2) { //When the deadline is reached one can close the challenge and assign the prize to the winner idea and return the remaining value to the investors
        //Check if all ideas are zero
        uint k;// Local variable
        uint j;
        uint l;
        uint[] voteValues;
        uint maxValue =0;
        uint winnerIdea;
        uint valueToSent;

        address dummieAccount;
        for (uint i=0;i<ideaNumber-1;i++){
            if(votesPerIdea[i].voteNumber>0){
                counterNotNulls=counterNotNulls+1;
                nonZeroVotes.push(i);
            }
        }

        if (counterNotNulls<0){ //There is ideas with votes
            //Check for Winner idea
            for (i=0;i<counterNotNulls;i++){
                voteValue=0;
                //votesPerIdea[nonZeroVotes[i]].voteNumber
                for (k=0;k<votesPerIdea[nonZeroVotes[i]].voteNumber;k++){
                  dummieAccount= votesPerIdea[nonZeroVotes[i]].SequencialVoter[k];
                  voteValue=voteValue+investmentStack[dummieAccount];
                } //Access Idea being analyzed;

                if (voteValue>maxValue){winnerIdea=nonZeroVotes[i];} //The value is compared to check for the maximum (all values area analyzed); The maximum value is the only one that we will save
                //voteValues.push[voteValue];//the value of the vote is stacked into the array
            }

            //All Value of the investors that point into an idea will be sent to the winner startup

            for (j=0;j<votesPerIdea[winnerIdea].voteNumber;j++){
                dummieAccount= votesPerIdea[nonZeroVotes[i]].SequencialVoter[k];
                valueToSent=investmentStack[dummieAccount];
                investmentStack[dummieAccount]=0;
                dummieAccount.send(valueToSent); //Pay the Amount //Reset Value
                }
        }

        //Reverts all the remaining Ether
        for(l=0;l<investorNumber;l++){
            dummieAccount=investorDetails[l];
            valueToSent=investmentStack[dummieAccount];
            investmentStack[dummieAccount]=0;
            dummieAccount.send(valueToSent);
        }

        status =challengeStatus.Closed;
    }






    //Close registration and pass state into voting phase
    function closingRegistration() public statusTypeOnly(1){
         //This function will change the phase of challenge from Registration to Voting
        if(challangeList[numberChallenges].typeRegistration==false && ideaNumber==challangeList[numberChallenges].deadlineRegistration){
            status=challengeStatus.Voting; //changes status
            challangeList[numberChallenges].deadlineVotation=now+ challangeList[numberChallenges].deadlineVotation*1 days;    //will add the number of days to the timestamp of the current block where the transaction is made;
            }

         if(challangeList[numberChallenges].typeRegistration==true && block.number>challangeList[numberChallenges].deadlineRegistration){
            status=challengeStatus.Voting;
            challangeList[numberChallenges].deadlineVotation=now+ challangeList[numberChallenges].deadlineVotation*1 days;
            }
     }


     //Close



    //Restart Challenge



    //General Getter Funtions





}
