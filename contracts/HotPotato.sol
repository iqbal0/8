// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HotPotato {
    address public owner;
    address public currentHolder;
    uint256 public currentPrice;
    uint256 public timeAcquired;
    uint256 public gameEndTime;
    bool public gameActive;
    
    // Game parameters
    uint256 public constant MAX_HOLD_TIME = 5 minutes;
    uint256 public constant PRICE_INCREASE_PERCENT = 120; // 20% increase per transfer
    
    event GameStarted(address indexed firstHolder, uint256 initialPrice, uint256 endTime);
    event PotatoBought(address indexed from, address indexed to, uint256 price, uint256 timestamp, bool wasForceSale);
    event GameOver(address indexed finalLoser);

    constructor() {
        owner = msg.sender;
    }

    function startGame() external {
        require(!gameActive, "Game already active");
        gameActive = true;
        currentHolder = msg.sender;
        currentPrice = 0.001 ether;
        timeAcquired = block.timestamp;
        
        // Pseudo-random game duration between 10 mins and 30 mins for gameplay
        uint256 randomDuration = 10 minutes + (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))) % 20 minutes);
        gameEndTime = block.timestamp + randomDuration;
        
        emit GameStarted(msg.sender, currentPrice, gameEndTime);
    }

    function buy() external payable {
        require(gameActive, "Game is not active");
        require(msg.sender != currentHolder, "You already hold the potato");
        
        // Check if music stopped
        if (block.timestamp >= gameEndTime) {
            gameActive = false;
            emit GameOver(currentHolder);
            revert("Music stopped! Game over. The potato exploded.");
        }

        require(msg.value >= currentPrice, "Insufficient funds to buy the potato");

        address previousHolder = currentHolder;
        
        // If held longer than MAX_HOLD_TIME, it's a force sale.
        // The previous holder is penalized and gets nothing (funds go to treasury).
        bool isForceSale = block.timestamp > (timeAcquired + MAX_HOLD_TIME);

        if (!isForceSale) {
            // Normal sale: previous holder gets the purchase amount
            (bool success, ) = previousHolder.call{value: currentPrice}("");
            require(success, "Transfer to previous holder failed");
        }

        // Refund any excess ETH sent by the buyer
        if (msg.value > currentPrice) {
            (bool success, ) = msg.sender.call{value: msg.value - currentPrice}("");
            require(success, "Refund failed");
        }

        // Update state for the new holder
        currentHolder = msg.sender;
        timeAcquired = block.timestamp;
        
        emit PotatoBought(previousHolder, msg.sender, currentPrice, block.timestamp, isForceSale);
        
        // Increase price by 20% for the next buyer
        currentPrice = (currentPrice * PRICE_INCREASE_PERCENT) / 100;
    }

    function checkGameState() external {
        if (gameActive && block.timestamp >= gameEndTime) {
            gameActive = false;
            emit GameOver(currentHolder);
        }
    }

    function withdrawTreasury() external {
        require(msg.sender == owner, "Only owner can withdraw treasury");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}
