require 'circleci'

abort "CIRCLE_TOKEN env var not set" if ENV['CIRCLE_TOKEN'].empty?

CircleCi.configure do |config|
  config.token = ENV['CIRCLE_TOKEN']
end

def extra_options(path)
  extra_options = []
  build_params = { build_parameters: {}}
  if ["develop", "master"].include? ENV['CIRCLE_BRANCH'] 
    repos = []
  else
    repos = File.readlines(path)
  end
  repos << "#{ENV['CIRCLE_PROJECT_REPONAME']}:#{ENV['CIRCLE_BRANCH']}"
  repos.each do |repo|
    repo = repo.gsub("\n", "")
    if repo != "" 
      parts = repo.split(":")
      if parts.first == "ernest"
        build_params[:build_parameters]['BASE_VERSION'] = parts.last
      elsif parts.first == "ernest-cli"
        build_params[:build_parameters]['CLI_VERSION'] = parts.last
      else
        extra_options << repo
      end
    end
  end
  if extra_options.length > 0 
    opts = extra_options.join(",")
    build_params[:build_parameters]['EXTRA_OPTIONS'] = "-b #{opts}"
  end
  build_params
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


