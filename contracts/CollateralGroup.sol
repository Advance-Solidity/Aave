// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "hardhat/console.sol";

import "./IERC20.sol";
import "./ILendingPool.sol";

contract CollateralGroup {
    ILendingPool pool =
        ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3);

    uint256 depositAmount = 10000e18;
    address[] members;

    /*
In the constructor, deposit all the collected DAI into the pool contract.

To do this, you will first need to approve the pool to spend our DAI.

Then, deposit the DAI into the pool contract. Deposit it on behalf of the collateral group
contract and you can set the referral code to 0 or any valid code you'd like.
*/
    constructor(address[] memory _members) {
        members = _members;
        uint256 lenght = _members.length;
        for (uint256 i; i < lenght; ++i) {
            dai.transferFrom(_members[i], address(this), depositAmount);
        }
        uint256 balance = dai.balanceOf(address(this));
        console.log("balance of all uses", balance);
        dai.approve(address(pool), balance);
        pool.deposit(address(dai), balance, address(this), 0);
    }

    /**
In the withdraw function, withdraw the entire balance of aDai from the pool, distributing the appropriate share to each member who joined the collateral group.

Before you can call withdraw on the pool you will need to approve the aDai to be spent by the pool.



*/
    function withdraw() external {
        require(onlymember(msg.sender));
        uint256 balance = aDai.balanceOf(address(this));
        aDai.approve(address(pool), balance);
        uint256 total = members.length;
        uint256 amount = balance / total;
        for (uint256 i; i < total; ++i) {
            pool.withdraw(address(dai), amount, members[i]);
            console.log(
                "adai token of contract",
                aDai.balanceOf(address(this))
            );
        }
    }

    /*
In the CollateralGroup borrow function, call borrow on the AAVE pool to borrow the 
amount of asset specified by the arguments. Be sure to set the onBehalfOf to the 
collateral group contract, this way the debt is incurred to the smart contract which
holds the collateral. You can set the referral code as you wish and the interestRateMode
should either be 1 for stable or 2 for variable rates.

*/
    function borrow(address asset, uint256 amount) external {
        require(onlymember(msg.sender));
        pool.borrow(asset, amount, 1, 0, address(this));
        IERC20(asset).transfer(msg.sender, amount);
        (, , , , , uint256 f) = pool.getUserAccountData(address(this));

/*
To ensure that our collateral/borrow ratio stays healthy, let's require that the borrow function will only execute borrows if the health factor is above 2 after the borrow is completed.

To find out the health factor, you will need to call getUserAccountData on the pool. When we provide the address of the smart contract this will respond with six return values. The last of the return values is the healthFactor.

After the borrow is completed, require that the health factor is above 2. If not, revert the transaction. The health factor is provided with 18 decimal places of precision, so you will need to check that is above 2e18.


*/


        require(f > 2e18);
    }




/*
In the repay function you can repay the loan in three steps:

First, transfer the asset from the member to the smart contract.

Next, approve the dai to be spent by the pool.

Finally, repay the pool on behalf of the collateral group. You will
 need to choose the same interest rate mode as you did in the borrow function.

*/
    function repay(address asset, uint256 amount) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        dai.approve(address(pool), amount);
        pool.repay(asset, amount, 1, address(this));
    }



/*
Let's make sure that only members can call borrow and withdraw. 
For anyone else who tries to call these methods, revert the transaction.

*/
    function onlymember(address user) public view returns (bool sucess) {
        address[] memory _members = members;
        for (uint256 i; i < members.length; ++i) {
            if (_members[i] == user) {
                sucess = true;
                break;
            }
        }
    }
}
