// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Govern.sol";
import "./ILendingPool.sol";

contract FlashVoter {
    ILendingPool constant pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint constant borrowAmount = 100000e18;

    Govern public governanceToken;
    uint public proposalId;



/*
In the constructor, you'll notice that there are two parameters being passed: the _governanceToken 
and the _proposalId. The governance token will point at the Govern contract, so we can call methods
on it. The _proposalId will be the current proposal we will be attempting to vote on.

Store these two variables in the storage variables governanceToken and proposalId respectively.

*/
    constructor(Govern _governanceToken, uint _proposalId) {
        governanceToken=_governanceToken;
        proposalId=_proposalId;
    }



/*
First let's take a look at the AAVE LendingPool flashloan function, which takes quite a few parameters! We'll break them down one by one.

receiverAddress - This is the address of a contract that will receive the funds. The contract must have an executeOperation function for the Lending Pool to call. This function has already been set up in FlashVoter contract. We'll want to set this parameter to be the contract's address.
assets - These are the addresses of the ERC20 contracts we want to borrow. For our purposes, it will be enough to supply one asset: DAI.
amounts - These are the amounts of the assets we want to borrow, corresponding to their position in the assets array. We are only borrowing DAI, so we only need to specify one amount.
modes - These are another array that corresponds to the indexes in amounts and assets. It will define the debt to create if the flash loan is not paid back. In our case, we will pay back the flash loan in full and not open any debt, so this can be set to 0.
onBehalfOf - Who will incur the debt. In our case, we will not incur any debt.
params - Extra parameters to send through to the executeOperation function. We won't need to use these, so you can supply an empty string "".
referralCode - You can supply any valid code or 0 here.


*/
    function flashVote() external {
        address[] memory assets = new address[](1);
        assets[0]=address(DAI);

        uint256[] memory amounts = new uint[](1);
        amounts[0]=100000e18;

        uint256[] memory modes = new uint[](1);
        modes[0]=0;

        pool.flashLoan(address(this),assets,amounts,modes,address(0),"",0);
        
        
    }



/*

Ensure that the flash loan call to executeOpeartion is successful by paying back the amount owed.

You can determine the total amount owned by taking the first value in the amounts array and adding it to the first value in the premiums array. This will be the amount your borrowed and the amount owed on top of that respectively.

Once you have calculated the total amount owed you just need to approve the pool to spend this amount of the smart contract's DAI and return true.

*/




/*
Your goal is to buy governance tokens, vote with them, and then sell them back to DAI so you can repay the flash loan. Do this all in the executeOperation function.

You stored the proposalId to vote on in a storage variable in the constructor. Vote on this proposal with your flash loaned Govern tokens.



*/
    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, bytes calldata
    ) external returns(bool) {
        
        uint owed = amounts[0] + premiums[0];
        // uint amount=IERC20(DAI).balanceOf(address(this));
        DAI.approve(address(governanceToken),borrowAmount);
        governanceToken.buy(borrowAmount);
        governanceToken.vote(proposalId,true);
        governanceToken.sell(borrowAmount);


        DAI.approve(address(pool), owed);
        console.log("owed amount",owed);
        console.log(IERC20(DAI).balanceOf(address(this)));
        return true;
    }
}