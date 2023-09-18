// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

contract chai{
    struct fields{
        string name ;
        string messege;
        uint ammount;
        uint timestamp;
        address receiver;
    }
    
     
     mapping (address => string) public  yourName;
     mapping (string => address) public save;
     mapping(address => fields[]) private data;
     mapping (address => fields[]) private sended;
    
    function login(string memory _name) external {
         require(keccak256(abi.encodePacked(yourName[msg.sender])) == keccak256(abi.encodePacked("")),"you have already signed up");
         require(save[_name] == address(0),"userName already taken");
         yourName[msg.sender] = _name;
         save[yourName[msg.sender]] = msg.sender;
    }

    function send(string memory _name,string memory _mes) external payable {
        require(keccak256(abi.encodePacked(yourName[msg.sender])) != keccak256(abi.encodePacked("")),"first login");
        require(save[_name] != address(0),"receiver not found");

        (payable(save[_name])).transfer(msg.value);

        fields memory f1 = fields(yourName[msg.sender], _mes, msg.value, block.timestamp, msg.sender);

        data[save[_name]].push(f1);
        f1.name = _name;
        f1.receiver = save[_name];
        sended[msg.sender].push(f1);
        
    }
      
    
    function callData() external view returns(fields[] memory re, fields[] memory se){
        return (data[msg.sender],sended[msg.sender]);
    }
}