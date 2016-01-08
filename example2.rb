require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'thread'

class JanDanArticle
  attr_accessor :title, :link, :star_num, :comment_num, :post_time, :author, :tag
end

class JanDanCrawler
  @@base_url = "http://jandan.net/"

  def self.get_all_articles_by_tag(tag)
    full_url = "http://jandan.net/tag/" + tag
    doc = Nokogiri::HTML(open(full_url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_789)"))
    pages = doc.at_css('.pages').text.split('/').last.to_i || 1
    puts "page #{pages}"

    # 用队列控制任务
    page_queue = Queue.new
    articles = []
    threads = []

    # threads << Thread.new do
    #   loop do
    #     sleep 0.01
    #     puts Thread.list.count
    #     break if Thread.list.count <= 2
    #   end
    # end

    if pages > 1
      2.upto(pages) do |i|
        page_queue << i
      end
    end

    5.times do
      threads << Thread.new do
        loop do
          break if page_queue.size == 0
          page = page_queue.pop
          full_url = "http://jandan.net/tag/" + tag + "/page/#{page}"
          doc = Nokogiri::HTML(open(full_url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_77#{page})"))
          articles_doc = doc.css('.post')
          articles_doc.each do |article_doc|
            articles << parse_doc_to_article(article_doc)
          end
        end
      end
    end

    threads.each(&:join)
    articles
  end

  def self.parse_doc_to_article(article_doc)
    JanDanArticle.new.tap do |article|
      article.title = article_doc.at_css(".title2 a").text
      article.link = article_doc.at_css(".title2 a").attr('href')
      article.author, article.tag = article_doc.at_css(".time_s").text
    end
  end
end

tag = 'geek'
time_s = Time.now
articles = JanDanCrawler.get_all_articles_by_tag(tag)
puts articles.size
File.write("articles-#{tag}.yml" , YAML.dump(articles))
time_e = Time.now
puts "spent #{time_e - time_s}s"
