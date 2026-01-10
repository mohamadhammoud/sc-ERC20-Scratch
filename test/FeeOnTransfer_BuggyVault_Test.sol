// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {FeeOnTransferToken} from "src/FeeOnTransferToken.sol";
import {BuggyVault} from "src/BuggyVault.sol";

import {IERC20} from "openzeppelin-contracts-5.0.0/contracts/token/ERC20/IERC20.sol";

contract FeeOnTransfer_BuggyVault_Test is Test {
    FeeOnTransferToken token;
    BuggyVault vault;

    address feeCollector = address(0xFEE);
    address alice = address(0xA11CE);

    function setUp() public {
        token = new FeeOnTransferToken(feeCollector);
        vault = new BuggyVault(IERC20(address(token)));

        token.mint(alice, 1000 ether);
    }

    function test_DepositCreditsOnlyReceivedAmount() public {
        // Alice approves vault
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        // Alice deposits 100
        vm.prank(alice);
        vault.deposit(100 ether);

        // ✅ FIX VERIFIED: Vault credits Alice with only the received amount (99)
        // not the requested amount (100)
        assertEq(vault.credits(alice), 99 ether, "Should credit only received amount");

        // Vault actually received 99 because of 1% fee
        assertEq(token.balanceOf(address(vault)), 99 ether);

        // FeeCollector got 1
        assertEq(token.balanceOf(feeCollector), 1 ether);
    }

    function test_WithdrawSucceedsWithCorrectAccounting() public {
        // Approve + deposit
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.deposit(100 ether);

        // ✅ FIX VERIFIED: Vault credited 99 and has 99 -> withdraw 99 succeeds
        vm.prank(alice);
        vault.withdraw(99 ether);

        // Alice should have received her tokens back
        // Note: There will be another 1% fee on withdrawal
        assertEq(token.balanceOf(alice), 900 ether + 98.01 ether); // 900 (remaining) + 99 * 0.99 (after fee)
        assertEq(vault.credits(alice), 0, "Credits should be zero after withdrawal");
    }

    function test_WithdrawFailsWhenTryingToWithdrawMoreThanCredited() public {
        // Approve + deposit
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);

        vm.prank(alice);
        vault.deposit(100 ether);

        // Vault credited 99, trying to withdraw 100 should fail
        vm.prank(alice);
        vm.expectRevert("not enough credit");
        vault.withdraw(100 ether);
    }
}
