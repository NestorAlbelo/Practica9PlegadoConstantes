desc "Run server"
task :default => [:use_keys, :clean, :jison] do
  sh "rackup"
end

desc "Save config.yml out of the CVS"
task :keep_secrets do
  sh "cp config/config_template.yml config/config.yml "
end

desc "Use the filled client_secrets"
task :use_keys do
  sh "cp config/config_filled.yml config/config.yml"
end

desc "Go to console.developers.google"
task :link do
  sh "open https://console.developers.google.com/project/apps~sinatra-ruby-gplus/apiui/api"
end

desc "Commit changes"
task :ci, [ :message ] => :keep_secrets do |t, args|
  message = args[:message] || ''
  sh "git commit -a -m '#{message}'"
end

task :jison => %w{public/pl0.js} 

desc "Compile the grammar public/pl0.jison"
file "public/pl0.js" => %w{public/pl0.jison} do
  sh "jison public/pl0.jison public/pl0.l -o public/pl0.js"
end

desc "Compile the sass public/styles.scss"
task :css do
  sh "sass public/styles.scss public/styles.css"
end

task :testf do
  sh " open -a firefox test/test.html"
end

task :tests do
  sh " open -a safari test/test.html"
end

desc "Remove pl0.js"
task :clean do
  sh "rm -f public/pl0.js"
end

desc "Open browser in GitHub repo"
task :github do
  sh "open https://github.com/crguezl/ull-etsii-grado-pl-jisoncalc"
end
