// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AuctionCreator{
    //on créé un array dynamique qui garde les adresses des auctions qui sont créées
    Auction[] public auctions;

    function createAuction()public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }

    //lorsque un utilisateur appelle la fonction createAuction, cette fonction va initialiser une nouvelle auction
}

contract Auction {
    address payable public owner;
    //lorsque l'enchère démarre, on a le timestamp(15sec blocktime)
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

//les états de notre enchère
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint public highestBindingBid;
    address payable public highestBider;

    mapping(address=> uint)public bids;
    uint bidIncrement;

    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        //enchère avec une durée d'une semaine
        endBlock = startBlock + 40320;
        ipfsHash = "";
        bidIncrement = 1;
    }

//on empeche l'oner de l'enchère d'enchérir lui meme sur son auction
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    //l'enchère aura lieue entre le début et la fin
    modifier afterStart(){
    require(block.number >= startBlock);
    _;
    }

    modifier beforeEnd(){
    require(block.number <= endBlock);
    _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

//il s'agit d'une fonction pure, elle n'interragit donc pas avec la blockchain
    function min(uint a, uint b)pure internal returns(uint){
        if(a <= b){
            return a;
        }else {
            return b;
            }
    }

    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }

//on applique les modifiers à notre fonction
//une enchère ne peut etre placé uniquement après le début et avant la fin, avec un montant minimum de 100 wei(modifiable)
    function placeBid()public payable notOwner afterStart beforeEnd{
    require(auctionState == State.Running);
    require(msg.value >= 100);

    uint currentBid = bids[msg.sender] + msg.value;
    //on exige que l'enchère soit plus élevé que l'enchère la plus haute
    require(currentBid > highestBindingBid);
//on actualise les variables pour l'utilisateur en cours
    bids[msg.sender] = currentBid;

    //Mécaniques des enchères

    if(currentBid <= bids[highestBider]){
        highestBindingBid = min(currentBid + bidIncrement, bids[highestBider]);
    
    }else{
        highestBindingBid = min(currentBid, bids[highestBider] + bidIncrement);
        highestBider = payable(msg.sender);
        }
    }

    function finalizeAuction()public {
        //si l'enchère est cancel par l'owner ou si elle est finie, alors la function renvoie true
        require(auctionState == State.Canceled || block.number > endBlock);
        //un bidder ou l'owner peuvent finaliser l'auction en cours
        require(msg.sender == owner || bids[msg.sender] > 0);
        //l'adresse recipient permet de recupérer des fonds
        address payable recipient;
        uint value;

        if(auctionState == State.Canceled) {//enchère annulée
        //le recipient est le bidder qui appelle la fonction pour récupérer sa mise
            recipient = payable(msg.sender);
            value = bids[msg.sender];

        }else {//enchère finie(pas annulée), si l'owner finalise l'auction il recevra la plus haute enchère
            if(msg.sender == owner) {//le owner 
            //le recipient est l'owner
            recipient = owner;
            value = highestBindingBid;

        }else {//c'est un encherisseur
            if(msg.sender == highestBider){
                //le recipient est le meilleur enchérisseur
            recipient == highestBider;
            value = bids[highestBider] - highestBindingBid;
            }else {//ni le owner ni le highestBider
            recipient = payable(msg.sender);
            value = bids[msg.sender];

        
                }
            }

        }
        //on re initialise les enchères du recipient à 0 
        bids[recipient] = 0;
        //on envoie les fonds au recipient
        recipient.transfer(value);
    }
}