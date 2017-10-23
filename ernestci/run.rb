require 'optparse'
require_relative 'lib/options'

build_params = extra_options(ARGV[0])
extra_features = "#{ARGV[1]}" if ARGV.length > 0

options = {}
OptionParser.new do |opt|
	opt.on('--enterprise') { |o| options[:enterprise] = o }
end.parse!

cli_version = build_params[:build_parameters]['CLI_VERSION']
base_version = build_params[:build_parameters]['BASE_VERSION']
extra_options = build_params[:build_parameters]['EXTRA_OPTIONS']
default_version = "master"
default_version = "develop" if base_version != "master"
extra_options = "#{extra_options} --edition enterprise" if options[:enterprise]

# clone ernest repo
`mkdir -p $ROOTPATH`
`cd $ROOTPATH && git clone -b #{base_version} git@github.com:ernestio/ernest.git`

# composable
`$ROOTPATH/ernest/internal/ci_install_service.sh r3labs composable master`
`composable set build.path /tmp/composable`
`mkdir -p /tmp/composable`
`cd $ROOTPATH/ernest && composable generate -G #{default_version} -E ERNEST_CRYPTO_KEY=$ERNEST_CRYPTO_KEY -exclude='*-aws-connector,*-vcloud-connector,*-azure-connector' #{extra_options} definition.yml template.yml`

# cli
`$ROOTPATH/ernest/internal/ci_install_service.sh ernestio ernest-cli #{cli_version}`

# install ernest
system("cd $ROOTPATH/ernest && ERNESTHOSTNAME=localhost ERNESTUSER=ci_admin ERNESTPASSWORD=secret123 ./setup")

`cp -R #{extra_features} $ROOTPATH/ernest/internal/features/` if not extra_features.to_s.empty?

# run tests
`$ROOTPATH/ernest/internal/ci_setup.sh`
exec("cd $ROOTPATH/ernest && make dev-deps && make test")
