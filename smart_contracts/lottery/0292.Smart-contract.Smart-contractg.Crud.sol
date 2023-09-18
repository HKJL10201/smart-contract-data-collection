pragma solidity 0.6.0;

contract crud{
    
       struct User{
           uint id;
           string name;
       }
       
        User[] public users;
        uint public next_id;
        
        function create(string memory name) public {
            users.push(User(next_id, name));
            next_id++;
        }
        
        function read(uint id) view public returns(uint , string memory){
            for(uint i = 0; i<users.length;i++){
                if(users[i].id == id){
                    return (users[i].id, users[i].name);
                }
            }
        } 
        
        function update(uint id, string memory name) public{
            for(uint i=0; i<users.length; i++){
                if(users[i].id == id){
                    users[i].name = name;
                }
            }
        }
        
        function _delete(uint id) public{
            delete users[id];
        }
    
    
}