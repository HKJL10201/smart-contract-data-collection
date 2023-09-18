pragma solidity ^0.5.0;
contract Insurance
{

    struct temp_teams
    {
        uint group_id;
        uint group_size;
        uint prem_amt;
        address[] user_id;
        bool payment_status;
    }
    address public contract_address;
    function getAddress()public
    {
        contract_address=address(this);
    }
 
    mapping(uint=>temp_teams) public temp_teamsData;
    //TODO:
    mapping(address=> uint) balances;
    
    function balanceOf() external view returns(uint)
    {
        return address(this).balance;
    }
    //TODO:
   

     
     uint public id=128965;
     address[]  public temp_user_id; //remember to push into this array to add the team mates.
     address public leader_addr;
     address payable recevier=address(uint160(leader_addr));
     uint public test_val;
     uint public test_val1;
     function enrollTeam(uint size, address id_user) public payable returns(uint)
     {
         for(uint i=0;i<temp_user_id.length;i++)
         {
             temp_user_id.pop();
         }
         if(size<=4)
         {
            balances[msg.sender] += msg.value;
            test_val=msg.value;

             id++;
             temp_user_id.push(id_user);
             leader_addr=temp_user_id[0];
             temp_teamsData[id]=temp_teams(id,size,40,temp_user_id,true);//payment_status=false
             //TODO:Send ERC Token from the address to the the contract 
             getAddress();
    
         }
         return(id);
     }

     
     temp_teams teams_ref;
     
    
    function joinTeam(uint grp_id, address id_user) public payable
    {
        balances[msg.sender] += msg.value;
        test_val1=msg.value;


         teams_ref=temp_teamsData[grp_id];
         
         if(teams_ref.group_size<=4 && teams_ref.payment_status==true)
         {
             temp_user_id.push(id_user);
             teams_ref.user_id=temp_user_id;
             
             //temp_teamsData[grp_id]=teams_ref;
             //TODO:Send ERC Token from the address to the the owner
         }
         
     }
     
     //SEND ERC From address to the addr[0]
     
     address payable[] recepients;
    address payable a;
    address payable b;

   
    function sendEther(address payable recepient) public{

        recepient.transfer(2 ether);
        //transfer 1 ether from smart contract to recipient
    }
    

    
   
 
    function() external payable
    {
        
    }
    
    function getBalanceCreate()external view returns(uint)
    {
        return(address(this).balance);
    }
    
     
}