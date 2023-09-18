pragma solidity ^0.4.17;

contract DappRegistry {

  uint BASE_FEE = 1000000;
  enum ApprovalState { PENDING, APPROVED, REJECTED, BANNED };
  enum UserVote { GOOD, BAD }

  struct Dapp {
    string name;
    string description;
    string website;
    string twitter;
    string github;
    uint good;
    uint bad;
    address dappOwner;
    address submitter;
    ApprovalState state;
  }

  Dapp[] public dapps;
  mapping(uint => string[]) public devUpdates;
  mapping(uint => uint[]) public daySponsor;
  mapping(address => UserVote) public userVote;

  uint creationTime;
  address owner;

  function DappRegistry() public {
    owner = msg.sender;
    creationTime = now;
  }

  function submit(string name string desc, string website, string twitter, string github,  address developer) public payable {
    require(msg.value > BASE_FEE);
    dapps.push(Dapp({
      name: name,
      description: desc,
      website: website,
      twitter: twitter,
      github: github,
      votes:0,
      developer:developer,
      submitter: msg.sender,
      state: ApprovalState.PENDING
    }));
  }

  modifier isDappAuthority(uint dappIndex){
    require(dapps[dappIndex].submitter == msg.sender || dapps[dappIndex].dappOwner == msg.sender);
  }
  function update(uint dappIndex, string name, string desc, string website, string twitter, string github, address dappOwner) isDappAuthority public {
    dapps[dappIndex].name = name;
    dapps[dappIndex].description = desc;
    dapps[dappIndex].website = website;
    dapps[dappIndex].twitter = twitter;
    dapps[dappIndex].github = github;
    dapps[dappIndex].dappOwner = dappOwner;
  }

  function devUpdate(uint dappIndex, string updateText) isDappAuthority public {
    devUpdates[dappIndex].push(updateText);
  }

  function getSponsorCost() public view {
    uint daysSince = (now - creationTime) * 1 days;
    uint sponsorsCount = daySponsor[daysSince].length;
    return BASE_FEE gwei * sponsorsCount;
  }

  function sponsor(uint dappIndex, uint offset) public payable {
    uint daysSince = (now - creationTime) * 1 days + offset days;
    uint sponsorsCount = daySponsor[daysSince].length;
    require(sponsorsCount < 8);
    require(msg.value > getSponsorCost());
    daySponsor[daysSince].push(dappIndex);
  }

  function upvote(uint dappIndex, bool good) public {
    if(userVote[msg.sender] == UserVote.GOOD) {
      dapps[dappIndex].good -= 1;
    } else if (userVote[msg.sender] == UserVote.BAD) {
      dapps[dappIndex].bad -= 1;
    }
    if(good) {
      dapps[dappIndex].good += 1;
      userVote[msg.sender] = UserVote.GOOD;
    } else {
      dapps[dappIndex].bad += 1;
      userVote[msg.sender] = UserVote.BAD;
    }
  }

  event Comment(uint indexed dapp, address indexed commenter, string comment);
  function comment(uint dappIndex, string comment) public {
    emit Comment(dappIndex, msg.sender, comment);
  }

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  function adminWithdraw(address withdrawWallet) public isOwner {
    withdrawWallet.transfer(address(this).balance);
  }

  function updateBaseFee(uint newFee) public isOwner {
    BASE_FEE = newFee;
  }

  function adminUpdate(uint dappIndex, string name, string desc, string website, string twitter, string github) isOwner public {
    dapps[dappIndex].name = name;
    dapps[dappIndex].description = desc;
    dapps[dappIndex].website = website;
    dapps[dappIndex].twitter = twitter;
    dapps[dappIndex].github = github;
    dapps[dappIndex].dappOwner = dappOwner;
    dapps[dappIndex].submitter = msg.sender;
  }

  function adminReject(uint dappIndex) isOwner public {
    dapps[dappIndex].state = ApprovalState.REJECTED;
  }
  function adminApprove(uint dappIndex) isOwner public {
    dapps[dappIndex].state = ApprovalState.APPROVED;
  }
  function adminBan(uint dappIndex) isOwner public {
    dapps[dappIndex].state = ApprovalState.BANNED;
  }
  function adminDelete(uint dappIndex) isOwner public {
    delete dapps[dappIndex];
    delete devUpdates[dappIndex];
  }
}
