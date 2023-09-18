pragma solidity  ^0.4.24;
// import "./usingOraclize.sol";
contract Auction
{
    struct Notary   // Notary struct -- may add more attributes to notary if necessary
    {
        address addr;
    }
    struct Bidder // Bidder struct -- 2D arrays for random representation of values
    {
        address addr;   // The unique address
        uint[2][] uv;   // The random representations of the items 
        uint[2] w;  // The random representation of w
    }
    struct Result // for storing result of comparision by notaries
    {
        address addr;
        uint u;  // u1-u2
        uint v;  // v2-v1
    }
    struct setIntersection // for storing result of intersections of item lists
    {
        address addr;
        bool intersect;
    }

    address public auctioneer;  // Auctioneer conducts the auction, maybe beneficiary also as of now?
    uint public q;  // Q decided by auctioneer
    bool auctionEnded = false;
    bool paymentsCalculated = false;
    
    Bidder[] public winners;  // containg list of winners
    Notary[] public notaries; // containg list of notaries
    Bidder[] public bidders; // containg list of bidders
    
    uint public count = 0;  // maintains count of notaries who have done comparision work
    uint public countIntersection = 0; // maintains count of notaries who have done determination of set intersections
    uint public constPayment  = 0;

    mapping(address => Notary) public bToN; // mapping between bidders and notaries
    mapping(address => uint[2]) public bidValues; // mapping between notaries and bid values of bidders assigned to them
    mapping(address => uint[]) public item_map; // mapping between notaries and set of items of bidders assigned to them
    mapping(address => setIntersection[]) public set_values; // mapping containing notaries address and set intersection results
    mapping(address => uint) public workDone; // mapping containg notaries address and amount to be paid to notaries
    mapping(address => Result[]) public results; // mapping between notaries and results of comparision used for sorting
    mapping(address => uint) public payments;
    mapping(address => uint) public notariesPayments;
    mapping(address => uint256) public pendingReturns;

    constructor (uint _q, uint _m) 
    public
    {
        auctioneer = msg.sender;
        q = _q;
        constPayment=q/10;
        emit auctionCreated(q, _m);
        // Auctioneer broadcasts the value Q and the no. of items m. 
    }

     // Modifiers
    modifier onlyIfTrue(bool x) { require(x == true, "Value of variable should be true"); _;}
    modifier onlyAuctioneer() {require(msg.sender == auctioneer, "Only Auctioneer is allowed to call this method"); _; }
    modifier workCompleted() { require(count == notaries.length, "All notaries have not finished work."); _; }
    modifier workCompleted1() { require(countIntersection == notaries.length, "All notaries have not finished work1."); _; }
    modifier isNotAuctioneer() {require(msg.sender != auctioneer, "Auctioneer is not allowed to call this method"); _; }
    modifier isNotBidder()
    {
        bool flag = false;
        for(uint i=0; i< bidders.length; i++)
        {
            if(msg.sender == bidders[i].addr)
            {
                flag = true;
            }
        }
        require(flag == false);
        _;
    }
    modifier isNotNotary()
    {
        bool flag = false;
        for(uint i=0;i<notaries.length; i++)
        {
            if(msg.sender == notaries[i].addr)
            {
                flag = true;
                break;
            }
        }
        require(flag == false);
        _;
    } 
    modifier sufficientNotaries()
    {
        require(notaries.length>=bidders.length,"Insufficient notaries registered");
        _;
    }
    modifier isNotary()
    {
        bool flag = false;
        for(uint i=0;i<notaries.length; i++)
        {
            if(msg.sender == notaries[i].addr)
            {
                flag = true;
                break;
            }
        }
        require(flag == true);
        _;
    } 
    
    // Events
    event bidGiven (address _bidder, uint[2][] _uv, uint[2] _w); // just for checking
    event auctionCreated(uint q, uint m);
    event auctionEnd();

    //Getter Functions for testing
    function getBiddersLength()
    public
    view
    returns(uint a)
    {   
        return bidders.length;
    }

    function getNotariesLength()
    public
    view
    returns(uint a)
    {
        return notaries.length;
    }
    // Bidder will bid using this function
    function registerBidder(uint[2][] _uv, uint[2] _w)
    payable
    isNotAuctioneer()
    isNotBidder()   // Same bidder can't bid more than once
    public
    {
        require( msg.value > _uv.length * (_w[0] + _w[1])%q, "Insufficient amount of ether sent");
        pendingReturns[msg.sender] = msg.value;
        bidders.push(Bidder({
            addr: msg.sender,
            uv: _uv,
            w: _w
        }));
        emit bidGiven(msg.sender, _uv, _w);

        // Assign a notary to this bidder
        // Throught mapping(notary ->  bidder) maybe?
    }

    // Notary will register using this function
    function registerNotary()
    isNotAuctioneer()
    isNotNotary()   // Same notary can't register more than once
    public
    {
        notaries.push(Notary({
            addr: msg.sender
        }));
    }

    /* 
    The auctioneer calls this to assign each bidder a notary
    The assigned notary must have access to the bid of each bidder.
    TODO: Only assigned notary should be able to see the bids
     */
    function assignNotary()
    onlyAuctioneer()    // Only auctioneer should be able to call this method
    public
    {
        for(uint i=0;i<bidders.length;i++)
        {
            bToN[bidders[i].addr] = notaries[i];
            bidValues[notaries[i].addr]=bidders[i].w;  // assigning bidding values of bidders to their notaries
            for(uint j=0;j<bidders[i].uv.length;j++)
            {
                item_map[notaries[i].addr].push((bidders[i].uv[j][0]+bidders[i].uv[j][1])%q); // assigning bidding items of bidders to notaries
            }
        }   
    }
    // uint count public =0;
    function performWork()
    isNotary()
    public
    {
        count++; // to maintain number of notaries who have done comparison work.
        uint[2] memory w2 = bidValues[msg.sender];  // u,v of bidder value of bidder assigned to notary
        for(uint i=0;i<notaries.length;i++){
            if(notaries[i].addr!= msg.sender){
                uint[2] memory w1 = bidValues[notaries[i].addr];
                results[msg.sender].push(Result({
                    addr: notaries[i].addr,
                    u: w2[0] - w1[0],
                    v: w1[1] -w2[1]
                }));  // add the val1 and val2 into the mapping
            }
        }
    }
    // Auctioneer starts the process to find the winner.
    
    function prior_Winner()
    isNotary()
    public
    {
        countIntersection++; // to maintain number of notaries who have done determination of intersection between sets.
        uint flag1=0;
        uint[] memory w2 = item_map[msg.sender];  // array of items for which bidding is to be done by that bidder
        for(uint i=0;i<notaries.length;i++)
        {
            flag1=0;
            if(notaries[i].addr != msg.sender)
            {
                uint[] memory w1 = item_map[notaries[i].addr];
                // setIntersection si;
                // si.addr = notaries[i].addr;
                bool _intersect = false;
                for(uint j=0;j<w2.length;j++){
                    for(uint k=0;k<w1.length;k++){
                        if(w2[j] == w1[k])
                        {
                            _intersect = true;
                            // si.intersect = true;
                            flag1=1;
                            break;
                        }
                    }
                    if(flag1==1)
                        break;
                    
                }
                set_values[msg.sender].push(setIntersection({
                    addr :  notaries[i].addr,
                    intersect : _intersect
                }));  // pushing true or false according to intersection found between array of items of different bidders
            }
        }
    }
    
    function findWinners()
    onlyAuctioneer()
    workCompleted1()
    public
    {
        winners.push(bidders[0]);  // first bidder in the list is always a winner so add directly
        pendingReturns[bidders[0].addr] -= ((bidValues[bToN[bidders[0].addr].addr])[0] + (bidValues[bToN[bidders[0].addr].addr])[1])%q;
        uint flag;
        for(uint i=1;i<bidders.length;i++){
            flag=0;
            for(uint j=0;j<winners.length;j++){
                
                workDone[(bToN[bidders[i].addr]).addr]++;
                workDone[(bToN[winners[j].addr]).addr]++;
                
                for(uint k=0;k<set_values[bToN[bidders[i].addr].addr].length;k++){
                    if(((set_values[bToN[bidders[i].addr].addr][k]).addr)==(bToN[winners[j].addr]).addr)
                    {
                        if((set_values[bToN[bidders[i].addr].addr][k]).intersect==true){
                            flag=1;  // if any intersection found break from loop
                            break;
                        }
                    }
                }
                if(flag==1)
                    break;
            }
            if(flag==0) //  if no intersection found between previous winner and current bidder make the bidder as a winner
            {
                winners.push(bidders[i]);
                pendingReturns[bidders[i].addr] -= ((bidValues[bToN[bidders[i].addr].addr])[0] + (bidValues[bToN[bidders[i].addr].addr])[1])%q;
            }
        }
        auctionEnded = true;
        emit auctionEnd();
    }
    
    function sortBidders()
    workCompleted() 
    onlyAuctioneer()
    public
    {
        // Sort the bidders array according to Procedure 1.
        for (uint i = 0; i <bidders.length; i++)      
        {
            // Last i elements are already in place   
            for (uint j = 0; j < bidders.length-i-1; j++){
                uint val1;
                uint val2;
                workDone[(bToN[bidders[j].addr]).addr]++;
                workDone[(bToN[bidders[j+1].addr]).addr]++;
                
                // for u1-u2
                for(uint k=0;k<results[(bToN[bidders[j].addr]).addr].length;k++)
                {
                    if((results[(bToN[bidders[j].addr]).addr][k]).addr==(bToN[bidders[j+1].addr]).addr)
                    {    
                        val1=(results[(bToN[bidders[j].addr]).addr][k]).u;
                        break;
                    }
                }
                
                // for v1-v2
                for(k=0;k<results[(bToN[bidders[j+1].addr]).addr].length;k++)
                {
                    if((results[(bToN[bidders[j+1].addr]).addr][k]).addr==(bToN[bidders[j].addr]).addr)
                    {    
                        val2=(results[(bToN[bidders[j+1].addr]).addr][k]).v;
                        break;
                    }
                }
               if((val1+val2)%q >= q/2) // if the condition is true swap the bidders and assigned notaries.
              {
                //   uint[2] memory w1 = bidValues[notaries[j].addr];   //There is no need to swap notaries because there is a mapping between bidders and notaries. -> i guesss it is necessary for the next step in which winner list is determined in the third loop we are accessing notaries array there so check that once..
                //   bidValues[notaries[j].addr] = bidValues[notaries[j+1].addr];
                //   bidValues[notaries[j+1].addr] = w1;
                  Bidder memory v=bidders[j];
                  bidders[j]=bidders[j+1];
                  bidders[j+1]=v;
                  
              }
            }
        }
    }

    function sqrt(uint x) 
    private
    returns (uint y) 
    {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function makePayments()
    onlyIfTrue(auctionEnded)
    onlyAuctioneer()
    public
    {
        for(uint it=0; it<winners.length; it++)
        {
            int idx=-1;
            uint[] memory w1=item_map[bToN[winners[it].addr].addr];
            bool flag = false;
            for(uint j=0;j<bidders.length;j++)
            {
                if(bidders[j].addr == winners[it].addr)
                {
                    continue;
                }
                uint[] memory w2 = item_map[bToN[bidders[j].addr].addr];
                for(uint it1=0;it1
                <w1.length;it1++)
                {
                    for(uint it2=0;it2<w2.length;it2++)
                    {
                        if(w1[it1] == w2[it2]){
                            idx=int(j);
                            flag = true;
                            break;
                        }
                    }
                    if(flag == true)
                        break;
                }
                if(flag == true)
                {
                    break;
                }
            }
            if(idx == -1)
            {
                payments[winners[it].addr]=0;
            }
            else
            {
                //biValues contains the value of w in the form of u,v u mean to use that here? or you want to sum all the item values?
                payments[winners[it].addr]=(((bidValues[bToN[bidders[uint(idx)].addr].addr])[0]+(bidValues[bToN[bidders[uint(idx)].addr].addr])[1]))*sqrt(w1.length);    
                pendingReturns[winners[it].addr] -= payments[winners[it].addr];
            }
        }   
    }

    function payNotaries()
    onlyIfTrue(auctionEnded)
    onlyAuctioneer()
    public
    {
        for(uint i=0;i<bidders.length;i++){
            notariesPayments[bToN[bidders[i].addr].addr]=workDone[bToN[bidders[i].addr].addr]*constPayment;
        }
        paymentsCalculated = true;
    }

    function withdrawNotaries()
    onlyIfTrue(paymentsCalculated)
    onlyIfTrue(auctionEnded)
    isNotary()
    public
    returns (bool)
    {
        uint amount=notariesPayments[msg.sender];
        if(amount > 0 ){
            notariesPayments[msg.sender]=0;
            msg.sender.transfer(amount);
        }
        return true;
    }

    function withdraw()
    onlyIfTrue(auctionEnded)
    public
    returns (bool)
    {
        uint256 amount = pendingReturns[msg.sender];
        if(amount > 0){
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
        return true;
    }
}
