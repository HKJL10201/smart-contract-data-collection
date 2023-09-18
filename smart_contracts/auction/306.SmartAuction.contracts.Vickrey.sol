pragma solidity >=0.5 <0.6.0;

import "./AbstractAuction.sol";

/// @title Vickrey
/// @notice Contract that implements the Vickrey type auction, The auction divides the three phases: Commitment, Withdrawal and Opening.
///      In the first phase participants send the SHA3 calculated with the price they have decided to bet and a random nonce, the consignment must be attached to the payment of the deposit which will be returned later;
///      In the second step, you can withdraw the bet but this will result in the loss of half of the deposit sent in the previous phase;
///      In the third phase, those who have decided not to make the withdrawal can send the price and the nonce decided initially if these return the same sha sent the opening is valid and the deposit is returned ( if you are not the winner ).
///      Whoever made the highest bet wins but the winner will pay the bet made by the second.
/// @author Ruggiero Santo
contract Vickrey is Auction {

    event new_phase_withdrawal (
        uint auction_id
    );
    event new_phase_opening (
        uint auction_id
    );

    /// @notice Winning bet
    uint public winning_bet;

    /// @notice Amount of money needed to make a bet, the deposit
    uint deposit_amount;

    /// @notice Duration in terms of blockage of the Commitment phase
    uint public commitment_btl;
    /// @notice Duration in terms of blockage of the Withdrawal phase
    uint public withdrawal_btl;

    /// @notice Reserve price, cost paid by the winner in case it is the only one
    uint public reserve_price;

    /// @notice map containing all the players who have made a bet
    mapping (address => bidder) bidders;
    struct bidder {
        uint price;
        uint nonce;
        bytes32 sended_sha;
        uint deposit_amount;
    }

    /// @notice Check if you are calling the function in the right period (game phase)
    modifier check_period (uint off_start, uint off_end) {
        require(
            (block.number > starting_block + off_start) &&
            (block.number < starting_block + off_end),
            "This function can be call in the proper phase");
        _;
    }

    /// @notice Contract constructor
    /// @param auction_id Auction identification number
    /// @param _seller Address of the seller of the goods
    /// @param _good_value Valuation of the asset, used to calculate the deposit required to place a bet
    /// @param _commitment_btl Duration in terms of blockage of the Commitment phase
    /// @param _withdrawal_btl Duration in terms of blockage of the Withdrawal phase
    /// @param _opening_btl Duration in terms of blockage of the Opening phase
    constructor(
        uint auction_id,
        address payable _seller,
        string memory _description,
        uint _good_value,
        uint _reserve_price,
        uint _commitment_btl,
        uint _withdrawal_btl,
        uint _opening_btl
    ) public Auction(auction_id, _seller, _description, "Vickrey") {
        deposit_amount = _good_value/2;
        reserve_price = _reserve_price;
        commitment_btl = _commitment_btl;
        withdrawal_btl = _commitment_btl + _withdrawal_btl;
        block_to_live = withdrawal_btl + _opening_btl;
        require(block_to_live >= 60, "Each phase must be at least 20 block long to transaction validation");
    }

    /// @notice Takes "the envelope" with the price. The bet can only be made once
    /// @param sha sha calculated by concatenating the price decided and the nonce, the values that will be sent in the opening phase
    function submit_bid(bytes32 sha) external payable check_period(0, commitment_btl) not_auctioneer {
        // NOTE: If you submit the submission request twice with the deposit, it will not be returned.
        require(msg.value >= deposit_amount, "Must send deposit to make a bid");
        bidder storage _bidder = bidders[msg.sender];
        require(_bidder.sended_sha == 0, "You can send a bid only one time");
        _bidder.deposit_amount = msg.value;
        _bidder.sended_sha = sha;
    }

    /// @notice Request for withdrawal from the auction, only half of the deposit will be returned
    function withdrawal() external check_period(commitment_btl, withdrawal_btl) {
        require(bidders[msg.sender].deposit_amount != 0, "Deposit already sended back");
        msg.sender.transfer(bidders[msg.sender].deposit_amount/2);
        bidders[msg.sender].deposit_amount = 0;
    }

    /// @notice Make the "opening" of the bet made in the first phase, sending the price bet and in nonce occurs if the two sha (calculated and sent) match. If everything is valid it will be vefica if who has just made the opening is the new winner and if not, the deposit will be returned immediately.
    /// @param price price used to calculate sha sent in commitment phase
    /// @param nonce nonce used to calculate sha sent in commitment phase
    function opening_bid(uint price, uint nonce) external check_period(withdrawal_btl, block_to_live) {
        bidder storage _bidder = bidders[msg.sender];
        require(_bidder.deposit_amount != 0, "You've already withdrawal the deposit, so you can't open a bid");

        bytes32 sha = sha256(abi.encodePacked(price, nonce));
        require(sha == _bidder.sended_sha, "Sended sha and sha256(price, nonce) don't match");

        _bidder.price = price;
        _bidder.nonce = nonce;

        uint _winner_deposit = bidders[winner].deposit_amount;

        if (price == winning_bet) {
            // Same price, I choose random sha256(nonce1, nonce2) % 2 => 1 winner unchanged, 0 new winner
            if ( uint256(keccak256(abi.encodePacked(bidders[winner].nonce, nonce))) % 2 == 0) {
                winner.transfer(_winner_deposit);
                _winner_deposit = 0;
                winner = msg.sender;
                return;
            }
        } else {
            // Different prices
            if (price > winning_bet) {
                sold_price = winning_bet;
                winning_bet = price;

                winner.transfer(_winner_deposit);
                _winner_deposit = 0;
                winner = msg.sender;
                return;
            } else
                if (price > sold_price)
                    sold_price = price;
        }

        // I return the deposit
        msg.sender.transfer(_bidder.deposit_amount);
        _bidder.deposit_amount = 0;
    }

    function commit_bid() external payable is_winner {
        require(!is_alive(), "Commit a bid is not avaiable, check phase to know more");
        if (reserve_price == 0)
            sold_price = reserve_price;
        require(msg.value >= sold_price - bidders[msg.sender].deposit_amount, "The amount sent must be equal to or greater than the sold price");
        emit payment_was_made(id, sold_price, winner);
        winner_sended_money = true;
    }

    /// @notice See description in abstract contract
    function current_phase() external view returns(string memory) {
        if (block.number > starting_block + block_to_live)
            return "Auction is over";
        if (block.number > starting_block + withdrawal_btl)
            return "Opening phase";
        if (block.number > starting_block + commitment_btl)
            return "Withdrawal phase";
        if (block.number > starting_block)
            return "Commitment phase";
        else
            return "Grace period";
    }

    /// @notice Function that sends events (see send_state_event in AuctionHouse)
    function send_state_event(string calldata _type) external {
        require(
            (msg.sender == auctioneer),
            "You do not have permission to call this function");
        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("s"))) {
            emit start_auction(id, auction_type, seller);
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("e"))) {
            emit end_auction(id, sold_price, winner);
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("w"))) {
            emit new_phase_withdrawal(id);
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("o"))) {
            emit new_phase_opening(id);
        }
    }

    /// @notice returns the amount of money needed to place a bet
    /// @return Amount of money
    function get_deposit_amount() external view returns(uint) {
        return deposit_amount;
    }

    // __________TEST_________
    //To be used for testing only, use in a real-world scenario would compromise the validity of the auction.
    function _test_sha(uint price, uint nonce) public pure returns(bytes32){
        return sha256(abi.encodePacked(price, nonce));
    }
}