# -*- coding: utf-8 -*-

require 'sinatra'
require 'thin'
require 'oauth'
require 'uri'
require 'json'
require 'erb'
require 'sanitize'

enable :sessions

use Rack::Auth::Basic do |username, password|
   username == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
end

consumer = OAuth::Consumer.new(ENV["CONSUMER_KEY"], ENV["CONSUMER_SECRET"], :site => "http://www.tumblr.com")
access = OAuth::AccessToken.new(consumer, ENV["ACCESS_TOKEN"], ENV["ACCESS_SECRET"])


get '/' do
  if !params.key?('pages')
      session['reblog'] = 0
      session['since_id'] = 0
  end

  query_string = (params||{}).map{|k,v|
    if k == 'pages'
      URI.encode('since_id') + "=" + URI.encode(session['since_id'].to_s)
    else
      URI.encode(k.to_s) + "=" + URI.encode(v.to_s)
    end
  }.join("&")

  @api = "http://api.tumblr.com/v2/user/dashboard" + (query_string.empty? ? "" : "?#{query_string}")
  response = access.get(@api)
  @dsbd = JSON.parse(response.body)
  delta = @dsbd["response"]["posts"][0]["id"] - @dsbd["response"]["posts"][-1]["id"]
  session['since_id'] = @dsbd["response"]["posts"][-1]["id"] - delta;
  @page = (!params.key?('pages') or params["pages"] == 1) ? 1 : params["pages"]
  erb :index
end

get '/reblog' do
  EM::defer do
    access.post("http://api.tumblr.com/v2/blog/malmrashede.tumblr.com/post/reblog", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  end
  session["reblog"] += 1
  '<html><head><title>rebloged</title></head><body>rebloged</body></html>'
end

get '/like' do
  EM::defer do
  access.post("http://api.tumblr.com/v2/user/like", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  end
  '<html><head><title>liked</title></head><body>liked</body></html>'
end

helpers do
  include Rack::Utils; alias_method :h, :escape_html
  def sanitize(html)
    Sanitize.clean(html, Sanitize::Config::BASIC)
  end
end

__END__

@@ index
<!DOCTYPE html>
<html lang="ja">
  <head>
    <title>dsbd</title>
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <link href="http://code.jquery.com/mobile/latest/jquery.mobile.min.css" rel="stylesheet" type="text/css" />
    <link href="dsbd.css" rel="stylesheet" type="text/css" />
    <script src="http://code.jquery.com/jquery-1.8.2.min.js"></script>
    <script src="http://code.jquery.com/mobile/latest/jquery.mobile.min.js"></script>
  </head>
  <body>


    <div id="page01" data-role="page">
    <div data-role="header">
        <h1><a href="http://guarded-caverns-4389.herokuapp.com/">dsbd <%= h session["reblog"] %> <%= h session["since_id"] %></a></h1>
    </div>
    <div class="content" data-role="content">
    <div class="autopagerize_page_element">
    <% @dsbd["response"]["posts"].each do |p| %>
      <div class="post xfolkentry taggedlink">
        <div class="<%= h(p['type']) %>">
        <% if(p['type'] == 'text') %>
          <p><%= sanitize p['title'] %></p>
          <p><%= sanitize p['body'] %></p>
        <% end %>

        <% if(p['type'] == 'quote') %>
          <div class="quote_text">
            <span class="short">
              <%= sanitize p["text"] %>
            </span>
          </div>
        <% end %>

        <% if(p['type'] == 'photo') %>
          <% img = p['photos'][0]['alt_sizes'][2] %>
    <p><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['HOST_NAME'] %>/reblog?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');"><img src='<%= img['url'] %>'/></a></p>
      <p><%= sanitize p['source'] %></p>
        <% end %>
        <div class="caption">
            <p><%= sanitize p['caption'] %></p>
            <% if(p.key?('source_title')) %>
              <p>(Source: <a href='<%= p['source_url'] %>'><%= sanitize p['source_title'] %>,</a> via <a href='<%= p['post_url'] %>'><%= sanitize p['blog_name'] %></a>)</p>
            <% end %>
        </div>
      <p class="reblog"><a data-role="button" href='javascript:void(0);' onclick="$.get('http://<%= h ENV['HOST_NAME'] %>/reblog?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">Reblog</a></p>
      <p class="like"><a data-role="button" href='javascript:void(0);' onclick="$.get('http://<%= h ENV['HOST_NAME'] %>/like?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">&hearts;</a></p>
        </div>
      </div>
  <% end %>
    </div>
    <div class="autopagerize_insert_before"></div>
    <div id="footer" data-role="footer">
      <a data-role="button" data-icon= "home" href="http://guarded-caverns-4389.herokuapp.com/">dsbd <%= h session["reblog"] %></a>
      <a rel="prev" data-role="button" href='/?pages=<%= h (@page.to_i-1) %>'>&lt;&lt;Prev</a>
      <a rel="next" data-role="button" href='/?pages=<%= h (@page.to_i+1) %>'>Next&gt;&gt;</a>
    </div>
  </div>
  </div>
  </body>
</html>

