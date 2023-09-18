pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;
import "./DataBuyerInterface.sol";

struct DataOwner {
  string encrypted_data;
  // unencrypted
  string params;
  uint price;
  uint epsilon;
  address payable data_owner_address;
}

struct IndexValue { uint keyIndex; DataOwner value; }
struct KeyFlag { address key; bool deleted; }

//https://solidity.readthedocs.io/en/v0.6.0/types.html#iterable-mappings
struct itmap {
    mapping(address => IndexValue) data;
    KeyFlag[] keys;
    uint size;
}

library IterableMapping {
    function insert(itmap storage self, address key, DataOwner memory value) internal returns (bool replaced) {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(itmap storage self, address key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contains(itmap storage self, address key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterate_start(itmap storage self) internal view returns (uint keyIndex) {
        return iterate_next(self, uint(-1));
    }

    function iterate_valid(itmap storage self, uint keyIndex) internal view returns (bool) {
        return keyIndex < self.keys.length;
    }

    function iterate_next(itmap storage self, uint keyIndex) internal view returns (uint r_keyIndex) {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function iterate_get(itmap storage self, uint keyIndex) internal view returns (address key, DataOwner storage value) {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}
contract Calculator {
  uint constant upper_bound = 1e7;
  address public calculator;

  struct DataBuyer {
    DataBuyerInterface buyer_contract;
    address payable[] selected_owner;
    uint[] selected_prices;
    uint budget;
    string requirements;
  }

  itmap public data;
  using IterableMapping for itmap;
  mapping(address => DataBuyer) public transactions;

  
  // step 1
  // calculator provide construct it's contract.
  constructor() public {
    calculator = msg.sender;
  }

  // step 2
  // send encrypted data and epsilon.
  function set_data(uint price, string memory encrypted_data, string memory params, uint epsilon, address payable _address) public {
    // TODO: assert

    require(price > 0, "price should larger than 0.");

    DataOwner memory data_owner = DataOwner(
      encrypted_data,
      params,
      price,
      epsilon,
      _address
    );
    data.insert(_address, data_owner);
  }

  function get_data() public view returns (uint price, string  memory encrypted_data, uint epsilon) {
    DataOwner storage data_owner = data.data[msg.sender].value;
    price = data_owner.price;
    encrypted_data = data_owner.encrypted_data;
    epsilon = data_owner.epsilon;
  }

  // step 7
  // event to notify off-chain calculator.
  event data_selected(address data_buyer,address data_buyer_contract, string requirements,address payable[] owners_address, string[] owners_data, uint[] owners_price, uint[] owners_epsilon,  string[] params);

  // step 4
  // data buyer provide it's budget by `payable`.
  // also, one should also privide where it selection contract is.
  function bid(DataBuyerInterface data_buyer_contract) public payable {

    require(data.size > 1, 
           "data amount less than 2");

    // store contract address
    transactions[msg.sender].buyer_contract = data_buyer_contract;
    
    // step 5, 6
    // calculator call data_buyer's contract 
    // to provide epsilon's and budget number,
    // and waiting for result.
    uint[] memory price_vec = new uint[](data.size);
    uint[] memory epsilon_vec = new uint[](data.size);
    string[] memory data_vec = new string[](data.size);
    string[] memory params = new string[](data.size);
    address payable[] memory address_vec = new address payable[](data.size);
    uint _i = 0;
    for(uint i = data.iterate_start();
       data.iterate_valid(i);
       (i = data.iterate_next(i), _i++)) {
         (address _address,DataOwner storage data_owner) = data.iterate_get(i);
         price_vec[_i] = data_owner.price;
         epsilon_vec[_i] = data_owner.epsilon;
         data_vec[_i] = data_owner.encrypted_data;
         params[_i] = data_owner.params;
         address_vec[_i] = data_owner.data_owner_address;
    }

    uint[] memory results = DataBuyerInterface(data_buyer_contract).send_budget_and_epsilons(msg.value, epsilon_vec, price_vec);

    // select data we want.
    address payable[] memory result_addresses = new address payable[](results.length);
    string[] memory result_data = new string[](results.length);
    string[] memory result_params = new string[](results.length);
    uint[] memory result_epsilons = new uint[](results.length);
    uint[] memory result_prices = new uint[](results.length);
    for(uint i = 0; i < results.length; i++ ){
      result_addresses[i] = address_vec[results[i]];
      result_data[i] = data_vec[results[i]];
      result_params[i] = params[results[i]];
      result_epsilons[i] = epsilon_vec[results[i]];
      result_prices[i] = price_vec[results[i]];
    }

    // suspend this transactions.
    transactions[msg.sender].selected_owner = result_addresses;
    transactions[msg.sender].selected_prices = result_prices;
    transactions[msg.sender].budget = msg.value;

    // get requirements from data buyer.
    // such as filter, query, query type
    string memory requirements = DataBuyerInterface(data_buyer_contract).get_requirements();

    transactions[msg.sender].requirements = requirements;
    

    // step 7
    // trigger the event, tell the calculator
    // that he may continue the computation.
    
    emit data_selected(msg.sender, address(data_buyer_contract), requirements,result_addresses, result_data,result_prices,result_epsilons, result_params);
    
  }

  // step 9, 10
  // send money to buyer & owner.
  function bidEnd(address payable data_buyer,string memory encrypted_result) public {

    // !QUESTION!
    require(transactions[data_buyer].buyer_contract != DataBuyerInterface(0), 
           "there is no transactions for current data_buyer.");

    uint sum = 0;
    
    // transfer to data owner
    for(uint i = 0; i < transactions[data_buyer].selected_prices.length; i++){
      //transactions[data_buyer].selected_owner[i].call{value:transactions[data_buyer].selected_prices[i] }("");
      transactions[data_buyer].selected_owner[i].transfer(transactions[data_buyer].selected_prices[i]);
      sum += transactions[data_buyer].selected_prices[i];
    }

    // send encrypted result
    transactions[data_buyer].buyer_contract.send_result(encrypted_result);

    // transfer to date buyer (rest of budget)
    data_buyer.transfer(transactions[data_buyer].budget-sum);

    // mark end (see `require`)
    transactions[data_buyer].buyer_contract = DataBuyerInterface(0);
  }

  function getDataBuyerTransactionInfo(address data_buyer) public view returns(address payable[] memory selected_owner, uint[] memory selected_prices, uint budget, string memory requirements) {
    selected_owner = transactions[data_buyer].selected_owner;
    selected_prices = transactions[data_buyer].selected_prices;
    requirements = transactions[data_buyer].requirements;
    return ( selected_owner, selected_prices, transactions[data_buyer].budget, requirements );
  }

   //say hello world
  function say() public pure returns (string memory) {
    return "Hello World";
  }
}
