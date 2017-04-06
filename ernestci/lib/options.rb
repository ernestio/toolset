def extra_options(path)
  extra_options = []
  build_params = { build_parameters: {
		'BASE_VERSION' => 'develop',
		'CLI_VERSION' => 'develop'
	}}
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
