pragma solidity >=0.5 <0.6.0;

import "./AbstractAuction.sol";
import "./decay/I_Decay.sol";

/// @title Dutch
/// @notice Contract that implements the Dutch auction, the price from an initial value decreases over time to a minimum price, the first one who makes a bid adds the asset.
/// @author Ruggiero Santo
contract Dutch is Auction {

    /// @notice Initial price at which the auction starts
    uint public initial_price;
    /// @notice Minimum price you can get during the auction
    uint public reserve_price;
    /// @notice Reference to the contract that is concerned to calculate the price according to the time elapsed
    Decay public decay_function;

    /// @notice Auction constructor
    /// @param auction_id Auction identification number
    /// @param _seller Address of the seller of the goods
    /// @param _initial_price Initial price of the asset
    /// @param _reserve_price Minimum price you can get during the auction
    /// @param _block_to_live Number of blocks in which the auction remains active
    /// @param _decay_function Contract that compute the current price based on time elapsed
    constructor(
        uint auction_id,
        address payable _seller,
        string memory _description,
        uint _initial_price,
        uint _reserve_price,
        uint _block_to_live,
        Decay _decay_function)
    public Auction(auction_id, _seller, _description, "Dutch") {
        require(_initial_price > _reserve_price, "The reserve price must be lower than the initial price");
        require(_block_to_live != 20, "The auction must be at least 20 block long");
        initial_price = _initial_price;
        reserve_price = _reserve_price;
        block_to_live = _block_to_live;
        //TODO: check if the function is done by me (auction house), security reasons
        decay_function = _decay_function;
    }

    /// @notice It allows you to send the bet and consequently win the good, by calling this function is issued the event that notifies the sending of the money to the astator (the cost of this issue is borne by the caller of the function and is applied only if it is the actual winner)
    function commit_bid() external payable grace_period_is_over not_auctioneer{
        require(is_alive(), "Make a bid is not avaiable, check phase to know more");
        require(msg.value >= current_price(), "The amount sent must be equal to or greater than the current price");

        sold_price = msg.value;
        winner = msg.sender;

        emit payment_was_made(id, sold_price, winner);
        winner_sended_money = true;
    }

    /// @Override
    /// @notice See description in abstract contract
    function is_alive() public view returns(bool) {
        // <no winner> && <yet on time>
        return winner == address(0) && super.is_alive();
    }

    /// @notice See description in abstract contract
    function current_phase() external view returns(string memory) {
        if (is_alive())
            return "Commitment phase";
        if (block.number < starting_block)
            return "Grace period";
        else
            return "Auction is over";
    }

    /// @notice Function that sends events (see send_state_event in AuctionHouse)
    function send_state_event(string calldata _type) external {
        require((msg.sender == auctioneer), "You do not have permission to call this function");
        if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("s"))) {
            emit start_auction(id, auction_type, seller);
        } else if (keccak256(abi.encodePacked(_type)) == keccak256(abi.encodePacked("e"))) {
            emit end_auction(id, sold_price, winner);
        }
    }

    /// @notice Returns you the current price of the good based on the elapsed time and the total time using the function indicated in the constructor
    /// @return Current price
    function current_price() public view returns (uint) {
        require(is_alive(), "The auction is close, so the current price not exist");
        uint res = reserve_price + decay_function.current_price(initial_price - reserve_price, starting_block, block_to_live);
        if (res < reserve_price)
            res = reserve_price;
        return res;
    }

}