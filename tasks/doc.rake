desc "Recompiles all the doc"
task :doc => [:txt, :man, :html]
