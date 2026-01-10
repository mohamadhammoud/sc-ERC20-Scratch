// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "openzeppelin-contracts-5.0.0/contracts/token/ERC20/IERC20.sol";

contract BuggyVault {
    IERC20 public immutable token;

    mapping(address => uint256) public credits;

    constructor(IERC20 _token) {
        token = _token;
    }

    function deposit(uint256 amount) external {
        // ✅ FIX: Check actual received amount (handles fee-on-transfer tokens)
        uint256 before = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 received = token.balanceOf(address(this)) - before;

        // ❌ BUG WAS HERE: credits[msg.sender] += amount;
        // The bug was crediting the user with the requested `amount` instead of
        // the actual `received` amount. This caused accounting mismatch when
        // tokens have transfer fees. User would be credited 100 but vault only
        // received 99 (after 1% fee), allowing user to drain more than deposited.

        // ✅ FIX: Credit the actual received amount
        credits[msg.sender] += received;
    }

    function withdraw(uint256 amount) external {
        require(credits[msg.sender] >= amount, "not enough credit");

        credits[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }
}
