//pragma solidity ^0.4.0;
pragma experimental ABIEncoderV2;
contract Auction 
{
    
    uint startTime;
    uint endTime;
    uint q=0;
    uint M=0;
    
    
    //address of Notaries and auctioneer
    
    address autioneerAddress ;
    
    address []  notaryAddress ;
    address []  registeredBiddersAddress ;
    
    mapping (address => uint) bidderMap ;
    mapping (address => uint)  submittedBidders ;
    mapping (address => uint)  notaryMap;
    
    struct Notaries
    {
        address myAddress ;
    }
    
    struct Pair
    {
        uint u ;
        uint v ;
    }
    
    struct Bidders
    {
        Pair w  ;
        // set of items 
        Pair[] bidderChoice ;
        
        int assignedNotary ;
        address thisBiddersAddress ;
        
    }
    
    // array of Bidders
    Bidders[] biddersList ;
    
    
    //acutioneer will invoke the constructor
    constructor ( uint _q , uint _M ) public payable
    {
        q = _q ;
        M = _M ;
        startTime = now; // in seconds
        autioneerAddress = msg.sender;
        
    }
    
    
    //check not auctioneer
    modifier notAuctioneer()
    {
        require (msg.sender != autioneerAddress);
        _;
    }
    
    //check not Bidder
    modifier notBidder()
    {
        require (bidderMap[msg.sender] != 1);
        _;
    }
    
    //check not Notary
    modifier notNotary()
    {
        require (notaryMap[msg.sender] != 1);
        _;
    }
    
    //check wheather already submitted bid 
    modifier notSubmittedBid()
    {
        require ( submittedBidders[msg.sender] !=1);
        _;
    }
    
    // check wheather values given by bidder are correct
    modifier checkValidValues(uint[] U , uint[] V)
    {
        require( (validateValues(U , V)==true) && (U.length == V.length ));
        _;
    }
    
    function validateValues( uint[] U , uint[] V)
    returns (bool)
    {
        bool ans = true ;
        uint len = U.length;
        for (uint i =0;i<len ;i++)
        {
            if ( ( U[i]+V[i] ) %q > M )
            ans = false;
        }
        return ans ;
    }
    
    
    
    
    
    function registerAsNotary() public
    notAuctioneer()
    notBidder()
    notNotary()
    {
        Notaries temp;
        temp.myAddress = msg.sender;
        notaryMap[msg.sender ] = 1;
        notaryAddress.push(msg.sender);
    }
    
    
    
    // check wheather bidder is notary/autioneer/anyother bidder
    function registerAsBidder() public 
    notAuctioneer()
    notBidder()
    notNotary()
    returns (uint  , uint)
    {
        
        bidderMap[msg.sender] = 1;
        return (q, M);
    }
    
    function submitBid (uint[] U , uint[] V , uint wu , uint wv) public // set of items 
    notSubmittedBid ()
    notNotary()
    notAuctioneer()
    checkValidValues(U , V)
    {
        submittedBidders[msg.sender] = 1 ;
        Bidders temp ;
        temp.w.u = wu;
        temp.w.v = wv;
        temp . thisBiddersAddress = msg.sender;
        
        registeredBiddersAddress.push(msg.sender) ;
        
        uint len = U.length;
        for (uint i=0;i<len;i++)
        {
            Pair x ;
            x.u = U[i];
            x.v = V[i];
            temp.bidderChoice.push(x);
        }
        biddersList.push(temp);
    }
    
    // function compareTwoBidders(Pair[]  X , Pair[]  Y ) internal 
    // returns(bool)
    // {
    //   // int i =0;
    //     uint n1 = (uint)(X.length);
    //     //int j =0;
    //     uint n2 = (uint) (Y.length);
        
    //     uint val1=0;
    //     uint val2=0;
    //     for (uint i =0;i<n1 && i<n2 ;i++)
    //     {
    //         val1 = X[i].u-Y[i].u ;
    //         val2 =  X[i].v-Y[i].v;
    //         if ( 2*(val1+val2) <q && val1+val2!=0)
    //         {
    //             return true;
    //         }
    //         if (2*(val1+val2) > q)
    //         {
    //             return false;
    //         }
    //     }
    //     if (n1<n2)
    //     return true;
    //     return false;
        
    //     return  true;
    // }
    
    
    
    function compareTwoBidders(Pair X , Pair Y ) internal 
    returns(int)
    {
      // int i =0;
        
        uint val1=0;
        uint val2=0;
        val1 = X.u-Y.u ;
        val2 =  X.v-Y.v;
        if ( (2*(val1+val2) <q ) && (val1+val2)!=0 )
        {
            return 1;
        }
        else if (val1+val2==0)
        {
            return 0;
        }
        return  2;
    }
    
    
    function compareItems(Bidders storage winner, Bidders storage bidder) internal
    returns (bool)
    {
        Pair[] choiceWinner = winner.bidderChoice;
        Pair[] choiceBidder = bidder.bidderChoice;
        
        for(uint i=0; i<choiceWinner.length; i++)
        {
            for(uint j=0; j<choiceBidder.length; j++)
            {
                if(compareTwoBidders(choiceWinner[i], choiceBidder[j]) == 0)
                {
                    return true;
                }
            }
        }
        return false;
    }
    
    
    function sqrt(uint x) returns (uint y)
    {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        
        uint z = (x + 1) / 2;
        y = x;
        while (z < y)
        {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    
    
    
    
    //merge
    function merge(Bidders[] storage arr, uint l, uint m, uint r) internal
    { 
        uint i;
        uint j;
        uint k;
        uint n1 = m - l + 1; 
        uint n2 =  r - m; 
     
        Bidders[]  L ;// = new Bidders[](n1);
        Bidders[]  R ;//= new Bidders[](n2);
      
        for (i = 0; i < n1; i++) 
            //L[i] = arr[l + i];
            L.push(arr[l+i]);
        for (j = 0; j < n2; j++) 
            //R[j] = arr[m + 1+ j];
            R.push(arr[m + 1+ j]);
      
        
        i = 0; 
        j = 0; 
        k = l; 
        while (i < n1 && j < n2) 
        { 
            
            
            int ans = 0;
            
            ans = compareTwoBidders (L[i].w , R[j].w);
            if ( ans==1) //if (L[i] > R[j])
            { 
                arr[k] = L[i]; 
                i++; 
            } 
            else
            { 
                arr[k] = R[j]; 
                j++; 
            } 
            k++; 
        } 
      
        while (i < n1) 
        { 
            arr[k] = L[i]; 
            i++; 
            k++; 
        } 
      
        while (j < n2) 
        { 
            arr[k] = R[j]; 
            j++; 
            k++; 
        } 
    }
    
    
    
    
    
    //mergeSort
    function mergeSort(Bidders[] storage arr, uint l, uint r) internal
    { 
        if (l < r) 
        { 
            uint m = l+(r-l)/2; 
      
            mergeSort(arr, uint(l), uint(m)); 
            mergeSort(arr, uint(m+1), uint(r)); 
      
            merge(arr, uint(l), uint(m), uint(r)); 
        } 
    } 
    
    
    function sort() public
    notNotary()
    notBidder()
    {
        if (biddersList.length == 0)
            return;
        mergeSort(biddersList, uint(0), uint(biddersList.length - 1));

    }
    
    
    
    
    function getWinners( ) public view
    returns (Bidders[], uint[])
    {
        mergeSort(biddersList, uint(0), uint(biddersList.length-1));
        //form array from sorted bidders to notaries.
        uint i;
        uint j;
        Bidders[] winners;
        uint[] payments;
        bool flag;
        winners.push(biddersList[0]);
        
        
        // finding winners
        for( i = 1; i<biddersList.length; i++)
        {
            flag = true;
            for( j = 0; j<winners.length; j++)
            {
                if(compareItems( biddersList[j], biddersList[i]))
                {
                   flag = false;
                   break;
                }
            }
            if(flag)
            {
                winners.push(biddersList[i]);
            }
        }
        
        //finding payments
        
        for(i=0; i<winners.length; i++)
        {
            flag = true;
            for(j=0; j<biddersList.length; j++)
            {
                if((winners[i].thisBiddersAddress != biddersList[j].thisBiddersAddress) && (compareItems(winners[i], biddersList[j])))
                {
                    uint w = (biddersList[j].w.u + biddersList[j].w.v)%q;
                    uint pay = w * sqrt(winners[i].bidderChoice.length);
                    payments.push(pay);
                    flag = false;
                    break;
                }
            }
            if(flag)
            {
                payments.push(uint(0));
            }
        }
        return (winners, payments);
    }
    
}