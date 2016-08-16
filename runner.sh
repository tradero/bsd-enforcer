#!/bin/sh

port=22
target=$1; shift
master_key=$(cat ~/.ssh/id_rsa.pub)

SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=5"

while getopts ":p:" opt; do
    case $opt in
    p)
        port=$OPTARG
        ;;
    \?)
        echo "invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND -1))

check_error () {
    if [ $1 -gt 0 ]; then
        echo "exit code: $1"
        exit $1
    fi
}

execute () {
    while [ 1 ]; do
        ssh $SSH_OPTS -n -t -t $target -p $port $1
        exitCode=$?

        if [ $exitCode -gt 0 ]; then
            if [ $exitCode -eq 255 ]; then
                echo "exit code: $exitCode"
                sleep 3
            else
                echo "exit code: $exitCode" 
                exit $exitCode
            fi
        else
            break
        fi
    done
}

scp $SSH_OPTS -P $port init.sh    $target:/root/init.sh    || check_error $?
execute "/bin/sh /root/init.sh"
execute "reboot"

scp $SSH_OPTS -P $port install.sh $target:/root/install.sh || check_error $?
execute "/bin/sh /root/install.sh"
execute "reboot"

execute "uname -a; zpool status"



/usr/bin/expect -c 'expect "\n" { eval spawn ssh -oStrictHostKeyChecking=no -oCheckHostIP=no usr@$myhost.example.com; interact }'
