pragma solidity ^0.4.15;
pragma experimental ABIEncoderV2;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Auction is usingOraclize{
    //static
    address auctioneer;
    uint public starttime;
    uint public endtime;
    uint256 public q;//large prime
    uint256 public M;// Number of items
    
    //state
    bool public cancelled;
    int128 notary_size;
    int128 bidder_size;
    int128 notary_no;
    uint256 rew=1;
    bool winner_flag=false;
    
    struct Bidder{
        address notary;
        uint256 no_items;
        bool is_valid;
    }
    
    mapping (address => Bidder) bidder;
    mapping (int128 => address) bidder_map;
    struct Notaries{
        address bidder;
        bool assigned;
        uint256[][] input_items;
        uint256[2] input_value;
        bool is_valid;
        uint256 interaction;
    }
    
    event Assignment(address bidd, address not);
    event randomnumber(int128 num);
    event pay(int128 k, int128 j, uint256 num);
    event equal_item(uint[2]a, uint[2] b);
    event oracle(bytes32 rand);
    event amount(uint256 amt);
    
    mapping (address => Notaries) notaries;
    mapping (int128 => address) notary_map;
    int128[] public winner;
    uint256[] public payments;
    
    constructor(uint _q, uint256 _M, uint _biddingTime) payable
    {
        starttime=now;
        endtime=starttime+(_biddingTime*60);
        // if (_startBlock >= _endBlock) throw;
        // if (_startBlock < block.number) throw;
        auctioneer=msg.sender;
        q=_q;
        M=_M;
        // startBlock=_startBlock;
        // endBlock=_endBlock;
        notary_size=0;
        bidder_size=0;
        notary_no=0;
    }
    function notaryRegister() public{
        assert(!notaries[msg.sender].is_valid && !bidder[msg.sender].is_valid && auctioneer!=msg.sender);
        assert(now<endtime);
        // if(notaries[msg.sender].is_valid || bidder[msg.sender].is_valid || auctioneer==msg.sender) throw;
        notaries[msg.sender].is_valid=true;
        notary_map[notary_size]=msg.sender;
        notary_size=notary_size+1;
    }
    function randomgenerator() private returns(uint128)
    {
        // bytes32 rand=oraclize_query("WolframAlpha", "random number between 0 and 100");
        // emit oracle(rand);
        return uint128(int128(keccak256(block.timestamp, block.difficulty))%notary_size)%uint128(notary_size);
    }
    function bidderRegister(uint256[][] items, uint256[2] input) public returns(uint256){
        assert(now<endtime);
        assert(!notaries[msg.sender].is_valid && !bidder[msg.sender].is_valid && auctioneer!=msg.sender);
        // if(notaries[msg.sender].is_valid || bidder[msg.sender].is_valid || auctioneer==msg.sender) throw;
        //get random number
        // if(notary_no>=notary_size) throw;
        assert(notary_no<notary_size);
        uint256 num_items=items.length;
        // if(num_items<=0 || num_items>M) throw;
        for(uint i=0;i<num_items;i++)
        {
            assert(items[i].length==2);
        }
        assert(num_items>0 && num_items<=M);
        // if(notaries[notary_map[notary_no]].assigned==true) throw;
        
        bidder_map[bidder_size]=msg.sender;
        bidder_size=bidder_size+1;
        int128 num=notary_no;
        // int128 num=int128(randomgenerator());
        // while(notaries[notary_map[num]].assigned==true)
        // {
        //     num=int128(randomgenerator());
        // }
        emit randomnumber(num);
        notaries[notary_map[num]].assigned=true;
        notaries[notary_map[num]].bidder=msg.sender;
        bidder[msg.sender].notary=notary_map[num];
        // notaries[notary_map[notary_no]].assigned==true;
        // notaries[notary_map[notary_no]].bidder=msg.sender;
        // bidder[msg.sender].notary=notary_map[notary_no];
        bidder[msg.sender].is_valid=true;
        notary_no=notary_no+1;
        bidder[msg.sender].no_items=num_items;
        notaries[bidder[msg.sender].notary].input_items=items;
        notaries[bidder[msg.sender].notary].input_value=input;
        emit Assignment(msg.sender,bidder[msg.sender].notary);
    }
    function sqrt(uint x) private returns(uint y)
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
        return y;
    }
    function comparator(uint[2] a, uint[2] b) private returns (uint)
    {
        int val1=int(a[0])-int(b[0]);
        int val2=int(a[1])-int(b[1]);
        if(val1<0)
        {
            if(val2<0)
            {
                assert((-1*(val1+val2))>(-1*val1));
            }
        }
        if(val1>0 && val2>0)
        {
            assert((val1+val2)>val1);
        }
        // return val1;
        if(val1+val2==0)
            return 2;
        else if((val1+val2+int(q))%int(q)<int(q)/2)
            return 1;
        return 0;
    }
    function sort(int128 left, int128 right) private
    {
        int128 i=left;
        int128 j=right;
        address pivot = notary_map[left + (right - left)/2];
        while (i <= j) {
            while((i<=right)&&(comparator(notaries[notary_map[i]].input_value,notaries[pivot].input_value)==1 || notaries[pivot].assigned==false))
            {
                notaries[notary_map[i]].interaction+=1;
                notaries[pivot].interaction+=1;
                i++;
            }
            // while (arr[i] < pivot) i++;
            // while (pivot < arr[j]) j--;
            while((j>=0)&&(comparator(notaries[notary_map[j]].input_value,notaries[pivot].input_value)==0 || notaries[notary_map[j]].assigned==false))
            {
                notaries[notary_map[j]].interaction+=1;
                notaries[pivot].interaction+=1;
                j--;
            }
            if (i <= j) {
                (notary_map[i], notary_map[j]) = (notary_map[j], notary_map[i]);
                i++;
                j--;
            }
        }
        if (left < j)
            sort(left, j);
        if (i < right)
            sort(i, right);
    }
    function intersection (uint256[][] items,uint256[][] upcoming) private returns(bool)
    {

        for(uint i=0;i<upcoming.length;i++)
        {
            // c=[upcoming[i][0],upcoming[i][1]];
            for(uint j=0;j<items.length;j++)
            {
                // d=[items[j][0],items[j][1]];
                if(comparator([upcoming[i][0],upcoming[i][1]],[items[j][0],items[j][1]])==2)
                {
                    return true;
                }
            }
        }
        return false;
    }
    event vals(Notaries kk);
    function get_payments() private returns(uint256[])
    {
        bool flag;
        for(uint256 k=0;k<winner.length;k++)
        {
            uint256 ans=0;
            int128 l=winner[k];
            emit pay(l,l,ans);
            emit vals(notaries[notary_map[l]]);
            flag=false;
            for(int128 j=0;j<notary_no;j++)
            {
                for(int128 i=0;i<j;i++)
                {
                    if(i==l)
                        continue;
                    if(notaries[notary_map[j]].assigned!=false && intersection(notaries[notary_map[j]].input_items,notaries[notary_map[i]].input_items)==true)
                    {
                      notaries[notary_map[j]].interaction+=notaries[notary_map[i]].input_items.length;
                      notaries[notary_map[j]].interaction+=notaries[notary_map[j]].input_items.length;
                      flag=true; 
                      break; 
                    }
                }
                if(flag==false)
                {
                    if(intersection(notaries[notary_map[j]].input_items,notaries[notary_map[l]].input_items)==true)
                    {
                        notaries[notary_map[j]].interaction+=notaries[notary_map[l]].input_items.length;
                        notaries[notary_map[l]].interaction+=notaries[notary_map[j]].input_items.length;
                        ans=(notaries[notary_map[j]].input_value[0]+notaries[notary_map[j]].input_value[1])%q;
                        emit pay(int128(notaries[notary_map[j]].input_value[0]),int128(notaries[notary_map[j]].input_value[1]),ans);
                        
                        ans=ans*sqrt(notaries[notary_map[l]].input_items.length);
                        emit pay(l,j,ans);
                        break;
                    }
                }
            }
            payments.push(ans);
        }
        return payments;
    }
    
    function find_winner() returns(int128[])
    {
        assert(msg.sender==auctioneer && now>endtime && !winner_flag);
        sort(0,notary_size-1);
        winner.push(0);
        // for(uint i=0;i<notaries[notary_map[0]].input_items.length;i++)
        // {
        //     bid_items.push(notaries[notary_map[0]].input_items[i]);
        // }
        bool flag=false;
        for(int128 j=1;j<notary_no;j++)
        {
            flag=false;
            for(int128 k=0;k<int128(winner.length);k++)
            {
                if(notaries[notary_map[j]].assigned==false||intersection(notaries[notary_map[j]].input_items,notaries[notary_map[k]].input_items))
                {
                    notaries[notary_map[j]].interaction+=notaries[notary_map[k]].input_items.length;
                    notaries[notary_map[k]].interaction+=notaries[notary_map[j]].input_items.length;
                    flag=true;
                    break;
                }
            }
            if(flag==true)
                continue;
            winner.push(j);
            // if(notaries[notary_map[j]].assigned==false||intersection(notaries[notary_map[j]].input_items,bid_items))
            // {
            //     continue;
            // }
            // for(uint i=0;i<notaries[notary_map[j]].input_items.length;i++)
            // {
            //     winner.push(j);
            //     bid_items.push(notaries[notary_map[j]].input_items[i]);
            // }
        }
        winner_flag=true;
        get_payments();
        return winner;
    }
    
    function cancel()
    {
        assert(msg.sender==auctioneer && now<endtime && !winner_flag);
        cancelled=true;
    }
    function reward_notaries() public payable
    {
        assert(msg.sender==auctioneer && !cancelled && winner_flag);
        uint256 sum=0;
        for(int128 i=0;i<notary_no;i++)
        {
            if(notaries[notary_map[i]].assigned==true)
            {
                sum+=notaries[notary_map[i]].interaction*rew;
                emit amount(notaries[notary_map[i]].interaction*rew);
                assert(notary_map[i].send(notaries[notary_map[i]].interaction*rew));
            }
        }
        if(sum<msg.value)
        {
            auctioneer.send(msg.value-sum);
        }
    }
}
