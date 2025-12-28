// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {
    IERC20
} from "openzeppelin-contracts-5.0.0/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "openzeppelin-contracts-5.0.0/contracts/token/ERC20/utils/SafeERC20.sol";

contract USDTHandler {
    using SafeERC20 for IERC20;

    function pay(IERC20 token, address to, uint256 amount) external {
        // SafeERC20 handles non-standard ERC20 tokens (like USDT that don't return bool)
        // safeTransfer either succeeds or reverts, it doesn't return a bool
        token.safeTransfer(to, amount);
    }

    function approveSpender(
        IERC20 token,
        address spender,
        uint256 amount
    ) external {
        // forceApprove handles USDT's approve quirk automatically
        // It first tries to approve, and if it fails, sets to 0 then approves again
        token.forceApprove(spender, amount);
    }
}
