// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library RedBlackTree {
    struct Node {
        uint256 parent;
        uint256 left;
        uint256 right;
        bool red;
    }

    struct Tree {
        uint256 root;
        uint256 total;
        mapping(uint256 => Node) nodes;
    }

    uint256 private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint256 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }

    function last(Tree storage self) internal view returns (uint256 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }

    function next(Tree storage self, uint256 target)
        internal
        view
        returns (uint256 cursor)
    {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function prev(Tree storage self, uint256 target)
        internal
        view
        returns (uint256 cursor)
    {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function exists(Tree storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return
            (key != EMPTY) &&
            ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }

    function isEmptyTree(Tree storage self) internal view returns (bool) {
        return self.root == EMPTY;
    }

    function getNode(Tree storage self, uint256 key)
        internal
        view
        returns (
            uint256 _returnKey,
            uint256 _parent,
            uint256 _left,
            uint256 _right,
            bool _red
        )
    {
        require(exists(self, key));
        return (
            key,
            self.nodes[key].parent,
            self.nodes[key].left,
            self.nodes[key].right,
            self.nodes[key].red
        );
    }

    function getAt(
        Tree storage self,
        uint256 index,
        bool descending
    ) internal view returns (uint256) {
        if (isEmptyTree(self)) {
            return EMPTY;
        } else {
            uint256 start = 0;
            uint256 current;
            if (descending) {
                current = last(self);
                while (start < index) {
                    uint256 prevKey = prev(self, current);
                    if (exists(self, prevKey)) {
                        current = prevKey;
                        start++;
                    } else {
                        current = EMPTY;
                        break;
                    }
                }
            } else {
                current = first(self);
                while (start < index) {
                    uint256 nextKey = next(self, current);
                    if (exists(self, nextKey)) {
                        current = nextKey;
                        start++;
                    } else {
                        current = EMPTY;
                        break;
                    }
                }
            }
            return current;
        }
    }

    function getBatch(
        Tree storage self,
        uint256 from,
        uint8 size,
        bool descending
    ) internal view returns (uint256[] memory array) {
        require(size > 0, "size must not be 0");
        array = new uint256[](size);
        uint8 length;
        uint256 current = getAt(self, from, descending);
        if (exists(self, current)) {
            if (descending) {
                while (length < size) {
                    array[length] = current;
                    length++;
                    uint256 prevKey = prev(self, current);
                    if (exists(self, prevKey)) {
                        current = prevKey;
                    } else {
                        break;
                    }
                }
            } else {
                while (length < size) {
                    array[length] = current;
                    length++;
                    uint256 nextKey = next(self, current);
                    if (exists(self, nextKey)) {
                        current = nextKey;
                    } else {
                        break;
                    }
                }
            }
        }
    }

    function getIndex(
        Tree storage self,
        uint256 key,
        bool descending
    ) internal view returns (bool found, uint256 index) {
        if (!isEmptyTree(self) && exists(self, key)) {
            if (descending) {
                uint256 current = last(self);
                while (true) {
                    if (current == key) {
                        return (true, index);
                    } else {
                        current = prev(self, current);
                        index++;
                    }
                }
            } else {
                uint256 current = first(self);
                while (true) {
                    if (current == key) {
                        return (true, index);
                    } else {
                        current = next(self, current);
                        index++;
                    }
                }
            }
        }
    }

    function insert(Tree storage self, uint256 key) internal returns (bool) {
        if (exists(self, key)) {
            return false;
        } else {
            uint256 cursor = EMPTY;
            uint256 probe = self.root;
            while (probe != EMPTY) {
                cursor = probe;
                if (key < probe) {
                    probe = self.nodes[probe].left;
                } else {
                    probe = self.nodes[probe].right;
                }
            }
            self.nodes[key] = Node({
                parent: cursor,
                left: EMPTY,
                right: EMPTY,
                red: true
            });
            if (cursor == EMPTY) {
                self.root = key;
            } else if (key < cursor) {
                self.nodes[cursor].left = key;
            } else {
                self.nodes[cursor].right = key;
            }
            insertFixup(self, key);
            self.total++;
            return true;
        }
    }

    function remove(Tree storage self, uint256 key) internal returns (bool) {
        if (exists(self, key)) {
            uint256 probe;
            uint256 cursor;
            if (
                self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY
            ) {
                cursor = key;
            } else {
                // M
                cursor = self.nodes[key].right;
                while (self.nodes[cursor].left != EMPTY) {
                    cursor = self.nodes[cursor].left;
                }
            }
            if (self.nodes[cursor].left != EMPTY) {
                // C
                probe = self.nodes[cursor].left;
            } else {
                probe = self.nodes[cursor].right;
            }
            //parent of M
            uint256 yParent = self.nodes[cursor].parent;
            self.nodes[probe].parent = yParent;
            if (yParent != EMPTY) {
                if (cursor == self.nodes[yParent].left) {
                    self.nodes[yParent].left = probe;
                } else {
                    self.nodes[yParent].right = probe;
                }
            } else {
                // case 1
                self.root = probe;
            }
            bool doFixup = !self.nodes[cursor].red;
            if (cursor != key) {
                replaceParent(self, cursor, key);
                self.nodes[cursor].left = self.nodes[key].left;
                self.nodes[self.nodes[cursor].left].parent = cursor;
                self.nodes[cursor].right = self.nodes[key].right;
                self.nodes[self.nodes[cursor].right].parent = cursor;
                self.nodes[cursor].red = self.nodes[key].red;
                (cursor, key) = (key, cursor);
            }
            if (doFixup) {
                removeFixup(self, probe);
            }
            delete self.nodes[cursor];
            self.total--;
            return true;
        } else {
            return false;
        }
    }

    function treeMinimum(Tree storage self, uint256 key)
        private
        view
        returns (uint256)
    {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    function treeMaximum(Tree storage self, uint256 key)
        private
        view
        returns (uint256)
    {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint256 key) private {
        uint256 cursor = self.nodes[key].right;
        uint256 keyParent = self.nodes[key].parent;
        uint256 cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }

    function rotateRight(Tree storage self, uint256 key) private {
        uint256 cursor = self.nodes[key].left;
        uint256 keyParent = self.nodes[key].parent;
        uint256 cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint256 key) private {
        uint256 cursor;
        //double red
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint256 keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                //case 3
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    //case 4
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key);
                    }
                    //case 4 step 2
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        //case 1
        if (self.nodes[self.root].red) {
            self.nodes[self.root].red = false;
        }
    }

    function replaceParent(
        Tree storage self,
        uint256 a,
        uint256 b
    ) private {
        uint256 bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    function removeFixup(Tree storage self, uint256 key) private {
        uint256 cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint256 keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                //case 2
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                //case 3
                if (
                    !self.nodes[self.nodes[cursor].left].red &&
                    !self.nodes[self.nodes[cursor].right].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    // case 5
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    // case 6
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (
                    !self.nodes[self.nodes[cursor].right].red &&
                    !self.nodes[self.nodes[cursor].left].red
                ) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        // case 4
        if (self.nodes[key].red) {
            self.nodes[key].red = false;
        }
    }
}
