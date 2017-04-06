require 'circleci'
require_relative 'lib/options'

abort "CIRCLE_TOKEN env var not set" if ENV['CIRCLE_TOKEN'].empty?

CircleCi.configure do |config|
  config.token = ENV['CIRCLE_TOKEN']
end


# Build Ernest integration tests
build_params = extra_options(ARGV[0])
puts "Executing remote build with parameters : #{build_params}"
project = CircleCi::Project.new(ENV['CIRCLE_PROJECT_USERNAME'], 'ernest')
res = project.build_branch 'develop', {}, build_params
url = res.body['build_url']

build = CircleCi::Build.new(ENV['CIRCLE_PROJECT_USERNAME'], 'ernest', res.body['build_num'])
puts "Checking related build #{url}"
loop do
  res = build.get
  break unless ['running', 'not_running', 'queued'].include? res.body['status']
  putc '.'
  sleep 10
end
puts res.body['status']
abort "Integration tests are broken (#{url})" if res.body['status'] == 'failed'
abort "Integration tests are broken (#{url})" unless res.success?


