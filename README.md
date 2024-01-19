| Function                          | Access Tier | Description |
|:----------------------------------|:------------|:------------|
| `launchDefault`                   | **2**       | Launches the staking program with two new staking pools, 1 locked and 1 flexible. |
| `pauseProgram`                    | **2**       | Pauses staking, withdrawal, and interest claim activities for all pools. |
| `resumeProgram`                   | **2**       | Resumes the staking program with predefined settings.* |
| `endProgram`                      | **2**       | Ends the staking program, closes staking, opens the withdrawal and interest claiming for all the pools, and sets the program end date to the current timestamp. |

> *The predefined settings for the staking program are:
> 1. Both staking and interest claiming are open for locked and flexible pools.
> 2. Withdrawal is open for flexible pools but closed for locked pools.
