# Catalog reconciliation

The newer bar provides the values below; the original uploaded catalog remains in reference/.

| ID | Field | Uploaded catalog | Newer bar / matched catalog |
| --- | --- | --- | --- |
| a-template-20261014:10 | name | Party - Assist and Follow | Party - Assistance |
| a-template-20261014:10 | alias | Assist | Assistance |
| a-template-20261014:10 | command | trust assist me; trust follow me; input /echo Party assisting and following. | send @others trust start; input /echo Asked party to stand ready! |
| a-template-20261014:13 | name | Party - Stop Trust | Party - Stand Down |
| a-template-20261014:13 | alias | Stop | Stand Down |
| a-template-20261014:13 | command | trust stopall; input /echo Asked party to stop! | send @all trust stop; input /echo Asked party to stand down! |
| a-template-20261014:11 | name | Party - Trust Toggle | Self - Trust Toggle |
| a-template-20261014:11 | command | trust toggle | trust toggle; trust follow stop |
| a-template-20261014:11 | icon | engage | custom_actions |
| a-template-20261014:17 | name | Dialogue - One Enter | Dialogue - Raw Enter |
| a-template-20261014:17 | alias | Confirm | All Confirm |
| a-template-20261014:17 | command | send @all slowenter once | send @all slowenter on; input /echo Sending all SlowEnter on; send @all slowenter once |
| a-template-20261014:17 | icon |  | custom_actions |
| a-template-20261014:19 | alias | Raw Cancel | All Cancel |
| a-template-20261014:19 | command | send @all slowenter off; send @all setkey escape down; wait 0.1; send @all setkey escape up | send @all slowenter off; send @all setkey escape down; wait 0.1; send @all setkey escape up; input /echo Canceling slow enter on all clients. |
| a-template-20261014:21 | icon |  | custom_actions |

No IDs or unrelated catalog records were removed. Suggested actions remain separate.
