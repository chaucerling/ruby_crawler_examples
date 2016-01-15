require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'thread'

class JanDanArticle
  attr_accessor :title, :link, :star_num, :comment_num, :post_time, :author, :tag
end

class JanDanCrawler
  @@base_url = "http://jandan.net/"

  def self.get_all_articles_by_date(date)
    raise TypeError, 'date is not Date type' unless date.is_a?(Date)
    full_url = @@base_url + date.strftime("%Y/%m/%d")
    puts full_url
    doc = Nokogiri::HTML(open(full_url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_6)"))

    articles_doc = doc.css('.post.f .indexs')
    puts "#{articles_doc.size} articles"

    articles_doc.map do |article_doc|
      JanDanArticle.new.tap do |article|
        article.title = article_doc.at_css("h2 a").text
        article.link = article_doc.at_css("h2 a").attr('href')
        article.author, article.tag = article_doc.at_css(".time_s").text.split(' / ')
      end
    end
  end

  # 多线程
  def self.get_all_articles_by_date_2(date)
    raise TypeError, 'date is not Date type' unless date.is_a?(Date)
    full_url = @@base_url + date.strftime("%Y/%m/%d")
    puts full_url
    doc = Nokogiri::HTML(open(full_url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_6)"))

    articles_doc = doc.css('.post.f .indexs')
    puts "#{articles_doc.size} articles"

    threads = []
    articles = []
    articles_doc.each do |article_doc|
      threads << Thread.new do
        articles << JanDanArticle.new.tap do |article|
          article.title = article_doc.at_css("h2 a").text
          article.link = article_doc.at_css("h2 a").attr('href')
          article.author, article.tag = article_doc.at_css(".time_s").text.split(' / ')
        end
      end
    end
    threads.each(&:join) # 挂起主线程，等待子线程全部执行完毕
    return articles
  end

  def self.get_all_articles_by_date_3(date)
    raise TypeError, 'date is not Date type' unless date.is_a?(Date)
    full_url = @@base_url + date.strftime("%Y/%m/%d")
    puts full_url
    doc = Nokogiri::HTML(open(full_url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_6)"))

    # <span class="pages">2 / 2</span>
    pages = doc.at_css('.pages').text.split('/').last.to_i || 1

    threads = []
    articles = []

    # threads << Thread.new do
    #   loop do
    #     sleep 0.01
    #     puts Thread.list.count
    #     break if Thread.list.count <= 2
    #   end
    # end

    threads << Thread.new do
      first_page_articles_doc = doc.css('.post.f .indexs')
      puts "page1: #{first_page_articles_doc.size}"
      add = get_page_articles_by_doc(first_page_articles_doc)
      articles += add
    end

    # 多页并行
    if pages > 1
      2.upto(pages) do |i|
        threads << Thread.new do
          add = get_page_articles(date, i)
          articles += add
        end
      end
    end

    threads.each(&:join)
    articles
  end

  def self.get_page_articles(date, page)
    full_url = @@base_url + date.strftime("%Y/%m/%d") + "/page/#{page}"
    doc = Nokogiri::HTML(open(full_url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_6)"))
    articles_doc = doc.css('.post.f .indexs')
    puts "page#{page}: #{articles_doc.size}"
    get_page_articles_by_doc(articles_doc)
  end

  def self.get_page_articles_by_doc(articles_doc)
    articles_doc.map do |article_doc|
      parse_doc_to_article(article_doc)
    end
  end

  def self.parse_doc_to_article(article_doc)
    JanDanArticle.new.tap do |article|
      article.title = article_doc.at_css("h2 a").text
      article.link = article_doc.at_css("h2 a").attr('href')
      article.author, article.tag = article_doc.at_css(".time_s").text.split(' / ')
    end
  end
end

date = Date.parse("2015-7-9")

# time_s = Time.now
# articles = JanDanCrawler.get_all_articles_by_date(date)
# File.write('articles-' << date.to_s, YAML.dump(articles))
# time_e = Time.now
# puts "spent #{time_e - time_s}s"

# time_s = Time.now
# articles = JanDanCrawler.get_all_articles_by_date_2(date)
# puts articles.size
# File.write('articles-' << date.to_s, YAML.dump(articles))
# time_e = Time.now
# puts "spent #{time_e - time_s}s"

time_s = Time.now
articles = JanDanCrawler.get_all_articles_by_date_3(date)
puts articles.size
File.write("articles-#{date.to_s}.yml", YAML.dump(articles))
time_e = Time.now
puts "spent #{time_e - time_s}s"
