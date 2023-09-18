// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.4;

import "./Queue.sol";

struct DataValue {
    Queue q;
    uint256 value;
}

struct Node {
    DataValue dv;
    uint256 prev;
    uint256 next;
}

// By default, in ascending order, and circular
contract DoublySortedLinkedList {

    // nodes[0].next is head, and nodes[0].prev is tail
    Node[] public nodes;

    constructor () {
        nodes.push(Node(DataValue(new Queue(), 0), 0, 0));
    }
    
    function max() public view returns (uint256) {
        return nodes[nodes[0].prev].dv.value;
    }
    
    function min() public view returns (uint256) {
        return nodes[nodes[0].next].dv.value;
    }
    
    function size() public view returns (uint256) {
        return nodes.length - 1;
    }
    
    function getQ(uint256 id) public view returns (Queue) {
        require (id != 0 || isValidNode(id));
        return nodes[id].dv.q;
    }
    
    function updateQ(uint256 id, Queue q) public {
        require (id != 0 || isValidNode(id));
        if (q.empty()) {
            remove(id);
        } else {
            nodes[id].dv.q = q;
        }
    }
    
    function getPrev(uint256 id) public view returns (uint256) {
        require (id != 0 || isValidNode(id));
        return nodes[id].prev;
    }
    
    function getNext(uint256 id) public view returns (uint256) {
        require (id != 0 || isValidNode(id));
        return nodes[id].next;
    }
    
    function find(uint256 value) public view returns (uint256 id) {
        uint256 head = nodes[0].next;
        uint256 tail = nodes[0].prev;
        if (value < nodes[head].dv.value || value > nodes[tail].dv.value) {
            id = 0;
        } else if (value == nodes[head].dv.value) {
            id = head;
        } else if (value == nodes[tail].dv.value) {
            id = tail;
        } else {
            uint256 target = head;

            while (target != tail) {
                if (value == nodes[target].dv.value) {
                    id = target;
                }
                target = nodes[target].next;
            }
        }
    }
    
    // find the less equal node
    function findle(uint256 value) public view returns (uint256) {
        uint256 head = nodes[0].next;
        uint256 tail = nodes[0].prev;

        uint256 target = head;

        while (target != tail) {

            if (value > nodes[target].dv.value) {
                return nodes[target].prev;
            }
            target = nodes[target].next;
        }
        return tail;
    }
    
    // find the greater equal node
    function findge(uint256 value) public view returns (uint256) {
        uint256 head = nodes[0].next;
        uint256 tail = nodes[0].prev;

        uint256 target = tail;

        while (target != head) {

            if (value < nodes[target].dv.value) {
                return nodes[target].next;
            }
            target = nodes[target].prev;
        }
        return head;
    }
    
    
    function insertToQueue(uint256 id, uint256 requestID) public {
        require (id != 0 || isValidNode(id));
        
        Node storage node = nodes[id];
        
        node.dv.q.enqueue(requestID);
    }

    function insertAfter(uint256 id, DataValue memory dv) internal returns (uint256 newID) {
        require (id == 0 || isValidNode(id));
        
        Node storage node = nodes[id];

        nodes.push(Node({
            dv:     dv,
            prev:   id,
            next:   node.next
        }));

        newID = nodes.length - 1;

        nodes[node.next].prev = newID;
        node.next = newID;
    }

    function remove(uint256 id) public {
        require (id != 0 || isValidNode(id));

        // retrieve the node
        Node storage node = nodes[id];

        nodes[node.next].prev = node.prev;
        nodes[node.prev].next = node.next;

        delete nodes[id];
    }

    function insert(DataValue memory dv) public returns (uint256 newID) {
        uint256 head = nodes[0].next;
        uint256 tail = nodes[0].prev;

        uint256 target = head;

        uint256 value = dv.value;

        while (target != tail) {

            if (value < nodes[target].dv.value) {
                return insertAfter(nodes[target].prev, dv);
            }
            target = nodes[target].next;
        }
        insertAfter(tail, dv);
    }

    function isValidNode(uint256 id) internal view returns (bool) {
        return id != 0 && (id == nodes[0].next || nodes[id].prev != 0);
    }
}