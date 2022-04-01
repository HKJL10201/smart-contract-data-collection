pragma solidity ^0.6.0;


contract ChickBoom {

  struct Win {
    address addr;
    uint256 cush;
  }

  event WinEvent(
    address indexed winner,
    uint32 round,
    uint256 cush
  );

  modifier only_owner() {
    require(msg.sender == owner, "Need owner permission");
    _;
  }

  modifier state_must(State state) {
    require(lottery_state == state, "Invalid state");
    _;
  }

  enum State { WaitingForStart, WaitingForSellingEnd, WaitingForWin }

  address payable private owner;
  uint256 private owner_round_reward;
  uint256 private owner_total_reward = 0;
  uint256 private ticket_price;
  uint32 private tickets_count;
  uint32 private sold_tickets = 0;
  uint32 private round = 0;
  State private lottery_state = State.WaitingForStart;

  address[] private players_addresses;
  mapping (address => bool) private players;
  mapping (uint32 => Win) private winners;


  constructor(uint32 new_tickets_count, uint256 new_ticket_price, uint256 new_owner_reward) public {
    owner = msg.sender;
    tickets_count = new_tickets_count;
    ticket_price = new_ticket_price;
    owner_round_reward = new_owner_reward;
  }

  function start_selling() external only_owner state_must(State.WaitingForStart) {
    lottery_state = State.WaitingForSellingEnd;
    sold_tickets = 0;
    round = round+1;

    for (uint32 i=0; i<players_addresses.length; i++) {
      delete players[players_addresses[i]];
    }

    delete players_addresses;
  }

  function buy_ticket() external state_must(State.WaitingForSellingEnd) payable {
    require(msg.value >= ticket_price, "Not enought amount");
    players[msg.sender] = true;
    sold_tickets = sold_tickets+1;
    players_addresses.push(msg.sender);
    if (tickets_count == sold_tickets) {
      lottery_state = State.WaitingForWin;
    }
  }

  function refound() external state_must(State.WaitingForSellingEnd) payable {
    if (players[msg.sender]) {
      address payable player_address = address(uint160(msg.sender));
      player_address.transfer(ticket_price);
      delete players[msg.sender];
      sold_tickets = sold_tickets-1;
      return;
    } else {
      revert("You have not ticket");
    }
  }

  function lets_win() external only_owner state_must(State.WaitingForWin) {
    uint256 cush = ticket_price * tickets_count;
    uint32 winner_id = uint32((block.timestamp-1)%(tickets_count));
    address winner_address = players_addresses[winner_id];
    winners[round] = Win({addr: winner_address, cush: cush});
    lottery_state = State.WaitingForStart;
    owner_total_reward = owner_total_reward+owner_round_reward;
    emit WinEvent(winner_address, round, cush-owner_round_reward);
  }

  function get_cush(uint32 winner_round) external payable {
    Win memory winner = winners[winner_round];
    require(winner.addr == msg.sender, "You have not cush");
    address payable winner_address = address(uint160(msg.sender));
    winner_address.transfer(winner.cush);
    delete winners[winner_round];
  }

  function reward_for_owner(uint256 value) external only_owner {
    require(owner_total_reward >= value, "Not enought coins");
    owner.transfer(value);
  }

  function change_ticket_price(uint256 new_price) external only_owner state_must(State.WaitingForStart) {
    ticket_price = new_price;
  }

  function change_tickets_count(uint32 new_count) external only_owner state_must(State.WaitingForStart) {
    tickets_count = new_count;
  }

  function get_lottery_state() public view returns (State) {
    return lottery_state;
  }

  function get_ticket_price() public view returns (uint256) {
    return ticket_price;
  }

  function get_sold_tickets() public view returns (uint32) {
    return sold_tickets;
  }

  function get_tickets_count() public view returns (uint32) {
    return tickets_count;
  }

  function get_owner() public view returns (address) {
    return owner;
  }

  function get_round() public view returns (uint256) {
    return round;
  }

  function get_owner_round_reward() public view returns (uint256) {
    return owner_round_reward;
  }

  fallback() external payable {}
}
