// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataLabelingIncentives {
    address public owner;
    mapping(address => uint256) public tokenBalance;
    mapping(uint256 => string) public labeledData;

    event DataLabeled(address indexed user, uint256 indexed dataId, string label, uint256 reward);

    constructor() {
        owner = msg.sender;
    }

    // Function to reward users for labeling data
    function submitLabel(uint256 dataId, string memory label) public {
        labeledData[dataId] = label;
        tokenBalance[msg.sender] += 10; // Reward 10 tokens per label
        emit DataLabeled(msg.sender, dataId, label, 10);
    }

    // Function to check the token balance
    function getBalance(address user) public view returns (uint256) {
        return tokenBalance[user];
    }

    // Admin can reset a user's balance (for demonstration or testing purposes)
    function resetBalance(address user) public {
        require(msg.sender == owner, "Only owner can reset balance");
        tokenBalance[user] = 0;
    }
}

