// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {IERC20} from "src/interfaces/IERC20.sol";

contract USDTHandler {
    function pay(IERC20 token, address to, uint256 amount) external {
        // THIS IS NORMAL ERC20 USAGE
        bool ok = token.transfer(to, amount);
        require(ok, "transfer failed");
    }
}
