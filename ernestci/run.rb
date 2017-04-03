require 'circleci'


CircleCi.configure do |config|
  config.token = ENV['CIRCLE_TOKEN']
end

def extra_options(path)
  return '' if ["develop", "master"].include? ENV['CIRCLE_BRANCH'] 
  repos = File.readlines(path)
  repos << "#{ENV['CIRCLE_PROJECT_REPONAME']}:#{ENV['CIRCLE_BRANCH']}"
  options = repos.join(",").gsub("\n","")
  "-b #{options}"
end

# Build Ernest integration tests
path = ARGV[0]
build_params = { build_parameters: { 'EXTRA_OPTIONS' => extra_options(path) } }
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


