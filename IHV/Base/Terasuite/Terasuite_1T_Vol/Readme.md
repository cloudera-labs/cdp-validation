## Run Terasuite for 1T
For this, you will use the script from the _Terasuite_1T_Vol_ directory in the git repo downloaded. 
 
For 1T data, the parameters need to be updated as below. 

_parameters_1T.sh_
```
#!/bin/bash
REPLICATION=3
MAP_MEMORY=2048
REDUCE_MEMORY=2048
NUM_MAPPERS=Total number of vcores - 20
NUM_REDUCERS=No. of datanodes or nodemanagers
```

### Parameter details: 
* Replication is set to 3 by default. 
* Block size is set to 128 MB (MiB). Memory for map and reduce tasks is set to 2G. At any phase of the job run, if you encounter any issue with map memory, feel free to increase this to higher value. 
* Number of mappers is, as a thumb rule, set to 20 vcores less than the total number of vcores available in the cluster. The remaining 20 vcores can also be used, however, they have been kept idle as a buffer. 
* Number of reducers is set to the number of datanodes or nodemanagers. This is to ensure that the reduce phase gets distributed across all the nodemanagers.

### Execution Steps:

* In the location where the scripts have been copied, run the below command to add execute permission and trigger the test. This ensures that the job will be running in the background and you can check the log at any time. 

```
cd Terasuite_1T_Vol/

chmod +x *.sh

nohup sh terasuite_1T.sh > terasuite_1T_Log &
```

* To keep checking the logs, you can run the below command. 
```
tail -f terasuite_1T_Log
```
* Additionally, you can track the progress from Resource Manager Web UI as well. 

* This script runs all three Teragen. Terasort, and Teravalidate jobs and if all the jobs are run successfully, then you will see the message TERASUITE TEST RAN SUCCESSFULLY at the end of execution.

* If there is any error during the execution, it could be due to multiple factors. 
    * Missing value in the parameter. 
    * Unaccepted value entered in the parameters file. 
    * Running out of memory, in which case, try to increase the Mapper and Reducer memory in the parameters file and rerun to see if the job completes. 
    * If you still are unable to proceed, please reach out to the Cloudera POC and they will be able to help you out.

