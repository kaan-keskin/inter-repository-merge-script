#!/bin/bash

# Inter-Repository Merge Script (IRM-Script)
# Author: Kaan Keskin
# Co-Authors: Semih Teker
# Creation Date: 25 August 2020 
# Modification Date: 3 December 2021
# Release: 1.12.3

HELP_MSG=(
""
"   Inter-Repository Merge Script (IRM-Script): "
""
"   IRM-Script can be used to clone and merge git repositories with different remote origin addresses in isolated networks. "
"   These repositories could be placed in different networks such as the internet and the corporate intranet and can be isolated in any way. "
""
"   For the download (cloning) step, IRM-Script clone defined git repositories from remote git address (source address). "
""
"   For the upload step, IRM-Script upload cloned repositories to defined git address (destination address) with new branch names formatted as IRM-SCRIPT-CODEMERGE-date."
""
"   Source and destination Git repository addresses are defined in the configuration files (repository.config, repository.list.config). "
""
"   IRM-Script can clone and merge any number of repositories at once."
""
"   IRM-Script can support merge operation for develop branches between source and destination Git repositories. "
"   If any conflicts occur, IRM-Script informs the user and logs Git conflict outputs to the associated log file."
""
"   The user can check and watch all processes from the prompt screen and also from the log.txt file. All prompt screen output logged to this file."
""
"   For Unix/Linux/Mac users: "
"   $ ./irm.sh -option(s) parameter "
""
"   For Windows bash users: "
"   $ bash irm.sh -option(s) parameter "
""
"   Options: "
"   -a : Archive option set. Git repositories will be archived (*.tar.gz) into the archive folder. "
"   -b : Found the -b (branch) option. For the upload operation, a given custom branch name will be used. "
"   -c : Cleaning option set. All output folders and files will be removed! "
"   -d : Download option set. Defined repositories will be cloned to the local disk in the repositories folder. "
"   -h : Shows this Help message. "
"   -m : Merge option set. In the upload operation, cloned repositories will be merged to develop branches of the remote repositories then pushed to the custom-created branches. "
"   -r : Release Candidate Branch option set. Creates new Release Candidate Branch from develop branch. Download and Upload operations included in this option. "
"   -u : Upload option set. Cloned repositories will be uploaded to remote repositories with new branch names formatted as IRM-SCRIPT-CODEMERGE-date. "
"   -y : Yes to all for errors option set. Given errors will be neglected and the process will continue. "
""
"   Example Parameter Usages: "
"   The command prompt parameter read from the file [parameter].repository.config in the conf folder. "
""
"   github : Custom Github repository configuration files will be used. "
"   repository-1 : Internet/Intranet Repository 1 configuration files will be used. "
"   repository-2 : Internet/Intranet Repository 2 configuration files will be used."
""
""
"   Example Usages: "
""
"   $ bash irm.sh -yda github "
"   $ bash irm.sh -yd github "
"   $ bash irm.sh -da github "
"   $ bash irm.sh -d github "
"   ----------------------------------------------------- "
"   $ bash irm.sh -yum -b code_merge github "
"   $ bash irm.sh -yum github "
"   $ bash irm.sh -yu github "
"   $ bash irm.sh -um -b code_merge github "
"   $ bash irm.sh -um github "
"   $ bash irm.sh -u github "
"   ----------------------------------------------------- "
"   $ bash irm.sh -y -r rc-0.23.0 github"
"   $ bash irm.sh -r rc-0.23.0 github"
"   ----------------------------------------------------- "
"   $ bash irm.sh -h "
"   $ bash irm.sh -c "
""
)

# Script Starting Path
START_PATH="$(pwd)"
SCRIPT_NAME="Inter-Repository Merge Script"

# Script Start Time
SCRIPT_START_TIME=$(date +%Y_%m_%d_%H_%M_%S)

# Created Folders and Files
OUTPUT_FOLDER="$START_PATH//outputs"
ARCHIVE_FOLDER="$OUTPUT_FOLDER//archives"
REPOSITORY_FOLDER="$OUTPUT_FOLDER//repositories"
LOG_FOLDER="$OUTPUT_FOLDER//logs"
LOG_FILE="$LOG_FOLDER//log.txt"
MERGE_LOG_FOLDER="$LOG_FOLDER//merges"

# Script Configuration Files
CONFIGURATION_FOLDER="$START_PATH//conf"
REPO_ADDR_FILE="$CONFIGURATION_FOLDER//repository.list.config"

# Script Functions
seperator_line() {
    echo "----------------------------------------------------------------------------------" | tee -a $LOG_FILE
}

custom_msg() {
    local message="$1"
    echo "[$(date +%H:%M:%S)] [INFO]    ${message}" | tee -a $LOG_FILE
}

custom_err() {
    local message="$1"
    local code="${3:-1}"
    local working_dir="$(pwd)"
    echo "[$(date +%H:%M:%S)] [ERROR] --------------------------------------------------------------------------" | tee -a $LOG_FILE
    echo "[$(date +%H:%M:%S)] [ERROR]   Working Directory: ${working_dir}" | tee -a $LOG_FILE
    echo "[$(date +%H:%M:%S)] [ERROR]   Step: ${code}" | tee -a $LOG_FILE
    echo "[$(date +%H:%M:%S)] [ERROR]   Message: ${message}" | tee -a $LOG_FILE
    echo "[$(date +%H:%M:%S)] [ERROR] --------------------------------------------------------------------------" | tee -a $LOG_FILE
}

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
err() {
    local code="${3:-1}"
    local working_dir="$(pwd)"
    echo "[ERROR]   WD: ${working_dir}, ${last_command} command filled with exit code ${code}." | tee -a $LOG_FILE
}
# echo an error message before exiting
trap 'err' ERR

custom_exit() {
    echo "[$(date +%H:%M:%S)] [EXIT] --------------------------------------------------------------------------" | tee -a $LOG_FILE
    echo "[$(date +%H:%M:%S)] [EXIT]    An ERROR occured!" | tee -a $LOG_FILE
    if [ $yes_flag -eq 0 ]; then
        read -n10 -p "[$(date +%H:%M:%S)] [EXIT]   Do you want to continue [Y/N]? " answer
        case $answer in
        Y | y | Yes | yes | YES)
            echo "[$(date +%H:%M:%S)] [EXIT]    Fine, continue on..." | tee -a $LOG_FILE
            echo "[$(date +%H:%M:%S)] [EXIT] --------------------------------------------------------------------------" | tee -a $LOG_FILE
            ;;
        N | n | No | no | NO)
            echo "[$(date +%H:%M:%S)] [EXIT]    OK, goodbye!" | tee -a $LOG_FILE
            exit
            ;;
        *)
            custom_err "Unknown option: $opt."
            exit 1
            ;;
        esac
    else
        echo "[$(date +%H:%M:%S)] [EXIT]    Yes to All option set. Fine, continue on..." | tee -a $LOG_FILE
        echo "[$(date +%H:%M:%S)] [EXIT] --------------------------------------------------------------------------" | tee -a $LOG_FILE
    fi
}

# Output Folder Operations
if [ -d $OUTPUT_FOLDER ]; then
    echo "Output folder exists: $OUTPUT_FOLDER"
else
    # New Output Folder Created
    mkdir "$OUTPUT_FOLDER" || exit
    echo "Output folder created: $OUTPUT_FOLDER"
fi

# Log Folder Operations
if [ -d $LOG_FOLDER ]; then
    echo "Log folder exists: $LOG_FOLDER"
else
    # New Log Folder Created
    mkdir "$LOG_FOLDER" || exit
    echo "Log folder created: $LOG_FOLDER"
fi

# Log File Operations
if [ -s $LOG_FILE ]; then
    echo "Log file exists: $LOG_FILE"
else
    echo "" >"$LOG_FILE" || exit
    echo "Log file created: $LOG_FILE"
fi

# Merge Log Folder Operations
if [ -d $MERGE_LOG_FOLDER ]; then
    echo "Merge Log folder exists: $MERGE_LOG_FOLDER"
else
    # New Merge Log Folder Created
    mkdir "$MERGE_LOG_FOLDER" || exit
    echo "Merge Log folder created: $MERGE_LOG_FOLDER"
fi

# Script Start Date
custom_msg "$SCRIPT_NAME Starting [$(date --rfc-3339=seconds)]"
custom_msg "Script starting path: $START_PATH"

# Script Options and Parameters
archive_flag=0
branch_flag=0
download_flag=0
merge_flag=0
release_branch_flag=0
upload_flag=0
yes_flag=0
while getopts :ab:cdhmr:uy opt; do
    case "$opt" in   
    a) 
        custom_msg "Found the -a (archive) option."
        custom_msg "Archive option set. Git repositories will be archived (*.tar.gz) to archive folder."
        archive_flag=1
        ;;
    b)
        custom_msg "Found the -b (branch) option."
        custom_msg "For the Upload operation, custom defined branch name will be used."
        CUSTOM_BRANCH_NAME=$OPTARG
        branch_flag=1
        ;;
    c)
        custom_msg "Found the -c (clean) option."
        custom_msg "Clean option set. All output folders and files will be removed!"
        if [ -d $OUTPUT_FOLDER ]; then
            rm -rf "$OUTPUT_FOLDER" || exit
        fi
        echo "Cleaning operation successfully completed."
        exit 0
        ;;
    d)
        custom_msg "Found the -d (download) option."
        custom_msg "Download option set. Defined repositories will be clone to local repository folders."
        download_flag=1
        if [ $upload_flag -eq 1 ] || [ $merge_flag -eq 1 ] || [ $release_branch_flag -eq 1 ]; then
            custom_err "You can not download/archive and upload/merge at the same time."
            custom_err "You can not use Release Candidate option with Upload and Download operations."
            exit 1
        fi
        ;;
    h)
        custom_msg "Found the -h (help) option."
        printf '%s\n' "${HELP_MSG[@]}"
        exit 0
        ;;
    m)
        custom_msg "Found the -m (merge) option."
        custom_msg "Merge option set. Uploaded remote repositories will be merged with develop branch."
        merge_flag=1
        if [ $download_flag -eq 1 ] || [ $archive_flag -eq 1 ]; then
            custom_err "You can not download/archive and upload/merge at the same time."
            exit 1
        fi
        ;;
    r)
        custom_msg "Found -r (release candidate branch) option."
        custom_msg "Creates new Release Candidate Branch from develop branch."
        if [ $branch_flag -eq 1 ] || [ $download_flag -eq 1 ] || [ $upload_flag -eq 1 ] || [ $merge_flag -eq 1 ]; then
            custom_err "You can not use Release Candidate option with Upload and Download operations."
            exit 1
        fi
        CUSTOM_BRANCH_NAME=$OPTARG
        release_branch_flag=1
        ;;
    u)
        custom_msg "Found the -u (upload) option."
        custom_msg "Upload option set. Downloaded repositories will be uploaded to remote repositories with new branch names formatted as IRM-SCRIPT-CODEMERGE-date."
        upload_flag=1
        if [ $download_flag -eq 1 ] || [ $archive_flag -eq 1 ] || [ $release_branch_flag -eq 1 ]; then
            custom_err "You can not download/archive and upload/merge at the same time."
            custom_err "You can not use Release Candidate option with Upload and Download operations."
            exit 1
        fi
        ;;
    y)
        custom_msg "Found the -y (Yes to All Error Continue) option."
        custom_msg "Yes to All Error Continue option set. Given errors will be neglected and process will continue."
        yes_flag=1
        ;;
    *)
        custom_err "Unknown option: $opt."
        exit 1
        ;;
    esac
done
shift $(($OPTIND - 1))
if [ $# -eq 0 ]; then
    custom_err "No parameters provided."
    exit 1
elif [ $# -gt 1 ]; then
    custom_err "Not correct number of parameters provided."
    exit 1
fi
for param in "$@"; do
    CONFIG_FILE="$CONFIGURATION_FOLDER//$param.repository.config"
    if [ -s $CONFIG_FILE ]; then
        custom_msg "Configuration files for $param exists: $CONFIG_FILE"
    else
        custom_err "Configuration files for $param could not found: $CONFIG_FILE"
        exit 1
    fi
done
seperator_line

# Current Working Directory
custom_msg "Current working directory: $START_PATH"
seperator_line

# Reading Repository Configuration
if [ -s $CONFIG_FILE ]; then
    source $CONFIG_FILE
    custom_msg "Configuration file ($CONFIG_FILE) found and not empty."
    if [ -n "$MAIN_GIT_REPO_ADDR" ] && [ -n "$GIT_DOWNLOAD_BRANCH" ]; then
        custom_msg "Main Git Repository Address: $MAIN_GIT_REPO_ADDR"
        custom_msg "Git Branch Name: $GIT_DOWNLOAD_BRANCH"
    else
        custom_err "Configuration file ($CONFIG_FILE) has missing information."
        exit 1
    fi
    if [ -n $CUSTOM_BRANCH_NAME ]; then
        GIT_UPLOAD_BRANCH=$CUSTOM_BRANCH_NAME
        custom_msg "Git Upload Branch: $GIT_UPLOAD_BRANCH"
    fi
else
    custom_err "Configuration file ($CONFIG_FILE) not found or empty."
    exit 1
fi
seperator_line

# Repository Folder Preprocess Operations
if [ -d $REPOSITORY_FOLDER ]; then
    custom_msg "Repositories folder exists: $REPOSITORY_FOLDER"
    if [ $download_flag -eq 1 ] || [ $release_branch_flag -eq 1 ]; then
        custom_err "Download operation can not be performed. Please check the options (-d or -u) and restart the script."
        custom_err "Repositories folder must be deleted to perform download operation. To remove repositories folder use -c option."
        exit 1
    fi
else
    if [ $upload_flag -eq 1 ] || [ $merge_flag -eq 1 ]; then
        custom_err "Upload operation can not be performed. Please check the options (-d or -u) and restart the script."
        custom_err "Repositories folder must be available to perform upload operation. Firstly, you must download repositories."
        exit 1
    elif [ $download_flag -eq 1 ] || [ $release_branch_flag -eq 1 ]; then
        # New Repository Folder Created
        mkdir "$REPOSITORY_FOLDER" || exit
        custom_msg "New repository folder created: $REPOSITORY_FOLDER"
    fi
fi
seperator_line
cd "$REPOSITORY_FOLDER" || exit

# Archive Folder Operations
if [ $archive_flag -eq 1 ]; then
    if [ -d $ARCHIVE_FOLDER ]; then
        custom_msg "Archive folder exists: $REPOSITORY_FOLDER"
        if [ $download_flag -eq 1 ]; then
            custom_err "Archive operation can not be performed. Please check the options (-d or -u) and restart the script."
            custom_err "Archives folder must be deleted to perform download operation. To remove archives folder use -c option."
            exit 1
        fi
    else
        if [ $download_flag -eq 1 ]; then
            # New Archive Folder Created
            mkdir "$ARCHIVE_FOLDER" || exit
            custom_msg "New Archive folder created: $ARCHIVE_FOLDER"
        fi
    fi
fi
seperator_line

# Installed Software Versions
custom_msg "Installed Software Versions"
custom_msg "Git Version:"
git --version | tee -a $LOG_FILE || exit

# Git User Information Fetch and IRM Script Modification
GIT_USER_NAME="$(git config --local --get user.name)"
GIT_USER_EMAIL="$(git config --local --get user.email)"
git config --local user.name "[IRM-SCRIPT]"
git config --local user.email "irm.script@company.com.tr"

# Inter Field Seperator (IFS) Modification
IFS_OLD="$IFS"
IFS=$'\n\r'

# Repository Addresses
if [ -s $REPO_ADDR_FILE ]; then
    for repo_add in $(cat $REPO_ADDR_FILE); do
        if [ -n "$repo_add" ]; then
            if [ $download_flag -eq 1 ] && [ $upload_flag -eq 0 ] && [ $merge_flag -eq 0 ]; then
                custom_msg "Processing repository name: $repo_add"
                temp_repository_name="$repo_add"
                cd "$REPOSITORY_FOLDER" || exit
                git clone "$MAIN_GIT_REPO_ADDR$temp_repository_name" | tee -a $LOG_FILE
                # Entering repository folder
                cd "$REPOSITORY_FOLDER//$temp_repository_name" || custom_exit
                custom_msg "Current Working Folder: $(pwd)"
                git remote -v | tee -a $LOG_FILE
                git checkout "$GIT_DOWNLOAD_BRANCH" | tee -a $LOG_FILE
                git pull --all | tee -a $LOG_FILE
                git fetch --all | tee -a $LOG_FILE
                git branch --all | tee -a $LOG_FILE
                git describe --all | tee -a $LOG_FILE
                # Exiting repository folder
                cd ..
                custom_msg "Git process completed for: $temp_repository_name"
                if [ $archive_flag -eq 1 ]; then
                    tar cvzf "$ARCHIVE_FOLDER//$temp_repository_name.tar.gz" "$REPOSITORY_FOLDER//$temp_repository_name" || custom_exit
                    custom_msg "Archive process completed for: $temp_repository_name"
                fi
                seperator_line
            fi
            if [ $download_flag -eq 0 ] && [ $upload_flag -eq 1 ]; then
                custom_msg "Processing repository name: $repo_add"
                temp_repository_name="$repo_add"
                cd "$REPOSITORY_FOLDER" || exit
                # Entering repository folder
                cd "$REPOSITORY_FOLDER//$temp_repository_name" || custom_exit
                custom_msg "Current Working Folder: $(pwd)"
                git remote -v | tee -a $LOG_FILE
                git remote set-url origin "$MAIN_GIT_REPO_ADDR$temp_repository_name" | tee -a $LOG_FILE
                git remote -v | tee -a $LOG_FILE
                if [ $branch_flag -eq 1 ]; then
                    git checkout -b "$GIT_UPLOAD_BRANCH" | tee -a $LOG_FILE
                else
                    git checkout -b "IRM-SCRIPT-CODEMERGE-$SCRIPT_START_TIME" | tee -a $LOG_FILE
                fi
                git branch --all | tee -a $LOG_FILE
                git pull --all | tee -a $LOG_FILE
                if [ $merge_flag -eq 1 ]; then
                    git merge origin "$GIT_DOWNLOAD_BRANCH" | tee -a "$MERGE_LOG_FOLDER//$temp_repository_name.txt"
                    git pull --all | tee -a $LOG_FILE
                fi
                if [ $branch_flag -eq 1 ]; then
                    git push --set-upstream origin "$GIT_UPLOAD_BRANCH" | tee -a $LOG_FILE
                else
                    git push --set-upstream origin "IRM-SCRIPT-CODEMERGE-$SCRIPT_START_TIME" | tee -a $LOG_FILE
                fi
                # Exiting repository folder
                cd ..
                seperator_line
            fi
            if [ $release_branch_flag -eq 1 ]; then
                custom_msg "Processing repository name: $repo_add"
                temp_repository_name="$repo_add"
                cd "$REPOSITORY_FOLDER" || exit
                git clone "$MAIN_GIT_REPO_ADDR$temp_repository_name" | tee -a $LOG_FILE
                # Entering repository folder
                cd "$REPOSITORY_FOLDER//$temp_repository_name" || custom_exit
                custom_msg "Current Working Folder: $(pwd)"
                git remote -v | tee -a $LOG_FILE
                git checkout "$GIT_UPLOAD_BRANCH" | tee -a $LOG_FILE
                git pull --all | tee -a $LOG_FILE
                git fetch --all | tee -a $LOG_FILE
                git branch --all | tee -a $LOG_FILE
                git describe --all | tee -a $LOG_FILE
                git push --set-upstream origin "$GIT_UPLOAD_BRANCH" | tee -a $LOG_FILE
                # Exiting repository folder
                cd ..
                seperator_line
            fi
        fi
    done
else
    custom_err "Repository addresses file ($REPO_ADDR_FILE) not found."
    exit 1
fi

# Git User Information Modification
git config --local user.name "$GIT_USER_NAME"
git config --local user.email "$GIT_USER_EMAIL"

# Inter Field Seperator (IFS) Modification
IFS="$IFS_OLD"

# Main Folder Return
cd "$START_PATH"