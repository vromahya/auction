//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.7.0 <0.9.0;

contract Auction {
    address payable auctioneer;
    uint256 public startBlock;
    uint256 public endBlock;

    enum auc_State {
        running,
        ended,
        cancelled
    }
    auc_State public auctionState;

    uint256 public highestPayableBid;
    uint256 public bidIncrement;

    address payable public highestBidder;

    mapping(address => uint256) public bids;

    event LogBid(
        address indexed bidder,
        uint256 indexed bid,
        address highestBidder,
        uint256 highestPayableBid
    );
    event LogWithdrawal(
        address indexed withdrawalAccount,
        uint256 indexed withdrawalAmount
    );
    event LogCanceled();

    constructor(
        address payable _auctioneer,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bidIncrement
    ) {
        require(_startBlock >= _endBlock);
        require(_startBlock < block.number);
        auctioneer = _auctioneer;
        startBlock = _startBlock;
        endBlock = _endBlock;
        bidIncrement = _bidIncrement;
        auctionState = auc_State.running;
    }

    modifier notOwner() {
        require(msg.sender != auctioneer, "Owner cannot bid");
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == auctioneer,
            "only owner cann access this function"
        );
        _;
    }
    modifier afterStart() {
        require(block.number > startBlock);
        _;
    }
    modifier beforeEnd() {
        require(block.number < endBlock);
        _;
    }

    function cancelAuc() public onlyOwner {
        auctionState = auc_State.cancelled;
        emit LogCanceled();
    }

    function placeBid()
        public
        payable
        notOwner
        afterStart
        beforeEnd
        returns (bool success)
    {
        require(auctionState == auc_State.running);
        require(msg.value >= 1);
        uint256 currentBid = bids[msg.sender] + msg.value;

        require(currentBid >= highestPayableBid);

        bids[msg.sender] = currentBid;

        if (currentBid < bids[highestBidder]) {
            highestPayableBid = min(
                currentBid + bidIncrement,
                bids[highestBidder]
            );
        } else {
            highestPayableBid = min(
                currentBid,
                bids[highestBidder] + bidIncrement
            );
            highestBidder = payable(msg.sender);
        }
        emit LogBid(msg.sender, currentBid, highestBidder, highestPayableBid);
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) return a;
        else return b;
    }

    function finalizeAuc() public returns (bool success) {
        require(
            auctionState == auc_State.cancelled ||
                block.number > endBlock ||
                auctionState == auc_State.ended
        );
        require(msg.sender == auctioneer || bids[msg.sender] > 0);

        address payable withdrawalAccount;
        uint256 withdrawalAmount;

        if (auctionState == auc_State.cancelled) {
            withdrawalAccount = payable(msg.sender);
            withdrawalAmount = bids[msg.sender];
        } else {
            if (msg.sender == auctioneer) {
                withdrawalAccount = auctioneer;
                withdrawalAmount = highestPayableBid;
            } else {
                if (msg.sender == highestBidder) {
                    withdrawalAccount = highestBidder;
                    withdrawalAmount = bids[highestBidder] - highestPayableBid;
                } else {
                    withdrawalAccount = payable(msg.sender);
                    withdrawalAmount = bids[msg.sender];
                }
            }
        }
        bids[msg.sender] = 0;
        withdrawalAccount.transfer(withdrawalAmount);
        emit LogWithdrawal(withdrawalAccount, withdrawalAmount);
        return true;
    }

    function getHighestBidder() external view returns (address payable) {
        require(auctionState == auc_State.ended);
        return payable(highestBidder);
    }
}
