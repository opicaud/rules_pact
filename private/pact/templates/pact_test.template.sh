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
cp {libpact_ffi} $(dirname $(dirname {run_consumer_test}))
cp {libpact_ffi} .
echo "### Running Consumers Tests ###"
mkdir -p protobuf-0.3.5
cp {manifest} protobuf-0.3.5
cp {plugin} pact-protobuf-plugin
mv pact-protobuf-plugin protobuf-0.3.5
export PACT_PLUGIN_DIR=$(pwd)
./{run_consumer_test}
echo "### Running Providers Tests On Contracts ###"
contract_path=$(dirname $(dirname {run_consumer_test}))/pacts/{contract}.json
if [ "{debug}" == "op" ]
then
  cat "${contract_path}"
fi
pact_verifier_cli_args=$(cat {pact_verifier_cli_opts} || echo "--help")
side_car_cli_args=$(cat {side_car_opts} || echo "")
cli_args="$side_car_cli_args -f $contract_path $pact_verifier_cli_args"
while read first_line; read second_line
do
    export "$first_line"="$second_line"
done < {env_side_car}
nohup {provider_bin} &
echo "Provider started.."
nohup {side_car_bin} &
echo "State manager started.."
_healthCheck $(cat {health_check_side_car}) "side_car"
echo "Now running provider on $contract"
./{pact_verifier_cli} $cli_args
