// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";
import "hardhat/console.sol";

contract Lottery  is Initializable{
  
  uint[] public winningLotteryNumber;//开奖号码
  uint public lotteryBet;//每次投注的金额
  uint256 public lastUserId;//用户投注编号
  address public owner;
  struct LotteryPlayers {
    uint256 id;     //用户投注编号
    address userAddress; //用户地址
    uint8[] lotteryNumber;//彩票号码
  }
  
  mapping(uint256 => LotteryPlayers) public idToLotteryPlayers;
  mapping(address => uint256[]) public addressToUserIds;

    function initialize() public initializer {
       lotteryBet = 1 ether;//每次限投 1 ether
       lastUserId =0;//用户投注编号
       owner = msg.sender;

    }
    //投注
    function throwIn(uint8[] calldata buyLotteryNumber) public payable{
        //require(msg.value == lotteryBet, "invalid price");//测试时关闭
        require(winningLotteryNumber.length == 0);	 //还没有开奖
        require(buyLotteryNumber.length == 4,'buyLotteryNumber.length == 4');//投注数字是否满足4个
        lastUserId++;//用户投注编号
        LotteryPlayers memory lotteryPlayers = LotteryPlayers({
            id:lastUserId,//用户投注编号
            userAddress:msg.sender,//用户地址
            lotteryNumber:buyLotteryNumber
        });
       idToLotteryPlayers[lastUserId]=lotteryPlayers;
       addressToUserIds[msg.sender].push(lastUserId);
    }
    //通过用户投注编号 查询 彩票数组内容
    function getLotteryNumberByUserId(uint256 id) public view returns (uint8[]  memory) {
      require(id <= lastUserId,'id <= lastUserId');//
       return idToLotteryPlayers[lastUserId].lotteryNumber;
    }
    //通过用户地址 查询 该用户所有的投注编号 
    function getUserIdsByAddress(address userAddress) public view returns (uint256[]  memory) {
       return addressToUserIds[userAddress];
    }
    //查询 开奖号码 
    function getWinningLotteryNumber() public view returns (uint[]  memory) {
       return winningLotteryNumber;
    }
    //抽奖 只有管理员有权限
    function luckDraw() public   {
        require(lastUserId != 0);	//确保当前盘内有人投注
        require(winningLotteryNumber.length == 0);	
        require(msg.sender == owner);	
        //利用当前区块的时间戳、挖矿难度和盘内投注彩民数来取随机值
        winningLotteryNumber.push(uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,owner,lastUserId)))%10);
        winningLotteryNumber.push(uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,owner,lastUserId)))%10);
        winningLotteryNumber.push(uint(keccak256(abi.encodePacked(block.difficulty,owner,block.timestamp,lastUserId)))%10);
        winningLotteryNumber.push(uint(keccak256(abi.encodePacked(block.difficulty,owner,lastUserId,block.timestamp)))%10);

        uint256[] storage firstPrize;    //一等奖
        uint256[]  storage secondPrize;   //二等奖

        for(uint256 i=1;i<=lastUserId;i++){
           uint have=0;
           for(uint256 j=0;j<4;j++){
             if(idToLotteryPlayers[i].lotteryNumber[j]==winningLotteryNumber[j]){
                have++;
             }
           }
           if(have==4){
                firstPrize.push(i);
           }else if(have==3){
                secondPrize.push(i);
           }
        }
        
        if(firstPrize.length>0&&secondPrize.length==0){//如果只有1等奖的用户，平均发放奖励
          uint256 _money=address(this).balance/firstPrize.length;
          for(uint256 i=0;i<firstPrize.length;i++){
            address(uint160(idToLotteryPlayers[firstPrize[i]].userAddress)).transfer(_money);
          }
        } else if(firstPrize.length==0&&secondPrize.length>0){//如果只有2等奖的用户，平均发放奖励
          uint256 _money=address(this).balance/secondPrize.length;
          for(uint256 i=0;i<secondPrize.length;i++){
            address(uint160(idToLotteryPlayers[secondPrize[i]].userAddress)).transfer(_money);
          }
        } else if(firstPrize.length>0&&secondPrize.length>0){//1等奖2等奖都有
          //余额的80% 1等奖 平均分配
          uint256 _money_first=address(this).balance*80/100/firstPrize.length;
          //余额的20% 2等奖 平均分配
          uint256 _money_second=address(this).balance*20/100/secondPrize.length;

          for(uint256 i=0;i<firstPrize.length;i++){
            address(uint160(idToLotteryPlayers[firstPrize[i]].userAddress)).transfer(_money_first);
          }
          
          for(uint256 i=0;i<secondPrize.length;i++){
            address(uint160(idToLotteryPlayers[secondPrize[i]].userAddress)).transfer(_money_second);
          }
        } 
    }
}