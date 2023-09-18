pragma solidity >=0.5 <0.6.0;

import "./AbstractAuction.sol";
import "./Dutch.sol";
import "./Vickrey.sol";

/// @title AuctionHouse
/// @notice Contract that generates the various auctions
/// @dev implements the template factory
/// @author Ruggiero Santo
contract AuctionHouse {

    /// @notice owner of the auction house
    address payable owner;

    event newAuction (
        string auction_type,
        address auction_address,
        address auctioneer,
        address seller,
        string description
    );

    /// @notice a kind of enum but variable to allow to store the various types of auction
    /// @dev map has been used since, unlike the enum, it has the possibility to be modified at runtime, so it is possible to add or delete auction type
    // was not implemented since it was not necessary, but it can be useful
    /// mapping (string => bool) auctionType;

    /// @notice a kind of enum but variable to allow to store the various types of decay function. Is useless because in the dutch auction is never used
    /// @dev same of auctionType
    mapping (string => address) decayType;

    /// @notice double key map ((user_address, auction_address) => info_auction)
    mapping(address => mapping(address => bool)) auctions;
    address[] public auctions_addresses;
    uint public n_auction = 0;

    /// @notice check if the caller is the owner.
    modifier is_owner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    /// @notice useful only to avoid spam from unnecessary auctions. (even if there is already the cost in gas to be paid by those who create the auction)
    modifier send_pay {
        require(msg.value >= 500000000000000, "Must sent a 0.0005 ether about 5$ to create a auction.");
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    /// @notice Is useless because in the dutch auction is never used
    function add_decay_type(string memory _type, address address_decay) public is_owner returns(string memory) {
        require(keccak256(abi.encodePacked(decayType[_type])) == keccak256(abi.encodePacked("")), "Exist");
        decayType[_type] = address_decay;
    }

    /// @notice I take back all earnings that have been made by the auction house
    function send_gain() public is_owner {
        //TODO: leaves some money to the contract to perform any transactions
        owner.transfer(address(this).balance);
    }

    /// @notice Contract useful in the Dapp. Done only for immediacy of implementation
    function create_dutch (
        string memory _description,
        uint _initial_price,
        uint _reserve_price,
        uint _block_to_live,
        Decay _decay_function
    ) public payable send_pay returns(address) {

        Dutch _auction = new Dutch(
            n_auction,
            msg.sender,
            _description,
            _initial_price,
            _reserve_price,
            _block_to_live,
            _decay_function
        );
        address _add = address(_auction);

        emit newAuction(
            "Dutch",
            _add,
            owner,
            msg.sender,
            _description
        );

        auctions_addresses.push(_add);
        auctions[msg.sender][_add] = true;
        n_auction += 1;
        return _add;
    }

    /// @notice Contract useful in the Dapp. Done only for immediacy of implementation
    function create_vickrey (
        string memory _description,
        uint _good_value,
        uint _reserve_price,
        uint _commitment_btl,
        uint _withdrawal_btl,
        uint _opening_btl
    ) public payable send_pay returns(address) {

        Vickrey _auction = new Vickrey(
            n_auction,
            msg.sender,
            _description,
            _good_value,
            _reserve_price,
            _commitment_btl,
            _withdrawal_btl,
            _opening_btl
        );
        address _add = address(_auction);

        emit newAuction(
            "Vickrey",
            _add,
            owner,
            msg.sender,
            _description
        );

        auctions_addresses.push(_add);
        auctions[msg.sender][_add] = true;
        n_auction += 1;
        return _add;
    }

    /// @notice Check if the passing auction was created by whoever called the function
    function is_mine(address _auction) public view returns(bool) {
        return auctions[msg.sender][address(_auction)];
    }

    /// @notice Delete the auction (only the person who created it can do so), the grace period must not have elapsed
    function destroy_auction(Auction _auction) public {
        require(auctions[msg.sender][address(_auction)], "Not exist");
        _auction.revert_auction();
    }

    /// @notice usefull to send event of auction (end of a phase)
    /// @dev this function is called from a python script that emulate the EthereumAlarmClock
    function send_state_event(uint auction_id, string memory _type) public is_owner {
        Auction(auctions_addresses[auction_id]).send_state_event(_type);
    }

}