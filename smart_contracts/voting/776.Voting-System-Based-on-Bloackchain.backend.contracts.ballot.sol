// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract first{

    enum Role{admin,non_admin}
 
    struct Voter {
        string name;
        address voter_address;
        bool voted;  // if true, that person already voted
        uint aadhar; 
        Role role; 
        bool is_valid;
        bytes32 passw;       
    }

    mapping(address=>uint) public address2index;

    // uint index = 1;
    
    Voter[] public voterlist;

   
    struct Candidate{
        // address 
        string name;
        uint votes;
        string party;
        
    }

    // mapping(uint => Candidate) public CandidateList;
    Candidate[] public CandidateList;
    // uint[] Candidateids; 
    // uint[] aadhars;

    struct  Ballot{
        bool is_voting_started;
        uint totalVotes;
    }

    Ballot public ballot = Ballot({is_voting_started :true , totalVotes:0});
    constructor(){
        voterlist.push(Voter({
            name: "admin",
            voted:false,
            voter_address: 0x0000000000000000000000000000000000000000 ,
            aadhar:100000000000,
            role:Role.admin,
            is_valid:true,
            passw:keccak256(abi.encodePacked("no pass"))
        }));

    }

    function createVoter(address voter_add,string memory _name ,
                        uint aadh,uint8 _role,string memory _passw) public{
        bool aadhar_present = false;
        bool address_present = false;
        for(uint i =0;i<voterlist.length;i++){
            if(voterlist[i].aadhar == aadh){
                aadhar_present = true;
            }
            if(voterlist[i].voter_address == voter_add){
                address_present = true;
            }
        }
        require(aadhar_present == false,"Aadhar is already present at index");
        require(address_present == false,"Address is already in use");

        // aadhars.push(aadh);
        address2index[voter_add] = voterlist.length;
        voterlist.push(Voter({
            name: _name,
            voted:false,
            aadhar:aadh,
            voter_address:voter_add,
            role:Role(_role),
            is_valid:true,
            passw:keccak256(abi.encodePacked(_passw))
        }));
        // index++;
    }



    function addCandidatetoCandidateList(address v_add,string memory partyname) public{

        // uint Cid = address2index[v_add];

        CandidateList.push(Candidate({name :voterlist[address2index[v_add]].name ,
                                votes:0,
                                party:partyname}));
        // Candidateids.push(Cid);
    }

    function Vote(address v_add,uint cid,string memory _passw) public {

        uint vid = address2index[v_add];

        require(voterlist[vid].voted == false, "Voter already voted");
        require(voterlist[vid].is_valid == true, "Voter is invalid");
        require(ballot.is_voting_started == true, "Voting has not Started");
        require(voterlist[vid].passw == keccak256(abi.encodePacked(_passw)),"Wrong password");
              
            CandidateList[cid].votes = CandidateList[cid].votes + 1 ;
            voterlist[vid].voted = true;
            ballot.totalVotes++;
    }

    function finishVoting(address admin_add) public{
        require(voterlist[address2index[admin_add]].role == Role.admin,
                            "This action is only allowed by admin" );
        ballot.is_voting_started = false;
        for(uint i = 0; i < voterlist.length; i++){
            voterlist[i].voted = true;
        }
    }
    function startVoting(address admin_add) public{
        require(voterlist[address2index[admin_add]].role == Role.admin,
                            "This action is only allowed by admin" );
        ballot.is_voting_started = true;
        for(uint i = 0; i < voterlist.length; i++){
            voterlist[i].voted = false;
        }
        ballot.totalVotes = 0;
    }

    function calculatewinner() private view returns(uint[] memory) {
        uint maxx= 0;

        uint[] memory ids = new uint[](CandidateList.length);
        for(uint i = 0; i < CandidateList.length; i++){
            if(maxx < CandidateList[i].votes){
                maxx = CandidateList[i].votes;
            }
        }
        for(uint i = 0; i < CandidateList.length; i++){
            if(maxx == CandidateList[i].votes){
                ids[i] = 1;
            }else{
                ids[i] = 0;
            }
        }
        return (ids);
    }

    function getStats(address admin_add) public view returns (uint,Candidate[] memory , uint[] memory){
        require(voterlist[address2index[admin_add]].role == Role.admin,
        "This action is only allowed by admin" );
        require(ballot.is_voting_started == false,
        "The Voting is still going on. " );

        uint noVotes = voterlist.length - ballot.totalVotes;
        uint[] memory winnerids = calculatewinner();
        return (noVotes,CandidateList,winnerids);
    }
    function getCandidateList() public view returns(Candidate[] memory){
        return CandidateList;
    }

    function disable_a_Voter(address admin_add,address add) public {
        require(voterlist[address2index[admin_add]].role == Role.admin,
        "This action is only allowed by admin" );
        voterlist[address2index[add]].is_valid= false;
    }

    function enable_a_Voter(address admin_add,address add) public {
        require(voterlist[address2index[admin_add]].role == Role.admin,
        "This action is only allowed by admin" );
        voterlist[address2index[add]].is_valid= true;
    }


/*
        Admin:
         0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678

        c:
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

        V: 
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

        123412341234

        0x0000000000000000000000000000000000000000

*/ 

}