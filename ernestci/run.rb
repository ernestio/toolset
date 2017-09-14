require_relative 'lib/options'

extra_features = licensed = ''

build_params = extra_options(ARGV[0])
extra_features = "#{ARGV[1]}" if ARGV.length > 0
licensed = ARGV[2] if ARGV.length > 1

cli_version = build_params[:build_parameters]['CLI_VERSION']
base_version = build_params[:build_parameters]['BASE_VERSION']
extra_options = build_params[:build_parameters]['EXTRA_OPTIONS']
default_version = "master"
default_version = "develop" if base_version != "master"

# Prepare environment
`export NATS_URI=nats://127.0.0.1:4222`
`export NATS_URI_TEST=nats://127.0.0.1:4222`
`export GOBIN=/home/circleci/.go_workspace/bin`
`export CURRENT_INSTANCE=http://ernest.local:80/`
`export JWT_SECRET=test`
`export IMPORT_PATH=github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME`
`export ERNEST_APPLY_DELAY=1`
`export ERNEST_CRYPTO_KEY=mMYlPIvI11z20H1BnBmB223355667788`
`export ROOTPATH=/home/circleci/.go_workspace/src/github.com/ernestio`

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
`cd $ROOTPATH/ernest && cat premium.yml >> definition.yml` if not licensed.to_s.empty?
env_variables = "-E ERNEST_CRYPTO_KEY=$ERNEST_CRYPTO_KEY"
env_variables = "#{env_variables},ERNEST_PREMIUM=#{licensed.to_s}" if not licensed.to_s.empty?
`cd $ROOTPATH/ernest && composable set build.path /tmp/composable`
`cd $ROOTPATH/ernest && composable generate #{env_variables} -exclude='*-aws-connector,*-vcloud-connector,*-azure-connector' -G #{default_version} #{extra_options} definition.yml template.yml --`
`cd $ROOTPATH/ernest && docker-compose -f docker-compose.yml up -d`
`cp -R #{extra_features} $ROOTPATH/ernest/internal/features/` if not extra_features.to_s.empty?

# Run ernestio/ernest tests
`$ROOTPATH/ernest/internal/ci_setup.sh`
exec("cd $ROOTPATH/ernest && make dev-deps && make test")
