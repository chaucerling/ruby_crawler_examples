require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'net/http'
require 'openssl'

config = YAML.load_file('config.yml')

if config['cookies'].nil? || config['cookies'].empty?
  # get authenticity_token
  response = Net::HTTP.get_response(URI("https://github.com/login"))
  doc = Nokogiri::HTML(response.body)
  authenticity_token = doc.at_css('input[name="authenticity_token"]').attr('value')
  puts authenticity_token
  cookies = response.get_fields('Set-Cookie').map {|x| x.split("; ").first}

  # post login form
  uri = URI("https://github.com/session")
  https = Net::HTTP.new(uri.host,uri.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/x-www-form-urlencoded'
  request['User-Agent'] = "Mozilla/5.0 Mac OS X 10_10_5"
  request['Cookie'] = cookies.join("; ")
  # # headers = {'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36"}
  data = {
    login: config['github']['username'],
    password: config['github']['password'],
    authenticity_token: authenticity_token,
    commit: 'Sign in'
  }
  request.body = URI.encode_www_form(data)
  response = https.request(request)

  # store cookie
  puts response.code, response.message
  if response.code == '200' || response.code == '302'
    cookies = response.get_fields('Set-Cookie').map {|x| x.split("; ").first}
    puts cookies
    config['cookies'] = cookies
    File.write("config.yml" , YAML.dump(config))
  else
    puts response.body
  end
end

# res = URI::HTTPS.get(URI("https://github.com/"), Cookie: config['cookies'].join("; "))
res_body = open("https://github.com/", "Cookie" => config['cookies'].join("; ")).read
puts Nokogiri::HTML(res_body).at_css('.alert').text
