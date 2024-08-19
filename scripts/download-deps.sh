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
            curl ${CURL_TRY} -L -o ./${part}/${file} ${s1}
            cp ./${part}/${file} ../
        else
            curl ${CURL_TRY} -L -o ./${part}/${s2} ${s1}

            if [ ${s2} == "redis-5.0.14.tar.gz" ]; then
                pushd ${part}
                tar xvf ${s2} && cd redis-5.0.14 && make && make install && cd ..
                rm -rf redis-5.0.14 && mkdir redis-5.0.14 && cp /usr/local/bin/redis* ./redis-5.0.14/
                tar cvf ./redis-5.0.14.tar.gz ./redis-5.0.14/ && rm -rf ./redis-5.0.14/
                cp ./redis-5.0.14.tar.gz ../
                popd
            else
                cp ./${part}/${s2} ../
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
        if [ "$s4" == "helm" ]; then
            pushd ${pkgpath}
            tar -zxvf ./${filename} && cp ./linux-${arch}/helm ./ && rm -rf ./linux-${arch} && rm -rf ./${filename}
            cp ./helm ./${part}/../
            popd
        else
            cp ${pkgpath}/${filename} ./${part}/../
        fi
    fi
done

echo "done..."
p=$(pwd)
echo "current dir: ${p}"
echo "file list:"
ls
echo "file tree:"
tree ./