pragma solidity ^0.4.11;

// a dynamic addresses list supporting dynamic insertion and removal of addresses and iteration
// Note: may contain duplicated items - it is up to the user to check the existence of an address using contains() before appending a new address
// based on https://github.com/ethereum/dapp-bin/blob/master/library/linkedList.sol
// Designed to overcome the pain and gas involved in converting between bytes32 and address primitive data types

library AddressesList {

  struct data {
    uint80 first;
    uint80 last;
    uint80 count;
    Item[] items;
  }

  uint80 constant None = uint80(0);

  struct Item {
    uint80 prev;
    uint80 next;
    address data;
  }

  // Appends `_data` to the end of the list `self`.
  function append(data storage self, address _data) returns (uint80) {

    var index = uint80(self.items.push(Item({prev: self.last, next: None, data: _data})));

    if (self.last == None)  {
      if (self.first != None || self.count != 0) throw;
      self.first = self.last = index;
      self.count = 1;
    } else {
      self.items[self.last - 1].next = index;
      self.last = index;
      self.count++;
    }

    return index;
  }

  /// Removes the element identified by the iterator
  /// `_index` from the list `self`.
  function remove(data storage self, uint80 _index) {

    Item item = self.items[_index - 1];

    if (item.prev == None) self.first = item.next;
    if (item.next == None) self.last = item.prev;
    if (item.prev != None) self.items[item.prev - 1].next = item.next;
    if (item.next != None) self.items[item.next - 1].prev = item.prev;
    delete self.items[_index - 1];
    self.count--;
  }

  /// @return an iterator pointing to the first element whose data
  /// is `_value` or an invalid iterator otherwise.
  function find(data storage self, address _value) constant returns (uint80) {

    var it = iterate_start(self);
    while (iterate_valid(self, it)) {
      if (iterate_get(self, it) == _value) return it;
      it = iterate_next(self, it);
    }
    return it;
  }

  function contains(data storage self, address item) constant returns (bool) {
    var it = find(self, item);
    return iterate_valid(self, it);
  }

  function itemsCount(data storage self) constant returns (uint80) {
    return self.count;
  }

  // Iterator interface
  function iterate_start(data storage self) constant returns (uint80) {
    return self.first;
  }

  function iterate_valid(data storage self, uint80 _index) constant returns (bool) {
    return _index - 1 < self.items.length;
  }

  function iterate_prev(data storage self, uint80 _index) constant returns (uint80) {
    return self.items[_index - 1].prev;
  }

  function iterate_next(data storage self, uint80 _index) constant returns (uint80) {
    return self.items[_index - 1].next;
  }

  function iterate_get(data storage self, uint80 _index) constant returns (address) {
    return self.items[_index - 1].data;
  }
}
