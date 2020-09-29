# to run this file
# do 
# bundle exec ruby dameon.rb
require 'daemons'

Daemons.run('runner.rb')

# to run as a deamon : -> 
# ruby server_control.rb start

# to stop the daemon:
# ruby server_control.rb stop