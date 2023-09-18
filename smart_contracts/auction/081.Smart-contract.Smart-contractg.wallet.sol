pragma solidity 0.6.0;

contract wallet{
    
    mapping(address => uint) private TotalAmount;
    address[] public UserList;
    
    constructor(address[] memory UserName) public{
        UserList = UserName;
        for(uint i = 0; i<UserList.length;i++){
            address temp = UserList[i];
            TotalAmount[temp] += 100;
        }
    }
    
    function GetBalance(address user)view public returns(uint){
          if(ValidUser(user) == false){
              revert();
          } 
          
          else{
              return TotalAmount[user];
          }
    }
    
    function SendMoney(address to, address from, uint amount) payable public{
        if(ValidUser(from) == false && ValidUser(to) == false){
            revert();
        }
        else{
            TotalAmount[from] -= amount;
            TotalAmount[to] += amount;
        }
    }
    
    function ValidUser(address user) private view returns(bool){
        for(uint i=0; i<UserList.length;i++){
            if(UserList[i]== user){
                return true;
            }
            else{
                return false;
            }
        }
    }
}