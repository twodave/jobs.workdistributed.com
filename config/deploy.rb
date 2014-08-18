# config valid only for Capistrano 3.1
lock '3.2.1'
require 'rubygems'
require 'sitemap_generator'
set :application, 'workdistributed.com'
set :repo_url, 'git@bitbucket.org:twodave/workdistributed.com.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/deploy/workdistributed.com'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
      execute "cd #{fetch(:deploy_to)}/current/ && (RBENV_ROOT=~/.rbenv RBENV_VERSION=2.0.0-p481 ~/.rbenv/bin/rbenv exec rails runner sitemap.rb)"
    end
  end

  after :finishing, 'deploy:restart'
end