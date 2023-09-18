contract Auction {
   
    struct Bidder{
       address bidder_addr;
       uint[] items_to_bid;
       uint w;
    }
    
    struct Notary{
       address notary_addr;
    }
    
    address public auctioneer;
    address public highestBidder;
    bool public AuctionisEnded;
    uint public startBlock;
    uint public endBlock;
    uint public q;
    uint[] Items;
    Bidder[] public bidders;
    Notary[] public notaries;
    
    mapping(address => Notary) public bidderToNotary;
    
    function Auction(uint _m,uint _start,uint _end) public
    {
        // assert(_start >= _end);
        // assert(_start < block.number);
        // assert(_owner == 0);
        auctioneer = this;
        q = 17;
        for(uint i=1 ; i <= _m ; i++)
        {
           Items.push(i);
        }
       
       emit createAuction(q,_m);
    }
    
    event createAuction(uint t_q,uint m);

    function cancelAuction() public returns (bool success) {
        AuctionisEnded = true;
        return true;
    }
    
    function sqrt(uint x) returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return z;
    }

    function newBidder(uint[] S,uint V) public view returns (uint)
    {
        uint x;
        uint w;
        w = V / sqrt(S.length);
        
        for(uint i =0;i<S.length;i++){
            uint u = Math.floor(Math.random() * 10) + 1;
            uint v;
        }
        return w;
    }
    
    // Placing bid after checking the required condition
    function placeBid() public
        AfterStart
        BeforeEnd
        NotOwner
        AuctionEnd
        returns (bool success)
    {
        send_to_Notary();
        send_to_Auctioneer();
    }
    
    modifier AfterStart{
        assert(block.number < startBlock);
        _;
    }
    
    modifier BeforeEnd{
        assert(block.number > endBlock);
        _;
    }
    
    modifier NotOwner{
        assert(msg.sender == auctioneer);
        _;
    }
    
    modifier AuctionEnd{
        assert(AuctionisEnded);
        _;
    }
    
    function send_to_Notary() public {}
    function send_to_Auctioneer() public {}
}