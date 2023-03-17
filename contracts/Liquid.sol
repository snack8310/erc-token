// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPool {
    IERC20 public echoToken;
    IERC20 public orpheusToken;
    mapping(address => uint) public echoBalances;
    mapping(address => uint) public orpheusBalances;
    uint public totalEcho;
    uint public totalOrpheus;
    uint public totalShares;
    mapping(address => uint) public shares;

    constructor(address _echoToken, address _orpheusToken) {
        echoToken = IERC20(_echoToken);
        orpheusToken = IERC20(_orpheusToken);
    }

    function addLiquidity(uint echoAmount, uint orpheusAmount) external {
        require(echoAmount > 0 && orpheusAmount > 0, "Invalid liquidity amount");
        echoToken.transferFrom(msg.sender, address(this), echoAmount);
        orpheusToken.transferFrom(msg.sender, address(this), orpheusAmount);
        echoBalances[msg.sender] += echoAmount;
        orpheusBalances[msg.sender] += orpheusAmount;
        totalEcho += echoAmount;
        totalOrpheus += orpheusAmount;
        uint share = 0;
        if (totalShares == 0) {
            share = sqrt(echoAmount * orpheusAmount);
        } else {
            share = (sqrt(echoAmount * orpheusAmount) * totalShares) / sqrt(totalEcho * totalOrpheus);
        }
        shares[msg.sender] += share;
        totalShares += share;
    }

    function removeLiquidity(uint share) external {
        require(share > 0 && shares[msg.sender] >= share, "Invalid share amount");
        uint echoAmount = (share * totalEcho) / totalShares;
        uint orpheusAmount = (share * totalOrpheus) / totalShares;
        echoBalances[msg.sender] -= echoAmount;
        orpheusBalances[msg.sender] -= orpheusAmount;
        totalEcho -= echoAmount;
        totalOrpheus -= orpheusAmount;
        shares[msg.sender] -= share;
        totalShares -= share;
        echoToken.transfer(msg.sender, echoAmount);
        orpheusToken.transfer(msg.sender, orpheusAmount);
    }

    function getReward() external {
        uint echoBalance = echoToken.balanceOf(address(this));
        uint orpheusBalance = orpheusToken.balanceOf(address(this));
        uint echoReward = (echoBalance * totalShares) / totalEcho;
        uint orpheusReward = (orpheusBalance * totalShares) / totalOrpheus;
        for (uint256 account = 0; account < totalShares; account++) {
            address accountAddress = address(uint160(account));
            uint share = shares[accountAddress];
            uint echoAmount = (share * echoReward) / totalShares;
            uint orpheusAmount = (share * orpheusReward) / totalShares;
            echoToken.transfer(accountAddress, echoAmount);
            orpheusToken.transfer(accountAddress, orpheusAmount);
        }
    }

    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
