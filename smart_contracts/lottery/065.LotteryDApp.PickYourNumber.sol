pragma solidity ^0.4.16;
import "./TOKEN.sol";
contract PickNumber is MyAdvancedToken{
    //建構子透過TOKEN函式
     constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) MyAdvancedToken(initialSupply, tokenName, tokenSymbol) public {}
    //PickNumber事件
    event PickNumberEvent(uint choosenumber, uint amount);
    //giveWinner事件
    event giveWinnerEvent(address[] winner,uint winprize);
    event resetEvent();
    //0~100數字量
    uint[101] public number;
    //玩家列表
    address[] public playerlist;
    //投注數字總量
    uint public totalnum;
    //開獎冷卻
    uint givewinnercooldown= 10 seconds ;
    uint public givewinner_readytime;
    uint payforwinfee= 0.0001 ether;
    uint public start=0;
    //數字 對應 其擁有者(陣列)
    mapping(uint=>address[])public  NumToOwner;
    //擁有者所 對應數字(陣列)
    mapping(address=>uint[])public  OwnerToNum;
    //擁有者 對應 擁有不重複數字量
    mapping(address=>uint) public   OwnerCount;
    //擁有者 對應 數字 對應 數字量
    mapping(address=> mapping(uint=>uint))public OwnerNumCount;
    //玩家 對應 參加與否
    mapping (address=> bool)public joining;
    /*
        檢查該數字是否被該玩家選過
        選過則回傳True
    */
    function Checkpick(uint _number ,address _address) public view returns(bool){
        uint[] memory temp;
        temp=OwnerToNum[_address];
        for(uint j=0;j<temp.length;j++){
            if(_number==temp[j])
             return true;
        }
    }
    /*
        參加遊戲
       每一輪只能參加一次
       初始token 100
       將玩家加入 playerlist
    */
    function joingame  () public {
        require(!joining[msg.sender]);
        joining[msg.sender]=true;
        if(start==0)
            _triggergivewinner_cooldowntime();
        _transfer(owner,msg.sender,100);
        playerlist.push(msg.sender);
        start=1;
    }
     function payfortoken()public payable{
        require(joining[msg.sender]);
        require(msg.value>=payforwinfee);
        _transfer(owner,msg.sender,10000);
    }
    /*
        選擇數字介於0~100 擁有TOKEN大於下注量 下注量>0
        先檢查數字是否被選過
        沒有則OwnerCount++
              NumToOwner[_choosenumber]加入choosenumber
              OwnerToNum[玩家]加入玩家
        OnwerNumCount[玩家][_choosenumber]加入數字量
        將_amount轉給合約
        totalnum+上_amount.
        觸發PickNumberevent
    */
    function PickYourNumber(uint _choosenumber ,uint _amount) public {
        require(_choosenumber>0&&_choosenumber<=100);
        require(balanceOf[msg.sender]>_amount);
        require(_amount>0);
        require(joining[msg.sender]);
        uint temp =balanceOf[address(this)];
        _transfer(msg.sender,address(this),_amount);
        uint temp2= balanceOf[address(this)];
        require(temp2>=temp+_amount);
        bool check=((Checkpick(_choosenumber,msg.sender)));
        number[_choosenumber]+=_amount;
        if(check==false){
            OwnerCount[msg.sender]++;}
        if(check==false){
            NumToOwner[_choosenumber].push(msg.sender);}
        if(check==false){
            OwnerToNum[msg.sender].push(_choosenumber);}
        OwnerNumCount[msg.sender][_choosenumber]+=_amount;
        totalnum+=_amount;
        emit PickNumberEvent(_choosenumber,_amount);
        
        
    }
    /*
        回傳玩家選所選擇之數字(陣列)與
                          數字量(陣列)
    */
    function getNumberPick()public view returns(uint[],uint[]){
     uint[] memory temp;
     uint[] memory  result=new uint[](OwnerCount[msg.sender]);
     temp=OwnerToNum[msg.sender];
        for(uint j=0; j<temp.length;j++){
         result[j]= OwnerNumCount[msg.sender][temp[j]];
        }
      return(temp,result);
    }
    /*
        獲得最後得獎號碼
        將number數字與數字量做加權
        再將num*2/3得到最後數字
    */
  
    function getWinnumber()public view returns(uint){
        uint total;
        uint num;
        uint winnummber;
        for(uint i=0;i<101;i++){
          total+= number[i]*i;
        }
        num=total/totalnum;
        winnummber=num*2/3;
        return winnummber;
    }
    /*
        回傳擁有勝利數字之擁有者(陣列)
    */
    function getWinner() public view returns(address[]){
        address[] memory winlist;
        uint winnernum=getWinnumber();
       winlist=NumToOwner[winnernum];
       return winlist;
    }
    /*
        回傳合約所獲得之TOKEN
    */
    function getWinprize()public view returns(uint){
    return  balanceOf[address(this)];
    }
    /*
        觸發派獎冷卻
    */
function _triggergivewinner_cooldowntime() internal  {
        givewinner_readytime=uint32(now + givewinnercooldown); 
  }
  /*
    回傳玩家所擁有之TOKEN
  */
  function getYourToken()public view returns(uint){
      return balanceOf[msg.sender];
  }
  /*
    回傳冷卻是否完成
  */
  function givewinnerReady()public view returns (bool){
      return(givewinner_readytime<=now);            
  }
  function getcooldowntime()public view returns (uint){
      return(givewinner_readytime-now);            
  }
  /*
    發獎給得獎者
    將總獎金平分給winnerlist中的玩家
  */
  function givewinner()public onlyOwner{
       require(givewinnerReady());
       uint winnerprize=getWinprize();
       address[] memory winnerlist =getWinner();
       uint winnercount=winnerlist.length;
       uint winnernumber=getWinnumber();
       uint num_count=number[winnernumber];
       uint averageprize=winnerprize/num_count;
       require(winnerprize>=totalnum);
       require(winnercount!=0);
       for(uint i=0;i<winnercount;i++){
         uint winner_numcount= OwnerNumCount[winnerlist[i]][winnernumber];
           _transfer(address(this),winnerlist[i],averageprize*winner_numcount-1);
       }
       _triggergivewinner_cooldowntime();
       emit giveWinnerEvent(winnerlist,averageprize-1);
       reset();
    }
    /*
        將所有值重製
    */
   function reset() public onlyOwner{
        address[] memory temp;
        uint[]   memory temp1;
        uint[] memory result;
        address[] memory temp2;
        for(uint i=0;i<101;i++){
            number[i]=0;
            NumToOwner[i]=temp;
        }
        totalnum=0;
        _transfer(address(this),owner,balanceOf[address(this)]);
        uint playercount=playerlist.length;
        for(uint j=0;j<playercount;j++){
             result=OwnerToNum[playerlist[j]]; 
             for(uint k=0;k<result.length;k++){
                OwnerNumCount[playerlist[j]][result[k]]=0;
             }
            OwnerCount[playerlist[j]]=0;
            OwnerToNum[playerlist[j]]=temp1;
            joining[playerlist[j]]=false;
        }
        start=0;
        playerlist=temp2;
        emit resetEvent();
    }

}
