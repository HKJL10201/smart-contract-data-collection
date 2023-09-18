// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Voting {
    //VARIABLES
    // STRUCTURE FOR A CURRENT VOTE
    struct vote{
          address voterAddress; //ADDRESS OF THE PERSON WHO VOTED
          bool choice;  //CHOICE OF THE PERSON WHAT HE HAD VOTED FOR 
    }
    //STRUCTURE FOR A VOTER
    struct voter{
        string voterName; //NAME OF THE PERSON WHO VOTED
        bool voted; //DID THAT VERSON VOTED OR NOT
    }
    // TO COUNT HOW MANY PEOPLE AGREED WITH MY PROPOSAL
    uint private countResult=0;
    uint public finalResult=0;

    //TO COUNT NUMBER OF VOTERS WHO REGISTERED THEMSELVES TO VOTE
    uint public totalVoter=0;

    //TO COUNT NUMBER OF VOTES BEING CASTED 
    uint public totalVote=0;
    
    //ADDRESS OF THE BALLOT OFFICIAL/ADMIN
    address public ballotOfficialAddress;

    //NAME OF THE ADMIN
    string public ballotOfficialName;

    //NAME OF THE PROPOSAL YOU WANT TO PLACE
     string public proposal;

    //TO MAP ID(INT) WITH THE VOTE
    mapping(uint => vote) private votes;

    //TO MAP CURRENT ADDRESS WITH THE VOTER
    mapping(address => voter) public voterRegister;

    // THREE STATES 1. VOTERS BEING CREATED , 2.VOTING IS TAKING PLACE ,3.VOTING ENDED
    enum State{Created , Voting ,Ended}

    State public state;

    //MODIFIERS(conditions)
    modifier condition(bool _condition){
        require(_condition);
        _;
    }
    //TO BE ACCESSED BY ADMIN
    modifier onlyofficial(){
        require(msg.sender == ballotOfficialAddress);
        _;
    }
    // TO CHECK IN WHICH STATE
    modifier inState(State _state){
        require(state == _state);
        _;
    }
    //FUNCTIONS
    constructor(
        string memory _ballotOfficialName,
        string memory _proposal
    ) {
    ballotOfficialAddress = msg.sender;
    ballotOfficialName = _ballotOfficialName;
    proposal = _proposal;
    state = State.Created;
    }


    //TO REGISTER/ADD A VOTER
    function addVoter(
        address _voterAddress,
        string memory _voterName
    )public
      inState(State.Created) //STATE MUST BE CREATED
      onlyofficial //VOTERES CAN BE ONLY ADDED BY THE ADMIN
    {
      voter memory v;
      v.voterName =_voterName;
      v.voted = false;
      voterRegister[_voterAddress] =v;
      totalVoter++;
    }


    //TO START THE PROCESS OF VOTING
    function startVote() 
      public
      inState(State.Created) //STATE MUST BE CREATED
      onlyofficial //VOTERES CAN BE ONLY ADDED BY THE ADMIN
    {
        state =State.Voting;
    }
    //TO CAST A VOTE
    function doVote(bool _choice)
    public 
    inState(State.Voting)
    returns (bool voted)
    {
      // CHECK WHETHER THE PERSON IS REGISTERED FOR VOTING OR IS BEING ADDED BY THE ADMIN TO CAST THE VOTE OR NOT
      bool isFound = false;
      //CHECK IF PERSON EXISTS OR NOT AND VOTER HAS ALREADY VOTED OR NOT THEN ONLY HE CAN CAST A VOTE
      if(bytes(voterRegister[msg.sender].voterName).length !=0 
           && voterRegister[msg.sender].voted == false)
           {
              voterRegister[msg.sender].voted == true;
              vote memory v;
              v.voterAddress = msg.sender;
              v.choice =_choice;
              if(_choice){
              countResult++;
              }
              votes[totalVote] = v;
              totalVote++;
              isFound = true;
           }
        return isFound;
    }

    // TO END THE PROCESS OF VOTING
    function endVote()
    public 
    inState(State.Voting)
    onlyofficial
    {
       state = State.Ended;
       finalResult = countResult;
    }
}
