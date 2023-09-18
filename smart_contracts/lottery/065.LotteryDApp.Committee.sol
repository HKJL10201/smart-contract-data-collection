pragma solidity ^0.4.16;
import "./PickYourNumber.sol";
contract Committee is PickNumber{
   constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) PickNumber(initialSupply, tokenName, tokenSymbol) public {}
//Committeelist加入
//透過隨機產生之隨機數與玩家之帳戶
//若最後結果<4則被加入進committeelist
address[] public Committeelist;
uint[101] public c_number;
mapping (address=> bool)public C_joining;
uint256 constant private FACTOR =  1157920892373161954235709852186879078532699846656405640394575840079131296399;
 function C_joingame  () public {
        require(!joining[msg.sender]);
        joining[msg.sender]=true;
        if(start==0)
            _triggergivewinner_cooldowntime();
        _transfer(owner,msg.sender,100);
        playerlist.push(msg.sender);
        uint send_num=C_sender(msg.sender);
        uint rand_num=rand(send_num);
        uint committee_num=uint(keccak256(send_num+rand_num))%10;
        if(committee_num<4)
            Committeelist.push(msg.sender);
        start=1;
    }
    function C_sender(address sender) private view returns(uint){
        return uint(sender);
   }
  function rand(uint max) constant private returns (uint256 result){
  uint256 factor = FACTOR * 100 / max;
  uint256 lastBlockNumber = block.number - 1;
  uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
  return uint256((uint256(hashVal) / factor)) % max;

}
       function C_check(address sender) public view returns(bool){
        if (C_joining[sender]==true)
            return true;
        else
            return false;
        }
    function C_PickYourNumber(uint _choosenumber ,uint _amount) public {
        require(_choosenumber>0&&_choosenumber<=100);
        require(balanceOf[msg.sender]>_amount);
        require(_amount>0);
        require(joining[msg.sender]);
        uint temp =balanceOf[address(this)];
        _transfer(msg.sender,address(this),_amount);
        uint temp2= balanceOf[address(this)];
        require(temp2>=temp+_amount);
        bool check=((Checkpick(_choosenumber,msg.sender)));
        bool check_committee=C_check(msg.sender);
        if(check_committee==true){
            c_number[_choosenumber]+=_amount;
        }
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
  //committeelist end
    
        //取得獲獎數字,將玩家所有下注之數字加總(包含Comittee)+上block的info
        //相加取hash在%101
     function C_getWinnumber()public view returns(uint){ 
        uint total;
        uint winnumber;
        uint c_total;
        for(uint i=0;i<101;i++){
          total+= number[i]*i;
          c_total+=c_number[i]*i;
        }
        uint n;
        uint d;
        (n,d)=C_getBlockinfo();
        winnumber=uint(keccak256(total+c_total+n+d))%101;
        return winnumber;
    }
        //取得得獎者
        function C_getWinner() public view returns(address[]){
        address[] memory winlist;
        uint winnernum=C_getWinnumber();
       winlist=NumToOwner[winnernum];
       return winlist;
    }
    //獲得blockinfo time,number,difficulty
    function C_getBlockinfo()public view returns(uint,uint){
        uint number;
        uint diff;
       number=block.number;
       diff=uint(block.difficulty);
       return (number,diff);
    }
    //派獎
    function C_givewinner()onlyOwner public  {
       require(givewinnerReady());
       uint winnerprize=getWinprize();
       address[] memory winnerlist =C_getWinner();
       uint winnercount=winnerlist.length;
       uint winnernumber=C_getWinnumber();
       uint num_count=number[winnernumber];
       uint averageprize=winnerprize/num_count;
       require(winnerprize>=totalnum);
       require(winnercount!=0);
       for(uint i=0;i<winnercount;i++){
         uint winner_numcount= OwnerNumCount[winnerlist[i]][winnernumber];
           _transfer(address(this),winnerlist[i],averageprize*winner_numcount-1);
       }
       _triggergivewinner_cooldowntime();
           reset();
    }
}
