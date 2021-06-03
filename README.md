# Inter-Repository Merge Script (IRM-Script)

**IRM-Script can be used to clone and merge git repositories with different remote origin addresses in isolated networks.** These repositories could be placed in different networks such as the internet and the corporate intranet and can be isolated in any way.

For the download (cloning) step, IRM-Script clone defined git repositories from remote git address (source address). 

For the upload step, IRM-Script upload cloned repositories to defined git address (destination address) with new branch names formatted as IRM-SCRIPT-CODEMERGE-date.

Source and destination Git repository addresses are defined in the configuration files (repository.config, repository.list.config). 

**IRM-Script can clone and merge any number of repositories at once.**

IRM-Script can support merge operation for "develop" branches between source and destination Git repositories. If any conflicts occur, IRM-Script informs the user and logs Git conflict outputs to the associated log file.

The user can check and watch all processes from the prompt screen and also from the log.txt file. All prompt screen output logged to this file.

For Unix/Linux/Mac users: 
```bash
./irm.sh -option(s) parameter 
```

For Windows Bash users: 
```bash
bash irm.sh -option(s) parameter 
```

Options: 
```
-a : Archive option set. Git repositories will be archived (*.tar.gz) into the archive folder.
-b : Found the -b (branch) option. For the upload operation, a given custom branch name will be used.
-c : Cleaning option set. All output folders and files will be removed!
-d : Download option set. Defined repositories will be cloned to the local disk in the repositories folder.
-h : Shows this Help message.
-m : Merge option set. In the upload operation, cloned repositories will be merged to develop branches of the remote repositories then pushed to the custom-created branches.
-u : Upload option set. Cloned repositories will be uploaded to remote repositories with new branch names formatted as IRM-SCRIPT-CODEMERGE-date.
-y : Yes to all for errors option set. Given errors will be neglected and the process will continue.
```

Example Parameter Usages:

The command prompt parameter read from the file [parameter].repository.config in the conf folder.

```bash
github : Custom Github repository configuration files will be used.

repository-1 : Internet/Intranet Repository 1 configuration files will be used.

repository-2 : Internet/Intranet Repository 2 configuration files will be used.
```

Example Usages: 
```bash
bash irm.sh -yda github
bash irm.sh -yd github
bash irm.sh -da github
bash irm.sh -d github
---------------------------
bash irm.sh -yum -b code_merge github
bash irm.sh -yum github
bash irm.sh -yu github
bash irm.sh -um -b code_merge github
bash irm.sh -um github
bash irm.sh -u github
---------------------------
bash irm.sh -h
bash irm.sh -c
```
