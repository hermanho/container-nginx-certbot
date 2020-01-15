import os, re, sys, errno

def mkdir_p(path, mode):
    try:
        os.makedirs(path, mode)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

env_domains_regex = re.compile(
    "(?:([a-z0-9.-]+)->(https?:\/\/[a-z0-9.]+(?::\d{1,5})?))", re.DOTALL | re.IGNORECASE
)

ssl_protocols_str = 'TLSv1.3'
if 'ALLOW_TLS_12' in os.environ and os.environ['ALLOW_TLS_12'] == 'TRUE':
    print("Enable TLSv1.2")
    ssl_protocols_str = ssl_protocols_str + ' TLSv1.2'


nginx_template = """
map $http_x_forwarded_proto $proxy_x_forwarded_proto {{
    default $http_x_forwarded_proto;
    ''      $scheme;
}}
map $http_x_forwarded_port $proxy_x_forwarded_port {{
    default $http_x_forwarded_port;
    ''      $server_port;
}}
map $http_upgrade $connection_upgrade {{
    default upgrade;
    ''      close;
}}
map $scheme $proxy_x_forwarded_ssl {{
    default off;
    https on;
}}

server {{
    listen              443 ssl http2;
    server_name         {dns};
    ssl_certificate     /etc/letsencrypt/live/{dns}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{dns}/privkey.pem;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_buffer_size 4k;

    # modern configuration
    ssl_protocols """ + ssl_protocols_str + """;
    ssl_prefer_server_ciphers off;
    
    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
    proxy_set_header X-Forwarded-Ssl $proxy_x_forwarded_ssl;
    proxy_set_header X-Forwarded-Port $proxy_x_forwarded_port;
    
    proxy_buffering off;
    proxy_buffers 32 4k; 
    proxy_buffer_size 32k;
    proxy_busy_buffers_size 32k;
    client_max_body_size 1G;
    proxy_max_temp_file_size 0;

    location / {{
        proxy_pass {forwardUri};

{nginx_websocket}
    }}
    
    
    location /nginx-health {{
        access_log off;
        default_type text/plain;
        return 200 "healthy\n";
    }}
}}
"""

nginx_websocket_template = """
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_read_timeout 2h;
"""

nginx_conf_path = "/etc/nginx/conf.d/"
mkdir_p(nginx_conf_path, 0o700)

print("Creating nginx config from template and environment variables")

env_domains_str = os.environ["DOMAINS"] if "DOMAINS" in os.environ else ""
env_websocket_str = os.environ["WEBSOCKET"] if "WEBSOCKET" in os.environ else ""
env_websocket = env_websocket_str == "true"
env_domains_array = env_domains_regex.findall(env_domains_str)

if len(env_domains_array) > 0:
    print(env_domains_array)

    for (domain, forwardUri) in env_domains_array:
        print(domain + "->" + forwardUri)
        nginx_merged = nginx_template.format(
            dns=domain,
            forwardUri=forwardUri,
            nginx_websocket=nginx_websocket_template if env_websocket else "",
        )
        nginx_domain_conf_path = os.path.join(nginx_conf_path, domain+".conf")
        f = open(nginx_domain_conf_path, "w")
        f.write(nginx_merged)
        f.close()
        print(nginx_domain_conf_path + " saved")
    print(str(len(env_domains_array)) + " domain nginx conf saved")
    sys.exit(0)
else:
    print("No domain mapping found in environment variables")
    sys.exit(1)

