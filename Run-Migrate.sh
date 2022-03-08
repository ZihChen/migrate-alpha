#!/bin/bash

WORK_PATH=$(dirname $(readlink -f $0))
readonly WORK_PATH

# 舊GitLab API token
TOKEN=Y2y6wW3_uDExGdmt_--H

# 新GitLab API token
NEW_TOKEN=Hky-4_UzF4xiLHZNwwdx

source config.sh

Init() {
    for gp in ${GROUP[@]}
    do
        mkdir -p $gp
    done
}

FetchRepoInfo(){

    for gp in ${GROUP[@]}
    do
        printf "\E[1;33m"
        echo -e "\n<===== 開始拉取$gp專案 =====>\n"
        printf "\E[0m"
            ## Repository Page
            repoPage=1
            while true
            do
                repoList=$(curl --insecure --request GET "https://git.cchntek.com/api/v4/groups/$gp/projects?page=$repoPage" \
                --header "Authorization: Bearer $TOKEN" | jq -c '[ .[] | {"http_url_to_repo":.http_url_to_repo,"name":.name,"description":.description,"group":.namespace.name} ]')
                ## 如果該頁沒資料，直接結束腳本
                if [[ $repoList == [] ]]
                then
                    echo "repoList 沒資料了!"
                    break
                fi

                ## 取得新GitLab group_id
                group_info=$(curl --insecure --request GET "https://git.1688898.xyz/api/v4/groups?search=$gp" \
                    --header "Authorization: Bearer $NEW_TOKEN" | jq -c '[ .[] | {"id":.id}]')
                group_id=$(echo $group_info | jq -c ".[] .id" )

                SyncRepo $repoList $gp

                PushToRemoteRepo $repoList $group_id

                (( repoPage++ ))
            done
        printf "\E[1;33m"
        echo -e "\n<===== $gp同步完畢! =====>\n"
        printf "\E[0m"
    done
}

SyncRepo(){

    count=$(echo $repoList | jq length)

    for ((i=0;i < $count; i++))
    do
        name=$(echo $repoList | jq -c ".[$i] .name" | sed s/\"//g)
        group=$(echo $repoList | jq -c ".[$i] .group" | sed s/\"//g)
        http_url_to_repo=$(echo $repoList | jq -c ".[$i] .http_url_to_repo" | sed s/\"//g)

        repo_dir=$WORK_PATH/$group

        if [ -d $repo_dir/$name ]
        then
            # 專案存在則對每個分支做pull
            printf "\E[1;32m"
            echo -e "\n<===== $group/$name已存在，進行pull =====>"
            printf "\E[0m"

            cd $repo_dir/$name

            # 修改remote url
            git remote set-url origin git@git.cchntek.com:$gp/$name.git

            # 對每個分支進行pull
            for br in ${BRANCH[@]}
            do
                git checkout $br
                git pull
            done

        else
            # 專案不存在則做clone
            printf "\E[1;32m"
            echo -e "\n<===== $group/$name不存在 - 進行clone =====>"
            printf "\E[0m"

            cd $repo_dir

            git clone $http_url_to_repo

            cd $repo_dir/$name

            for br in ${BRANCH[@]}
            do
            git checkout -b $br origin/$br
            done
        fi
        printf "\E[1;32m"
        echo -e "<===== $group/$name已同步至本地端 =====>\n"
        printf "\E[0m"
    done
}

PushToRemoteRepo(){
    count=$(echo $repoList | jq length)

    for ((i=0;i < $count; i++))
    do
        name=$(echo $repoList | jq -c ".[$i] .name" | sed s/\"//g)
        group=$(echo $repoList | jq -c ".[$i] .group" | sed s/\"//g)
        description=$(echo $repoList | jq -c ".[$i] .description" | sed s/\"//g)

        printf "\E[1;32m"
        echo -e "\n<===== $group/$name開始同步至遠端Repo =====>"
        printf "\E[0m"

        cd $WORK_PATH/$group/$name

        check_repo=$(curl --insecure --request GET "https://git.1688898.xyz/api/v4/groups/$gp/projects?search=$name" \
        --header "Authorization: Bearer $NEW_TOKEN")

        # 修改remote url
        git remote set-url origin git@git.1688898.xyz:$gp/$name.git

        if [[ $check_repo == [] ]]
        then
            curl --silent --insecure --request POST 'https://git.1688898.xyz/api/v4/projects' \
                                --header "Authorization: Bearer $NEW_TOKEN" \
                                --form "name=$name" \
                                --form "path=$name" \
                                --form "namespace_id=$group_id" \
                                --form "description=$description"
            
            for br in ${BRANCH[@]}
            do
                git checkout $br
                git push -u origin $br
            done
        else
            for br in ${BRANCH[@]}
            do
                git checkout $br
                git push
            done
        fi

        printf "\E[1;32m"
        echo -e "<===== $group/$name已同步至遠端Repo =====>\n"
        printf "\E[0m"
    done
}

# 創建基礎目錄
Init

# 取得舊專案最新資訊
FetchRepoInfo


