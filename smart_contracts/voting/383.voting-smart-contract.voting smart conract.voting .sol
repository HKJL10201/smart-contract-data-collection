// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract voting{
    // this is user defined data type related to candidate details
    struct Candidate{
        string candidate_name;
        address candidate_id;
        uint vote_count;
        bool supported;

    }

    event Registered(address candidateid, string candidatename, uint256 candidatenum );
    event Supported(address voter, address candidate);
    event Voted(address voter,address candidate);


    // giving refrencing uisng maping
    mapping(address=>bool) voters; /* this will give a voter is voted our not*/

    mapping(uint=> Candidate)public candidates; //this will help us to track candidate

    address public Vt_admin;

    uint public candidates_count;  //this will store how many candidates ragistred
    uint256 public start_time;   //this will store when time is start for voting
    uint256 public stop_time;  //this will store when time is end with help of timestamp

    constructor(){
        Vt_admin = msg.sender;  // here I am specfing that this person is smart contract deplopyer         

    } 

    //  here I have created a function for adding candidate for join the vting as per the requirement 
   function add_candidate (string memory _name) public payable{
       require (msg.value == 1 ether ,"please enter atleast 0.1 eather"); //here I set the some amount to registre any candidate for voting
       candidates_count ++;                            
       candidates[candidates_count] = Candidate(_name,msg.sender,0,false);
       emit Registered(msg.sender,_name,candidates_count); 
     }
  // this function will show wether this a candidate supported or not
     function supprt_candidate(uint256 _candidateid) external{
         require(candidates[_candidateid].candidate_id !=address(0x00),"not register"); //here i chaeck candidate ragister our not
         require(candidates[_candidateid].candidate_id !=msg.sender,"can not support to his self"); //here i check whether a candidate supporting to his self our not
         require(candidates[_candidateid].supported == false, "you already supported this ");  //here cheking a person is not supporting again same candidate

         candidates[_candidateid].supported=true; //this will show candidate is supported 

         emit Supported(msg.sender,candidates[_candidateid].candidate_id);

     }
    //  this voting contract can start only voting admin
     modifier vtadminonly(){
         require(msg.sender == Vt_admin,"voting can start vtadmin");
         _;
     }
    //  is this we set our time,when voting will be start
     function setstarttime(uint256 num) external vtadminonly{
         require(num >= block.timestamp, "start at earlier time" );
         start_time =num;   
     }

    //  here will be set ,when voting will be end
     function setstoptime(uint num) external vtadminonly{
         require(num > block.timestamp && num > start_time, "stop at leter time");
         stop_time =num;   
     }
  //in this will give vote
//   count the vote and store that
     function vote(uint _candidateid) public {
         require(block.timestamp > start_time , "voting is  not started " );
         require(block.timestamp <= stop_time, "voting  over");
         require(voters[msg.sender]== false , "already voted");
         require(candidates[_candidateid].candidate_id !=address(0x00),"candidate not ragistred");
         require(candidates[_candidateid].supported == true , "do not vot this ,its not supported");
         

         voters[msg.sender] == true;
        candidates[_candidateid].vote_count++;

        emit Voted(msg.sender, candidates[_candidateid].candidate_id);
        }

        //  this function will give the result of voting that who is win
        // we can calculate the candidate votes
        function winner() public view returns (Candidate memory candidate){
        require(block.timestamp >= stop_time,"please wait till then voting completed");
        uint256 x;
        uint256 max=0;
        for(uint i=1; i<=candidates_count; i++)
            {
            if(candidates[i].vote_count > max){
                max=candidates[i].vote_count;
                x=i;
            }
            return candidates[x];
        }
    }

}