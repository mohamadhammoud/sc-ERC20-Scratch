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
        // transferFrom sends "amount"...
        token.transferFrom(msg.sender, address(this), amount);

        // ❌ BUG: assumes vault received `amount`
        // User deposits 100 tokens, but vault receives only 99 (because fee).
        // Yet vault credits user 100.
        // So user can withdraw 100.
        // but vault only has 99.
        credits[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(credits[msg.sender] >= amount, "not enough credit");

        credits[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }
}
