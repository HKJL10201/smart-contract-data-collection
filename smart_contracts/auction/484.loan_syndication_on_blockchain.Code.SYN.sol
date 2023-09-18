pragma solidity ^0.5.5;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/Crowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/crowdsale/distribution/RefundablePostDeliveryCrowdsale.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Mintable.sol";


// This contract imports the fungible standard tokens and allows for minting of the tokens in conjuction with the crowdsale contract

contract MyToken is ERC20, ERC20Detailed, ERC20Mintable {
    constructor(
        string memory name,
        string memory symbol,
        uint initial_supply
    )
        ERC20Detailed(name, symbol, 18)
        public
    {
        // constructor can stay empty
    }
}

// This contract is for the crowdsale portion of the contract which imitates a large bank seeking syndicate partners with smaller banks

contract MyTokenSale is Crowdsale, MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, RefundablePostDeliveryCrowdsale {

    constructor(uint rate, address payable wallet, MyToken token, string memory symbol, uint goal, uint open, uint close, uint cap)
        Crowdsale(rate, wallet, token) RefundableCrowdsale(goal) TimedCrowdsale(open, close) CappedCrowdsale(cap) public
    {
        // constructor can stay empty
    }
}

// This is the master loan deployer contract which the borrower should use to initiate the syndicated loan

contract LoanContractDeployer {

    address public token_sale_address;
    address public token_address;
    address public auction_address;
    address public borrower;
    uint public paytime;

    constructor(string memory name, string memory symbol, address payable wallet, uint goal, uint cap) public {   
        
        // Token creation
        MyToken token = new MyToken(name, symbol, 0);
        token_address = address(token);

        // Auction Portion to determine interest rate, token ownership (transfer to bank)

        borrower = msg.sender;

        LoanAuction winner = new LoanAuction(wallet, goal, borrower);
        auction_address = address(winner);
        
        
        // Crowdsale portion
        uint open = now;
        
        // Set this to the desired duration of the crowdsale
        uint close = now + 2 minutes;
        
        // Set this to the desired duration of the loan contract
        paytime = now + 365 days;
        
        
        // Wallet should be address of bank
        MyTokenSale my_token_sale = new MyTokenSale(1, wallet, token, symbol, goal, open, close, cap);
        token_sale_address = address(my_token_sale);
        
        // make the MyTokenSale contract a minter, then have the MyTokenSaleDeployer renounce its minter role
        token.addMinter(token_sale_address);
        token.renounceMinter();
        
        }
        
        function Final_Payment(address payable receiver, uint InterestRate, uint tokens_paid) public payable {
            require(paytime >= now, "You must wait until the paytime before making final payment.");
            require(msg.sender == borrower, "You must be the borrower to make the final payment.");
            require(msg.value == ((tokens_paid * InterestRate/10000) + tokens_paid),"You must pay interest and the loan amount.");
            
            // The borrower pays the final amount to the recipient
            receiver.transfer(msg.value);
        }
        
        function() external payable {}
        
        function set_lowestRate() public view returns(uint) {
            LoanAuction auction_address = LoanAuction(auction_address);
            uint InterestRate = auction_address.get_lowestRate();
            return InterestRate = auction_address.get_lowestRate();
        }

        function set_lowestBidder() public view returns(address) {
            LoanAuction auction_address = LoanAuction(auction_address);
            address big_bank = auction_address.get_lowestBidder();
            return big_bank;
        }
        
        function balanceOf(address account) external view returns (uint256) {
            MyToken token = MyToken(token_address);
            return token.balanceOf(account);
            
        }
        
}

// This contract facilitates the auction process whereby competing large banks can bid the lowest rate for the loan amount in exchange for receiving the right to create tokens on the borrowers behalf

contract LoanAuction {
    // variables
    address payable public beneficiary;
    address public deployer;
    uint public lowestBid;
    address payable public lowestBidder;
    uint public lowestRate = 2000;
    uint public goal;
    bool public auctionEnded;
    
    mapping(address => uint) bidList;
    mapping(address => uint) rateList;
    
    event LowestRateDecreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    constructor(address payable _beneficiary, uint _goal, address _deployer) public {
        deployer = _deployer;
        beneficiary = _beneficiary;
        goal = _goal;
    }
    
    // Function needs to be reworked so the bid amount is below the cap and have the interest rate be an input
    function bid(address payable bidder, uint interest_rate) public payable {
        require(!auctionEnded, "The auction has ended.");
        require(msg.value == goal, "Bid must be for the entire loan amount.");
        require(interest_rate < lowestRate);
        
        if (lowestBid != 0) {
            bidList[lowestBidder] = lowestBid;
        }
        
        if (lowestRate != 0) {
            rateList[lowestBidder] = lowestRate;
        }
        
        // Setting the lowest bidder
        lowestBidder = bidder;
        lowestRate = interest_rate;
        
        // Setting the amount for a refund
        lowestBidder = bidder;
        lowestBid = msg.value;
        
        emit LowestRateDecreased(lowestBidder, lowestRate);
    }
    
    function getBidList(address bidder) public view returns(uint) {
        return bidList[bidder];
    }
    
    function balance() public view returns(uint) {
        return address(this).balance;
    }
    
    function get_lowestRate() external view returns(uint) {
        return lowestRate;
    }
    
    function get_lowestBidder() external view returns(address) {
        return lowestBidder;
    }
    
    function withdraw() public returns(bool) {
        require(!auctionEnded,"The auction has already ended.");
        uint amount = bidList[msg.sender];
        
        if (amount > 0) {
            bidList[msg.sender] = 0;
            
            // If the send worked it will return true
            if (!msg.sender.send(amount)) {
                bidList[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    function endAuction() payable public {
        require(!auctionEnded,"The auction has already ended.");
        require(msg.sender == deployer, "You are not the auction deployer.");
        
        auctionEnded = true;
        emit AuctionEnded(lowestBidder, lowestRate);
        
        beneficiary.transfer(msg.value);
    }
    
}