pragma solidity ^0.8.0;

contract auction{
    uint[] indtial = [0];
    uint[] bidprice;
    address maxbider;
    uint mxx;
    
    uint i =0;
    constructor() {
        bidprice.push(indtial[0]);
        i++;
    }
    function bid(uint bidamount) public{
        require(bidamount > bidprice[0] && bidamount >= 100);
        bidprice[0] = bidamount;
        mxx = bidprice[0];
        maxbider = msg.sender;
    }
    function leadbidder() public view returns(address){
        return maxbider;
    }
    function currentmaxbid() public view returns(uint){
        return mxx;
    }
  
   
    
 
    
  
 
    
    
}