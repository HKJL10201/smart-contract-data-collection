pragma solidity ^0.6.0;
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./ERC777Token.sol";

contract CardsMarket is ERC721, Ownable{
    constructor() ERC721("NFT","NFT") public { }
    struct Cards {
        string name;
        int aggressivity;
        // uint quantity;
        uint sort;
        string description;
        uint  Object_of_action;
        int aggressivity_action;
        uint tokenid;
    }
    string[24] public card_names = ["黑手党","无人机","办公室职员","面具","教授","童工","商人","刺青组","沉思少女","引路人","烟鬼","奸商","工头","叛变执法者","迷失者","雏鹰","公爵夫人","酒鬼","夜视者","诡面","鸦雀","拼图","重拳","猩红猎人"];
    int[24] public card_aggressivity = [6,3,4,5,5,4,4,3,6,8,6,5,4,6,1,3,5,6,8,5,4,4,5,6];
    int[24] public card_aggressivity_action = [0,0,0,2,0,2,0,0,0,0,0,3,0,0,2,0,0,0,0,2,0,0,0,0];
    uint[24] card_Object_of_action = [0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0];
    string[24] public card_description = ["最大黑势力，加攻击防御","运输能力提升，防御力提升","尽职尽责，防御力提升","间谍，减对方防御","研究科技，防御提升","为对方安排童工，增加逮捕可能，减少对方防御","销路提升，增加防御","地头蛇组织，增加攻击","审视自己，加强力量，增加防御","运输能力提升，减少曝光几率，增加攻击防御","理智清醒的混混，增加攻击防御","使对方产品成本提高，减少对方防御","劳工头目，增加攻击防御","被贿赂的执法人员，增加攻击防御","迷失自我，减少自身防御","野心勃勃的少女，增加攻击","黑政合作，提高防御","神志不清的混混，增加攻击","紧盯黑夜生意，对方沉默一回合","黑暗下的阴险谋士，增加攻击，减少防御","鸦雀无声，和平相处，清除间谍","共赢，清除迷失者","奋力一击，增加攻击","狩猎机遇，增加攻击，增加防御"];
    
    Cards[] public All_Cards;
    mapping(uint256 => Cards) public map_cards;
    struct ArrayForCards{
        uint[] saling_cards;
    }

    enum StateType {
        HandsOn,
      ItemAvailable,
      OfferPlaced,
      Accepted
    }
    uint[] public SaleCards;
    mapping (uint => StateType) State;
    struct InstanceOwner{
        address Owner_address;
        uint Card_mapping_key;
        uint AskingPrice;
        string Description;
    }
    struct InstanceBuyer{
        address Buyer_address;
        uint Card_mapping_key;
        uint offerPrize;
    }
    mapping (uint => InstanceOwner) public AllInstanceOwner;
    mapping (uint => InstanceBuyer) public AllInstanceBuyer;

    //ERC777
    ERC777Token ERC_777;
    
    function Link_ERC777Token  (address address_ERC777Token) public {
        ERC_777 = ERC777Token(address_ERC777Token);
    }
    function Create_The_Card(uint card_symbol) public onlyOwner{
    uint256 _tokenid = totalSupply();
    All_Cards.push(Cards({name : card_names[card_symbol], aggressivity : card_aggressivity[card_symbol], sort:card_symbol, description:card_description[card_symbol], Object_of_action:card_Object_of_action[card_symbol], aggressivity_action:card_aggressivity_action[card_symbol], tokenid:_tokenid}));
    map_cards[_tokenid]=Cards({name : card_names[card_symbol], aggressivity : card_aggressivity[card_symbol], sort:card_symbol, description:card_description[card_symbol], Object_of_action:card_Object_of_action[card_symbol], aggressivity_action:card_aggressivity_action[card_symbol], tokenid:_tokenid});
    State[_tokenid]=StateType.HandsOn;
    _safeMint(owner(), _tokenid);
    }
    function Create_The_Card_ForYou(uint card_symbol,address TheYou) public onlyOwner{
            uint256 _tokenid = totalSupply();
            All_Cards.push(Cards({name : card_names[card_symbol], aggressivity : card_aggressivity[card_symbol], sort:card_symbol, description:card_description[card_symbol], Object_of_action:card_Object_of_action[card_symbol], aggressivity_action:card_aggressivity_action[card_symbol], tokenid:_tokenid}));
            map_cards[_tokenid]=Cards({name : card_names[card_symbol], aggressivity : card_aggressivity[card_symbol], sort:card_symbol, description:card_description[card_symbol], Object_of_action:card_Object_of_action[card_symbol], aggressivity_action:card_aggressivity_action[card_symbol], tokenid:_tokenid});
            State[_tokenid]=StateType.HandsOn;
            _safeMint(TheYou, _tokenid);
    }
    function CreateDeal (uint Card_mapping_key, string memory description, uint price) public returns(uint) {
        
        require(price>0);
        require(State[Card_mapping_key] == StateType.HandsOn);
        require(ownerOf(Card_mapping_key) == msg.sender);
        InstanceOwner memory newOwner = InstanceOwner({Owner_address:msg.sender, Card_mapping_key:Card_mapping_key, AskingPrice:price, Description:description});
        AllInstanceOwner[Card_mapping_key]=newOwner;
        State[Card_mapping_key] = StateType.ItemAvailable;  
        SaleCards.push(Card_mapping_key);
        uint num_of_deal = SaleCards.length;
        return num_of_deal;
    }

    function MakeOffer(uint Card_mapping_key, uint offerPrice) public returns(uint) {
        require(offerPrice>0);
        require(State[Card_mapping_key] == StateType.ItemAvailable);
        require(AllInstanceOwner[Card_mapping_key].Owner_address != msg.sender);
        // uint balance = ERC_777.balanceOf(msg.sender);
        require(offerPrice >= AllInstanceOwner[Card_mapping_key].AskingPrice);
        InstanceBuyer memory newBuyer = InstanceBuyer({Buyer_address:msg.sender, Card_mapping_key:Card_mapping_key ,offerPrize:offerPrice});
        // newBuyer.Buyer_address = msg.sender;
        // newBuyer.Card_mapping_key = Card_mapping_key;
        // newBuyer.offerPrize = offerPrice;
        AllInstanceBuyer[Card_mapping_key] = newBuyer;
        State[Card_mapping_key] = StateType.OfferPlaced;
        ERC_777.approve(AllInstanceOwner[Card_mapping_key].Owner_address,offerPrice);
        return Card_mapping_key;
    }

    function Reject(uint Card_mapping_key) public {
        require(State[Card_mapping_key] == StateType.OfferPlaced);
        require(AllInstanceOwner[Card_mapping_key].Owner_address == msg.sender);
        delete AllInstanceBuyer[Card_mapping_key];
        State[Card_mapping_key] = StateType.HandsOn;
    }
    function CancelDeal(uint Card_mapping_key) public {
        require(State[Card_mapping_key] == StateType.ItemAvailable);
        require(AllInstanceOwner[Card_mapping_key].Owner_address == msg.sender);
        delete AllInstanceOwner[Card_mapping_key];
        State[Card_mapping_key] = StateType.HandsOn;
        
    }
    function AcceptOffer(uint Card_mapping_key) public returns (uint){
        require(AllInstanceOwner[Card_mapping_key].Owner_address == msg.sender);
        //ERC777
        
        ERC_777.transferFrom(AllInstanceBuyer[Card_mapping_key].Buyer_address, msg.sender, AllInstanceOwner[Card_mapping_key].AskingPrice);
        approve(AllInstanceBuyer[Card_mapping_key].Buyer_address, Card_mapping_key);
        safeTransferFrom(msg.sender,AllInstanceBuyer[Card_mapping_key].Buyer_address,Card_mapping_key);
        State[Card_mapping_key] = StateType.HandsOn;
        delete AllInstanceOwner[Card_mapping_key];
        delete AllInstanceBuyer[Card_mapping_key];
        uint length = SaleCards.length;
        for(uint i=0;i<length;i++){
            if(SaleCards[i]==Card_mapping_key){
                delete SaleCards[i];
                SaleCards[i]=SaleCards[length-1];
                SaleCards.pop();
                break;
            }
        }
        uint num_of_deal = SaleCards.length;
        return num_of_deal;
    }
    function getGoodAddresses(uint Card_mapping_key) public view returns(address buyer,uint askprice){
        return (AllInstanceBuyer[Card_mapping_key].Buyer_address, AllInstanceOwner[Card_mapping_key].AskingPrice);
    }
    function getOwnedTokens(address _owner) public view returns (uint256[] memory) {
        uint256 length;
        uint256 i;
        uint256[] memory tokens;
        uint256 card;
        length = balanceOf(_owner);
        for(i=0;i<length;i++){
            card =tokenOfOwnerByIndex(_owner,i);
            tokens[i] = card;
        }
        return tokens;
    }
    function getmySaleCards(address _user) public returns (ArrayForCards memory) {
        ArrayForCards mySaleCards;
        uint256[] memory myCards;
        uint i=0;
        uint j = 0;
        myCards = getOwnedTokens(_user);
        uint256 length;
        length = balanceOf(_user);
        for(i=0;i<length;i++){
            if(State[myCards[i]]==StateType.ItemAvailable){
                mySaleCards.saling_cards[j]=myCards[i];
                j=j+1;
            }
        }
        return mySaleCards;
    } 
    function getSaleCards() public returns (ArrayForCards memory){
        ArrayForCards copy_sale_cards;
        for(uint i=0;i<SaleCards.length;i++){
            copy_sale_cards.saling_cards[i]=SaleCards[i];
        }
        return copy_sale_cards;
    }
    function getNumOfSaleCards() public view returns (uint){
        return SaleCards.length;
    }
    function getthatSalecard(uint symbolid) public view returns (uint) {
        return SaleCards[symbolid];
    }
    function ifthiscardOnSaling(uint symbolid) public view returns (bool){
        if(State[symbolid]!=StateType.HandsOn){
            return true;
        }
        else{
            return false;
        }
    }
    function ifthiscardBeOffered(uint symbolid) public view returns (bool){
        if(State[symbolid]==StateType.OfferPlaced){
            return true;
        }
        else{
            return false;
        }
    }
    function getTokenProperty(uint256 tokenId) public view returns (int aggressivity,uint  Object_of_action,int aggressivity_action ,uint sort) {
        return (map_cards[tokenId].aggressivity,map_cards[tokenId].Object_of_action,map_cards[tokenId].aggressivity_action,map_cards[tokenId].sort);
    }
    function getSalingTokenProperty(uint256 tokenId) public view returns (int aggressivity,uint  Object_of_action,int aggressivity_action ,uint sort ,string memory Description ,uint AskingPrice ,address Owner_address) {
        require(State[tokenId] != StateType.HandsOn);
        return (map_cards[tokenId].aggressivity,map_cards[tokenId].Object_of_action,map_cards[tokenId].aggressivity_action,map_cards[tokenId].sort,AllInstanceOwner[tokenId].Description,AllInstanceOwner[tokenId].AskingPrice,AllInstanceOwner[tokenId].Owner_address);
    }

}