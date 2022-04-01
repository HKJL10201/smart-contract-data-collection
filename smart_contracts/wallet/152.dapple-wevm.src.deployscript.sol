contract SH {
  function to_uint(string input) returns (uint){
    return 11;
  }
}

// The OnBlockchain Contract lives on the "real" Blockchain
contract OnBlockchain {
  event owner(address owner);
  function OnBlockchain(bytes construcorrr) {
    owner(msg.sender);
    // hahaha
  }
  function giveMeTHIRTYTWO() constant returns (uint) {
    return 32;
  }
  function giveMeSEVENTEEN(uint integer) returns (uint) {
    return 17;
  }
  function giveMeFOUR() returns (uint) {
    return 4;
  }
}

contract Script {
  // bunch of events which direct the interaction
  event exportNumber(string name, uint number);
  event exportObject(string name, address addr);

  event setCalls(bool flag);
  event setOrigin(address origin);

  event shUint(bytes input, uint result);

  modifier static {
    setCalls(true);
    _
    setCalls(false);
  }
}

// Interaction script
contract B is Script {
  function B() {
    // deploys a new contract
    OnBlockchain a = new OnBlockchain("123");
    // export the contract address and its classA
    // TODO - can I ommit the Class name and infer it based on a codemapping
    exportObject("a", a);
    // retreive a value and export it
    // TODO - find a way to get return values from transaction calls
    //        a possible way could be sending a transaction
    //        if it was include, calling it again on old state root
    //        saving the return value
    // ????   but what if i want to call a function without triggering a tx?

    exportNumber("thirtytwo", a.giveMeTHIRTYTWO());
    exportNumber("seventeen_nonstatic", a.giveMeSEVENTEEN(2));

    setCalls(true);
    exportNumber("seventeen", a.giveMeSEVENTEEN(3));
    setCalls(false);

    // another instance from another origin
    setOrigin(0x6deec6383397044107be3a74a6d50d41901f0356);
    OnBlockchain b = new OnBlockchain("123");

    staticStuff(b);

    // In order for this to work, curl and jq need to be installed
    uint TWELVE = SH(0x0).to_uint("curl -s https://api.coindesk.com/v1/bpi/currentprice.json|jq '.bpi.USD.rate|tonumber|floor'");
    exportNumber("twelve", TWELVE);
  }

  function staticStuff(OnBlockchain a) static {
    exportNumber("four", a.giveMeFOUR());
    execOn(a, "event", "asd");
  }

  address asdd;
  function callback() event("asd") {
    asdd.getFuckDone();
  }
}
