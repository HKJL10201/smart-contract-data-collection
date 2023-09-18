pragma solidity ^0.4.7;
//pragma experimental ABIEncoderV2;
contract auction
{
    event Print(string str1,address addrr);
    event Print1(string str2,uint x2);
    
    uint numBidders;
    uint currNotaries = 0; 
    uint currBidders = 0; 
    uint numItems;
    uint public q;
    
    uint[] Items;
    address public auctioneer;
    address[] public Winners;

    uint[] public items_WinnersSet;
    uint[] temp_arr;
    
    address[] public notary_address;
    mapping(address=>uint) payment_map;     
    mapping(address => notary) public notary_map;
    mapping(address => address) public bidder_notary_map;
    mapping(address => address) public notary_bidder_map;
    mapping(address => bidder) public bidder_map;
    mapping(address => bidder) public notary_bidder_struct_map;
    
    struct bidder
    {
        address account;
        bool isValid;
    }
    
    struct notary
    {
        address account;
        uint u;
        uint v;
        uint w;
        
        uint[] items;
        uint[] item_u;
        uint[] item_v;
        
        uint payment_amt;               // amount bidder will pay
        uint charge;                    // amount notary charge for every interaction
        uint num_of_interactions;       
        
        bool isValid;
    }
    
    
    constructor (uint _q, uint[] M,uint _n) public {
        auctioneer = msg.sender;
        q = _q;
        uint flag=0;
        if(q==1 || q==0)
            flag=1;
        for(uint j=2;j<q;j++)
        {
            if(q%j==0)
            {
                flag=1;
                break;
            }
        }
        //condition checking whether q is prime or not
        require(flag==0,"Pass prime number as q");
        uint l = M.length;
        numItems=l;
        numBidders = _n;
        //storing items {1 to m} into Items
        for(uint i=1;i<=l;i++)
        {
            Items.push(i);
            emit Print1("Items main",i);
        }
    }
    
    //each notary registers for the auction using registerNotary() function
    function registerNotary(uint _charges) public payable
    {
        //condtion to check if number of notaries registered doesnot exceed total limit on number of bidders 
        require(currNotaries < numBidders,"notaries limit exceeded");

        //condition to checkk if same address is already registered as bidder
        require(bidder_map[msg.sender].isValid==false,"This address is already registered as bidder");

        //condtion to check if same address is assigned to two notaries
        require(notary_map[msg.sender].isValid==false,"already notary registered");
        
        //condition to check if auctioneer is again registering
        require(auctioneer!=msg.sender,"Auctioneer can't be notary");

        //assigning a distinct address to each notary
        
        currNotaries = currNotaries + 1;
        notary_map[msg.sender].isValid = true;
        notary_map[msg.sender].account = msg.sender;
        notary_map[msg.sender].charge = _charges;
        notary_address.push(msg.sender);
    }
    
    //each bidder registers for the auction using registerBidder() function
    function registerBidder(uint _u,uint _v,uint[] _item_u,uint[] _item_v) public payable
    {
        //condtion to check if number of bidders registered doesnot exceed total limit on number of bidders
        require(currBidders<numBidders,"Bidders limit exceeded");
        
        //condition to check if same address is registered as notary
        require(notary_map[msg.sender].isValid==false,"This address is registered as notary already");

        //condtion to check if same address is assigned to two bidders
        require(bidder_map[msg.sender].isValid==false,"This address is registered as bidder already");

        //condtion to check if number of bidders donot exceed number of notaries as we have to assign notaries to bidder on the fly
        require(currBidders+1<=currNotaries,"notaries cannot be assigned");

        //condition to check if auctioneer is again registering
        require(auctioneer!=msg.sender,"Auctioneer can't bid");
    
        require(_item_u.length <= numItems,"Bidding for items which are not there");
        require(_item_v.length <= numItems,"Bidding for items which are not there");
        require(_item_u.length==_item_v.length,"Give compatible values");

        //Checking whether bidder has enough money
        //require( msg.value >= ((_u+_v)%q),"Not enough ether");

        //assigning a distinct address to each bidder
        bidder_map[msg.sender].account = msg.sender;
        bidder_map[msg.sender].isValid = true;
        
        //assign notaries to bidders and send (u,v) pairs to notaries

        //temp.w = (_u+_v)%q;
        
        uint i23 = 0;
        uint temp1;
        
        temp_arr.length = _item_u.length;
        for(i23 = 0;i23< _item_u.length;i23++){
            temp1 = (_item_u[i23] + _item_v[i23])%q;
            require(temp1!=0,"item number cannot be zero");
            
            uint b1;
            for(b1=0;b1<temp_arr.length;b1++){
                if(temp_arr[b1]==temp1){
                    break;
                }
            }
            require(b1==temp_arr.length,"cannot bid multiple times for same item");
            
            temp_arr[i23] = temp1;
            emit Print1("Items=",temp1);
        }
        
        
        bidder_notary_map[msg.sender] = notary_address[currBidders];
         
        address notary_addr = notary_address[currBidders];
        notary_bidder_map[notary_addr] = msg.sender;
        notary_map[notary_addr].u = _u;
        notary_map[notary_addr].v = _v;
        notary_map[notary_addr].w = (_u+_v)%q;
        
        notary_map[notary_addr].item_u = _item_u;
        notary_map[notary_addr].item_v = _item_v;
        notary_map[notary_addr].items = temp_arr;
        
        temp_arr.length=0;
        notary_bidder_struct_map[notary_addr] = bidder_map[notary_bidder_map[notary_addr]];
        currBidders = currBidders + 1;
    }
    
    
    //Insertion sort
    function sortfunction()  public returns (address[],uint)
    {
        uint i;
        uint j;
        
        for(i=1;i < notary_address.length; i++)
        {   
            uint  u_i = notary_map[notary_address[i]].u;
            uint  v_i = notary_map[notary_address[i]].v;
            address key=notary_address[i];
            j = i-1;
            
            while (j >= 0)
            {
                uint  u_j = notary_map[notary_address[j]].u;
                uint  v_j = notary_map[notary_address[j]].v;
                
                uint val1 = (u_i-u_j)%q;
                uint val2 = (v_i-v_j)%q;
                
                // number of times notaries interact with auctioneer
                notary_map[notary_address[j]].num_of_interactions+=1;
                notary_map[notary_address[i]].num_of_interactions+=1;
                
                if((val1+val2)%q < q/2)
                {
                    notary_address[j+1] = notary_address[j];
                    if(j==0)
                    {
                        break;
                    }
                    j = j-1;
                }
                else
                {
                    break;
                }
            }
            notary_address[j+1] = key;
        }
        return (notary_address,notary_address.length);
    }
   
    // function to find square root
    function sqrt(uint x) returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return z;
    }
    
    // check for intersection of items list
    function is_disjoint_set(address w, address nn) returns (bool){
        uint len1;
        uint len2;
        len1 = notary_map[w].items.length;
        len2 = notary_map[nn].items.length;
        
        uint l;
        uint k;
        for(l = 0 ; l<len2 ; l++)
        {
            for(k = 0 ; k<len1 ; k++)
            {
                if(notary_map[w].items[k] == notary_map[nn].items[l] && notary_map[nn].items[l]!=0)
                {
                    // second highest bid is what the respective winner will pay to auctioneer
                    if(notary_map[w].payment_amt < notary_map[nn].w * sqrt( notary_map[w].items.length))
                        notary_map[w].payment_amt = notary_map[nn].w * sqrt( notary_map[w].items.length);
    
                    return false;
                }
            }
        }        
        return true;        
    }
   
    // winner determination algorithm
    function get_Winner() public returns (address[],uint)
    {
        require(auctioneer==msg.sender,"Only auctioneer can call get_Winner function");
        Winners.push(notary_address[0]);
        
        // Finding the Winners
        uint ii;
        uint flag;
        uint size_notary = notary_address.length;
        uint size_winner;
        
        uint jj;
        for(ii = 1 ; ii < size_notary ; ii++)
        {
            flag = 0;
            require(flag==0,"flag not zero");
            size_winner = Winners.length;
            for( jj = 0 ; jj < size_winner ; jj++)
            {
                if(!is_disjoint_set(Winners[jj],notary_address[ii])){
                    break;
                }
            }
            if(jj==size_winner)
            {
                Winners.push(notary_address[ii]);
            }
        }
        return (Winners,Winners.length);
    }
    
    // List of amount which bidders will pay after the completion of auction
    uint[] public bidders_payment;
    function get_bidders_payment() public view returns (uint[] bidders_p){
        uint a1 = 0;
        for(a1=0;a1<notary_address.length;a1++){
            bidders_payment.push(notary_map[notary_address[a1]].payment_amt);
        }
        return bidders_payment;
    }
    
    // List of amount which notaries will receive after the completion of auction
    uint[] public notary_payment;
    function get_notaries_payment() public view returns (uint[] notaries_p){
        uint a2 = 0;
        for(a2=0;a2<notary_address.length;a2++){
            notary_payment.push((notary_map[notary_address[a2]].num_of_interactions) * (notary_map[notary_address[a2]].charge));
        }
        return notary_payment;
    }    
}