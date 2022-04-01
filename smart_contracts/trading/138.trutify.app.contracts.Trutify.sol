contract Trutify {
  address public creator;
  mapping (bytes32 => address) public products;
  mapping (address => string) public users;


  event Insert(address _by, string _id);
  event Transfer(address _from, address _to, string _id);

  function Trutify() { // Constructor
    creator = msg.sender;
  }
  function insertProduct(string id) public returns (bool success) {
     if (msg.sender != creator) { return; }
     // already inserted
     if (products[sha3(id)] != address(0x0)) { return; }
     products[sha3(id)] = msg.sender;
     Insert(msg.sender, id);
     return true;
  }
  function registerUser(string name) public returns (bool success) {
     users[msg.sender] = name;
     return true;
  }
  function productOwner(string id) public returns (string) {
      address userAddress = products[sha3(id)];
      return users[userAddress];
  }
  function transferProduct(string id, address recipient) public returns (bool success) {
     // product does not exist
     if (products[sha3(id)] == address(0x0)) { throw; }
     // user is not owner
     if (products[sha3(id)] != msg.sender) { return; }
     products[sha3(id)] = recipient;
     Transfer(msg.sender, recipient, id);
     return true;
  }
}
