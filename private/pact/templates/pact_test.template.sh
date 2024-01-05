#!/usr/bin/env bash
_healthCheck () {
    echo "starting health check of $2"
    healthy="503"
    if [ $1 == "nop" ]; then healthy="200" && echo "health check ignored"; fi
    attempt=0
    until [ $healthy = "200" ]
    do
     healthy=$(curl -s -o /dev/null -w "%{http_code}" $1)
     echo "health check of $2 not ok, will recheck in 1 sec.."
     sleep 1
    done
}
echo "### Copying libpact_ffi"
cp {libpact_ffi} $(dirname $(dirname {run_consumer_test}))
cp {libpact_ffi} .

echo "### Copying plugin protobuf-0.3.5 ###"
mkdir -p protobuf-0.3.5
cp {manifest} protobuf-0.3.5
cp {plugin} pact-protobuf-plugin
mv pact-protobuf-plugin protobuf-0.3.5
export PACT_PLUGIN_DIR=$(pwd)

echo "### Running Consumer Tests ###"
./{run_consumer_test}

echo "### Fetch Contract Path ###"
contract_path=$(dirname $(dirname {run_consumer_test}))/pacts/{contract}.json
if [ "{debug}" == "op" ]
then
  cat "${contract_path}"
fi
echo "### Preparing Pact Verifier CLI args ###"
pact_verifier_cli_args=$(cat {pact_verifier_cli_opts} || echo "--help")
side_car_cli_args=$(cat {side_car_opts} || echo "")
cli_args="$side_car_cli_args -f $contract_path $pact_verifier_cli_args"
echo "### Preparing env variables from Provider ###"
while read first_line; read second_line
do
    export "$first_line"="$second_line"
done < {env_side_car}
echo "### Starting Provider ###"
nohup {provider_bin} &
echo "### Starting SideCar as State Manager ###"
nohup {side_car_bin} &
echo "### Health Check SideCar ###"
_healthCheck $(cat {health_check_side_car}) "side_car"

echo "### Running Pact test $contract on Provider"
./{pact_verifier_cli} $cli_args
