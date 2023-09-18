pragma solidity ^0.4.22;
pragma experimental ABIEncoderV2;

contract Auction {
    
    address public auctioner;
    uint[] public m_items;
    int public q;
    uint public notary_count;
    uint public bidder_repr;
    
    uint[] public payment_record;
    
    constructor() public{
        auctioner = msg.sender;
    }
    
    struct Bidder{
        address bidder_addr;
        uint[2] value;
        uint[] u;
        uint[] v;
        uint assigned_notary;
        uint[] mod;
    }
    
    struct Notary{
        address notary_addr;
        uint exchange_val;
        uint assigned_bidder;
        bool assigned;
    }
    
    Bidder[] public bidders;
    Notary[] public notaries;
    Notary[] public assigned_notaries;
    Bidder[] public winner_bidder;
    
    //mapping(bidders[0].bidder_addr => notaries[0].notary_addr) public map; 
    
    function getAuctioner(int prime, uint[] m) public
    {
        q = prime;
        m_items = m;
    }
    
    
    function getBidder(uint[] x,uint[] y ,uint[2] w) public //view returns(address)
    {
        
        bytes20 b = bytes20(keccak256(msg.sender, now));
        uint addr = 0;
        for (uint index = b.length-1; index+1 > 0; index--) {
            addr += uint(b[index]) * ( 16 ** ((b.length - index - 1) * 2));
        }
        
        uint[] mod_array;
        for(uint i = 0;i<x.length;i++){
            uint take_mod = (x[i] + y[i]) % uint(q);
            mod_array.push(take_mod);
        }
        
        bidders.push(Bidder({
           bidder_addr: address(addr),
           u: x,
           v: y,
           value: w,
           assigned_notary : 0,
           mod: mod_array
        }));
        
        //return address(addr);
    }
    
    function getNotary() public //view returns (address) 
    {
        bytes20 b = bytes20(keccak256(msg.sender, now));
        uint addr = 0;
        for (uint index = b.length-1; index+1 > 0; index--) {
            addr += uint(b[index]) * ( 16 ** ((b.length - index - 1) * 2));
        }
        
        notaries.push(Notary({
            notary_addr: address(addr),
            exchange_val: 0,
            assigned_bidder: 0,
            assigned : false
        }));
        
        //return address(addr);
    }
    
   function notary_bidder_mapping() public{
       uint mod = notaries.length;
       for(uint i=0; i<bidders.length; i++){
           uint ran = uint8(uint256(keccak256(block.timestamp, block.difficulty))%mod);
           while (notaries[ran].assigned==true){
               ran = (ran+1) % mod;
           }
           bidders[i].assigned_notary = i;
           notaries[ran].assigned = true;
           assigned_notaries.push(Notary({notary_addr: notaries[ran].notary_addr,
               exchange_val: 0,
               assigned_bidder: i,
               assigned: true
           }));
       }
   }
   
  
   function comparison(uint bid1, uint bid2) public returns(int,int)//(uint,uint,uint,uint)
   {

        int val1 = int(bidders[bid1].value[0])-int(bidders[bid2].value[0]);
      int val2 = int(bidders[bid1].value[1])-int(bidders[bid2].value[1]);
      return (val1,val2);
   }
   
   
   function go_to_auctioner(int val1,int val2) public returns(int){
       int sum = val1+val2;
       if(sum == 0){
           return 0;
       }
       else if (sum < q/2){
           return 0;
       }
       else {
           return 1;
       }
       
   }
   
   function winner_set() public view returns (Bidder[]){
       
       uint len = assigned_notaries.length;
       uint[] arr;
       for(uint i=0;i<len;i++)
       {
           uint index = assigned_notaries[i].assigned_bidder;
           Bidder check_bidder =  bidders[index];
           uint mod_length = check_bidder.mod.length;
           
           bool flag;
           for (uint j = 0;j<mod_length;j++)
           {
                for (uint kj = 0; kj<arr.length; kj++)
                {
                    if( check_bidder.mod[j] == arr[kj])
                    {
                        flag = true;
                        break;
                    }
                }
                
                if(flag == true)
                {
                    break;
                }
           }
               
            if (flag == false)
            {
                winner_bidder.push(check_bidder);
                for(uint ki = 0;ki< mod_length;ki++)
               {
                   arr.push(check_bidder.mod[ki]);
               }
            }
            else
            {
                flag = false;
            }
       }
       return winner_bidder;
       
    }
   
   function sort() public view returns( Notary[]){
      uint len = assigned_notaries.length;
    //   return (len,assigned_notaries[0].assigned_bidder,assigned_notaries[1].assigned_bidder);    
      for(uint i=0 ; i<len-1 ; i++){
          for(uint j=0; j < len - i - 1; j++){
              uint k =j+1;
              (int val1,int val2) = comparison(assigned_notaries[j].assigned_bidder,assigned_notaries[k].assigned_bidder);
              //return (val1,val2);
              int check = go_to_auctioner(val1,val2);
              if(check == 1){
                  Notary memory temp1 = assigned_notaries[j];
                  Notary memory temp2 = assigned_notaries[j+1];
                  assigned_notaries[j] = temp2;
                  assigned_notaries[j+1] = temp1;
        
              }
          }
      }
      
     return (assigned_notaries);
     
    }
    
    
    
    
}