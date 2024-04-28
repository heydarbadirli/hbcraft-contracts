// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestSetUp.t.sol";

contract AuxiliaryFunctions is TestSetUp {
    function _approveToken(address user, uint256 amount) internal {
        bool isPrank = (user != address(this));

        if (isPrank) vm.startPrank(user);
        quoteToken.approve(address(testStore), amount * (10 ** qtDecimals));
        if (isPrank) vm.stopPrank();
    }

    function _approveNFT(address user) internal {
        bool isPrank = (user != address(this));

        if (isPrank) vm.startPrank(user);
        testNFT.setApprovalForAll(address(testStore), true);
        if (isPrank) vm.stopPrank();
    }

    function _createListing(address user, uint256 nftID, uint256 quantity, uint256 btPriceWithoutDecimals) internal {
        bool isPrank = (user != address(this));

        if (isPrank) vm.startPrank(user);
        testStore.createListing(address(testNFT), nftID, quantity, btPriceWithoutDecimals * (10 ** btDecimals));
        if (isPrank) vm.stopPrank();
    }

    function _cancelListing(address user, uint256 listingID) internal {
        bool isPrank = (user != address(this));

        if (isPrank) vm.startPrank(user);
        testStore.cancelListing(listingID);
        if (isPrank) vm.stopPrank();
    }

    function _createListingWithApproval(address user, uint256 nftID, uint256 quantity, uint256 btPriceWithoutDecimals)
        internal
    {
        _approveNFT(user);
        _createListing(user, nftID, quantity, btPriceWithoutDecimals);
    }

    function _safePurchase(address user, uint256 listingID, uint256 quantity, bool ifRevert) internal {
        bool isPrank = (user != address(this));
        uint256 forMaxPriceInQT = testStore.checkListingQTPrice(listingID);

        if (isPrank) vm.startPrank(user);
        if (ifRevert) vm.expectRevert();
        testStore.safePurchase(listingID, quantity, forMaxPriceInQT);
        if (isPrank) vm.stopPrank();
    }

    function _purchaseWithTest(address user, uint256 nftID, uint256 listingID, uint256 quantity, bool ifRevert)
        internal
    {
        uint256 listingPriceInQT = testStore.checkListingQTPrice(listingID);

        uint256 qtBalanceBeforeTreasury = quoteToken.balanceOf(treasury);
        uint256 qtBalanceBeforeBuyer = quoteToken.balanceOf(user);

        uint256 nftBalanceBeforeLister = testNFT.balanceOf(lister, nftID);
        uint256 nftBalanceBeforeBuyer = testNFT.balanceOf(user, nftID);

        uint256 listingQuantitiyBefore = testStore.getListingQuantityLeft(listingID);

        _safePurchase(user, listingID, quantity, ifRevert);
        if (ifRevert) return;

        assertEq(testNFT.balanceOf(lister, nftID), nftBalanceBeforeLister - quantity);
        assertEq(testNFT.balanceOf(user, nftID), nftBalanceBeforeBuyer + quantity);

        assertEq(quoteToken.balanceOf(treasury), qtBalanceBeforeTreasury + (quantity * listingPriceInQT));
        assertEq(quoteToken.balanceOf(user), qtBalanceBeforeBuyer - (quantity * listingPriceInQT));

        assertEq(testStore.getListingQuantityLeft(listingID), listingQuantitiyBefore - quantity);
    }
}
