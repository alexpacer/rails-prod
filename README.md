# Rails Container configuration for production 


This is the setup that I use for the next rails production  application. The point for this setup is that I want to keep nginx and unicorn on same container rather then sepearate ones (although this may not be suitable for some production cases).


## Supervisor

As containers are mostly surving a single process at time, Supervisor is used to manage multiple processeses running on this container: nginx (& unicorn later when we use this image to deploy our app). 

When using this image, you should add program of rails process in `/etc/supervisor.d/*.ini` so supervisor will pick it up

a sample of `unicorn.ini`:

    [program:unicorn]
    command=/app/bin/bundle exec unicorn -c /app/config/unicorn.rb -E production
    process_name=%(program_name)s
    autostart=true

##  Nginx
 
For nginx it'd be a pretty standard setup of creating your version of a nginx configuration `/etc/nginx/nginx.conf` and a unicorn upstream configuration `/etc/nginx/conf.d/default.conf`. 

`nginx.conf`

	user nginx;
	worker_processes  1;
	
	error_log  /var/log/nginx/error.log warn;
	pid        /var/run/nginx.pid;
	
	
	events {
	    worker_connections  1024;
	}
	
	
	http {
	    include       /etc/nginx/mime.types;
	    default_type  application/octet-stream;
	
	    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
	                      '$status $body_bytes_sent "$http_referer" '
	                      '"$http_user_agent" "$http_x_forwarded_for"';
	
	    access_log  /var/log/nginx/access.log  main;
	
	    sendfile        on;
	    #tcp_nopush     on;
	
	    keepalive_timeout  65;
	
	    #gzip  on;	
	    include /etc/nginx/conf.d/*.conf;
	}
	
	
`/etc/nginx/conf.d/default.conf`

	upstream app {
	    # Path to Unicorn SOCK file, as defined previously
	    server unix:/app/shared/sockets/unicorn.sock fail_timeout=0;
	}
	
	server {
	    listen 80;
	    server_name 127.0.0.1;
	
	    root /app/public;
	
	    try_files $uri/index.html $uri @app;
	
	    location @app {
	        proxy_pass http://app;
	        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	        proxy_set_header Host $http_host;
	        proxy_redirect off;
	    }
	
	    error_page 500 502 503 504 /500.html;
	    client_max_body_size 4G;
	    keepalive_timeout 10;
	}



## Unicorn

And here's what my `unicorn.rb` look like


	# set path to application
	app_dir = File.expand_path("../..", __FILE__)
	shared_dir = "#{app_dir}/shared"
	working_directory app_dir
	
	# Set unicorn options
	worker_processes 2
	preload_app true
	timeout 30
	
	# Set up socket location
	listen "#{shared_dir}/sockets/unicorn.sock", :backlog => 64
	
	# Logging
	stderr_path "#{shared_dir}/log/unicorn.stderr.log"
	stdout_path "#{shared_dir}/log/unicorn.stdout.log"
	
	# Set master PID location
	pid "#{shared_dir}/pids/unicorn.pid"
