pragma solidity ^0.4.7;

contract Auction
{

    modifier checkValidWeight(uint w1, uint w2)
    {
        uint weight = (w1+w2)%q;
        require(weight<(q/2), "Weight should be less than Q/2");
        _;
    }
    
    function compareItems(Bidder winner, Bidder bidder) returns (bool)
    {
        Pair[] choiceWinner = winner.bidderChoice;
        Pair[] choiceBidder = bidder.bidderChoice;
        
        for(uint i=0; i<choiceWinner.length; i++)
        {
            for(uint j=0; j<choiceBidder.length; j++)
            {
                if(compare(choiceWinner[i], choiceBidder[j]) == uint(0))
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
    
    function getWinners(uint[] storage bidders, uint n) returns (uint[], uint[])
    {
        mergeSort(bidders, uint(0), uint(bidders.length-1));
        //form array from sorted bidders to notaries.
        uint i;
        uint j;
        uint[] winners;
        uint[] payments;
        bool flag;
        winners.push(bidders[0]);
        
        
        // finding winners
        for( i = 1; i<bidders.length; i++)
        {
            flag = true;
            for( j = 0; j<winners.length; j++)
            {
                if(compareItems( bidders[j], bidders[i]))
                {
                   flag = false;
                   break;
                }
            }
            if(flag)
            {
                winners.push(bidders[i]);
            }
        }
        
        //finding payments
        
        for(i=0; i<winners.length; i++)
        {
            flag = true;
            for(j=0; j<bidders.length; j++)
            {
                if((winners[i].thisBiddersAddress != bidders[j].thisBiddersAddress) && (compareItems(winners[i], bidders[j])))
                {
                    uint w = (bidders[j].wu + bidders[j].wv)%q;
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