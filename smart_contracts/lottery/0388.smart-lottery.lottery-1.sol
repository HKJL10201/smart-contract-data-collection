pragma solidity ^0.4.0;

contract lottery {
    
    struct account {
        address user;
        uint256 tokens;
    }
    
    event Draw (address user, uint256 tokens);

    mapping (address => uint256) public party;
    mapping (uint => address) private queue;
    uint256 counter = 0;
    uint256 weight = 0;

    uint256 rate = 100;                         // divides wei for tokens
    uint256 threshold = 500000000000000000;     // maximum balance for draw
    
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
        
        delete new_i;
        delete new_p;
        delete new_min;
        delete new_piv;
        
        return pivot;
    }
    
    function sort(int left, int right, account[] memory acc) internal {
        if (left<right) {
            int pivot = partition(uint(left), uint(right), acc);
            sort(left, pivot-1, acc);
            sort(pivot+1, right, acc);
        }
    }

    function quicksort() private returns (account[] memory) {
        account[] memory acc = new account[](counter);
        for (uint i = 0; i < counter; i++) {
            acc[i].user = queue[i];
            acc[i].tokens = party[queue[i]];
            party[queue[i]] = 0;
            queue[i] = 0;
        }
        sort(0, int(counter-1), acc);
        return acc;
    }
    
    // choose a token holder at random with probability proportional to their token balance
    function choose_winner() private {
        require(counter>0);

        // hash head of chain
        bytes32 head = block.blockhash(block.number-1);
        
        // select random number
        uint random = (uint(head)%weight + 1);
        
        account[] memory acc = quicksort();
        
        uint winner = 0;
        for (uint j = 0; j < counter; j++) {
            random = random + acc[j].tokens;
            winner = j;
            if (random>weight) {
                break;
            }
        }

        // log order of draw
        for (uint k = 0; k < counter; k++) {
            Draw (acc[k].user, acc[k].tokens);
        }
        
        // reset state and transfer funds
        weight = 0;
        counter = 0;
        acc[winner].user.transfer(this.balance);
        delete acc;
    }
    
    // wei for tokens
    function exchange() public payable returns (uint256) {
        require(msg.value>0);
        if (party[msg.sender]==0) {
            queue[counter] = msg.sender;
            counter = counter + 1;
        }
        party[msg.sender] = msg.value/rate;
        weight = weight + msg.value;
        if (this.balance>=threshold) {
            choose_winner();
        }
        return party[msg.sender];
    }
   
}
