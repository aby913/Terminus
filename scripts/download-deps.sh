PLATFORM=${1:-linux/amd64}

arch="amd64"
if [ x"$PLATFORM" == x"linux/arm64" ]; then
    arch="arm64"
fi


part=""
CURL_TRY="--connect-timeout 30 --retry 5 --retry-delay 1 --retry-max-time 10 "

cat ./dependencies.mf | while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    case "$line" in
        *\[components\]*)
            part="components"
            mkdir -p "${part}"
            continue
            ;;
        *\[pkg\]*)
            part="pkg"
            mkdir -p "${part}"
            continue
            ;;
        *)
            ;;
    esac

    if [ -z "$part" ]; then
        exit 1
    fi

    s1=$(echo "$line" | cut -d',' -f1)
    s2=$(echo "$line" | cut -d',' -f2)
    s3=$(echo "$line" | cut -d',' -f3)

    file=$(echo "$s1" | rev | cut -d'/' -f1 | rev)

    if [ "$part" == "components" ]; then
        if [ -z "$s2" ]; then
            echo "---com / 1--- ${file}"
            curl ${CURL_TRY} -L -o ./${part}/${file} ${s1}
        else
            echo "---com / 2--- ${s2}"
            curl ${CURL_TRY} -L -o ./${part}/${s2} ${s1}

            if [ ${s2} == "redis-5.0.14.tar.gz" ]; then
                cd ${part} && tar xvf ${s2} && cd redis-5.0.14 && make && make install && cd .. && rm -rf redis-5.0.14 && mkdir redis-5.0.14 && cp /usr/bin/redis* ./redis-5.0.14 && tar cvf ./redis-5.0.14.tar.gz ./redis-5.0.14/
            fi
        fi
    else
        s4=$(echo "$line" | cut -d',' -f4)
        pkgpath="./${part}/${s2}/${arch}"
        mkdir -p ${pkgpath}
        filename=${file}
        if [ ! -z ${s3} ]; then
            filename=${s3}
        fi
        curl ${CURL_TRY} -L -o ${pkgpath}/${filename} ${s1}
        # echo "---filename--- ${filename}"
        # echo "---s1--- ${s1}"
        # echo "---s2--- ${s2}"
        # echo "---s3--- ${s3}"
        # echo "---s4--- ${s4}"
        if [ "$s4" == "helm" ]; then
            pushd ${pkgpath}
            tar -zxvf ./${filename} && cp ./linux-${arch}/helm ./ && rm -rf ./linux-${arch} && rm -rf ./${filename}
            popd
        fi
    fi
done

echo "---done---"
pwd