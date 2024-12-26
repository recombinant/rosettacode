// https://rosettacode.org/wiki/Ukkonen%E2%80%99s_suffix_tree_construction
// Translation of https://www.geeksforgeeks.org/suffix-tree-application-3-longest-repeated-substring/
// also https://www.geeksforgeeks.org/ukkonens-suffix-tree-construction-part-6/
// complete with mostly original comments
const std = @import("std");

const Ukkonen = struct {
    const MAX_CHAR = 256;
    const SuffixTreeNode = struct {
        children: [MAX_CHAR]?*SuffixTreeNode = @import("std").mem.zeroes([MAX_CHAR]?*SuffixTreeNode),
        // pointer to other node via suffix link
        suffix_link: ?*SuffixTreeNode = null,

        // (start, end) interval specifies the edge, by which the
        // node is connected to its parent node. Each edge will
        // connect two nodes, one parent and one child, and
        // (start, end) interval of a given edge will be stored
        // in the child node. Lets say there are two nods A and B
        // connected by an edge with indices (5, 8) then this
        // indices (5, 8) will be stored in node B.
        start: usize,
        end: *usize,

        // for leaf nodes, it stores the index of suffix for
        // the path from root to leaf
        suffix_index: ?usize = null,
    };
    const Node = SuffixTreeNode;
    allocator: std.mem.Allocator,
    text: []const u8, // input string
    root: ?*Node = null, // pointer to the root node

    // last_new_node will point to newly created internal node,
    // waiting for it's suffix link to be set, which might get
    // a new suffix link (other than root) in next extension of
    // same phase. last_new_node will be set to NULL when last
    // newly created internal node (if there is any) got it's
    // suffix link reset to new internal node created in next
    // extension of same phase.
    last_new_node: ?*Node = null,

    // active_edge is represented as input string character
    // index (not the character itself)
    active_edge: usize,
    active_node: *Node,

    active_length: usize = 0,

    // remaining_suffix_count tells how many suffixes yet to
    // be added in tree
    remaining_suffix_count: usize = 0,
    leaf_end: usize,
    root_end: *usize,
    split_end: *usize,

    fn init(allocator: std.mem.Allocator, text: []const u8) Ukkonen {
        return Ukkonen{
            .allocator = allocator,
            .text = text,
            .active_edge = undefined,
            .active_node = undefined,
            .leaf_end = undefined,
            .root_end = undefined,
            .split_end = undefined,
        };
    }

    fn newNode(self: *Ukkonen, start: usize, end: *usize) *Node {
        const node: *Node = self.allocator.create(Node) catch unreachable;
        node.* = Node{
            // For root node, suffix_link will be set to null
            // For internal nodes, suffix_link will be set to root
            // by default in current extension and may change in
            // next extension
            .suffix_link = self.root,
            .start = start,
            .end = end,

            // suffix_index will be set to null by default and
            // actual suffix index will be set later for leaves
            // at the end of all phases
            .suffix_index = null,
        };
        return node;
    }
    fn edgeLength(self: *const Ukkonen, n: *Node) usize {
        if (n == self.root) return 0;
        return n.end.* - n.start + 1;
    }

    /// "active_node (activePoint) change for walk down" (APCFWD) using
    /// Skip/Count Trick (Trick 1). If active_length is greater
    /// than current edge length, set next internal node as
    /// active_node and adjust active_edge and active_length
    /// accordingly to represent same active_node
    fn walkDown(self: *Ukkonen, curr_node: *Node) bool {
        if (self.active_length >= self.edgeLength(curr_node)) {
            self.active_edge += self.edgeLength(curr_node);
            self.active_length -= self.edgeLength(curr_node);
            self.active_node = curr_node;
            return true;
        }
        return false;
    }
    fn extendSuffixTree(self: *Ukkonen, pos: usize) void {
        // extension Rule 1, this takes care of extending all
        // leaves created so far in tree
        self.leaf_end = pos;

        // increment remaining_suffix_count indicating that a
        // new suffix added to the list of suffixes yet to be
        // added in tree
        self.remaining_suffix_count += 1;

        // set last_new_node to NULL while starting a new phase,
        // indicating there is no internal node waiting for
        // it's suffix link reset in current phase
        self.last_new_node = null;

        // add all suffixes (yet to be added) one by one in tree
        while (self.remaining_suffix_count > 0) {
            if (self.active_length == 0) {
                self.active_edge = pos; // APCFALZ
            }
            // there is no outgoing edge starting with
            // active_edge from active_node
            if (self.active_node.children[self.text[self.active_edge]] == null) {
                // extension Rule 2 (A new leaf edge gets created)
                self.active_node.children[self.text[self.active_edge]] = self.newNode(pos, &self.leaf_end);

                // A new leaf edge is created in above line starting
                // from an existing node (the current active_node), and
                // if there is any internal node waiting for it's suffix
                // link get reset, point the suffix link from that last
                // internal node to current active_node. Then set last_new_node
                // to null indicating no more node waiting for suffix link
                // reset.
                if (self.last_new_node != null) {
                    self.last_new_node.?.suffix_link = self.active_node;
                    self.last_new_node = null;
                }
            } else
            // there is an outgoing edge starting with active_edge
            // from active_node
            {
                // get the next node at the end of edge starting
                // with active_edge
                const next: *Node = self.active_node.children[self.text[self.active_edge]].?;
                if (self.walkDown(next)) {
                    // start from next node (the new active_node)
                    continue;
                }
                // extension Rule 3 (current character being processed
                // is already on the edge)
                if (self.text[next.start + self.active_length] == self.text[pos]) {
                    // if a newly created node waiting for it's
                    // suffix link to be set, then set suffix link
                    // of that waiting node to current active node
                    if ((self.last_new_node != null) and (self.active_node != self.root)) {
                        self.last_new_node.?.suffix_link = self.active_node;
                        self.last_new_node = null;
                    }

                    // APCFER3
                    self.active_length += 1;
                    // STOP all further processing in this phase
                    // and move on to next phase
                    break;
                }

                // We will be here when active_node is in middle of
                // the edge being traversed and current character
                // being processed is not on the edge (we fall off
                // the tree). In this case, we add a new internal node
                // and a new leaf edge going out of that new node. This
                // is Extension Rule 2, where a new leaf edge and a new
                // internal node get created
                self.split_end = self.allocator.create(usize) catch unreachable;
                self.split_end.* = next.start + self.active_length - 1;

                // new internal node
                const split: *Node = self.newNode(next.start, self.split_end);
                self.active_node.children[self.text[self.active_edge]] = split;

                // new leaf coming out of new internal node
                split.children[self.text[pos]] = self.newNode(pos, &self.leaf_end);
                next.start += self.active_length;
                split.children[self.text[next.start]] = next;

                // We got a new internal node here. If there is any
                // internal node created in last extensions of same
                // phase which is still waiting for it's suffix link
                // reset, do it now.
                if (self.last_new_node != null) {
                    // suffix_link of last_new_node points to current newly
                    // created internal node
                    self.last_new_node.?.suffix_link = split;
                }

                // Make the current newly created internal node waiting
                // for it's suffix link reset (which is pointing to root
                // at present). If we come across any other internal node
                // (existing or newly created) in next extension of same
                // phase, when a new leaf edge gets added (i.e. when
                // Extension Rule 2 applies is any of the next extension
                // of same phase) at that point, suffix_link of this node
                // will point to that internal node.
                self.last_new_node = split;
            }
            self.remaining_suffix_count -= 1;

            if ((self.active_node == self.root) and (self.active_length > 0)) {
                // APCFER2C1
                self.active_length -= 1;
                self.active_edge = pos - self.remaining_suffix_count + 1;
            } else if (self.active_node != self.root) {
                std.debug.assert(self.active_node.suffix_link != null);
                //APCFER2C2
                self.active_node = self.active_node.suffix_link.?;
            }
        }
    }

    fn print(self: *const Ukkonen, i: usize, j: usize) void {
        for (self.text[i .. j + 1]) |c|
            _ = std.debug.print("{c}", .{c});
        std.debug.print("\n", .{});
    }

    /// Print the suffix tree as well along with setting suffix index
    /// So tree will be printed in DFS manner
    /// Each edge along with it's suffix index will be printed
    fn setSuffixIndexByDFS(self: *const Ukkonen, n_: ?*Node, label_height: usize) void {
        if (n_) |n| {
            if (n != self.root) {
                // Print the label on edge from parent to current node
                // Uncomment below line to print suffix tree
                // self.print(n.start, n.end.*);
            }
            var leaf = true;
            for (n.children) |child_|
                if (child_) |child| {
                    // current node is not a leaf as it has outgoing
                    // edges from it
                    leaf = false;
                    self.setSuffixIndexByDFS(child, label_height + self.edgeLength(child));
                };
            if (leaf)
                n.suffix_index = self.text.len - label_height;
        }
    }
    fn freeSuffixTreeByPostOrder(self: *const Ukkonen, n_: ?*Node) void {
        if (n_) |n| {
            for (n.children) |child_|
                if (child_) |child|
                    self.freeSuffixTreeByPostOrder(child);
            if (n.suffix_index == null)
                self.allocator.destroy(n.end);
            self.allocator.destroy(n);
        }
    }

    // Build the suffix tree and print the edge labels along with
    // suffix_index. suffix_index for leaf edges will be >= 0 and
    // for non-leaf edges will be null
    fn buildSuffixTree(self: *Ukkonen) void {
        self.root_end = self.allocator.create(usize) catch unreachable;
        self.root_end.* = undefined;

        // root is a special node with start and end indices undefined,
        // as it has no parent from where an edge comes to root
        std.debug.assert(self.root == null);
        self.root = self.newNode(undefined, self.root_end);

        self.active_node = self.root.?; // first active_node will be root
        for (0..self.text.len) |i|
            self.extendSuffixTree(i);
        const label_height: usize = 0;
        self.setSuffixIndexByDFS(self.root, label_height);
    }
    fn doTraversal(self: *const Ukkonen, n_: ?*Node, label_height: usize, max_height: *usize, substring_start_index: *usize) void {
        if (n_) |n| {
            if (n.suffix_index == null) {
                for (n.children) |child_|
                    if (child_) |child| {
                        self.doTraversal(child, label_height + self.edgeLength(child), max_height, substring_start_index);
                    };
            } else if ((n.suffix_index != null) and (max_height.* < (label_height - self.edgeLength(n)))) {
                max_height.* = label_height - self.edgeLength(n);
                substring_start_index.* = n.suffix_index.?;
            }
        }
    }
    fn getLongestRepeatedSubstring(self: *const Ukkonen) void {
        var max_height: usize = 0;
        var substring_start_index: usize = 0;
        self.doTraversal(self.root, 0, &max_height, &substring_start_index);
        std.debug.print("Longest Repeated Substring in {s} is: ", .{self.text});
        if (max_height != 0) {
            for (0..max_height) |k|
                std.debug.print("{c}", .{self.text[k + substring_start_index]});
        } else {
            std.debug.print("No repeated substring", .{});
        }
        std.debug.print("\n", .{});
    }
};

pub fn main() !void {
    // ---------------------------------------------------- allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // --------------------------------------------------------------
    {
        var u = Ukkonen.init(allocator, "GEEKSFORGEEKS$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
    {
        var u = Ukkonen.init(allocator, "AAAAAAAAAA$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
    {
        var u = Ukkonen.init(allocator, "ABCDEFG$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
    {
        var u = Ukkonen.init(allocator, "ABABABA$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
    {
        var u = Ukkonen.init(allocator, "ATCGATCGA$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
    {
        var u = Ukkonen.init(allocator, "banana$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
    {
        var u = Ukkonen.init(allocator, "abcpqrabpqpq$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
    {
        var u = Ukkonen.init(allocator, "pqrpqpqabab$");
        u.buildSuffixTree();
        u.getLongestRepeatedSubstring();
        u.freeSuffixTreeByPostOrder(u.root);
    }
}
