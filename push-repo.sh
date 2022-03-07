#!/bin/bash

WORK_PATH=$(dirname $(readlink -f $0))

source config.sh

TOKEN=Y2y6wW3_uDExGdmt_--H

# 新GitLab API token
NEW_TOKEN=Hky-4_UzF4xiLHZNwwdx

for gp in ${GROUP[@]}
do
    group_info=$(curl --insecure --request GET "https://git.cchntek.com/api/v4/groups?search=$gp" \
        --header "Authorization: Bearer $TOKEN" | jq -c '[ .[] | {"id":.id}]')

    group_id=$(echo $group_info | jq -c ".[] .id" )

    group_dirs=$(ls -l $WORK_PATH/$gp |awk '/^d/ {print $NF}')

    for repo in ${group_dirs[@]}
    do
        cd $WORK_PATH/$gp/$name

        # 修改remote url
        git remote set-url origin git@git.1688898.xyz:$gp/$name.git

        for br in ${BRANCH[@]}
        do
            git checkout $br
            git push -u origin $br
        done

    done

    exit
done