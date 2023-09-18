pragma solidity ^0.4.0;
//pragma experimental ABIEncoderV2;
contract Auction
{

    event Print(string _name, address _value);
    event Print1(string _name, uint _value);
    uint startTime;
    uint endTime;
    uint q=0;
    uint M=0;
    
    uint notaryCount =0 ;
    
    //address of auctioneer
    address autioneerAddress ;

    address []  notaryAddress ;
    address []  registeredBiddersAddress ;
    uint    []  notaryPayment ; 
    mapping (address => uint) bidderMap ;
    mapping (address => uint)  submittedBidders ;
    mapping (address => uint)  notaryMap;

    Bidders[] winners;
    uint[] payments;
    
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
        
        uint itemLength;

        uint assignedNotary ;
        address thisBiddersAddress ;

    }

    // array of Bidders
    Bidders[] biddersList ;
    Bidders[]  L ;
    Bidders[]  R ;



    //acutioneer will invoke the constructor
    constructor ( uint _q , uint _M ) public payable
    {
        q = _q ;
        M = _M ;
        startTime = now; // in seconds
        endTime = now + 60;
        autioneerAddress = msg.sender;
    }

    function getQM() view public
    returns (uint ,uint )
    {
        return( q , M );
    }
    
    modifier onlyAfter (uint _time) {require(now > _time, "Too early"); _;}
    
    //check not auctioneer
    modifier notAuctioneer()
    {
        require (msg.sender != autioneerAddress , "Call by auctioneer not permitted");
        _;
    }
    
    modifier checkIfSufficientNotaries()
    {
        require ( notaryCount > biddersList.length , "Number of Notaries not sufficient");
        _;
    }

    //check not Bidder
    modifier notBidder()
    {
        require (bidderMap[msg.sender] != 1 , "Call by bidder not permitted");
        _;
    }

    //check not Notary
    modifier notNotary()
    {
        require (notaryMap[msg.sender] != 1 , "Call by Notary not permitted");
        _;
    }

    //check wheather already submitted bid
    modifier notSubmittedBid()
    {
        require ( submittedBidders[msg.sender] !=1 , "Bid already submitted");
        _;
    }

    // check wheather values given by bidder are correct
    modifier checkValidValues(uint[] U , uint[] V)
    {
        require( ((U.length == V.length ) && validateValues(U , V)==true) , "Either length not equal or invalid values"  );
        _;
    }

    function validateValues( uint[] U , uint[] V) internal
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
        notaryMap[msg.sender] = 1;
        
        notaryAddress.push(msg.sender);
        notaryCount = notaryCount + 1;
        notaryPayment.push(0);
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

    function submitBid (uint[] U , uint[] V , uint wu , uint wv)
public // set of items
    notSubmittedBid ()
    notNotary()
    notAuctioneer()
    checkValidValues(U , V)
    checkIfSufficientNotaries()
    {
        uint chutiyapa = notaryCount;
        submittedBidders[msg.sender] = 1 ;
        Bidders temp ;
        temp.w.u = wu;
        temp.w.v = wv;
        temp . thisBiddersAddress = msg.sender;
        temp.assignedNotary = biddersList.length ; 
        uint len = U.length;
        temp.itemLength = len;
        for (uint i=0;i<len;i++)
        {
            temp.bidderChoice[i].u = U[i];
            temp.bidderChoice[i].v = V[i];
        }
        biddersList.push(temp);
        L.push(temp);
        R.push(temp);
        
        notaryCount = chutiyapa;
    }

    //this evalution is done by notary
    function evaluationByNotary(uint a , uint b , uint idxOfNotaryToBePaid) internal
    returns(uint)
    {
        notaryPayment[idxOfNotaryToBePaid ] = notaryPayment[idxOfNotaryToBePaid ] + 5 ;
        return(a-b);        
    }

    function compareTwoBidders(Pair X , Pair Y , uint assignedNotaryOfX , uint assignedNotaryOfY ) internal
    returns(int)
    {
      // int i =0;

        uint val1=0;
        uint val2=0;
        
        val1 = evaluationByNotary(X.u , Y.u , assignedNotaryOfX) ;
        val2 =  evaluationByNotary( X.v , Y.v , assignedNotaryOfY) ;
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


    function compareItems(Bidders storage winner, Bidders storage
bidder) internal
    returns (bool)
    {
        Pair[] choiceWinner = winner.bidderChoice;
        Pair[] choiceBidder = bidder.bidderChoice;

        for(uint i=0; i<winner.itemLength; i++)
        {
            for(uint j=0; j<bidder.itemLength; j++)
            {
                if(compareTwoBidders(choiceWinner[i], choiceBidder[j] , winner.assignedNotary , bidder.assignedNotary) == 0)
                {
                    return true;
                }
            }
        }
        return false;
    }


    function sqrt(uint x) internal returns (uint y) 
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
    function merge(uint l, uint m, uint r) internal
    {
        uint i;
        uint j;
        uint k;
        uint n1 = m - l + 1;
        uint n2 =  r - m;

       
        for (i = 0; i < n1; i++){
            //L[i] = arr[l + i];
            L[i] = biddersList[l+i];
            // Print("L[i] data", L[i].thisBiddersAddress);
            // Print("biddersList[l+i] data", biddersList[l+i].thisBiddersAddress);
        }
        for (j = 0; j < n2; j++){
            //R[j] = arr[m + 1+ j];
            R[j] = biddersList[m + 1+ j];
            //Print("R[j] data", R[j].thisBiddersAddress);
        }


        i = 0;
        j = 0;
        k = l;
        while (i < n1 && j < n2)
        {


            int ans = 0;
            // Print("L[i] ", L[i].thisBiddersAddress);
            // Print("R[j] ", R[j].thisBiddersAddress);
            ans = compareTwoBidders (L[i].w , R[j].w , L[i].assignedNotary , R[j].assignedNotary );
            if ( ans==1) //if (L[i] > R[j])
            {
                biddersList[k] = L[i];
                i++;
                // Print("dekho yaha ", biddersList[k].thisBiddersAddress);
            }
            else
            {
                biddersList[k] = R[j];
                // Print("dekho yaha bhi ", biddersList[k].thisBiddersAddress);
                j++;
            }
            k++;
        }

        while (i < n1)
        {
            biddersList[k] = L[i];
            // Print("dekho yaha par bhi ", biddersList[k].thisBiddersAddress);
            i++;
            k++;
        }

        while (j < n2)
        {
            biddersList[k] = R[j];
//             Print("dekho yaha par bhi dekh hi lo ", biddersList[k].thisBiddersAddress);
            j++;
            k++;
        }
    }





    //mergeSort
    function mergeSort(uint l, uint r) internal
    {
        if (l < r)
        {
            uint m = l+(r-l)/2;

            mergeSort(uint(l), uint(m));
            mergeSort(uint(m+1), uint(r));

            merge(uint(l), uint(m), uint(r));
        }
    }


    function sort() public
    //notNotary()
    //notBidder()
    {
        if (biddersList.length == 0)
            return;
        mergeSort(uint(0), uint(biddersList.length - 1));
    }
    
    function getAuctionResult() public
    notBidder()
    notNotary()
    onlyAfter(endTime)
    {
        sort();
        findWinners();
        finalizePayment();
    }
    
    function findWinners() public
    {
        uint i;
        uint j;

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
    }



    function finalizePayment( ) public
    //returns (Bidders[], uint[])
    {

        bool flag =true;
        
        for(uint i=0; i<winners.length; i++)
        {
            flag = true;
            for(uint j=0; j<biddersList.length; j++)
            {
                if((winners[i].thisBiddersAddress !=
biddersList[j].thisBiddersAddress) && (compareItems(winners[i],
biddersList[j])))
                {
                    uint w = (biddersList[j].w.u + biddersList[j].w.v)%q;
                    uint pay = w * sqrt(winners[i].itemLength);
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
        
        for (i=0;i<notaryCount ;i++)
        {
            Print1("Finalize Payment " , notaryPayment[i]) ;
        }
        //return (winners, payments);
        // Print("Val of Winners", winners[0].thisBiddersAddress);
        // Print1("Val of payment", payments[0]);
    }

    function showWinners () public
    returns (address[], uint)
    {
        uint len = winners.length;
        address [] result;
        for (uint i =0;i<len;i++)
        {
            if(i < result.length){
                result[i] = winners[i].thisBiddersAddress;
            } else {
                result.push(winners[i].thisBiddersAddress);
            }
            
        }
        for (i=0;i<notaryCount ;i++)
        {
            Print1("Finalize Payment " , notaryPayment[i]) ;
        }
        return (result, winners.length);
    }

}