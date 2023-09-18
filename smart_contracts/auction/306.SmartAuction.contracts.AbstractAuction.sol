pragma solidity >=0.5 <0.6.0;

/*
 *  @title Auction
 *  @notice Abstract contract that implements the whole basic structure of a generic auction including the exchange phase of the asset (an escrow)
 *  @author Ruggiero Santo
 */
contract Auction {

    event start_auction (
        uint auction_id,
        string auction_type,
        address indexed seller
    );
    event end_auction (
        uint auction_id,
        uint sold_price,
        address indexed winner
    );

    uint test_block;

    /// @notice Auction identification number
    uint public id;

    /// @notice Required by assignment about 5min
    int8 grace_period = 20;
    /// @notice After 16 blocks with 99.99% all parallel braches, if any, are cut off
    int8 validation_period = 20;

    /// @notice Number of the block in which the auction was created
    uint public starting_block;
    /// @notice Number of total blocks in which the auction remains open
    uint public block_to_live;

    /// @notice Address of the astator, the entity that created and manages the auction
    address payable public auctioneer;
    /// @notice Address of who is selling the auction item
    address payable public seller;
    /// @notice Address of the person who bought the item
    address payable public winner;
    /// @notice Description of the auction
    string public description;
    /// @notice type of auction
    string public auction_type;

    /// @notice The price at which the object was sold
    uint public sold_price;
    /// @notice Amount of money given by the seller as security for the shipment
    uint public bail_seller;
    /// @notice Amount of money given by the seller as security for any non-compliant product notification
    uint public bail_winner;

    /// @notice Block in which the goods have been notified by the seller that is shipping them to you
    uint shipping_block;
    /// @notice whether the winner has notified the arrival of the object
    bool public winner_recived_good;
    /// @notice whether the winner has notified the existence of an error in the object
    bool public shipped_good_have_problem;
    /// @notice whether the winner sent all the money decided at the auction
    bool public winner_sended_money;
    /// @notice whether the seller has sent the item to the winner
    bool public seller_shipped_good;
    /// @notice whether the finalisation function has already been performed
    bool public finalized;
    /// @notice indicates to whom I have to give the deposit if I have problems with the good that came to the winner
    bool internal seller_is_right;


    event good_was_shipped (
        uint auction_id,
        uint bail,
        uint shipping_code,
        address indexed seller
    );
    event payment_was_made (
        uint auction_id,
        uint amount,
        address indexed winner
    );
    event good_was_arrived (
        uint auction_id,
        address indexed winner
    );
    event good_have_problem (
        uint auction_id,
        uint bail,
        string problem_description,
        address indexed winner
    );
    event auction_finalized (
        uint auction_id,
        bool with_problem,
        address is_right
    );

    /// @notice Create the generic auction
    /// @param auction_id Auction identification number
    /// @param _seller Address of who is selling the item at auction
    constructor(uint auction_id, address payable _seller, string memory _description, string memory _auction_type) internal {
        auctioneer = msg.sender;
        require(auctioneer != _seller, "The auctioneer cant crate a auction");
        id = auction_id;
        seller = _seller;
        description = _description;
        auction_type = _auction_type;
        starting_block = block.number + uint(grace_period);

        test_block = block.number;
    }

    /// @notice Check if the caller is the seller.
    modifier is_seller {
        require(msg.sender == seller, "You do not have permission to call this function.");
        _;
    }
    /// @notice I'm checking to see if the caller is the winner.
    modifier is_winner {
        require(msg.sender == winner, "You do not have permission to call this function");
        _;
    }

    /// @notice Check if the grace period has passed (The auction can start)
    modifier grace_period_is_over {
        require(
            block.number > starting_block,
            "Grace period must be over to submit a bid");
        _;
    }
    /// @notice Check if after the closing of the auction the sailing time has passed.
    modifier validation_period_is_over {
        require(
            block.number > starting_block + block_to_live + uint(validation_period),
            "Validation period must be over to require the finalization of auction");
        _;
    }

    /// @notice Check to see if the astator's taking part... he can't.
    modifier not_auctioneer {
        require(
            msg.sender != auctioneer,
            "Auctioneer can not partecipate.");
        _;
    }

    /// @notice Check if the auction has already been finalized.
    modifier already_finalized {
        require(!finalized, "the auction is already finalized");
        _;
    }

    /// @notice Utility, Returns if the auction is still "alive" that is if the winner has not been decreed
    /// @return Bool, true if the auction is still open and the winner has not yet been decided, false otherwise
    function is_alive() public view returns(bool) {
        return block.number > starting_block && block.number < starting_block + block_to_live;
    }

    /// @notice Utility, Returns the address of the current winner
    /// @dev there are no special controls as I can check who is the winner even before the end of the auction
    /// @return Address, The address of the winner in case there is otherwise address(0)
    function get_winner() external view returns(address) {
        return winner;
    }

    /// @notice Function that actually sends the planned money
    function commit_bid() external payable;

    /// @notice Function that sends events (see send_state_event in AuctionHouse)
    function send_state_event(string calldata _type) external;

    /// @notice Auction finalization function, it carries out the actual exchange of money between the seller and the winner by checking first whether everyone got what they
    ///     deserved. In case of problems, the finalization is not performed by the seller of the winner but only by the astator.  The finalization of the auction is blocked after
    ///     the notification of the shipment until the winner receives the notification of receipt from you if the notification of receipt was not wrong within 60 days the auction
    ///     becomes self-finalisable.
    function finalize() public already_finalized validation_period_is_over {
        require(
            (msg.sender == winner) ||
            (msg.sender == seller) ||
            (msg.sender == auctioneer),
            "You do not have permission to call this function");

        if (winner != address(0)) {
            // Checking whether the winner has sent the money that was decided at the auction
            require(winner_sended_money, "The winner did not send the amount of sale decided during the auction, can do it with commit_bid function");

            // Check if the winner has received the goods and if seller has sent the goods
            if (!winner_recived_good) {
                require(seller_shipped_good, "The seller has not yet sent the good to the winner");
                //If it's been 60 days, then I can finalize
                require((block.number - shipping_block) > 345600, "The winner has not yet reported the arrival of the good, finalization without notification is possible are after 60 days");
            }

            //If I have problems in the good received block everything
            if (shipped_good_have_problem) {
                require(msg.sender == auctioneer, "If there are problems in the good that the winner received only the auctioneer can finalize the auction");
                // IDEA: I can create an event to notify that the seller and the winner was dishonest
                if (seller_is_right) {
                    seller.transfer(sold_price + bail_winner + bail_seller);
                    emit auction_finalized(id, true, seller);
                } else {
                    winner.transfer(sold_price + bail_winner + bail_seller);
                    emit auction_finalized(id, true, winner);
                }
                finalized = true;
            } else {
                //I return the deposit and the money given by the winner to the seller if all went well.
                seller.transfer(sold_price + bail_seller);
                winner.transfer(bail_winner);
                emit auction_finalized(id, false, address(0));
            }
        }
        finalized = true;
    }

    /// @notice Function that can only be called by the auction house/astator, which closes the auction definitly. This function replaces the money to the eventual winner
    ///     if the seller has not sent the item, but still finalizes the payment after 60 days if the item has been sent but the winner has not communicated anything. The
    ///     call of this function destroys the contract.
    function close_auction() external validation_period_is_over {
        require(msg.sender == auctioneer, "Only auctioneer can close the auction");
        if (!finalized)
            finalize();
        selfdestruct(auctioneer);
    }

    /// @notice Utility, Calculate the amount of the minimum deposit to be paid by the seller
    /// @return Minimum amount of money to be sent as a deposit
    function get_bail_amount() public view returns(uint) {
        return sold_price / 2;
    }

    /// @notice Function that must be called by the seller to notify the sending of the goods
    function good_sended(uint shipping_code) external payable is_seller {
        require(!is_alive(), "The auction must be over");
        require(msg.value >= get_bail_amount(), "You must send a bail to notify the shipping of at least half of sold price");
        bail_seller = msg.value;
        shipping_block = block.number;

        emit good_was_shipped(id, bail_seller, shipping_code, seller);
        seller_shipped_good = true;
    }

    /// @notice Function that must be called by the winner to notify the receipt of the asset
    function good_recived(bool problem) external payable is_winner {
        good_recived(problem, "");
    }
    function good_recived(bool problem, string memory problem_description) public payable is_winner {
        if (problem) {
            require(msg.value > get_bail_amount(), "You must send a bail to notify problem in the good of at least half of sold price");
            emit good_have_problem(id, bail_winner, problem_description, winner);
            shipped_good_have_problem = true;
        } else
            emit good_was_arrived(id, winner);
        winner_recived_good = true;
    }

    /// @notice Destroy the auction if it hasn't started yet.
    function revert_auction() external {
        require(msg.sender == auctioneer, "Only auctioneer can destroy the auction");
        require(
            block.number < starting_block,
            "You can destroy the auction only before ending of grace period");
        selfdestruct(auctioneer);
    }

    /// @notice The auctioneer decide who is right between the seller and the winner in case of problems.
    function who_is_right(bool _seller_is_right) external {
        require(msg.sender == auctioneer, "Only auctioneer can decide who is right");
        seller_is_right = _seller_is_right;
    }

    /// @notice Utility function to understand what stage the rod is at.
    /// @return The description of the phase in which the auction is at the moment when the
    function current_phase() external view returns(string memory);
}
