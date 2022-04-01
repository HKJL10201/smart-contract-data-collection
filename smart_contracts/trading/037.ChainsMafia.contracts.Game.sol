pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./ERC777Token.sol";
import "./CardsMarket.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
contract Game is Ownable{

    struct SingleGame{//游戏对局结构体
        int totalAggressivityOfPlayer;//总战力
        // uint[] cardsorts;//对局卡牌种类
        address Opponent;//对手地址
        uint result; //2为游戏胜利
        uint Mover;//牌权
        uint NightCantMove;//夜视者作用
        address DefaultMover;//每局默认先手权
        uint[] used_cards;//每局废弃牌堆
	uint[] temp_used_cards;
    }
    struct GameResult{//返回对局结果结构体
        uint ifend;//游戏是否结束，1为是，0为否
        address winner;//每轮或最终赢家
    }
    struct playerCardsorts{
        uint[] cardsorts;
    }
    mapping (address => playerCardsorts) Cardsorts;
    // mapping (address => address) public Opponent;
    mapping (address => SingleGame) SingleGameProperty;//映射
    struct CardDes{//卡牌信息结构体
            int aggressivity;//战力点
            uint sort;//卡牌种类/DNA
            uint Object_of_action;//特殊作用对象
            int aggressivity_action;//特殊作用动作
            
        }
    // SingleGame[] public SingleGames;
    // uint256 WaitGamerNum = 0;//排队总人数
    // mapping(address => uint256[]) public usersSingleGames;
    address[] public WaitGamer;//排队玩家地址数组
    // address[] Gamers;//总在线玩家地址数组
    CardsMarket public cardsmarket;//CardsMarket合约示例

    enum State{//在线玩家状态
	rest,
        wait,//排队中
        playTime//游玩中
    }
    mapping(address => State) PlayerState;//玩家状态映射
function Link_CardsMarket(address address_CardsMarket) public {
        cardsmarket = CardsMarket(address_CardsMarket);
    }
    function creatSingleGame(address player1,address player2) payable public returns(uint256){//创建对局
        SingleGameProperty[player1].Opponent = player2;
        SingleGameProperty[player2].Opponent = player1;
        SingleGameProperty[player1].totalAggressivityOfPlayer=0;
        SingleGameProperty[player2].totalAggressivityOfPlayer=0;
        SingleGameProperty[player1].result = 0;
        SingleGameProperty[player2].result = 0;
        delete SingleGameProperty[player1].used_cards;
        delete SingleGameProperty[player1].temp_used_cards;
        delete SingleGameProperty[player2].used_cards;
        delete SingleGameProperty[player2].temp_used_cards;
        SingleGameProperty[player1].NightCantMove = 0;
        SingleGameProperty[player2].NightCantMove = 0;
        uint Mover = rand(2);
        if(Mover == 0){
            SingleGameProperty[player1].Mover = 1;
            SingleGameProperty[player2].Mover = 0;
            SingleGameProperty[player1].DefaultMover = player1;
            SingleGameProperty[player2].DefaultMover = player1;
        }
        else{
            SingleGameProperty[player1].Mover = 0;
            SingleGameProperty[player2].Mover = 1;
            SingleGameProperty[player1].DefaultMover = player2;
            SingleGameProperty[player2].DefaultMover = player2;
        }
	return Mover;
    }


	function Can_I_Play(address player) public view returns (address Opponent,address DefaultMover){
            return (SingleGameProperty[player].Opponent,SingleGameProperty[player].DefaultMover);
            }
    function WhoIsMover(address player) public view returns(address Mover){
        if(SingleGameProperty[player].Mover==1){
            return player;
        }
        else{
            return SingleGameProperty[player].Opponent;
        }
    }
    function playTime(address player, uint tokenId) public returns(uint256){//出牌阶段
        if(SingleGameProperty[player].Mover == 1){
            CardDes memory thisCard;
            getCardProperty(thisCard,tokenId);
            SingleGameProperty[player].used_cards.push(tokenId);
		SingleGameProperty[player].temp_used_cards.push(tokenId);
            SingleGameProperty[player].totalAggressivityOfPlayer = SingleGameProperty[player].totalAggressivityOfPlayer+thisCard.aggressivity;
            if(thisCard.Object_of_action==0){//该卡牌的特殊作用对象为自己
                SingleGameProperty[player].totalAggressivityOfPlayer = SingleGameProperty[player].totalAggressivityOfPlayer - thisCard.aggressivity_action;
            }
            else{//该卡牌的特殊作用对象为对方
                SingleGameProperty[SingleGameProperty[player].Opponent].totalAggressivityOfPlayer = SingleGameProperty[SingleGameProperty[player].Opponent].totalAggressivityOfPlayer - thisCard.aggressivity_action;
            }
            if(thisCard.sort==18){//夜视者
                SingleGameProperty[SingleGameProperty[player].Opponent].NightCantMove = 1;
                
            }
            else if(thisCard.sort==20){//鸦雀
                if(ifusedCards_has_TokenId(SingleGameProperty[player].Opponent,3)){
                    CardDes memory thatCard;
                    getCardProperty(thatCard,3);
                    SingleGameProperty[player].totalAggressivityOfPlayer = SingleGameProperty[player].totalAggressivityOfPlayer+thatCard.aggressivity_action;
                }
            }
            else if(thisCard.sort==21){//拼图
                if(ifusedCards_has_TokenId(player,14)){
                    CardDes memory thatCard;
                    getCardProperty(thatCard,14);
                    SingleGameProperty[player].totalAggressivityOfPlayer = SingleGameProperty[player].totalAggressivityOfPlayer+thatCard.aggressivity_action;
                }
                if(ifusedCards_has_TokenId(SingleGameProperty[player].Opponent,14)){
                    CardDes memory thatCard;
                    getCardProperty(thatCard,14);
                    SingleGameProperty[SingleGameProperty[player].Opponent].totalAggressivityOfPlayer = SingleGameProperty[SingleGameProperty[player].Opponent].totalAggressivityOfPlayer+thatCard.aggressivity_action;
                }
            }
        }
    }


    function restTime(address player) public returns(address){//交换牌权
        if(SingleGameProperty[player].Mover == 1){
            if(SingleGameProperty[SingleGameProperty[player].Opponent].Mover==2){//对方放弃跟牌，该玩家仍可出牌
                SingleGameProperty[player].Mover = 1;
                return player;
            }
            else{//对方未放弃出牌
                if(SingleGameProperty[SingleGameProperty[player].Opponent].NightCantMove == 1){//夜视者起作用
                    SingleGameProperty[SingleGameProperty[player].Opponent].NightCantMove = 0;
                    return player;
                }
                else{//普通情况，交换出牌权
                    SingleGameProperty[player].Mover = 0;
                    SingleGameProperty[SingleGameProperty[player].Opponent].Mover = 1;
                    return SingleGameProperty[player].Opponent;    
                }
            }
        }
    }

        function dropTime(address player) public returns (uint , address){//放弃跟牌
        address nowwinner;
        if(SingleGameProperty[player].Mover == 1){
            SingleGameProperty[player].Mover = 2;
            if(SingleGameProperty[SingleGameProperty[player].Opponent].Mover == 2){//本轮游戏结束
                if((SingleGameProperty[player].totalAggressivityOfPlayer)>(SingleGameProperty[SingleGameProperty[player].Opponent].totalAggressivityOfPlayer)){
                    SingleGameProperty[player].result = SingleGameProperty[player].result + 1;
                    nowwinner=player;//本局当前玩家胜利
                }
                else if((SingleGameProperty[player].totalAggressivityOfPlayer)<(SingleGameProperty[SingleGameProperty[player].Opponent].totalAggressivityOfPlayer)){
                    SingleGameProperty[SingleGameProperty[player].Opponent].result = SingleGameProperty[SingleGameProperty[player].Opponent].result + 1;
                    nowwinner=SingleGameProperty[player].Opponent;//本局对方胜利
                }
                else{
                    nowwinner = address(0);//平局
                }
                if(SingleGameProperty[player].result==2){//游戏结束且当前玩家胜利
                    nowwinner = player;
                    // cancelSingleGame(player,SingleGameProperty[player].Opponent);
                    return (1,nowwinner);
                }
                else if(SingleGameProperty[SingleGameProperty[player].Opponent].result==2){//游戏结束且对方玩家胜利
                    nowwinner = SingleGameProperty[player].Opponent;
                    // cancelSingleGame(player,SingleGameProperty[player].Opponent);
                    return (1,nowwinner);
                    
                }
                else{//游戏未结束，下一轮开始
                    if(SingleGameProperty[player].DefaultMover==player){
                        SingleGameProperty[player].DefaultMover=SingleGameProperty[player].Opponent;
                        SingleGameProperty[player].Mover=0;
                        SingleGameProperty[SingleGameProperty[player].Opponent].Mover=1;
                    }
                    else{
                        SingleGameProperty[player].DefaultMover==player;
                        SingleGameProperty[player].Mover=1;
                        SingleGameProperty[SingleGameProperty[player].Opponent].Mover=0;
                    }
                    return (0,nowwinner);
                }
            }
            else{//本轮游戏未结束
                SingleGameProperty[SingleGameProperty[player].Opponent].Mover == 1;
            }
        }
    }
    function NumOfTempCards(address player) public view returns(uint){
        return SingleGameProperty[SingleGameProperty[player].Opponent].temp_used_cards.length;
    }
    function ThisTempCards(address player,uint index) public view returns(uint){
        return SingleGameProperty[SingleGameProperty[player].Opponent].temp_used_cards[index];
    }
	function DeleteHisTempCards(address player) public{
		delete SingleGameProperty[player].temp_used_cards;
        delete SingleGameProperty[SingleGameProperty[player].Opponent].temp_used_cards;
	}
    function gettotalAggressivity(address player) public view returns(uint mine,uint him){
        return (SingleGameProperty[player].totalAggressivityOfPlayer,SingleGameProperty[SingleGameProperty[player].Opponent].totalAggressivityOfPlayer);
    }
// function ifusedCards_has_TokenId(address player,uint tokenId) public returns(bool) {//查找废弃牌堆中有没有目标卡牌
function ifusedCards_has_TokenId(address player,uint tokenId) public view returns(bool){
        uint length = SingleGameProperty[player].used_cards.length;
        uint i=0;
        for(i=0;i<length;i++){
            if(SingleGameProperty[player].used_cards[i]==tokenId){
                return true;
            }
            else{
                
            }
            
        }
        return false;
    }
    function cancelSingleGame(address player1,address player2) public {//结束游戏，释放资源
        address nowplayer1=player1;
        address nowplayer2=player2;
        delete SingleGameProperty[nowplayer1];
        delete SingleGameProperty[nowplayer2];
	PopWaitGamer(player1);
        PopWaitGamer(player2);
    }
    function PushWaitGamer(address player) public returns(uint) {//将玩家加入总队列、排队队列
        PlayerState[player]=State.rest;
        if(PlayerState[player]==State.rest){//玩家不在排队队列中，加入排队队列
            uint user_is_on = 0;
            uint length = WaitGamer.length;
            for(uint i=0;i<length;i++){
                if(WaitGamer[i]==player){
                    user_is_on = 1;
                    break;
                }
            }
            if(user_is_on ==0){
                WaitGamer.push(player);
		        PlayerState[player]=State.wait;
            }
            
        }
        uint nowlength=WaitGamer.length;
	        return nowlength;
    }
    function PopWaitGamer(address player) public {//玩家移出排队队列
        PlayerState[player] = State.rest;
        uint length = WaitGamer.length;
        for(uint i=0;i<length;i++){
            if(WaitGamer[i]==player){
                delete WaitGamer[i];
                WaitGamer[i]=WaitGamer[length-1];
                WaitGamer.pop();
                break;
            }
        }
        
    }    
	function GetTheOpponent(address self) public returns(address){//为排队玩家匹配
        if(WaitGamer.length>=2&&PlayerState[self]==State.wait){
        uint256 random2 = rand(WaitGamer.length);
        while(self==WaitGamer[random2]){
            random2 = rand(WaitGamer.length);
        }
        PlayerState[self]=State.playTime;
        PlayerState[WaitGamer[random2]]=State.playTime;
        address player1 = self;
        address player2 = WaitGamer[random2];
        PopWaitGamer(self);
        PopWaitGamer(WaitGamer[random2]);
        //creatSingleGame(player1,player2);
        return player2;
        }
        else{
            return self;
        }
    }
    function rand(uint256 _length) public view returns(uint256) {//产生伪随机数
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)))%_length;
        return random;
}
    function getNumOfWaitGamer() public view returns(uint){
        return WaitGamer.length;
    }
    function getCardProperty(CardDes memory thisCard,uint256 card) public view  {//获取对应卡牌信息
        (thisCard.aggressivity,thisCard.Object_of_action,thisCard.aggressivity_action,thisCard.sort) = cardsmarket.getTokenProperty(card);
    }
}
