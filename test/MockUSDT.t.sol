// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts-5.0.0/contracts/token/ERC20/IERC20.sol";
import {MockUSDT} from "src/MockUSDT.sol";
import {USDTHandler} from "src/USDTHandler.sol";

contract MockUSDTTest is Test {
    MockUSDT public token;
    USDTHandler public handler;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        token = new MockUSDT("Mock USDT", "USDT");

        handler = new USDTHandler();
        token.mint(address(handler), 1000000 * 10 ** 18);
    }

    // ============ USDT Approve Quirk Tests ============
    // USDT requires: currentAllowance == 0 || amount == 0
    // This means you can only approve non-zero when current allowance is zero

    function test_Approve_FromZeroToNonZero_Success() public {
        // ✅ Allowed: currentAllowance == 0, amount != 0
        vm.prank(alice);
        token.approve(bob, 1000);
        assertEq(token.allowance(alice, bob), 1000);
    }

    function test_Approve_FromNonZeroToZero_Success() public {
        // Allowed: amount == 0 (regardless of currentAllowance)
        vm.prank(alice);
        token.approve(bob, 1000);

        vm.prank(alice);
        token.approve(bob, 0);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_Approve_FromNonZeroToNonZero_Reverts() public {
        //  Reverts: currentAllowance != 0 && amount != 0
        vm.prank(alice);
        token.approve(bob, 1000);

        vm.prank(alice);
        vm.expectRevert("USDT: approve must be zero first");
        token.approve(bob, 2000);
    }

    function test_Approve_TwoStepUpdate_Success() public {
        // USDT workaround: Set to 0 first, then set new value
        vm.prank(alice);
        token.approve(bob, 1000);

        // Step 1: Set to zero (allowed)
        vm.prank(alice);
        token.approve(bob, 0);

        // Step 2: Set to new value (now allowed since current is zero)
        vm.prank(alice);
        token.approve(bob, 2000);
        assertEq(token.allowance(alice, bob), 2000);
    }

    // ============ Transfer Tests ============

    function test_Transfer_Success() public {
        uint256 amount = 1000 * 10 ** 18;
        token.mint(alice, amount);

        vm.prank(alice);
        token.transfer(bob, amount);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), amount);
    }

    function test_Transfer_EmitsTransfer() public {
        uint256 amount = 1000 * 10 ** 18;
        token.mint(alice, amount);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, amount);
        token.transfer(bob, amount);
    }

    function test_Transfer_DoesNotReturnBool() public {
        // MockUSDT.transfer() doesn't return bool (like old USDT)
        // This test verifies the transfer still works, just without return value
        token.mint(alice, 1000 * 10 ** 18);
        vm.prank(alice);
        token.transfer(bob, 1000 * 10 ** 18);
        assertEq(token.balanceOf(bob), 1000 * 10 ** 18);
    }

    function test_Transfer_PartialAmount() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 300 * 10 ** 18;
        token.mint(alice, mintAmount);

        vm.prank(alice);
        token.transfer(bob, transferAmount);

        assertEq(token.balanceOf(alice), mintAmount - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
    }

    function test_Transfer_RevertsWhen_InsufficientBalance() public {
        token.mint(alice, 500 * 10 ** 18);

        vm.prank(alice);
        vm.expectRevert("ERC20: insufficient balance");
        token.transfer(bob, 1000 * 10 ** 18);
    }

    function test_Transfer_RevertsWhen_ToIsZero() public {
        token.mint(alice, 1000 * 10 ** 18);

        vm.prank(alice);
        vm.expectRevert("ERC20: Invalid recipient");
        token.transfer(address(0), 1000 * 10 ** 18);
    }

    function test_Transfer_ZeroAmount() public {
        token.mint(alice, 1000 * 10 ** 18);

        vm.prank(alice);
        token.transfer(bob, 0);

        assertEq(token.balanceOf(alice), 1000 * 10 ** 18);
        assertEq(token.balanceOf(bob), 0);
    }

    function test_Transfer_ToSelf() public {
        uint256 amount = 1000 * 10 ** 18;
        token.mint(alice, amount);

        vm.prank(alice);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
    }

    // ============ USDTHandler Tests ============
    // USDTHandler now uses SafeERC20.safeTransfer() which handles non-standard ERC20 tokens
    // SafeERC20 gracefully handles tokens that don't return bool (like old USDT)
    // This demonstrates how SafeERC20 solves the non-standard ERC20 token problem

    function test_USDTHandler_Transfer_Success_WithSafeERC20() public {
        // Handler has USDT minted in setUp
        uint256 amount = 1000 * 10 ** 18;
        uint256 initialBalance = token.balanceOf(address(handler));

        // SafeERC20 handles MockUSDT.transfer() even though it doesn't return bool
        // The transfer succeeds because SafeERC20 doesn't require a return value
        handler.pay(IERC20(address(token)), alice, amount);

        // Verify the transfer succeeded
        assertEq(token.balanceOf(address(handler)), initialBalance - amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_USDTHandler_Transfer_RevertsWhen_InsufficientBalance() public {
        uint256 handlerBalance = token.balanceOf(address(handler));
        uint256 amount = handlerBalance + 1; // More than handler has

        // SafeERC20 will revert with MockUSDT's revert message
        vm.expectRevert("ERC20: insufficient balance");
        handler.pay(IERC20(address(token)), alice, amount);
    }

    function test_USDTHandler_Transfer_RevertsWhen_ToIsZero() public {
        uint256 amount = 1000 * 10 ** 18;

        // SafeERC20 will revert with MockUSDT's revert message
        vm.expectRevert("ERC20: Invalid recipient");
        handler.pay(IERC20(address(token)), address(0), amount);
    }

    // ============ forceApprove Tests ============
    // forceApprove handles USDT's approve quirk automatically
    // It tries to approve directly, and if that fails, sets to 0 first then approves

    function test_ForceApprove_FromZeroToNonZero_Success() public {
        // forceApprove should work directly when current allowance is 0
        uint256 amount = 1000 * 10 ** 18;

        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, amount);

        assertEq(token.allowance(address(handler), bob), amount);
    }

    function test_ForceApprove_FromNonZeroToNonZero_Success() public {
        // forceApprove automatically handles the USDT quirk
        // It will set to 0 first, then approve the new value
        uint256 initialAmount = 1000 * 10 ** 18;
        uint256 newAmount = 2000 * 10 ** 18;

        // First approve a non-zero amount
        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, initialAmount);
        assertEq(token.allowance(address(handler), bob), initialAmount);

        // Now forceApprove a different non-zero amount
        // This would normally revert with direct approve, but forceApprove handles it
        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, newAmount);

        assertEq(token.allowance(address(handler), bob), newAmount);
    }

    function test_ForceApprove_FromNonZeroToZero_Success() public {
        // forceApprove should work directly when setting to 0
        uint256 initialAmount = 1000 * 10 ** 18;

        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, initialAmount);
        assertEq(token.allowance(address(handler), bob), initialAmount);

        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, 0);
        assertEq(token.allowance(address(handler), bob), 0);
    }

    function test_ForceApprove_MultipleUpdates_Success() public {
        // Test multiple forceApprove calls in sequence
        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, 1000);
        assertEq(token.allowance(address(handler), bob), 1000);

        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, 2000);
        assertEq(token.allowance(address(handler), bob), 2000);

        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, 500);
        assertEq(token.allowance(address(handler), bob), 500);

        vm.prank(address(handler));
        handler.approveSpender(IERC20(address(token)), bob, 0);
        assertEq(token.allowance(address(handler), bob), 0);
    }

    function test_ForceApprove_EmitsApprovalEvents() public {
        // forceApprove should emit Approval events
        uint256 amount = 1000 * 10 ** 18;

        vm.prank(address(handler));
        vm.expectEmit(true, true, false, true);
        emit Approval(address(handler), bob, amount);
        handler.approveSpender(IERC20(address(token)), bob, amount);
    }
}
