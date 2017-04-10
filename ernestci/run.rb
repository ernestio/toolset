require_relative 'lib/options'

build_params = extra_options(ARGV[0])
cli_version = build_params[:build_parameters]['CLI_VERSION']
base_version = build_params[:build_parameters]['BASE_VERSION']
extra_options = build_params[:build_parameters]['EXTRA_OPTIONS']
default_version = "master"
default_version = "develop" if base_version != "master"

# Install docker compose
`curl -L https://github.com/docker/compose/releases/download/1.10.0/docker-compose-\`uname -s\`-\`uname -m\` > /home/ubuntu/bin/docker-compose`
`chmod +x /home/ubuntu/bin/docker-compose`


# Prepare environment
`export NATS_URI=nats://127.0.0.1:4222`
`export NATS_URI_TEST=nats://127.0.0.1:4222`
`export GOBIN=/home/ubuntu/.go_workspace/bin`
`export CURRENT_INSTANCE=http://ernest.local:80/`
`export JWT_SECRET=test`
`export IMPORT_PATH=github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME`
`export ERNEST_APPLY_DELAY=1`
`export ERNEST_CRYPTO_KEY=mMYlPIvI11z20H1BnBmB223355667788`
`export ROOTPATH=/home/ubuntu/.go_workspace/src/github.com/ernestio`


# Clone ernestio/ernest
`mkdir -p $ROOTPATH`
`cd $ROOTPATH && git clone -b #{base_version} git@github.com:ernestio/ernest.git`
`$ROOTPATH/ernest/internal/ci_install_service.sh r3labs natsc master`
`$ROOTPATH/ernest/internal/ci_install_service.sh r3labs composable master`
`$ROOTPATH/ernest/internal/ci_install_service.sh ernestio ernest-cli #{cli_version}`
`mkdir -p /tmp/composable`
`sed -i "s:443 ssl:80:g" $ROOTPATH/ernest/config/nginx/ernest.local`
`sed -i "s:ERNESTHOST:ernest.local:g" $ROOTPATH/ernest/config/nginx/ernest.local`
`sed -i "/ssl_certificate/d" $ROOTPATH/ernest/config/nginx/ernest.local`
`sed -i "s:443:80:g" $ROOTPATH/ernest/template.yml`

# Build ernest on specific versions
`cd $ROOTPATH/ernest && composable gen -E ERNEST_CRYPTO_KEY=$ERNEST_CRYPTO_KEY -exclude='*-aws-connector,*-vcloud-connector' -G #{default_version} #{extra_options} definition.yml template.yml --`
`cd $ROOTPATH/ernest && docker-compose -f docker-compose.yml up -d`

# Run ernestio/ernest tests
`$ROOTPATH/ernest/internal/ci_setup.sh`
exec("cd $ROOTPATH/ernest && make dev-deps && make test")
