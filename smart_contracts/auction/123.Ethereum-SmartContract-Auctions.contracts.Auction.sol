// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
import "../node_modules/Counters.sol";
import "../node_modules/Ownable.sol";

contract Auction {
    
    using Counters for Counters.Counter;
    Counters.Counter private saleId;

    enum State { AwaitingAuctionsStart, OngoingAuctions, AuctionsEnded }
    State public CurrentState = State.AwaitingAuctionsStart;

    struct Sale{
        address sellerAdress;
        string name;
        string description;
        string image;
        uint price;
    }
    
    struct Bider{
        bool isRegistered;
        bool ongoingBid;
        bool hasProposedSale;
    }

    struct AuctionWinner {
        address topBidder;
        uint topBid;
    }
    
    mapping( address => bool) adminList;
    mapping( address => Bider) bidderWhiteList;
    mapping( address => uint) bidHistory;
    mapping(address => uint) credits;
    
    Sale[] sales;
    Sale registeredSale;

    AuctionWinner winner;

    event newAdmin(address admin);
    event newBidder(address bidder);
    event newSale(address seller);
    event newBid(uint price);
    event newSender(address sender);

    /**
     * N'autorise que les administrateurs
     */
    modifier onlyAdmin () {
        require(adminList[msg.sender] == true, unicode"Vous devez être administrateur pour enregistrer un utilisateur");
        _;
    }
    /**
     * N'autorise que les enchérisseurs
     */
    modifier onlyBidder () {
        require(bidderWhiteList[msg.sender].isRegistered, unicode"Vous n'êtes pas enregistré");
        _;
    }
    /**
     * N'autorise que le vendeur
     */
    modifier onlySeller () {
        require(msg.sender == registeredSale.sellerAdress, unicode"Vous n'êtes pas le vendeur");
        _;
    }
    
    function registerAdmin(address _user) public {
        adminList[_user] = true;
        
        emit newAdmin(_user);
    }

    function registerBidder(address _user) public onlyAdmin{
        bidderWhiteList[_user].isRegistered = true;
        
        emit newBidder(msg.sender);
    }
    
    function startAuction() public onlyAdmin returns (State) {
        require(CurrentState == State.AwaitingAuctionsStart, unicode"Les enchères sont en cours ou terminée.");
        
        CurrentState = State.OngoingAuctions;
        return CurrentState;
    }
    
    function endAuction() public onlyAdmin returns (State) {
        require(CurrentState == State.OngoingAuctions, unicode"Les enchères n'ont pas démarré ou sont terminée");
        CurrentState = State.AuctionsEnded;

        allowForPull(registeredSale.sellerAdress, winner.topBid);

        return CurrentState;
    }

    function allowForPull(address _receiver, uint _amount) private {
        credits[_receiver] += _amount;
    }

    function sellerWithdrawCredits() public onlySeller {
        require(CurrentState == State.AuctionsEnded, unicode"Les enchères ne sont pas encore terminées");
        uint amount = credits[msg.sender];

        require(amount != 0);
        require(address(this).balance >= amount);

        credits[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    function buyerWithdrawCredits() public onlyBidder {
        require(bidHistory[msg.sender] < winner.topBid, unicode"vous gagnez l'enchère impossible de retirer");

        uint amount = bidHistory[msg.sender];

        require(amount != 0);
        require(address(this).balance >= amount);

        bidHistory[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }
    
    function proposeSale(string memory _name, string memory _description, string memory _image, uint _amount) public onlyBidder {
        require(CurrentState == State.AwaitingAuctionsStart, unicode"Les enchères ont déjà démarré ou elles sont terminée");
        require(bidderWhiteList[msg.sender].isRegistered == true, unicode"vous devez etre enregistré en tant qu'utilisateur");
        require(bidderWhiteList[msg.sender].hasProposedSale == false, unicode"vous avez déjà proposé une vente");

        bidderWhiteList[msg.sender].hasProposedSale = true;

        sales.push(Sale(msg.sender, _name, _description, _image, _amount));
        
        emit newSale(msg.sender);
    }
    
    function viewPendingSales() public onlyAdmin view returns(Sale[] memory){
        return sales;
    }

    function viewRegisteredSale() public onlyBidder view returns(Sale memory){
        return registeredSale;
    }

    

    function acceptSale(address _sellerAdress) public onlyAdmin{
        for(uint i=0; i<sales.length; i++){
            if(sales[i].sellerAdress == _sellerAdress){
                registeredSale = sales[i];
            }
        }
    }

    function bid() public onlyBidder payable {
        require(CurrentState == State.OngoingAuctions, unicode"Les enchères n'ont pas démarré ou sont terminée");
        require(winner.topBidder != msg.sender, unicode"Vous avez déjà la meilleure enchère");
        require(msg.value > winner.topBid, unicode"Cette somme est inférieure à l'enchère actuelle");
        require(msg.value > registeredSale.price, unicode"Cette somme est inférieure au prix initial");

        winner.topBid = msg.value;
        winner.topBidder = msg.sender;

        bidHistory[msg.sender] = msg.value;
    }

    function viewYourBid() public onlyBidder view returns(uint){
        require(CurrentState != State.AwaitingAuctionsStart, unicode"Les enchères n'ont pas encore démarré");
        return bidHistory[msg.sender];
    }

    function viewBestBid() public onlyBidder view returns(uint){
        require(CurrentState != State.AwaitingAuctionsStart, unicode"Les enchères n'ont pas encore démarré");
        return winner.topBid;
    }

    function viewResults() public onlyBidder view returns(AuctionWinner memory){
        require(CurrentState == State.AuctionsEnded, unicode"Les enchères ne sont pas encore terminées");
        return winner;
    }

    function showCurrentState() public view returns(State){
        return CurrentState;
    }

}