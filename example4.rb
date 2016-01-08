require 'mechanize'

def goole_translate_en_to_zh(en)
  agent = Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
  end

  page = agent.get('https://translate.google.com/')
  search_result = page.form_with(:id => 'gt-form') do |search|
    search['text'] = en
    search['sl'] = 'en'
    search['tl'] = 'zh-CN'
  end.submit

  puts search_result.search('#result_box').text
end

# goole_translate_en_to_zh('hello world')

def github_login()
  agent = Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
  end
  config = YAML.load_file('config.yml')

  login_page = agent.get('https://github.com/login')
  session_page = login_page.form_with(action: "/session") do |form|
    form['login'] = config['github']['username']
    form['password'] = config['github']['password']
  end.submit

  # puts session_page.search('.header').text
  # agent.cookie_jar.save('github_cookie.yml')
  agent.cookie_jar.save('github_cookie.yml', session: true)
end

def github_index()
  agent = Mechanize.new do |agent|
    agent.user_agent_alias = 'Mac Safari'
  end
  agent.cookie_jar.load('github_cookie.yml')
  puts agent.get("https://github.com").search('.alert').text
end

github_login()
github_index()
