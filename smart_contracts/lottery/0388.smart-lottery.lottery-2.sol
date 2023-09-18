pragma solidity ^0.4.0;

contract lottery {
    
    struct account {
        address user;
        uint256 tokens;
    }
    
    event Draw (address user, uint256 tokens);

    mapping (address => uint256) public party;
    mapping (uint => address) private queue;
    
    // pre-initialise to prevent surcharge to first trader
    uint256 counter = 1;
    uint256 weight = 1;

    uint256 rate = 100;     // divides wei for tokens
    uint256 limit = 5;

    function partition(uint left, uint right, account[] memory acc) internal returns (int) {
        int pivot = int(left);
        for (uint i = left+1; i < right+1; i++) {
            if (acc[i].tokens<=acc[left].tokens) {
                pivot++;
                account memory new_i = acc[uint(pivot)];
                account memory new_p = acc[i];
                acc[i] = new_i;
                acc[uint(pivot)] = new_p;
            }
        }
        
        account memory new_min = acc[uint(pivot)];
        account memory new_piv = acc[left];
        
        acc[left] = new_min;
        acc[uint(pivot)] = new_piv;
        
        return pivot;
    }
    
    function quicksort(int left, int right, account[] memory acc) internal {
        if (left<right) {
            int pivot = partition(uint(left), uint(right), acc);
            quicksort(left, pivot-1, acc);
            quicksort(pivot+1, right, acc);
        }
    }

    // choose a token holder at random 
    // with probability proportional to their token balance
    function choose_winner() public {
        require(counter>=limit+1);
        weight -= 1;

        // hash head of chain
        bytes32 head = block.blockhash(block.number-1);
        
        // select random values
        uint random = (uint(head)%weight + 1);
        uint pivot = (uint(head)%counter + 1);
        
        account[] memory acc = new account[](counter);      // build account
        for (uint i = 0; i < counter; i++) {                // stack of users
            acc[i].user = queue[i];
            acc[i].tokens = party[queue[i]];
            party[queue[i]] = 0;
            queue[i] = 0;
        }
        
        account memory new_min = acc[uint(pivot)];      // swap random pivot 
        account memory new_piv = acc[0];                // for leftmost value
        acc[0] = new_min;
        acc[uint(pivot)] = new_piv;
        
        quicksort(0, int(counter-1), acc); 
        
        uint winner = 0;
        for (uint j = 0; j < counter; j++) {
            random += acc[j].tokens;
            winner = j;
            if (random>=weight) {
                break;
            }
        }

        // log winner
        Draw (acc[winner].user, acc[winner].tokens);

        msg.sender.transfer((this.balance/100)*5);      // reimburse caller
        acc[winner].user.transfer(this.balance);        // transfer funds to winner
        
        // reset state
        weight = 1;
        counter = 1;
        delete acc;
    }
    
    // wei for tokens
    function exchange() public payable {
        // prevent division into floating points
        require(msg.value>0);
        // prevent spam
        if (counter>limit+1) {
            msg.sender.transfer(msg.value);
        } else {
            if (party[msg.sender]==0) {
                queue[counter-1] = msg.sender;
                counter++;
            }
            party[msg.sender] = msg.value/rate;
            weight = weight + msg.value/rate;
        }

    }
   
}
