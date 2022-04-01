pragma solidity ^0.4.24;

contract Auctioneer{

    /* this variable holds the address of the moderator which will run the bidding */
    address public moderator;

    /* m is the set of all distinct items and q is a large prime number */
    uint[] public m;
    uint public q;

    /* Time when contract is created */
    uint startTime;

    /* Time passed after initialisation of contract */
    function getcurrTime() public view returns(uint a){
        return now - startTime;
    }

    /* Till {startTime + notaryDeadline} all notaries who want to take part should be registered*/
    uint notaryDeadline;
    
    /* Till {startTime + bidderDeadline} all bidders who want to take part should be registered*/
    uint bidderDeadline;
    
    /* The time until all the winners are found by the auctioneer */
    uint winnersFoundDeadline = 32519016732;    // year 3000, month 06, day 27

    /* to check the number of bidders registering for the auction */
    uint num_bidders;

    /* To store all the winners among the Bidders */
    uint[] public winners;

    /* This structure will represent each bidder in the game */
    struct Bidder{
        /* Address of Bidder */
        address account;
        /* Two arrays of variable size of type uint for storing item choices of bidder*/
        uint[] u;
        uint[] v;

        /* Two numbers w1 and w2 for representing W */
        uint w1;
        uint w2;
    }


    /* This structure will represent each notary in the game */
    struct Notary{
        address account;
    }
    
    /* For now any number of Bidders are allowed, but these must be kept private*/
    Bidder[] private bidders;

    /* For now any number of Notaries are allowed*/
    Notary[] public notaries;

    /* Stores the number of computations performed by the notary */
    mapping(address => uint) pendingReturns;

    /* To check that only one bidder can register from one address */
    mapping (address => uint) private is_bidder;
    

    /* is_notary(x) = 0 means he is not a notary, is_notary(x) = 1 means he is a notary and not been assigned yet, is_notary(x) = $someAddress$ means this notary has been assigned to a bidder
    This mapping needs to be private because it contains information about the bidders address which implies it contains bidders interested items and it's value also. */
    mapping (address => address) private is_notary;
    
    /* Mapping to store the notary corresponding to a bidder */
    mapping(address => address) private b_notary;
    
    /* find weather 2 bidders have their sets as intersection */
    mapping(uint => uint[]) private intersect;
    
    /* Number of notaries which are not assigned yet */
    uint num_not_asgnd_notary = 0;
    

    function getNotarycnt() public view returns(uint a){
        return notaries.length;
    }
    function getBiddercnt() public view returns(uint a){
        return bidders.length;
    }
    
    function getWinnerscnt() public view returns(uint a){
        return winners.length;
    }
    function getWinners(uint i) public view returns(uint a){
        return winners[i];
    }
    function getBidderidx(address _a) public view returns(int a){
        int res=-1;
        for (uint i = 0;i < bidders.length; i++){
            if(_a == bidders[i].account)
                res = int(i);            
        }
        return res;
    }
    function getBidderadd(uint _a) public view returns(address a){
        return bidders[_a].account;
    }
    function getmod() public view returns(uint a){ 
        return q;
    }
    
    function getAssignedNotary(address _a) public view returns(address a){
        return b_notary[_a];
    }
    
    function bid_val1(uint pos) public view returns(uint a){ 
        return bidders[pos].w1;
    }   
    function bid_val2(uint pos) public view returns(uint a){
        return bidders[pos].w2;
    }

    function getPendingReturn(address _a) public view returns(uint a){
        return pendingReturns[_a];
    }
    

    // ensures the call is made before certain time
    modifier onlyBefore(uint _time){
        require(now - startTime < _time, "Too Late"); _;
    }

    // ensures the call is made after certain time
    modifier onlyAfter(uint _time){
        require(now - startTime > _time, "Too early"); _;
    }

    // ensures only the moderator is calling the function
    modifier onlyModerator(){
        require(msg.sender == moderator, "Only Moderator is allowed to call this method"); _;
    }
    
    // ensures one of the Bidder is calling the function
    modifier isBidder(){
        bool is_bidder_var = false;
        for(uint i = 0;i < bidders.length; i++){
            if(msg.sender == bidders[i].account)
                is_bidder_var = true;
        }
        require(is_bidder_var == true, "You are not part of this auction"); _;
    }
    
    /* You can call this event to check what all items are available for auction */
    event displayItems(uint[] m);

    /* To display the bidder array */
    event displayBidder(address b);

    /* To display booleans */
    event displayBool(bool b);
    
    /* To display the winners finally */
    event auctionEnd(uint[] w);
    
    /* To display uint */
    event displayuint(uint a);
    
    /* Takes no of of items, prime number, Time after which notary registeration will close (measured from startTime),
    Time after which bidder registeration will close (measured from startTime), */
    constructor (uint _noofitems, uint _q, uint _notaryDeadline, uint _bidderDeadline) public{
        notaryDeadline = _notaryDeadline;
        bidderDeadline = _bidderDeadline;
        startTime = now;
        moderator = msg.sender;
        for(uint i = 0;i < _noofitems; i++){
            m.push(i+1);
        }
        q = _q;
        emit displayItems(m);
    }
    
    /* A public function which will register the notary iff one has not registered before */
    function registerNotary()
    public
    
    // allow registration of notaries only before the notaryDeadline
    onlyBefore(notaryDeadline)
    {
        require(is_notary[msg.sender] == 0, "Sorry, but you have already registered for this auction as a notary");
        is_notary[msg.sender] = 1;   // Means now this is present
        notaries.push(Notary({account:msg.sender}));
        num_not_asgnd_notary += 1;
    }
    
    /* A public function which will register the bidders, But here the one public address can place multiple bids*/
    function registerBidder(uint[] _u, uint[] _v, uint _w1, uint _w2)
    public
    payable
    
    // allow registration of bidders only before the bidderDeadline
    onlyBefore(bidderDeadline)
    {
        // For checking that the pair's array are equal in length
        require(_u.length == _v.length, "Wrong input format");
        bool is_item = false;
        for(uint i = 0;i < _u.length; i++){
            uint x = (_u[i] + _v[i])%q;
            is_item = false;
            for(uint j = 0;j < m.length; j++){
                if(x == m[j]){
                    is_item = true;
                    break;
                }
            }
            // All the items that the bidder is interested in, should be available in the set m
            require(is_item == true, "The items you sent are not correct");
        }
        /* Checking if the bidder has already registered */
        require(is_bidder[msg.sender] == 0, "Sorry, but you have already registered for this auction as a bidder");
        is_bidder[msg.sender] = 1;          // Add it to the map
        /* Assigning random notary to the bidder */
        require(assign_notary(Bidder({account:msg.sender, u:_u, v:_v, w1:_w1, w2:_w2})) == true, "No notaries are available");
        uint mon_recieved = ((_w1+_w2)%q)*sqroot(_u.length);
        uint recieved = msg.value;
        // emit displayuint(mon_recieved);
        // emit displayuint(recieved);
        require(recieved >= mon_recieved, "Insufficient funds");
        bidders.push(Bidder({account:msg.sender, u:_u, v:_v, w1:_w1, w2:_w2}));
        pendingReturns[msg.sender] = msg.value;
    }
    
    /* A random number generator, returns number between zero and n*/
    function random(uint n) private view returns (uint8) {
        if(n == 0)
            return 0;
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%n);
    }
    
    /* A function to randomly assign a notary to a bidder */
    function assign_notary(Bidder _b) private returns (bool) {
        if(num_not_asgnd_notary == 0)   return false;
        uint x = random(num_not_asgnd_notary);
        for(uint i = 1;i <= notaries.length; i++){
            if(x >= num_not_asgnd_notary)   return false;
            if(is_notary[notaries[i-1].account] == 1){
                if(x == 0){
                    /* Handling the case where notary comes equal to the bidder */
                    if(notaries[i-1].account == _b.account){
                        if(num_not_asgnd_notary == 1)   return false;   // When only one notary is available and the bidder is also the nottary himself
                        i = 0;
                        x++;
                        x = x % num_not_asgnd_notary;
                    }
                    else{
                        is_notary[notaries[i-1].account] = _b.account;  // storing the bidder corresponding to the notary
                        b_notary[_b.account] = notaries[i-1].account;   // storing the notary corresponding to the bidder
                        num_not_asgnd_notary--;
                        return true;
                    }
                }
                else
                    x--;
            }
        }
        return false;
    }

    /* A function to test sorting */
    /* NOTE: value of (w1 + w2)%q < q/2 as mentioned in the news forum */
    uint[] ani;
    uint[] gul;
    Bidder temp_try;
    function help() public{
        ani.push(1);gul.push(19);
        bidders.push(Bidder({account:1, u:ani, v:gul, w1:30, w2:9}));
        bidders.push(Bidder({account:2, u:ani, v:gul, w1:30, w2:13}));
        bidders.push(Bidder({account:3, u:ani, v:gul, w1:30, w2:12}));
        bidders.push(Bidder({account:4, u:ani, v:gul, w1:30, w2:10}));
        auctioneer_sort();
        for(uint i = 0;i < bidders.length; i++){
            emit displayBidder(bidders[i].account);
        }
         emit displayBool(compare(1, 0));
         emit displayBool(compare(0, 1));
    }
    
    function auctioneer_sort() public {
        if(bidders.length >= 2){
            sort(0, int(bidders.length - 1));
        }
        for(uint i = 0;i < bidders.length/2; i++){
            temp_try = bidders[i];
            bidders[i] = bidders[bidders.length - i - 1];
            bidders[bidders.length - i - 1] = temp_try;
        }
    }
    
    function sort(int low, int high) internal {
        int i = low;
        int j = high;
        if(i == j)  return;
        uint pivot = uint(low + (high - low) / 2);
        while(i <= j){
            while(compare(uint(i), pivot) == false) i++;
            while(compare(pivot, uint(j)) == false) j--; 
            // while(bidders[uint(i)] < pivot) i++;
            // while(pivot < bidders[uint(j)]) j--;
            if(i <= j){
                temp_try = bidders[uint(i)];
                bidders[uint(i)] = bidders[uint(j)];
                bidders[uint(j)] = temp_try;
                i++;
                j--;
            }
        }
        if(low < j){
            sort(low, j);
        }
        if(i < high){
            sort(i, high);
        }
    }
    
    function compare(uint i, uint j) public returns(bool){
        Bidder storage x = bidders[i];
        Bidder storage y = bidders[j];
        pendingReturns[b_notary[x.account]]++;    // work performed by the notary is stored here
        pendingReturns[b_notary[y.account]]++;    // work performed by the second notary is here
        uint val1 = x.w1 - y.w1;
        uint val2 = x.w2 - y.w2;
        if(val1 + val2 == 0 || val1 + val2 < q/2){
            return true;    // x >= y
        }
        else
            return false;   // x < y
    }
    
    function cmp_items(uint i, uint j) internal{
        for(uint k = 0;k < bidders[i].u.length; k++){
            for(uint l = 0;l < bidders[j].u.length; l++){
                pendingReturns[b_notary[bidders[i].account]]++;   // work performed by notaries is here
                pendingReturns[b_notary[bidders[j].account]]++;
                uint val1 = bidders[i].u[k] - bidders[j].u[l];
                uint val2 = bidders[i].v[k] - bidders[j].v[l];
                if(val1 + val2 == 0){
                    intersect[i].push(j);   // pushing in both the lists
                    intersect[j].push(i);   // pushing in both the lists
                    return;
                }
            }
        }
    }
    
    function compute_intersect() public{
        for(uint i = 0;i < bidders.length; i++){
            for(uint j = i;j < bidders.length; j++){
                cmp_items(i, j);
            }
        }
    }
    
    /* given two bidders, returns weather their items intersect or not */
    function do_intersect(uint i, uint j) public view returns(bool){
        for(uint k = 0;k < intersect[i].length; k++){
            if(intersect[i][k] == j)
                return true;
        }
        return false;
    }
    
    function find_winners() 
    public
    
    onlyModerator
    onlyAfter(bidderDeadline)
    {
        auctioneer_sort();
        compute_intersect();
        for(uint i = 0;i < bidders.length; i++){
            bool is_winner = true;
            for(uint j = 0;j < winners.length; j++){
                if(do_intersect(winners[j], i) == true){
                    is_winner = false;
                    break;
                }
            }
            if(is_winner == true){
                winners.push(i);
                emit displayBidder(bidders[i].account);
            }
        }
        find_payments();
        emit auctionEnd(winners);
        winnersFoundDeadline = 0;   // means now winners are found
    }
    
    
    /* To withdraw the leftover amounts */
    function withdraw()
    public
    onlyAfter(winnersFoundDeadline)
    returns(bool)
    {
        uint amount = pendingReturns[msg.sender];
        if(amount > 0){
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);    
        }
        return true;
    }
    
    function sqroot(uint x) public pure returns(uint y){
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function find_payments() public{
        for(uint i = 0;i < winners.length; i++){
            // need to find proper j and k values as specified in the doc
            uint j;
            bool cond = true;
            for(uint id = 0;id < bidders.length; id++){
                if(do_intersect(id, winners[i]) == false){  // means there intersection must not be phi
                    continue;
                }
                j = id; // choosing my j as id
                cond = true;
                for(uint k = 0;k < j; k++){  // checking if any k is not satisfying the given condition
                    if(winners[i] == k) continue;        // given k != j
                    if(do_intersect(k, j) == true){      // this should never happen
                        cond = false;
                        break;
                    }
                }
                if(cond == true){
                    // my j is found
                    uint pay = ((bidders[j].w1 + bidders[j].w2) % q) * sqroot(bidders[winners[i]].u.length);
                    pendingReturns[bidders[winners[i]].account] -= pay;
                    break;
                }
            }
            if(cond == false){
                // no j found, hence payment is equal to zero
                pendingReturns[bidders[winners[i]].account] -= 0; // no money deducted
            }
        }
    }
}
