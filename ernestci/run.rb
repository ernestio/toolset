require 'optparse'
require_relative 'lib/options'
require "slack-ruby-client"

build_params = extra_options(ARGV[0])
extra_features = "#{ARGV[1]}" if ARGV.length > 0

options = {}
OptionParser.new do |opt|
	opt.on('--enterprise') { |o| options[:enterprise] = true }
end.parse!

cli_version = build_params[:build_parameters]['CLI_VERSION']
base_version = build_params[:build_parameters]['BASE_VERSION']
extra_options = build_params[:build_parameters]['EXTRA_OPTIONS']
default_version = "master"
default_version = "develop" if base_version != "master"
extra_options = "#{extra_options} --edition enterprise" if options.key?(:enterprise)

# clone ernest repo
`mkdir -p $ROOTPATH`
`cd $ROOTPATH && git clone -b #{base_version} git@github.com:ernestio/ernest.git`

# composable
`$ROOTPATH/ernest/internal/ci_install_service.sh r3labs composable master`
`composable set build.path /tmp/composable`
`mkdir -p /tmp/composable`
`cd $ROOTPATH/ernest && composable generate -G #{default_version} -E ERNEST_CRYPTO_KEY=$ERNEST_CRYPTO_KEY -X '*-aws-connector,*-vcloud-connector,*-azure-connector' #{extra_options} definition.yml template.yml`

# cli
`$ROOTPATH/ernest/internal/ci_install_service.sh ernestio ernest-cli #{cli_version}`

# install ernest
system("cd $ROOTPATH/ernest && ERNESTHOSTNAME=localhost ERNESTUSER=ci_admin ERNESTPASSWORD=secret123 ./setup")

`cp -R #{extra_features} $ROOTPATH/ernest/internal/features/` if not extra_features.to_s.empty?
`cd $ROOTPATH/ernest && make dev-deps`

if ENV.key? 'SLACK_API_TOKEN'
	# Replace original gucumber by r3labs
	`rm -rf ~/.go_workspace/src/github.com/gucumber/gucumber/`
	`mkdir -p ~/.go_workspace/src/github.com/gucumber && cd ~/.go_workspace/src/github.com/gucumber/ && git clone git@github.com:r3labs/gucumber.git && go get github.com/stretchr/testify`
	`cd ~/.go_workspace/src/github.com/gucumber/gucumber/cmd/gucumber && go build -a`
	`mv ~/.go_workspace/src/github.com/gucumber/gucumber/cmd/gucumber/gucumber /home/circleci/.go_workspace/bin/gucumber`
end

# run tests
`$ROOTPATH/ernest/internal/ci_setup.sh`


def finished? l
  l.include?("Finished") &&
  l.include?("passed") &&
  l.include?("failed") &&
  l.include?("skipped")
end
output = []

line = ""
sw = false
status = 0
process = IO.popen("cd $ROOTPATH/ernest && make test") do |io|
	while line = io.gets
		sw = true if finished?(line)
		output << line if sw
		line.chomp!
		puts line
	end
	io.close
	status = $?.to_i
	puts "+++++++++++++"
	puts "+++++++++++++"
	puts "+++++++++++++"
	puts status
	puts "+++++++++++++"
	puts "+++++++++++++"
	puts "+++++++++++++"
end

=begin
sw = false
line = ""
status = 0
IO.popen("cd $ROOTPATH/ernest && make test").each do |l|
	puts line
	sw = true if finished?(line)
	output << line if sw
	line = l.chomp
	status = $?.to_i if status == 0
end
status = $?.to_i if status == 0
puts line
=end

if output.length > 1
  if ENV.key? 'SLACK_API_TOKEN'
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
    puts ENV['SLACK_API_TOKEN']
    o = "Oops! something is broken on #{ENV['CI_PULL_REQUESTS']}\n"
    o += "```\n"
    output.each do |l|
      l = l.gsub("[0;0m", "")
      l = l.gsub("[0;1m", "")
      l = l.gsub("[39;0m", "")
      o += "#{l} \n"
    end
    o += "```"
    client = Slack::Web::Client.new
    client.auth_test

    client.chat_postMessage(channel: '#drone', text: o, as_user: true)
	end
end

puts ("---------------")
puts ("---------------")
puts ("---------------")
puts ("---------------")
puts status
puts ("---------------")
puts ("---------------")
puts ("---------------")
exit(status.to_i)
