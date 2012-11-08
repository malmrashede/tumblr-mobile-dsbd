# -*- coding: utf-8 -*-

require 'sinatra'
require 'thin'
require 'oauth'
require 'uri'
require 'json'
require 'erb'

use Rack::Auth::Basic do |username, password|
  username == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
end

consumer = OAuth::Consumer.new(ENV["CONSUMER_KEY"], ENV["CONSUMER_SECRET"], :site => "http://www.tumblr.com")
access = OAuth::AccessToken.new(consumer, ENV["ACCESS_TOKEN"], ENV["ACCESS_SECRET"])


get '/' do

  query_string = (params||{}).map{|k,v|
    if k == 'pages'
      URI.encode('offset') + "=" + URI.encode(((v.to_i-1)*20).to_s)
    else
      URI.encode(k.to_s) + "=" + URI.encode(v.to_s)
    end
  }.join("&")

  @api = "http://api.tumblr.com/v2/user/dashboard" + (query_string.empty? ? "" : "?#{query_string}")
  response = access.get(@api)
  @dsbd = JSON.parse(response.body)
  @page = (!params.key?('pages') or params["pages"] == 1) ? 1 : params["pages"]
  erb :index
end

get '/reblog' do
  access.post("http://api.tumblr.com/v2/blog/malmrashede.tumblr.com/post/reblog", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  '<html><head><title>rebloged</title></head><body>rebloged</body></html>'
end

get '/like' do
  access.post("http://api.tumblr.com/v2/user/like", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  '<html><head><title>liked</title></head><body>liked</body></html>'
end

helpers do
  include Rack::Utils; alias_method :h, :escape_html
end

__END__

@@ index
<html>
  <head>
  <title>dsbd</title>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<style type="text/css">
            body {
                margin: 0px;
                background-color: #fff;
                font-family: Helvetica, Arial, sans-serif;
            }            

            a {
                color: #6498cc;
            }

            h1 {
                //width: 600px;
                padding: 0px 100px 20px 100px;
                margin: 50px auto 40px auto;
                border-bottom: solid 1px #ccc;
                text-align: center;
                font: Bold 55px 'Trebuchet MS', 'Lucida Sans Unicode', 'Lucida Grande', 'Lucida Sans', Arial, sans-serif;
                letter-spacing: -2px;
                line-height: 50px;
                position: relative;
            }
            
                h1 a {
                    color: #444;
                    text-decoration: none;
                }
                
                h1 img#rss {
                    border-width: 0px;
                    position: absolute;
                    right: 0px;
                    bottom: 10px;
                    width: 43px;
                    height: 23px;
                }

            div#content {
                //width: 420px;
                margin: auto;
                position: relative;
            }

                div#content div#description {
                    position: absolute;
                    right: -170px;
                    width: 160px;
                    text-align: right;
                }

            div#description {
                font: normal 17px Helvetica, Arial, sans-serif;
                line-height: 20px;
                color: #777;
            }

                div#description a {
                    color: #777;
                }

            div.post {
                position: relative;
                margin-bottom: 40px;
                padding-right: 20px;
            }

                div.post div.date {
                    position: absolute;
                    left: -260px;
                    text-align: right;
                    width: 230px;                
                    white-space: nowrap;
                    font: normal 34px Helvetica, sans-serif;
                    letter-spacing: -2px;
                    color: #ccc;
                    text-transform: uppercase;
                    line-height: 35px;
                }
                
                    div.post div.date div.date_brick {
                        float: right;
                        height: 30px;
                        width: 45px;
                        background-color: #6498cc;
                        color: #bbd5f1;
                        font: Bold 12px Verdana, Sans-Serif;
                        text-align: center;
                        line-height: 12px;
                        margin-left: 10px;
                        padding-top: 5px;
                        letter-spacing: 0px;
                        overflow: hidden;
                    }

                div.post img.permalink {
                    width: 14px;
                    height: 13px;
                    border-width: 0px;
                    background-color: #000;
                    display: none;
                    position: absolute;
                    right: 0px;
                    top: 0px;
                    z-index: 10;
                }
                
                    div.post:hover img.permalink {
                        display: inline;
                    }
                    
                div.post img {
                  //max-width: 500px;
                }

                div.post h2 {
                    font-size: 18px;
                    font-weight: bold;
                    color: #6498cc;
                    letter-spacing: -1px;
                    margin: 0px 0px 5px 0px;
                }

                    div.post h2 a {
                        color: #6498cc;
                        text-decoration: none;
                    }
            
                div.post div.caption {
                    font-size: 14px;
                    font-weight: bold;
                    color: #444;
                    margin-top: 10px;
                    padding: 0px 20px 0px 20px;
                }

                    div.post div.caption a {
                        color: #444;
                    }
    
            /* Regular Post */
            
                div.post div.regular {
                    font-size: 12px;
                    color: #444;
                    line-height: 17px;
                }

                    div.post div.regular blockquote {
                        font-style: italic;
                        border-left: solid 2px #444;
                        padding-left: 10px;
                    }
                        
            /* Quote Post */
            
                div.post div.quote div.quote_text {
                    font-family: Helvetica, Arial, sans-serif;
                    font-weight: bold;
                    color: #888;
                    border-left: solid 5px #6498cc;
                    padding-left: 10px;
                }
                
                    div.post div.quote div.quote_text span.short {
                        font-size: 36px;
                        line-height: 40px;
                        letter-spacing: -1px;
                    }
                    
                    div.post div.quote div.quote_text span.medium {
                        font-size: 25px;
                        line-height: 27px;
                        letter-spacing: -1px;
                    }
                    
                    div.post div.quote div.quote_text span.long {
                        font-size: 16px;
                        line-height: 20px;
                    }

                    div.post div.quote div.quote_text a {
                        color: #888;
                    }
        
                div.post div.quote div.source {
                    font-size: 16px;
                    font-weight: Bold;
                    color: #555;
                    margin-top: 5px;
                }

                    div.post div.quote div.source a {
                        color: #555;
                    }
            
            /* Link Post */
            
                div.post div.link a.link {
                    font: Bold 20px Helvetica, Arial, sans-serif;
                    letter-spacing: -1px;
                    color: #c00;
                }

                    div.post div.link span.description {
                        font-size: 13px;
                        font-weight: normal;
                        letter-spacing: -1px;
                        color: #444;
                    }
            
            /* Conversation Post */
                        
                div.post div.conversation ul {
                    list-style-type: none;
                    margin: 0px;
                    padding: 0px 0px 0px 1px;
                    border-left: solid 5px #bbb;
                }
            
                    div.post div.conversation ul li {
                        font-size: 12px;
                        padding: 4px 10px 4px 8px;
                        color: #444;
                        margin-bottom: 1px;
                    }
            
                        div.post div.conversation ul li span.label {
                            font-weight: bold;
                        }
                        
                            div.post div.conversation ul li span.user_1 {
                                color: #c00;
                            }
                            
                            div.post div.conversation ul li span.user_2 {
                                color: #00c;
                            }
                            
                            div.post div.conversation ul li span.user_3 {
                                color: #0a0;
                            }
                        
                        div.post div.conversation ul li.odd {
                            background-color: #f4f4f4;
                        }

                        div.post div.conversation ul li.even {
                            background-color: #e8e8e8;
                        }
            
            /* Video Post */
            
                div.post div.video {
                    width: 400px;
                    margin: auto;
                }

            /* Footer */
            
                div#footer {
                    margin: 40px 0px 30px 0px;
                    text-align: center;
                    font-size: 15px;
                    font-weight: bold;
                    color: #444;
                }
            
                    div#footer a {
                        text-decoration: none;
                        color: #444;
                    }
            
                        div#footer a:hover {
                            text-decoration: underline;
                        }
                    
                    div#footer div#credit {
                        font: normal 13px Georgia, serif;
                        font-size: 13px;
                        margin-top: 15px;
                    }

            .query {
                padding: 0px;
                margin: 25px 0px;
                list-style-type: none;
                border-bottom: solid 1px #ccc;
            }

            ol.notes li.note {
                border-top: solid 1px #ccc;
                padding: 10px;
            }

            ol.notes li.note img.avatar {
                vertical-align: -4px;
                margin-right: 10px;
                width: 16px;
                height: 16px;
            }

            ol.notes li.note span.action {
                font-weight: bold;
            }

            ol.notes li.note .answer_content {
                font-weight: normal;
            }

            ol.notes li.note blockquote {
                border-color: #eee;
                padding: 4px 10px;
                margin: 10px 0px 0px 25px;
            }

            ol.notes li.note blockquote a {
                text-decoration: none;
            }
        </style>
</head>
  <body>
    <div style="position: fixed; top: 0px; left: 0px; height: 0px; width: 0px; z-index: 9999999; "><div style="position: fixed; top: 100%; height: 0px; "><div style="position: relative; "></div></div></div>
  <div id="content">
  <% @dsbd["response"]["posts"].each do |p| %>
  <div class="post">
    <div class="<%= h(p['type']) %>">
    <% if(p['type'] == 'text') %>
      <p><%= p['title'] %></p>
      <p><%= p['body'] %></p>
    <% end %>

    <% if(p['type'] == 'quote') %>
      <div class="quote_text">
        <%= p["text"] %>
      </div>
    <% end %>

    <% if(p['type'] == 'photo') %>
      <% img = p['photos'][0]['alt_sizes'][-3] %>
<p><a href='<%= p['post_url'] %>'><img src='<%= img['url'] %>'  width='<%= img['width'] %>' height='<%= img['height'] %>'/></a></p>
      <p><%= p['source'] %></p>
    <% end %>
    <div class="caption">
    <p><%= p['caption'] %></p>
    <% if(p.key?('source_title')) %>
      <p>(Source: <a href='<%= p['source_url'] %>'><%= p['source_title'] %>,</a> via <a href='<%= p['post_url'] %>'><%= p['blog_name'] %></a>)</p>
    <% end %>
    </div>
    <p><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['BASIC_AUTH_USERNAME'] %>:<%= h ENV['BASIC_AUTH_PASSWORD'] %>@<%= h ENV['HOST_NAME'] %>/reblog?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">reblog</a></p>
    <p><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['BASIC_AUTH_USERNAME'] %>:<%= h ENV['BASIC_AUTH_PASSWORD'] %>@<%= h ENV['HOST_NAME'] %>/like?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">like</a></p>
  </div>
  <% end %>
    <div id="footer">
      <a rel='next' href='/?pages=<%= h (@page.to_i+1) %>'>Next&gt;&gt;</a>
      <p><%= h @api %></p>
    </div>
  </div>
  </body>
</html>

