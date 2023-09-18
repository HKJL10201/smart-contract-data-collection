pragma solidity ^0.4.0;

contract voting_mechanism
{
    uint cnt_of_staff=99;
    uint vote_id = cnt_of_staff+1;
    uint voter_id = cnt_of_staff+1000;
    uint poller_id=15648;
    string key="EC123";
    mapping (string => uint) cnt_with_card;
    
    mapping (uint =>uint) count_vote;

    mapping (string =>uint) find_id;
    mapping (string => string) code_to_party;
    mapping (string => uint) vote_of_party;
    string one="1";
    string two="2";
    string three="3";
    string four="4";

    function getvote_id() public view returns (uint)
    {
        return vote_id;
    }
    
     string mesg="All Data will show 0 for voter and have only authority view";
    function VoteCount(uint id) public view returns(uint,uint,uint,uint,string)
    {
          
          if(id==15648)
          {
               return (vote_of_party[one],vote_of_party[two],vote_of_party[three],vote_of_party[four],mesg);
          }
          return (0,0,0,0,mesg);
    }
    struct voter
    {
        string voter_aadhar;
        string party_name;
        string party_code;
        address ownership;
    }
    
    mapping (uint => voter) public voters;
    
    string a1="VOTER"; 
    string a2="DEPARTMENT";
    mapping (string => uint) aadhar_to_vodeid;
    function CastVote(uint sid, string types, string name, string specs) public returns (uint)
    {
        
           
             /*
             vote_id++ ;
            uint vot_id = vote_id;
            
            voters[vot_id].voter_aadhar = types;
            voters[vot_id].party_name = name;
            voters[vot_id].ownership = users[sid].USERAddress;
            voters[vot_id].party_code = specs;
            */
            
            string s=users[sid].name;
            if(cnt_with_card[s]==0)
            {
                vote_id++;
                 uint vot_id = vote_id;
            
                 voters[vot_id].voter_aadhar = types;
                 voters[vot_id].party_name = name;
                 voters[vot_id].ownership = users[sid].USERAddress;
                 voters[vot_id].party_code = specs;
                aadhar_to_vodeid[s]=vot_id;
                vote_of_party[name]++;
            }
            cnt_with_card[s]++;
            count_vote[sid]++;
            
            
            return aadhar_to_vodeid[s];
            
            
       
    } 
    function getparty() public
    {
           code_to_party[one]="Bharatiya Janata Party";
           code_to_party[two]="Indian National Congress";
           code_to_party[three]="Aam Aadmi Party";
           code_to_party[four]="Trinamool Congress";
    }
    function Voterdetail(uint id) public view returns(string, string, address, string)
    {
        getparty();
        string s;
        s=voters[id].party_name;
        s=code_to_party[s];
        return (voters[id].voter_aadhar, s, voters[id].ownership, voters[id].party_code);
    }

    //======================================================================================
    //current voters
    struct current_user
    {
        string name;
        string password; 
        address USERAddress;
        string type_user;
    }
    
    mapping(uint => current_user)public users;
    function getID() public view returns(uint)
    {
        
        return voter_id-1;
    }
    function setcurrent_user(string _name, string pass, address Add, string typeuser) public returns(uint)
    {
           uint id = voter_id ; 
              voter_id++;
            users[id].name = _name;
            users[id].password = pass;
            users[id].USERAddress = Add;
            users[id].type_user = typeuser;
           
    
           return id;
    }
    
    
    
    function getcurrent_users(uint id)public view returns (string , string , address , string )
    {
        return (users[id].name,  users[id].password , users[id].USERAddress, users[id].type_user);
    }
    
    //==================================================================================
    //Login users
    function login (uint id, string pass, string types)public returns (bool)
    {
        /*
        if(keccak256(users[id].type_user) == keccak256(types))
        {    
            if(keccak256(users[id].password) == keccak256(pass))
            {
                return true;
            }
        }
        */
        if(keccak256(types)==keccak256(a2))
        {
            if(id==poller_id && keccak256(pass)==keccak256(key))
            {
                return true;
            }
            else
            return false;
        }
        else if(keccak256(users[id].type_user) == keccak256(a1))
        {    
            if(keccak256(users[id].password) == keccak256(pass))
            {
                return true;
            }
        }
        return false;
    }
    
    
    function EditVote(uint u_id1, uint u_id2, uint _cid) public returns (bool)
    {
        if(count_vote[u_id1]>0)
        {
            string s;
            if(u_id2==1)
            {
               s=one;
            }
            if(u_id2==2)
            {
               s=two;
            }
            if(u_id2==3)
            {
               s=three;
            }
            if(u_id2==4)
            {
               s=four;
            }
            vote_of_party[voters[_cid].party_name]--;
            voters[_cid].party_name=s;
            vote_of_party[s]++;  
            return (true);
        }
        return (false);
       
        
    }
    
    
     
}