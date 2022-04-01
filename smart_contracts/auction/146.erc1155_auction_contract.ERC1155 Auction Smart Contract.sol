// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/* open source library for ERC1155 standard interface */
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC1155/ERC1155.sol";

/* This contract issues tokens for several classes of spaceships with different rarity */
contract GameItems is ERC1155 { /* Contract inherits from ERC1155 spec */

    /* The game developer should change these values before deploying the contract */
    uint256 public constant VESSEL_ID = 0;
    uint256 public constant VESSEL_COUNT = 100;
    uint256 public constant VESSEL_INITIAL_VALUE = 10**17; /* Initial value of 0.1 ETH (prices in wei) */

    uint256 public constant CRUISER_ID = 1;
    uint256 public constant CRUISER_COUNT = 100;
    uint256 public constant CRUISER_INITIAL_VALUE = 10**17; /* Initial value of 0.1 ETH */

    uint256 public constant DREADNOUGHT_ID = 2;
    uint256 public constant DREADNOUGHT_COUNT = 50;
    uint256 public constant DREADNOUGHT_INITIAL_VALUE = 5*(10**17); /* Initial value of 0.5 ETH */

    uint256 public constant BATTLESHIP_ID = 3;
    uint256 public constant BATTLESHIP_COUNT = 5;
    uint256 public constant BATTLESHIP_INITIAL_VALUE = 2*(10**18); /* Initial value of 2 ETH */

    uint256 public constant DESTROYER_ID = 4;
    uint256 public constant DESTROYER_COUNT = 1;
    uint256 public constant DESTROYER_INITIAL_VALUE = 10**19; /* Initial value of 10 ETH */

    uint256 public constant AUCTION_END_TIME = 1611230400; /* epoch time (seconds) - Currently set to 01/21/2021 @ 12:00pm (UTC) */

    uint256 public constant MAX_ID = 4; /* max id for a token class, range is 0 <= id <= MAX_ID */

    /* Declaring custom structs for holding individual bids (Bidlink) and sets of bids for each item (SubAuction) */

    struct BidLink {
        address payable bidder;
        uint256 value;
        uint256 next;
    }

    struct SubAuction {
        uint256 token_count;
        mapping(uint => BidLink) bids;
        uint256 bidcount;
        uint256 head;
        uint256 initial_price;
    }

    address payable private owner;

    bool private wasDistributed;

    SubAuction[5] subauctions;

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        owner = msg.sender;
        wasDistributed = false;

        _mint(owner, VESSEL_ID, VESSEL_COUNT, "");
        _mint(owner, CRUISER_ID, CRUISER_COUNT, "");
        _mint(owner, DREADNOUGHT_ID, DREADNOUGHT_COUNT, "");
        _mint(owner, BATTLESHIP_ID, BATTLESHIP_COUNT, "");
        _mint(owner, DESTROYER_ID, DESTROYER_COUNT, "");

        /* The struct that stores the bids has a nested mapping of 'bids'. The nested mapping is part of storage
        upon declaration and cannot be reassigned in a constructor. Thus, we change each of the values for each
        subauctions manually  */

        /* developer should ensure initial token price is large enough for transactions to be refunded (> gas cost) */

        subauctions[VESSEL_ID].token_count = VESSEL_COUNT;
        subauctions[VESSEL_ID].bidcount = 0;
        subauctions[VESSEL_ID].head = 0;
        subauctions[VESSEL_ID].initial_price = VESSEL_INITIAL_VALUE;

        subauctions[CRUISER_ID].token_count = CRUISER_COUNT;
        subauctions[CRUISER_ID].bidcount = 0;
        subauctions[CRUISER_ID].head = 0;
        subauctions[CRUISER_ID].initial_price = CRUISER_INITIAL_VALUE;

        subauctions[DREADNOUGHT_ID].token_count = DREADNOUGHT_COUNT;
        subauctions[DREADNOUGHT_ID].bidcount = 0;
        subauctions[DREADNOUGHT_ID].head = 0;
        subauctions[DREADNOUGHT_ID].initial_price = DREADNOUGHT_INITIAL_VALUE;

        subauctions[BATTLESHIP_ID].token_count = BATTLESHIP_COUNT;
        subauctions[BATTLESHIP_ID].bidcount = 0;
        subauctions[BATTLESHIP_ID].head = 0;
        subauctions[BATTLESHIP_ID].initial_price = BATTLESHIP_INITIAL_VALUE;

        subauctions[DESTROYER_ID].token_count = DESTROYER_COUNT;
        subauctions[DESTROYER_ID].bidcount = 0;
        subauctions[DESTROYER_ID].head = 0;
        subauctions[DESTROYER_ID].initial_price = DESTROYER_INITIAL_VALUE;

    }

    function distribute() public {
        require(block.timestamp > AUCTION_END_TIME, "Auction has not ended");
        require(wasDistributed == false, "Tokens already distributed");
        wasDistributed = true; /* prevent re-entrancy */

        for (uint256 id = 0; id <= MAX_ID; id++) {
            BidLink memory current = subauctions[id].bids[subauctions[id].head]; // Start at head of linked list
            for (uint256 i = 0; i < subauctions[i].bidcount; i++) {
                safeTransferFrom(owner, current.bidder, id, 1, ""); // Transfers 1 token per bid to winner
                current = subauctions[id].bids[current.next];
            }
        }

        /* The .transfer() method receives gas from the transaction initiator (2300 gwei) */
        owner.transfer(address(this).balance); /* Send contract owner all funds in the smart contract */
    }


    function bid(uint256 id) payable public {
        require(id <= MAX_ID, "Id doesn't exist"); /* Require that the sent item ID exists */
        require(msg.value >= subauctions[id].initial_price, "Sent value below initial price");

        /* when max amount of bids were received, the sent transaction must be higher
        than the lowest bid to be considered */
        if (subauctions[id].bidcount >= subauctions[id].token_count
                && msg.value < subauctions[id].bids[subauctions[id].head].value) {
            revert("Sent value below lowest bid");
        }

        /* if auction has already ended, throw error */
        require(block.timestamp < AUCTION_END_TIME, "Auction has ended");

        BidLink memory new_bid = BidLink({bidder:msg.sender, value:msg.value, next:0});

        /* add bids smaller than any other bid by replacing the head with it, but only if there is room */
        if ((subauctions[id].bidcount == 0 || msg.value < subauctions[id].bids[subauctions[id].head].value)
                && subauctions[id].bidcount < subauctions[id].token_count) {
            new_bid.next = subauctions[id].head;
            subauctions[id].head = subauctions[id].bidcount;
            subauctions[id].bids[subauctions[id].bidcount] = new_bid;
            subauctions[id].bidcount++;
            return;
        }

        /* find the first bid which is higher than the current bid and insert this bid before it if possible...
        by adding items in this way our list stays sorted and the head points to the smallest item (start) */

        /* start at head of linked list (lowest bid of current item id) */
        BidLink memory current_bid = subauctions[id].bids[subauctions[id].head];
        for (uint256 i = 0; i < subauctions[id].bidcount; i++) { /* only for count - 1 since we look at next value in loop */
            /* comparing to next bid since head value is checked before this */
            if (i == subauctions[id].bidcount - 1
                    || new_bid.value < subauctions[id].bids[current_bid.next].value) {
                /* to make room for new bid, replace smallest bid (head) and move the head one upwards */
                new_bid.next = current_bid.next;
                uint256 oldhead = subauctions[id].head; /* save head for repayment of bid, since bidder gets kicked */

                /* for distributing one token, the head remains, pointing to same index (0) */
                if (subauctions[id].token_count > 1) {
                    subauctions[id].head = subauctions[id].bids[subauctions[id].head].next; /* set new head to next largest */
                }
                subauctions[id].bids[oldhead] = new_bid;

                 /* send back money to address kicked off list */
                uint256 amount = subauctions[id].bids[current_bid.next].value - 2300 * tx.gasprice;
                subauctions[id].bids[current_bid.next].value = 0;  /* stop re-entrancy vulnerability */
                subauctions[id].bids[current_bid.next].bidder.transfer(amount);

                /*  O --> O   to    O --------> O  to  O -        -> O
                       O                 O -´             `-> O -´      */

                current_bid.next = oldhead;
                return;
            }
            else {
                current_bid = subauctions[id].bids[current_bid.next];
            }
        }

    }
}
